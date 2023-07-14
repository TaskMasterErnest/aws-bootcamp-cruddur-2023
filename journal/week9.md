# Week 9 — CI/CD with CodePipeline, CodeBuild and CodeDeploy
Continuous Integration is the basically the process of getting code ready to be served. It entails the testing, building and packaging of code. This is done automatically via pipeline so that every time code is committed and that pipeline triggered, it runs a set of instructions to test, build and package the code.
Continuous Deployment is the automatic serving of code that has been tested, built and packaged unto a platform made available to serve the code eg, a server. 
Continuous Integration is an integral part of Continuous Deployment, it is the automatic delivery of code unto a platform where it can be served.

AWS has CI and CD tools; CodeCommit, CodeBuild and CodeDeploy which are all an integral part of a bigger tool called the CodePipeline.

AWS CodePipeline is a continuous delivery service that helps you automate your release pipelines for fast and reliable application and infrastructure updates. It automates the steps required to release your software changes continuously. CodePipeline can be used to automate the following steps:
- Source control: CodePipeline can be used to fetch source code from a variety of source control repositories, including GitHub, Bitbucket, and AWS CodeCommit.
- Build: CodePipeline can be used to build your code using a variety of build tools, including AWS CodeBuild, Jenkins, and Travis CI.
- Test: CodePipeline can be used to test your code using a variety of testing frameworks, including JUnit, Cucumber, and Selenium.
- Deploy: CodePipeline can be used to deploy your code to a variety of deployment targets, including AWS Elastic Beanstalk, AWS Lambda, and Amazon ECS.
CodePipeline is a fully managed service, so you don't have to worry about provisioning or managing any servers. It is also highly scalable, so you can easily add or remove stages as your needs change.



In this session, the Cruddur application backend will be built and deployed with the AWS CodePipeline tool. The process entails the following:
1. building the image with CodeBuild. 
2. deploying the built image with CodeDeploy to Amazon ECS.

Before creating the pipeline, create a new branch called `production` from the `main` branch in the Github repository. This new branch will be used to trigger the pipeline to activate.

Also we need to create two files that will be used in the successful deployment of our image.
1. a buildspec code, in the `/backend-flask/buildspec.yml` file.
```json
# Buildspec runs in the build stage of your pipeline.
version: 0.2
phases:
  install:
    runtime-versions:
      docker: 20
    commands:
      - echo "cd into $CODEBUILD_SRC_DIR/backend"
      - cd $CODEBUILD_SRC_DIR/backend-flask
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $IMAGE_URL
  build:
    commands:
      - echo Build started on `date`
      - echo Building the Docker image...
      - docker build -f Dockerfile.prod -t backend-flask .
      - docker tag $REPO_NAME $IMAGE_URL/$REPO_NAME
  post_build:
    commands:
      - echo Build completed on `date`
      - echo Pushing the Docker image..
      - docker push $IMAGE_URL/$REPO_NAME
      - cd $CODEBUILD_SRC_DIR
      - echo "imagedefinitions.json > [{\"name\":\"$CONTAINER_NAME\",\"imageUri\":\"$IMAGE_URL/$REPO_NAME\"}]" > imagedefinitions.json
      - printf "[{\"name\":\"$CONTAINER_NAME\",\"imageUri\":\"$IMAGE_URL/$REPO_NAME\"}]" > imagedefinitions.json

env:
  variables:
    AWS_ACCOUNT_ID: <replace with ACCOUNT ID>
    AWS_DEFAULT_REGION: eu-west-2
    CONTAINER_NAME: backend-flask
    IMAGE_URL: <replace with ACCOUNT ID>.dkr.ecr.eu-west-2.amazonaws.com
    REPO_NAME: backend-flask:latest
artifacts:
  files:
    - imagedefinitions.json
```

2. a policy that allows CodeBuild to access ECR, in the `aws/policies/codebuild-ecr-backend-role.json`.
	1. this policy is to be put in the backend repository on ECR. This will allow CodeBuild to have access to ECR.
	2. there will be a default role created like this `codebuild-cruddur-backend-flask-bake-image-service-role`. Go to that Role and add this as an inline policy, can call it `codebuild-ecr-backend-role-policy`.
