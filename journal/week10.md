# Week 10 — CloudFormation 

CloudFormation is an AWS IaC tool. It is a service that helps the user to model and set up AWS resources so that they can spend lesstime managing resources and more time focusing on the applications that run on those services in AWS.

With CloudFormation, a user can:
- *Model the infrastructure as code*: The AWS resources can be defined on a template and the CloudFormation used to provision those resources. It makes it easy to replicate those resources and tot manage/make changes to them in a controlled way.
- *Provision the infrastructure quickly and reliably*: Provisioning of resources is done automatically so the user can be sure of up-to-date infrastructure brought up fast when needed.
- *Manage infrastructure as a single unit*: CloudFormation has all the resources in one place on the same template. Updating and rolling back your resources can be done using the same template.
- *Automate infrastructure deployments*: CloudFormation can be integrated with AWS services like CodePipeline and CodeDeploy to automate the deployment of infrastructure.

In simple terms, this resource is used to set up and deploy AWS services in a repeatable and reliable way.

## Preparation
1. Install `cfn-lint` in the `.gitpod.yml` with `pip install cfn-lint` under the `cfn` task (change this to `cloudformation`).
2. Install `cfn-guard` tool. The `cfn-guard` is an open-source command line interface (CLI) that checks CloudFormation templates for policy compliance using a simple, policy-as-code, declarative language. It is used to enforce security and compliance policies on AWS CloudFormation templates. It is a tool written in Rust so we install with the command `cargo install cfn-guard`; add this to the `.gitpod.yml` file under `cloudformation` task. The docs on how to use to tool to [validate a CloudFormation template.](https://docs.aws.amazon.com/cfn-guard/latest/ug/validating-rules.html)
3. Create an s3 bucket to house the CloudFormation changeset templates that will be generated. Create manually or use the the CLI command `aws s3 mb s3:// bucketname` as `aws s3 mb s3://cfn-artifacts-taskmaster`. Export this and make this available in the Gitpod environment; `export CFN_BUCKET="cfn-artifacts-taskmaster"` and `gp env CFN_BUCKET="cfn-artifacts-taskmaster"`.
4. Install Andrew Brown's ruby library used to work configure CloudFormation to work with `.toml` files. Mostly to pass parameters to the CloudFormation templates. Install with the command, `gem install cfn-toml`. Add this to the `.gitpod.yml` file under the `cloudformation` task. The version should be `1.0.12` or greater. For manual installation this should be done in the root dir.
5. Install the AWS SAM CLI. Place it in the `.gitpod.yml` file under its own `aws-sam` task.
```YAML
- name: aws-sam
    before: |
      cd /workspace
      wget https://github.com/aws/aws-sam-cli/releases/latest/download/aws-sam-cli-linux-x86_64.zip
      unzip aws-sam-cli-linux-x86_64.zip -d sam-installation
      sudo ./sam-installation/install
      sudo rm -rf ./aws-sam-cli-linux-x86_64.zip
      sudo rm -rf ./sam-installation
      cd $THEIA_WORKSPACE_ROOT
```

## Tips
1. On VSCode, you can use an extension called CloudFormation Linter, which lints the code automatically.

## Creating Configuration and Templates
- Create a dir `/aws/cloudformation` to house all the CloudFormation templates.
- Create a dir `/bin/cloudformation` to house all the scripts that will be used to activate the CloudFormation templates.
- You will need to delete all running services that have been already configured to avoid bills on AWS, keep them running if spend is not an issue.

### 1. Networking Template
- Much of the code is self-explanatory in the CloudFormation template, here, a custom network will be configured for the resources that will be deployed using the CloudFormation templates.
- Create a directory `/aws/cloudformation/network`; with the files, `/network/template.yaml` and `/network/config.toml` and another `/network/config.example.toml`.
- The `.toml` files contain parameters that the template references that cannot be passed directly into the CloudFormation template.
- Create a `/bin/cloudformation/network-provision` file, to hold the scripts needed to deploy this template.

### 2. Cluster Template
- This template is for the Fargate cluster in which the application will be running, complete with an Application LoadBalancer with its security groups and other configurations.
- Create a directory `/aws/cloudformation/cluster`; with the files, `/cluster/template.yaml` and `/cluster/config.toml` and another `/cluster/config.example.toml`.
- In here, the already configured TLS certificate ARN for the LoadBalancer from the Amazon Certificate Manager (ACM) has to be referenced. Place it in the `.toml` file where it will be referenced.
- A new Application LoadBalancer will be created. Go to Route53 and configure the `api.` and `<blank>` record in the Hosted Zones to use the new LoadBalancer instead.
	- delete the old LoadBalancer with its target group and security groups.
- Create a `/bin/cloudformation/cluster-provision` file, to hold the scripts needed to deploy this template.

### 3. RDS - PostgreSQL Template
- This template is to create an RDS instance with PostgreSQL database running in it; complete with its Security Group.
- Create a directory `/aws/cloudformation/postgresRDS`; with the files, `/postgresRDS/template.yaml` and `postgresRDS/config.toml` and another `/postgresRDS/config.example.toml`.
- In here, the `MasterUserPassword` has to be passed discreetly into the code when deploying this template. Override the parameters for this by exporting the `MasterUserPassword` and making it available in the Gitpod environment. `export DB_PASSWORD=<strong-password>` and `gp env DB_PASSWORD=<strong-password>`.
- After the deployment of this instance, we have to change / add the CONNECTION_URL for the RDS instance in the Parameter Store to contain the new instance's username, password and ARN.
	- this will be a perfect time to stop the old database and delete it completely (if comfortable).
- Create a `/bin/cloudformation/postgresRDS-provision` file, to hold the scripts needed to deploy this template.

### 4. AWS Serverless Application Model, DynamoDB and DynamoDB Streams Template
- This template creates the DynamoDB database and the streams needed to constantly process information against the DynamoDB
- We write this in a SAM (Serverless Application Model) template. The DynamoDB data/streams is going to be served with Lambdas.
- This SAM directory structure is different, it is going to be in the root directory. Create a `sam-dynamodb` dir in the root directory.
- Copy over the `aws/json/lambda/cruddur-messaging-dynamodb-stream.py` file over to `/sam-dynamodb/function/lambda_function.py`.
- Create the following files, `/sam-dynamodb/config.toml`, `/sam-dynamodb/template.yaml`, `/sam-dynamodb/build`, `/sam-dynamodb/package`, `/sam-dynamodb/deploy`.
- Add `build.toml` to the `.gitignore` file.
- Run the commands in the order; `build`, `package`, `deploy`. Check that a `.aws-sam` dir will be created and if the configurations have been successfully executed and the right directories are populated.

### 5. Service Template
- This template creates the services that will be deployed in the Fargate cluster, the ECS services/containers.
- This template relies on the first three created, as it specifically needs the LoadBalancer for testing purposes.
- The `backend-flask` service is the one being tested here, when deployed check to see if it is successfully up and running. Test the service by calling on the `/api/health-check`. 
	- this might take a while to come up if the `api` route has not been configured to point to the new LoadBalancer. Patience and constant checks on the service are what are needed make this work LOL.
- Create a `/bin/cloudformation/service-provision` file, to hold the scripts needed to deploy this template.

### 6. CI/CD Template
- This template is to cater for the automated building and deployment of our backend and frontend code that will be run by the Fargate service.
- Create the `/aws/cloudformation/cicd` directory, add the `cicd/template.yaml` and the `cicd/config.toml`. 
- We will be implementing a nested stack where we build the code separately with CodeBuild and then ship it to CodePipeline for the delivery.
- Create a `/cicd/nested/codebuild.yaml` file and populate it with code. For me, the `GITHUB_BRANCH = production`.
- create an artifacts bucket to store the artifacts that will be generated with the CodeBuild code. Use the command `aws s3 mb s3://codepipeline-cruddur-artifacts-taskmaster`.
- Make a new directory in the root directly, `/tmp` and put `tmp/*` in the `.gitignore` file.
- When this code has run, it will fail on the Source Pipeline in the CodeDeploy stage of CodePipeline.
	- You will see `Action execution failed`.
	- On the left panel, go to Settings and click Connections
	- Select the pending `codestar connection` and click on `Update Pending Connection`.
	- A pop-up will show that that will require you to connect to your GitHub account, choose the installed application, confirm and start the process. 
	- Go back to Pipeline and click on Release Change to start the pipeline again.
- Create a `/bin/cloudformation/cicd-provision` script to hold the code to 'deploy'

### 7. Hosting the Frontend Statically on CloudFront
- This template will help to host the frontend code out of an S3 bucket.
- In the code, we will create two buckets to take care of the naked domain and the www. bucket.
- For this template, we use the Certificate ARN from the `us-east-1` region.
- Go to Route53 Hosted Zone in my default region, delete the `A` record for `taskmasterernest.cyou`. This is done so as not to conflict with the one to be generated by the template for use.
- The `HostedZoneId` for CloudFront is a default number defined by AWS that has to be used in order for the template to work.