```json
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "VisualEditor0",
        "Effect": "Allow",
        "Action": [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:GetAuthorizationToken",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ],
        "Resource": "*"
      }
    ]
  }
```


### Creating the build in CodeBuild
- Create a new project with the name `cruddur-backend-flask-bake-image`.
	- enable build badges.
- In Source, choose GitHub to be the source provider.
	- connect to your GitHub using OAuth
	- in the repo box, select the `aws-bootcamp-cruddur-2023` as the projecto to use.
	- enter `production` as the source version, as this is the branch the code will be taken from.
	- set the code depth to 1
- ~~For the primary source webhook events, on "Webhook", activate "rebuild every time a code change is pushed to this repository".~~
	- ~~choose "Single Build" as the build type.
	- ~~for event type, set it to `PULL_REQUEST_MERGED`, this makes sure to start building the code only when a pull request has been merged into the `production` branch.~~
- In Environment, choose "Managed Image".
	- use "Amazon Linux 2" as the Operating System
	- choose the "Standard" runtime
	- for images, choose the latest image
	- set the environment type to be "Linux"
	- check the "Privileged" button that allows the user to build Docker images
	- use a "New Service Role" and let the service role name be the default name 
- In "Additional Configurations", set the timeout to be 15 minutes.
	- leave the "Queued timeout"
	- we have no certificate to use to access the S3 resources so "Do not install any certificate"
	- do not use a VPC nor a subnet nor any security groups
	- set the compute to use "3GB memory, 2 VCPUs".
- Under the BuildSpec, choose "use a buildspec file".
	- set the name to be `backend-flask/buildspec.yml`
- In Artifacts, choose "No Artifacts" as we are going to be pushing the built Docker image to ECR.
- For Logs, choose CloudWatch Logs, set the group name to be `/cruddur/build/backend-flask` and the stream name to be `backend-flask`.


### Creating the pipeline in CodePipeline
- Enter the AWS Console, go to CodePipeline. Create a new pipeline with the name `cruddur-backend-fargate`. This will build the backend and deploy it to be used in Fargate.
	- use the default S3 storage and the default Managed Key services.
- Set the source provider to GitHub (Version 2) and then click on "Connect to GitHub". 
	- give it a connection name, eg `cruddur`.
	- click on "Install a new app", find your working repo and connect into it.
- In the CodePipeline page, choose the working repo and choose a branch to work off in ie. `production` branch created early on.
	- set the change detection process to "start the pipeline on source code change".
	- for the Output Artifact, choose the default one given in CodePipeline.
- For the build stage, select "AWS CodeBuild" as the build provider, select the appropriate region and select the `cruddur-backend-flask-bake-image` as the project to be used.
	- set the Input Artifacts to be 'SourceArtifact'
	- set the Output Artifacts to be "ImageDefinition"
- For the deploy stage, select/use Amazon ECS.
	- select the appropriate region
	- choose the cluster name in Amazon ECS, the `cruddur` cluster on the ECs cluster.
	- choose the `backend-flask` service.
	- set the Input Artifact to be "ImageDefinition".


### Testing the Pipeline
- In AWS Fargate, set the desired number of tasks for the backend from 0 to 1, to start the service. When up, test the `api.thetaskmasterernest.cyou/api/health-check` to see it you get the message `{ success: true }`.
- In the `/backend-flask/app.py` file, modify the code in the health-check function to `return {"success": True, "version": 1}, 200`.
- Update the image repo by building and pushing the image to ECR, run `/bin/ecr/login`, then `/bin/backend/build` and `/bin/backend/push.
- Merge this branch into the `production` branch to trigger the pipeline to run.
- After the pipeline has completed, check the `api.thetaskmasterernest.cyou/api/health-check`, the message returned should be `{"success": True, "version": 1}`.

- CodePipeline was successful.
![[codepipeline.png]]
