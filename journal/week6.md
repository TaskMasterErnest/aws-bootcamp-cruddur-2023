# Week 6 — Deploying Containers

1. What is AWS Fargate?
	- AWS Fargate is a *serverless compute engine* for containers that allows you to run containers without having to manage the underlying EC2 instances.
	- It's a fully managed service that scales and provisions the resources needed to run your containers.
```Text
- A serverless compute engine is a cloud computing service that allows you to run code without having to manage servers or infrastructure.
- It works by dynamically allocating resources for your code to run and automatically scaling up or down based on demand.
- This means you only pay for the compute resources you actually use, rather than paying for a fixed amount of server capacity.
- Serverless compute engines typically use event-driven architecture, where code is triggered by events such as HTTP requests, file uploads, or database changes.
- AWS Lambda, Google Cloud Functions, and Azure Functions are examples of serverless compute engines provided by cloud providers.
```
	

2. How does AWS Fargate work?
	- You create a task definition that describes your container requirements (e.g. memory, CPU).
	- You create a service that runs one or more instances of your task definition.
	- Fargate provisions the necessary compute resources to run your containers and manages the scaling and availability of the containers.
```Text
A task definition in AWS Fargate is a blueprint that defines the container(s) that run as part of a task.

In simpler terms, a task definition tells Fargate what containers to run and how to run them.

It includes important information such as the Docker image to use, the CPU and memory requirements, networking information, and any data volumes that need to be mounted.

For example, a task definition might include instructions to run two containers: one for a web server and one for a database, with specific configurations for each container, such as the port to listen on or the amount of memory to use. The task definition would also specify how the containers communicate with each other and with the outside world.
```

3. What are the benefits of using AWS Fargate?
	- Reduced operational overhead: You don't have to manage or patch EC2 instances, as Fargate handles the underlying infrastructure.
	- Efficient resource utilization: Fargate optimizes the resources needed to run your containers, which reduces costs and improves performance.
	- Scalability: Fargate can scale your containers automatically based on demand.

4. How do you use AWS Fargate?
	- Define your container requirements in a task definition.
	- Launch a service that runs your task definition.
	- Optionally, use an Application Load Balancer to distribute traffic to your containers.

5. How does pricing work for AWS Fargate?
	- You pay only for the resources used by your containers, which is calculated based on the CPU and memory allocated to your tasks.

6. What are some use cases for AWS Fargate?
	- Running microservices and APIs.
	- Running batch jobs and processing tasks.
	- Building and deploying containerized applications.
	- Running machine learning and data processing workloads.


- In the `gitpod.yml` file, automate the connection to the RDS PostgreSQL instance by updating the command that updates the security group for that instance:
```Yaml
 - name: postgres
    init: |
      curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc|sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg
      echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" |sudo tee  /etc/apt/sources.list.d/pgdg.list
      sudo apt update
      sudo apt install -y postgresql-client-13 libpq-dev
    command: |
      export GITPOD_IP=$(curl ifconfig.me)
      source "$THEIA_WORKSPACE_ROOT/backend/bin/rds/update-sg-rule" //writing the correct path to take to update the security group.
```


## Performing Healthchecks on Services

### 1. Test the connection to the RDS instance using this script:
```Bash
#!/usr/bin/env python3

import psycopg
import os
import sys

connection_url = os.getenv("CONNECTION_URL") #can change this to the PROD_CONNECTION_URL to test the production postgresDB

conn = None
try:
  print('attempting connection')
  conn = psycopg.connect(connection_url)
  print("Connection successful!")
except psycopg.Error as e:
  print("Unable to connect to the database:", e)
finally:
  conn.close()
```


### 2. Test Flask Service

1. Place an endpoint in the `app.py` to run a health-check on the Flask backend service.
```Python
# place before Rollbar test, and do not include Rollbar test in production, comment it out.

@app.route('/api/health-check')
def health_check():
  return {'success': True}, 200
  
#@app.route('/rollbar/test')
#def rollbar_test():
#    rollbar.report_message('Hello World!', 'warning')
#    return "Hello World!"
```

2. Create a new script at `/bin/flask/health-check` to check on the health-check endpoint given:
	- give it user permissions to be run `chmod u+x ./bin/flask/health-check`
```Bash
#!/usr/bin/env python3

import urllib.request

try:
  response = urllib.request.urlopen('http://localhost:4567/api/health-check')
  if response.getcode() == 200:
    print("[OK] Flask server is running")
    exit(0) # success
  else:
    print("[BAD] Flask server is not running")
    exit(1) # false
# This for some reason is not capturing the error....
#except ConnectionRefusedError as e:
# so we'll just catch on all even though this is a bad practice
except Exception as e:
  print(e)
  exit(1) # false
```


### 3. Create a CloudWatch Log group
1. Create a log group to store logs for the Fargate cluster for the Cruddur application:
	- the retention persists the logs for 1 day in CloudWatch.
```Bash
aws logs create-log-group --log-group-name "cruddur"
aws logs put-retention-policy --log-group-name "cruddur" --retention-in-days 1
```


### 4. Create ECS Cluster
1. Create an ECS cluster via the CLI
```bash
aws ecs create-cluster \
--cluster-name cruddur \
--service-connect-defaults namespace=cruddur
```
- The need to use ECS clusters is to eliminate the need for the user to manually install, operate and scale their own cluster management infrastructure. It makes use of containers as the building blocks of the applications.
- In the code above, the defaults are set; including using Fargate's serverless computing as the primary infrastructure.
- The `service-connect-defaults` maps unto the services creates in the Cloud and can be viewed through the Cloud Map; AWS Cloud Map acts as a DNS service, hence the services here can be accessed via their namespaces by the account user.
```Text
- AWS Cloud Map is a service discovery tool for discovering and connecting to resources.
- ECS services can be registered with AWS Cloud Map to create a custom namespace.
- Services can be discovered by other services using the custom namespace and DNS queries.
- AWS Cloud Map can provide additional metadata about the service, such as its IP address, port, and other attributes.
- This integration enables highly scalable and dynamic microservices-based applications that can adapt to changing conditions.
- AWS Cloud Map manages the DNS and service discovery, while ECS handles the deployment and scaling of containers.
```


## 5. Create ECR Repo and Push Image
- There are three images to take care of here, the default python image for building the application, the flask backend and the react frontend. 
- Create a repository for each image, to store the image versions in it.
- Download, tag and push a docker image into that ECR repo. (DockerHub repo usually is not reliable in development.)
- The procedures for having repo image is this:
	- create a repo for the image
	- login to Docker via the AWS account
	- set a local URL for the path of the repository on AWS
	- pull the image
	- tag the image with the local URL
	- push the newly-tagged image to the AWS ECR repo.



### A. The base Python image
1. Create base Python image ECR repo:
```bash
aws ecr create-repository --repository-name cruddur-python --image-tag-mutability MUTABLE
```
2. Login to Docker via the ECR 
	- the ACCOUNT_ID and DEFAULT_REGION should be present as environment variables locally.
```Bash
aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com"
```
3. Set the URL to the AWS ECR for the Python repo.
```Bash
export ECR_PYTHON_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/cruddur-python"
echo $ECR_PYTHON_URL #this is to verify that the URl is the same as given by ECR for that repository URI
```
4. Pull the Docker image for the base python being used.
```Bash
docker pull python:3.10-slim-buster
```
5. Tag the image to hold the name of the ECR repo created; this is to make pushing to that repo easier.
```Bash
docker tag python:3.10-slim-buster $ECR_PYTHON_URL:3.10-slim-buster
docker push $ECR_PYTHON_URL:3.10-slim-buster
```
- Change the address of the container image to use the AWS ECR repo image in the `backend-flask` Dockerfile.
	- and make a modification to the environment the Python server will be running in
```Dockerfile
FROM $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/cruddur-python 
# replace the ID and REGION with the actual fleshed-out values.

#change the ENV FLASK_ENV=development
ENV FLASK_DEBUG=1
```
- Test that the container can be pulled into the Gitpod environment. Best thing to do is to run the above Docker login command again in preferrably the `aws-cli` terminal of gitpod and use compose to start the `backend-flask` service. `docker compose up backend-flask db`.
- The the health-check endpoint to ascertain that it is working `/api/health-check` in the URL of the `backend-flask` service.


### B. The backend Flask app
1. Create base backend-flask image ECR repo:
```bash
aws ecr create-repository --repository-name backend-flask --image-tag-mutability MUTABLE
```
2. Login to Docker via the ECR 
	- the ACCOUNT_ID and DEFAULT_REGION should be present as environment variables locally.
```Bash
aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com"
```
3. Set the URL to the AWS ECR for the backend-flask repo.
```Bash
export ECR_BACKEND_FLASK_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/backend-flask"
echo $ECR_BACKEND_FLASK_URL #this is to verify that the URl is the same as given by ECR for that repository URI
```
4. Build the Docker image for the backend-flask being used.
```Bash
docker build -t backend-flask .
```
5. Tag the image to hold the name of the ECR repo created; this is to make pushing to that repo easier.
	- add the `latest` tag, this will help ECS find the image easily, not adding it will create a DevOps overhead.
```Bash
docker tag backend-flask:latest $ECR_BACKEND_FLASK_URL:latest
```
6. Push the image to AWS ECR.
```Bash
docker push $ECR_BACKEND_FLASK_URL:latest
```

- FOR THE FRONTEND APPLICATION, CERTAIN SERVICES HAVE TO BE WORKING THAT WILL BE REFERENCED IN THE BUILD PROCESS OF THE CONTAINER,
- HENCE SEE BELOW FOR PROCEDURE TO LAUNCH FRONTEND CONTAINER.


## 6. Services and Tasks in ECS Cluster
A quick definition for Services are tasks that are designed to be long-running. Tasks on the other hand are jobs that run to do a single job, they are NOT long-running. Creating a service / task requires that a task definition is set up for either one of them.
`Learn how to create an ECS cluster through ClickOps`.
- Before setting up the task definitions, the ServiceExecutionRoles and TaskRoles have to be set in the AWS account. They are set up as AWS Roles.
- Our Roles here depend on parameters to function, the AWS Parameter Store handles the parameters.
	- The procedure is as this:
		1. set the parameters in the Parameter Store.
		2. execute the Role policies.
- Set the parameters by running these in the AWS CLI:
```Bash
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/AWS_ACCESS_KEY_ID" --value $AWS_ACCESS_KEY_ID
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/AWS_SECRET_ACCESS_KEY" --value $AWS_SECRET_ACCESS_KEY
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/CONNECTION_URL" --value $RDS_CONNECTION_URL
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/ROLLBAR_ACCESS_TOKEN" --value $ROLLBAR_ACCESS_TOKEN
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/OTEL_EXPORTER_OTLP_HEADERS" --value "x-honeycomb-team=$HONEYCOMB_API_KEY"
```
- check the AWS Parameter Store and verify that these parameters are all set and accurate.



#### Create ServiceRoles
- The procedure involved in creating the ServiceExecutionRole is this:
- Create a folder called `/aws/policies`
1. Create a Role, `CruddurServiceExecutionRole`, with the JSON file below.
	- file name for JSON, `aws/policies/service/service-assume-execution-role.json`
```Json
{
		"Version": "2012-10-17",
		"Statement": [
				{
					"Sid": "",
					"Effect": "Allow",
					"Principal": {
							"Service": [
									"ecs-tasks.amazonaws.com"
							]
					},
					"Action": "sts:AssumeRole"
				}
		]
}
```

```Bash
aws iam create-role --role-name CruddurServiceExecutionRole \
--assume-role-policy-document file://aws/policies/service/service-assume-execution-role.json
```

2. Create a Policy for that role, `CruddurServiceExecutionPolicy` with the JSON file below
	- file name for JSON, `aws/policies/service/service-execution-policy.json`
```Json
{
		"Version": "2012-10-17",
		"Statement": [
				{
		      "Effect": "Allow",
		      "Action": [
		        "ecr:GetAuthorizationToken",
		        "ecr:BatchCheckLayerAvailability",
		        "ecr:GetDownloadUrlForLayer",
		        "ecr:BatchGetImage",
		        "logs:CreateLogStream",
		        "logs:PutLogEvents"
		      ],
		      "Resource": "*"
		    },
				{
					"Effect": "Allow",
					"Action": [
							"ssm:GetParameters",
							"ssm:GetParameter"
					],
					"Resource": "arn:aws:ssm:eu-west-2:<AWS_ACCOUNT_ID>:parameter/cruddur/backend-flask/*"
				}
		]
}
```
3. Add the permissions policy ie. `CruddurServiceExecutionPolicy`  to the role `CruddurServiceExecutionRole`.
```Bash
aws iam put-role-policy \
--role-name CruddurServiceExecutionRole \
--policy-name CruddurServiceExecutionPolicy \
--policy-document file://aws/policies/service/service-execution-policy.json
```
4. Attach the policy to the role as such:
```Bash
aws iam attach-role-policy \
--policy-arn arn:aws:iam::478429420160:policy/CruddurServiceExecutionPolicy \
--role-name CruddurServiceExecutionRole
```



#### Create TaskRoles
- The procedure is identical to the ones above.
- Using the same `aws/policies` but adding another folder for tasks ie `aws/policies/task`.
1. Create a TaskRole, `CruddurTaskRole`, using the JSON below
	- file name for this should be `aws/policies/task/task-assume-execution-role.json`
```JSON
{
		"Version": "2012-10-17",
		"Statement": [
				{
					"Sid": "",
					"Effect": "Allow",
					"Principal": {
							"Service": [
									"ecs-tasks.amazonaws.com"
							]
					},
					"Action": "sts:AssumeRole"
				}
		]
}
```

```Bash
aws iam create-role \
--role-name CruddurTaskRole \
--assume-role-policy-document file://aws/policies/task/task-assume-execution-role.json
```

2. Create a policy for that role, `SSMAccessPolicy`, with the JSON file below.
	- filename for the JSON `aws/policies/task/task-execution-policy.json`
```JSON
{
	"Version": "2012-10-17",
	"Statement": [
			{
				"Effect": "Allow",
				"Action": [
						"ssmmessages:CreateDataChannel",
						"ssmmessages:OpenDataChannel",
						"ssmmessages:OpenControlChannel",
						"ssmmessages:CreateControlChannel"
				],
				"Resource": "*"
			}
	]
}
```
3. Add the Policy to the Role
```Bash
aws iam put-role-policy \
--role-name  CruddurTaskRole \
--policy-name SSMAccessPolicy \
--policy-document file://aws/policies/task/task-execution-policy.json
```
4. Attach some new policies for CloudWatch and AWSXRay services
```Bash
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/CloudWatchFullAccess --role-name CruddurTaskRole
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess --role-name CruddurTaskRole
```
- Check Polices to see if these roles are available and attached.



#### Task Definitions
Create the Task Definitions in the `aws/task-definitions` folder.
1. BACKEND FLASK TASK DEFINITION
The task definition for the backend-flask app is in `aws/task-definitions/backend-flask.json`.
- A couple of things to change are the AWS ACCOUNT ID and the AWS REGION; 
	- the ARNs for the execution and task roles and under environment, change the values to match personal preference.
```json
{
    "family": "backend-flask",
    "executionRoleArn": "arn:aws:iam::478429420160:role/CruddurServiceExecutionRole",
    "taskRoleArn": "arn:aws:iam::478429420160:role/CruddurTaskRole",
    "networkMode": "awsvpc",
    "cpu": "256",
    "memory": "512",
    "requiresCompatibilities": [ 
      "FARGATE" 
    ],
    "containerDefinitions": [
      {
        "name": "xray",
        "image": "public.ecr.aws/xray/aws-xray-daemon" ,
        "essential": true,
        "user": "1337",
        "portMappings": [
          {
            "name": "xray",
            "containerPort": 2000,
            "protocol": "udp"
          }
        ]
      },
      {
        "name": "backend-flask",
        "image": "478429420160.dkr.ecr.eu-west-2.amazonaws.com/backend-flask",
        "essential": true,
        "healthCheck": {
          "command": [
            "CMD-SHELL",
            "python /backend-flask/bin/flask/health-check"
          ],
          "interval": 30,
          "timeout": 5,
          "retries": 3,
          "startPeriod": 60
        },
        "portMappings": [
          {
            "name": "backend-flask",
            "containerPort": 4567,
            "protocol": "tcp", 
            "appProtocol": "http"
          }
        ],
        "logConfiguration": {
          "logDriver": "awslogs",
          "options": {
              "awslogs-group": "cruddur",
              "awslogs-region": "eu-west-2",
              "awslogs-stream-prefix": "backend-flask"
          }
        },
        "environment": [
          {"name": "OTEL_SERVICE_NAME", "value": "backend-flask"},
          {"name": "OTEL_EXPORTER_OTLP_ENDPOINT", "value": "https://api.honeycomb.io"},
          {"name": "AWS_COGNITO_USER_POOL_ID", "value": "eu-west-2_uEICac8VL"},
          {"name": "AWS_COGNITO_USER_POOL_CLIENT_ID", "value": "hodtei9aau4ai8gncgtmgnrto"},
          {"name": "FRONTEND_URL", "value": "*"},
          {"name": "BACKEND_URL", "value": "*"},
          {"name": "AWS_DEFAULT_REGION", "value": "eu-west-2"}
        ],
        "secrets": [
          {"name": "AWS_ACCESS_KEY_ID"    , "valueFrom": "arn:aws:ssm:eu-west-2:478429420160:parameter/cruddur/backend-flask/AWS_ACCESS_KEY_ID"},
          {"name": "AWS_SECRET_ACCESS_KEY", "valueFrom": "arn:aws:ssm:eu-west-2:478429420160:parameter/cruddur/backend-flask/AWS_SECRET_ACCESS_KEY"},
          {"name": "CONNECTION_URL"       , "valueFrom": "arn:aws:ssm:eu-west-2:478429420160:parameter/cruddur/backend-flask/CONNECTION_URL" },
          {"name": "ROLLBAR_ACCESS_TOKEN" , "valueFrom": "arn:aws:ssm:eu-west-2:478429420160:parameter/cruddur/backend-flask/ROLLBAR_ACCESS_TOKEN" },
          {"name": "OTEL_EXPORTER_OTLP_HEADERS" , "valueFrom": "arn:aws:ssm:eu-west-2:478429420160:parameter/cruddur/backend-flask/OTEL_EXPORTER_OTLP_HEADERS" }
        ]
      }
    ]
  }
```
- Activate this task definition by registering it with AWS ECS. Using the command:
```Bash
aws ecs register-task-definition --cli-input-json file://aws/task-definitions/backend-flask.json
```
CHECK TO SEE IF TASK-DEFINITION IS RUNNING AND ACCURATE

2. FRONTEND-REACT-JS TASK DEFINITION
The task definition for the frontend-react-js app is in `aws/task-definitions/frontend-react-js.json`.
- A couple of things to change are the AWS ACCOUNT ID and the AWS REGION; 
	- the ARNS for the execution and task roles and under environment, change the values to match personal preference.
```JSON
{
  "family": "frontend-react-js",
  "executionRoleArn": "arn:aws:iam::AWS_ACCOUNT_ID:role/CruddurServiceExecutionRole",
  "taskRoleArn": "arn:aws:iam::AWS_ACCOUNT_ID:role/CruddurTaskRole",
  "networkMode": "awsvpc",
  "containerDefinitions": [
    {
      "name": "frontend-react-js",
      "image": "BACKEND_FLASK_IMAGE_URL",
      "cpu": 256,
      "memory": 256,
      "essential": true,
      "healthCheck": {
        "command": [
          "CMD-SHELL",
          "curl -f http://localhost:3000 || exit 1"
        ],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
      },
      "portMappings": [
        {
          "name": "frontend-react-js",
          "containerPort": 3000,
          "protocol": "tcp", 
          "appProtocol": "http"
        }
      ],

      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
            "awslogs-group": "cruddur",
            "awslogs-region": "ca-central-1",
            "awslogs-stream-prefix": "frontend-react"
        }
      }
    }
  ]
}
```
- Activate this task definition by registering it with AWS ECS. Using the command:
```Bash
aws ecs register-task-definition --cli-input-json file://aws/task-definitions/frontend-react-js.json
```
CHECK TO SEE IF TASK-DEFINITION IS RUNNING AND ACCURATE


#### CREATE A SECURITY GROUP
- A security group that is linked to the ECS cluster so we can deploy in that security group.
- The security group will be deployed in the default VPC group, obtain the default VPC ID, it will help create the security group.
Make the Default_VPC_ID available.
```Bash
export DEFAULT_VPC_ID=$(aws ec2 describe-vpcs \
--filters "Name=isDefault, Values=true" \
--query "Vpcs[0].VpcId" \
--output text)
echo $DEFAULT_VPC_ID
```
Create the Security Group:
```Bash
export CRUD_SERVICE_SG=$(aws ec2 create-security-group \
--group-name "cruddur-ecs-security-group" \
--description "Security group for Cruddur services on ECS" \
--vpc-id $DEFAULT_VPC_ID \
--query "GroupId" --output text)
echo $CRUD_SERVICE_SG
```

#### MAKE THE DEFAULT SUBNETS AVAILABLE
- This default subnets are needed when creating an ECS service (which will be created shortly). These are where the service will be available from in the same Region.
```Bash
export DEFAULT_SUBNET_IDS=$(aws ec2 describe-subnets \
--filters Name=vpc-id,Values=$DEFAULT_VPC_ID \
--query 'Subnets[*].SubnetId' \
--output json | jq -r 'join(",")')
echo $DEFAULT_SUBNET_IDS
```
- Copy these subnet values, it will be needed shortly.
```Bash
#place the subnet IDs here.
subnet-0f2fb759de5ca1193
subnet-05331bdaa0941db52
subnet-0e22ac9178bc10e92
```

#### AUTHORIZE SECURITY GROUP INGRESS RULE
- For the security group, set the inbound (ingress) rules.
- Here, we are telling the ports 4567 to be accessible on the security group in every subnet in the Region.
```Bash
aws ec2 authorize-security-group-ingress \
--group-id $CRUD_SERVICE_SG \
--protocol tcp \
--port 4567 \
--cidr 0.0.0.0/0
```

#### INSTALL AWS SESSIONS MANAGER (for FARGATE)
- AWS Sessions Manager is a service provided and managed by AWS itself. 
	- It is used for managing instances and access to those instances securely.
- In this case, we have the Sessions Manager manage the Fargate instances. Our Gitppod environment uses Ubuntu hence the Ubuntu install config is used to provide Sessions Manager in the development environment.
Install on Gitpod Ubuntu, run this:
```Bash
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
sudo dpkg -i session-manager-plugin.deb
```
Verify that Session Manager is working, run this:
```Bash
session-manager-plugin
```

#### CREATE A LOADBALANCER (USING CLICKOPS IN AWS CONSOLE)
- The loadbalancer is a service that will route traffic to the respective services available to be reached by the web.
- The procedure to create a Loadbalancer in the console is below:
```Text
- Create an Application Load Balancer
- name: cruddur-application-loadbalancer
- scheme: internet-facing
- IP address type: IPv4
- use the default VPC
- Mappings: select all 3 subnets in the region
```
- The next section is the creation of a Security Group, we need to create new Security Group for the LoadBalancer.
```Text
- name: cruddur-loadbalancer-security-group
- use the default VPC
- let the inbound rule: HTTP and HTTPS from anywhere
- then create the security group
```
- Come back to the Application LoadBalancer and use the newly created security group as the SG for the Loadbalancer.

- Here, edit the rules of the `cruddur-ecs-security-group` to allow access for the LoadBalancer's security group `cruddur-loadbalancer-security-group`.

- In the Listeners and Routing section:
	- create a Listener for the backend-flask application.
```Text
1. The Protocol for the listener: HTTP and Port: 4567

- Create a target group for the backend-flask app
- use the IP address as the target group type
- target group name: cruddur-backend-flask-targetgrp
- let the protocol: HTTP, 4567
- use the IPv4 address type
- In the HealthCheck section; use HTTP and set the healthcheck path: /api/health-check
- change the advanced health check settings, set healthy threshold = 3
- go next, and create a target group.

3. Select the newly created target group as the default action
```
-  create a Listener for the frontend-react-js application
```Text
1. The Protocol for the listener: HTTP and Port: 3000

- Create a target group for the frontend-react-js application
- use the IP address as the target group type
- target group name: cruddur-frontend-react-targetgrp
- let the protocol: HTTP, 3000
- use the IPv4 address type
- HealthCheck is given, but leave path to be "/"
- change the advanced health check settings, set healthy threshold = 3
- go next, and create a target group.

3. Select the newly created target group as the default action
```
- Read the summary and create the Loadbalancer.

- The Loadbalancer can be created using the AWS CLI by adding code to the `service-backend-flask.json` code to provision the Loadbalancer.
- The ARN can typically be found in the AWS Management Console by navigating to the target group in the EC2 or ECS service and selecting "Details" or "Edit".
```JSON
"loadbalancers": [
		{
				"targetGroupArn": "arn:aws:elasticloadbalancing:ca-central-1:387543059434:targetgroup/cruddur-backend-flask-tg/87ed2a3daf2d2b1d",
				"containerName": "backend-flask",
				"containerPort": 4567
		}
],
"networkConfiguration": {
```

#### CREATE A SERVICE FROM THE TASK DEFINITIONS
- A collection of things finally culminate here in creating an ECS Service that runs on the task definitions.
#### 1. Backend-Flask Service
- Place this command in the `aws/ecs/service-backend-flask.json`.
```Bash
{
  "cluster": "cruddur",
  "launchType": "FARGATE",
  "desiredCount": 1,
  "enableECSManagedTags": true,
  "enableExecuteCommand": true,
  "loadBalancers": [
		{
				"targetGroupArn": "arn:aws:elasticloadbalancing:ca-central-1:387543059434:targetgroup/cruddur-backend-flask-tg/87ed2a3daf2d2b1d",
				"containerName": "backend-flask",
				"containerPort": 4567
		}
	],
  "networkConfiguration": {
    "awsvpcConfiguration": {
      "assignPublicIp": "ENABLED",
      "securityGroups": [
        "sg-04ca5ebd69e0aec6f" ## change the value here to match
      ],
      "subnets": [
        "subnet-0462b87709683ccaa", ## change the subnets to match
        "subnet-066a53dd88d557e05",
        "subnet-021a6adafb79249e3"
      ]
    }
  },
  "propagateTags": "SERVICE",
  "serviceName": "backend-flask",
  "taskDefinition": "backend-flask",
  "serviceConnectConfiguration": {
    "enabled": true,
    "namespace": "cruddur",
    "services": [
      {
        "portName": "backend-flask",
        "discoveryName": "backend-flask",
        "clientAliases": [{"port": 4567}]
      }
    ]
  }
}
```

Launch this service via the AWS CLI command with this:
```Bash
aws ecs create-service --cli-input-json file://aws/ecs/service-backend-flask.json
```

#### 2. Frontend-React-Js Service
- Place this command in the `aws/ecs/service-frontend-react-js.json` file
```JSON
{
  "cluster": "cruddur",
  "launchType": "FARGATE",
  "desiredCount": 1,
  "enableECSManagedTags": true,
  "enableExecuteCommand": true,
  "loadBalancers": [
		{
				"targetGroupArn": "arn:aws:elasticloadbalancing:ca-central-1:387543059434:targetgroup/cruddur-frontend-react-js-tg/87ed2a3daf2d2b1d",
				"containerName": "frontend-react-js",
				"containerPort": 3000
		}
	],
  "networkConfiguration": {
    "awsvpcConfiguration": {
      "assignPublicIp": "ENABLED",
      "securityGroups": [
        "sg-04bdc8d5443cc8283"
      ],
      "subnets": [
        "subnet-0462b87709683ccaa",
        "subnet-066a53dd88d557e05",
        "subnet-021a6adafb79249e3"
      ]
    }
  },
  "propagateTags": "SERVICE",
  "serviceName": "frontend-react-js",
  "taskDefinition": "frontend-react-js",
  "serviceConnectConfiguration": {
    "enabled": true,
    "namespace": "cruddur",
    "services": [
      {
        "portName": "frontend-react-js",
        "discoveryName": "frontend-react-js",
        "clientAliases": [{"port": 3000}]
      }
    ]
  }
}
```

Launch this service via the AWS CLI command with this:
```Bash
aws ecs create-service --cli-input-json file://aws/ecs/service-frontend-react-js.json
```


#### CONNECT TO THE ECS SERVICE AND EXECUTE A COMMAND
- Test whether there is a valid connection to the ECS cluster by trying to connect to the backend-flask service running.
- The command requires the use of the ECS task ARN; find this by: ECS cruddur cluster > enter the service, backend-flask > enter a running task/container and look out for "Task Overview"... the ARN will be present there.
- Insert the task ARN (a 32 alphanumeric combo) here: 
```Bash
TASK_ARN = arn:aws:ecs:eu-west-2:478429420160:task/cruddur/06956ed295e6475b85610c3b39537da3
```
Run this command to access the service:
```Bash
aws ecs execute-command  \
--region $AWS_DEFAULT_REGION \
--cluster cruddur \
--task <insert the TASK_ARN here> \
--container backend-flask \
--command "/bin/bash" \
--interactive
```

#### REMEMBER THE HEALTH-CHECK 
- In the beginning, we wrote a health-check API endpoint we needed to hit.
- This can be done manually in the Session Manager after the just above command has been implemented:
- in the `backend-flask` in the Sessions Manager, run the `./bin/flask/health-check` command verify is the health-check is working.

### THE FRONTEND APPLICATION (CONTD.)
- The Frontend application has a few changes made to get it production-ready. 
	- A production Dockerfile is made, complete with configurations to match.
- In the `/frontend-react-js` folder, create a Dockerfile for production, `Dockerfile.prod`.
```Dockerfile
# Base Image ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
FROM node:16.18 AS build

ARG REACT_APP_BACKEND_URL
ARG REACT_APP_AWS_PROJECT_REGION
ARG REACT_APP_AWS_COGNITO_REGION
ARG REACT_APP_AWS_USER_POOLS_ID
ARG REACT_APP_CLIENT_ID

ENV REACT_APP_BACKEND_URL=$REACT_APP_BACKEND_URL
ENV REACT_APP_AWS_PROJECT_REGION=$REACT_APP_AWS_PROJECT_REGION
ENV REACT_APP_AWS_COGNITO_REGION=$REACT_APP_AWS_COGNITO_REGION
ENV REACT_APP_AWS_USER_POOLS_ID=$REACT_APP_AWS_USER_POOLS_ID
ENV REACT_APP_CLIENT_ID=$REACT_APP_CLIENT_ID

COPY . ./frontend-react-js
WORKDIR /frontend-react-js
RUN npm install
RUN npm run build

# New Base Image ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
FROM nginx:1.23.3-alpine

# --from build is coming from the Base Image
COPY --from=build /frontend-react-js/build /usr/share/nginx/html
COPY --from=build /frontend-react-js/nginx.conf /etc/nginx/nginx.conf

EXPOSE 3000
```
-  An NGINX configuration file also is made available for use in the folder, `/frontend-react-js/nginx.conf`.
```C
# Set the worker processes
worker_processes 1;

# Set the events module
events {
  worker_connections 1024;
}

# Set the http module
http {
  # Set the MIME types
  include /etc/nginx/mime.types;
  default_type application/octet-stream;

  # Set the log format
  log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

  # Set the access log
  access_log  /var/log/nginx/access.log main;

  # Set the error log
  error_log /var/log/nginx/error.log;

  # Set the server section
  server {
    # Set the listen port
    listen 3000;

    # Set the root directory for the app
    root /usr/share/nginx/html;

    # Set the default file to serve
    index index.html;

    location / {
        # First attempt to serve request as file, then
        # as directory, then fall back to redirecting to index.html
        try_files $uri $uri/ $uri.html /index.html;
    }

    # Set the error page
    error_page  404 /404.html;
    location = /404.html {
      internal;
    }

    # Set the error page for 500 errors
    error_page  500 502 503 504  /50x.html;
    location = /50x.html {
      internal;
    }
  }
}
```

SET A GITIGNORE FILE
- Get into the `frontend-react-js` directory and run `npm run build` to build the application.
- In the subsequent section, a production build of the frontend-react-js app will be built and hence per best practices, a .gitignore file will be needed.
- A docker folder containing raw information on a database and the build directory of the frontend-react-js application.
```text
docker/**/*
frontend-react-js/build/*
```


### The FrontEnd React app
Changes are made later regarding the use of Dockefiles but the processes are here nonetheless
1. Create base frontend-react image ECR repo:
```bash
aws ecr create-repository \
--repository-name frontend-react-js \
--image-tag-mutability MUTABLE
```
2. Login to Docker via the ECR 
	- the ACCOUNT_ID and DEFAULT_REGION should be present as environment variables locally.
```Bash
aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com"
```
3. Set the URL to the AWS ECR for the frontend-react-js repo.
```Bash
export ECR_FRONTEND_REACT_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/frontend-react-js"
echo $ECR_FRONTEND_REACT_URL #this is to verify that the URl is the same as given by ECR for that repository URI
```
4. Build the Docker image for the frontend-react-js app being used:
```Bash
# make sure to change the values to match your personal environment.
docker build \
--build-arg REACT_APP_BACKEND_URL="http://cruddur-application-loadbalancer-2137950182.eu-west-2.elb.amazonaws.com" \
--build-arg REACT_APP_AWS_PROJECT_REGION="$AWS_DEFAULT_REGION" \
--build-arg REACT_APP_AWS_COGNITO_REGION="$AWS_DEFAULT_REGION" \
--build-arg REACT_APP_AWS_USER_POOLS_ID="eu-west-2_uEICac8VL" \
--build-arg REACT_APP_CLIENT_ID="hodtei9aau4ai8gncgtmgnrto" \
-t frontend-react-js \
-f Dockerfile.prod \
.

#Another method, later stages, when loadbalancer and certificates are available
docker build \
--build-arg REACT_APP_BACKEND_URL="https://api.thetaskmasterernest.cyou" \
--build-arg REACT_APP_AWS_PROJECT_REGION="$AWS_DEFAULT_REGION" \
--build-arg REACT_APP_AWS_COGNITO_REGION="$AWS_DEFAULT_REGION" \
--build-arg REACT_APP_AWS_USER_POOLS_ID="eu-west-2_uEICac8VL" \
--build-arg REACT_APP_CLIENT_ID="hodtei9aau4ai8gncgtmgnrto" \
-t frontend-react-js \
-f Dockerfile.prod \
.
```
5. Tag and push the image to AWS ECR
```Bash
docker tag frontend-react-js:latest $ECR_FRONTEND_REACT_URL:latest
docker push $ECR_FRONTEND_REACT_URL:latest
```
6. Test out the container to check whether it works
```Bash
docker run --rm -p 3000:3000 -it frontend-react-js 
```

### ALLOW TRAFFIC IN ECS SECURITY GROUP
- The ECS security has inbound rules to allow traffic from all places, that is not secure.
- Changes have to be made so that it receives traffic only from the Loadbalancer.
- Go to EC2 and find the ECS security group, `cruddur-ecs-security-group`, and change the inbound rules to accept only traffic from only the security group of the Loadbalancer, `cruddur-loadbalancer-security-group`, on the ports 4567 and 3000 respectively and ONLY.
- TEST THE CONNECTION BY ROUTING USING THE DNS NAME AND THE RESPECTIVE PORTS.

### MEASURES FOR DEBUGGING
- Both containers have to be available to enter and debug when neccessary.
- A couple of bash scripts that will prove useful, and make use of the Sessions Manager, to directly enter the containers when they are running.
- These scripts make use of the Service Connect functionality of the cloud, code is present in the Service files of the applications.
	- Enter AWS Cloud Map to find the services that are connected to each other via specific namespaces.
The service-connect script for the backend-flask app, in the `backend-flask/bin/ecs/service-connect-backend`.
```Bash
#!/usr/bin/bash

if [ -z "$1" ]; then
	echo "No task argument ID supplied eg. ./bin/ecs/service-connect-backend taskARN"
	exit 1
fi
TASK_ID=$1

CONTAINER_NAME=backend-flask

echo "TASK ID : $TASK_ID"
echo "CONTAINER_NAME : $CONTAINER_NAME"

aws ecs execute-command  \
--region $AWS_DEFAULT_REGION \
--cluster cruddur \
--task $TASK_ID \
--container backend-flask \
--command "/bin/bash" \
--interactive
```

The way to connect to these services via the AWS CLI is this:
```Bash
./bin/ecs/service-connect-* taskARN_value
```

The service-connect script for the backend-flask app, in the `backend-flask/bin/ecs/service-connect-frontend`.
```Bash
#!/usr/bin/bash

if [ -z "$1" ]; then
	echo "No task argument ID supplied eg. ./bin/ecs/service-connect-frontend taskARN"
	exit 1
fi
TASK_ID=$1

CONTAINER_NAME=frontend-react-js

echo "TASK ID : $TASK_ID"
echo "CONTAINER_NAME : $CONTAINER_NAME"

aws ecs execute-command  \
--region $AWS_DEFAULT_REGION \
--cluster cruddur \
--task $TASK_ID \
--container frontend-react-js \
--command "/bin/sh" \
--interactive
```


## SECURING THE DNS + DOMAIN CONFIGURATION
- First thing to do in securing the endpoint of the Load-Balancer is to configure a hosted zone.
- Amazon Route53 is used to create a Hosted Zone, `<namecheap_domain-name.xyz`. I have my domain bought on Namecheap, so I need to port it over for Route53 for usage.
- Here is a great article on how to bring over the nameservers from Namecheap over to Route53. [Connect Namecheap domain to Route53](https://aws.plainenglish.io/how-to-connect-your-domain-from-namecheap-to-amazon-route-53-840bc745ce67)
- Generate an SSL certificate that will be used to create records, from AWS ACM (Certificate Manager)
	- Request a public certificate for the domains `thetaskmasterernest.cyou` and `*.thetaskmasterernest.cyou`. 
	- Request that the hosted zone be validate via DNS validation.
	- Go into the Hosted Zones, create DNS records with the above domain names. These records will be created in the CNAME categories.
- Go to the LoadBalancer and configure the following:
	- add a new listener that redirects Port 80 to HTTPS 443.
	- add another listener that listens on HTTPS 443 and forwards to the cruddur-frontend-react-js service. Add the SSL certificate from ACM.
	- delete the initial ports, the default HTTP 4567 and HTTP 3000 listeners.
	- select the new HTTPS 443 listener and go to Manage Rules and select Add Another Rule.
		- set the HostHeader to `api.thetaskmasterernest.cyou` to forward to the backend target group.
		- set the default one to forward to the frontend target group.
- Go to Route53 and proceed to add another record.
	- set no name for the first record, turn on Alias, select Alias to Application Loadbalancer, set the region, select the configured Application Loadbalancer and set the routing policy to Simple Routing Policy.
	- add another record and set its name to be `api`, turn on Alias, select Alias to Application Loadbalancer, set the region, select the Application Loadbalancer and set the routing policy to Simple Routing Policy
	- With this done, the Hosted Zone will route to the Application Loadbalancer.
	- Check connections to the service by running a curl command `curl https://api.thetaskmasterernest.cyou/api/health-check` and this should return a good response.

## Securing the Backend Application, Fixing Messaging in Production & Refreshing Cognito Token.
- TIP: In this section, the `/bin` directory will be moved from the `backend-flask` directory to make it easy to access some bash scripts important to the deployment of the service. Move everything except the `/bin/flask/health-check` which is to be maintained to check the health of the application at runtime.
- Limit the LoadBalancer's access to the public by setting the IP it should receive traffic to be from only the PC's IP address.
- Create a new Dockerfile for production for the backend-flask application, in securing, we make sure the app does not reload or return errors to the webpage.
	- the `--no-debug, --no-debugger and --no-reload`, take care of this. The `ENV=debug` is removed as it is not a best practice to use in production.
```Dockerfile
FROM <AWS_ACCOUNT_ID>.dkr.ecr.<AWS_REGION>.amazonaws.com/cruddur-python:3.10-slim-buster

# [TODO] For debugging, don't leave these in
#RUN apt-get update -y
#RUN apt-get install iputils-ping -y
# -----

# Inside Container
# make a new folder inside container
WORKDIR /backend-flask

# Outside Container -> Inside Container
# this contains the libraries want to install to run the app
COPY requirements.txt requirements.txt

# Inside Container
# Install the python libraries used for the app
RUN pip3 install -r requirements.txt

# Outside Container -> Inside Container
# . means everything in the current directory
# first period . - /backend-flask (outside container)
# second period . /backend-flask (inside container)
COPY . .

EXPOSE ${PORT}

# CMD (Command)
# python3 -m flask run --host=0.0.0.0 --port=4567
CMD [ "python3", "-m" , "flask", "run", "--host=0.0.0.0", "--port=4567", "--no-debug","--no-debugger","--no-reload"]
```

- Make a `/bin/ecr/login` file that will be used to login into Docker on AWS ECR, to simplify the login process.
	- make it executable, `chmod u+x`.
```Bash
aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com"
```

### Changes to be made to the /bin directory
1. Backend directory; contains sub-directories as build, push, deploy, connect.
-  `/bin/backend/build`. Make It Executable.
```Bash
#! /usr/bin/bash
# the ABS_PATH finds the absolute path for the current script, no matter the directoty in which it is executed
ABS_PATH=$(readlink -f "$0")
BACKEND_PATH=$(dirname $ABS_PATH)
BIN_PATH=$(dirname $BACKEND_PATH)
PROJECT_PATH=$(dirname $BIN_PATH)
# this links the workspace directory 
BACKEND_FLASK_PATH="$PROJECT_PATH/backend-flask"

docker build \
-f "$BACKEND_FLASK_PATH/Dockerfile.prod" \
-t backend-flask-prod \
"$BACKEND_FLASK_PATH/."
```
- `/bin/backend/push`. Make It Executable.
```bash
#! /usr/bin/bash
# sets the environment variable for the backend-flask app for ECR
ECR_BACKEND_FLASK_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/backend-flask"
echo $ECR_BACKEND_FLASK_URL

docker tag backend-flask-prod:latest $ECR_BACKEND_FLASK_URL:latest
docker push $ECR_BACKEND_FLASK_URL:latest
```
- `/bin/backend/deploy`. Make It Executable.
```Bash
#! /usr/bin/bash

CLUSTER_NAME="cruddur"
SERVICE_NAME="backend-flask"
TASK_DEFINITION_FAMILY="backend-flask"


LATEST_TASK_DEFINITION_ARN=$(aws ecs describe-task-definition \
--task-definition $TASK_DEFINITION_FAMILY \
--query 'taskDefinition.taskDefinitionArn' \
--output text)

echo "TASK DEF ARN:"
echo $LATEST_TASK_DEFINITION_ARN

aws ecs update-service \
--cluster $CLUSTER_NAME \
--service $SERVICE_NAME \
--task-definition $LATEST_TASK_DEFINITION_ARN \
--force-new-deployment

#aws ecs describe-services \
#--cluster $CLUSTER_NAME \
#--service $SERVICE_NAME \
#--query 'services[0].deployments' \
#--output table
```
- `/bin/backend/connect`. Make It Executable.
```Bash
#! /usr/bin/bash
if [ -z "$1" ]; then
  echo "No TASK_ID argument supplied eg ./bin/ecs/connect-to-backend-flask 99b2f8953616495e99545e5a6066fbb5d"
  exit 1
fi
TASK_ID=$1

CONTAINER_NAME=backend-flask

echo "TASK ID : $TASK_ID"
echo "Container Name: $CONTAINER_NAME"

aws ecs execute-command  \
--region $AWS_DEFAULT_REGION \
--cluster cruddur \
--task $TASK_ID \
--container $CONTAINER_NAME \
--command "/bin/bash" \
--interactive
```

2. Frontend directory; contains same as backend.
- `/bin/frontend/build`. Make It Executable.
```Bash
#! /usr/bin/bash

ABS_PATH=$(readlink -f "$0")
FRONTEND_PATH=$(dirname $ABS_PATH)
BIN_PATH=$(dirname $FRONTEND_PATH)
PROJECT_PATH=$(dirname $BIN_PATH)
FRONTEND_REACT_JS_PATH="$PROJECT_PATH/frontend-react-js"

docker build \
--build-arg REACT_APP_BACKEND_URL="https://api.thetaskmasterernest.com" \
--build-arg REACT_APP_AWS_PROJECT_REGION="$AWS_DEFAULT_REGION" \
--build-arg REACT_APP_AWS_COGNITO_REGION="$AWS_DEFAULT_REGION" \
--build-arg REACT_APP_AWS_USER_POOLS_ID="insert_mine" \
--build-arg REACT_APP_CLIENT_ID="insert_mine" \
-t frontend-react-js \
-f "$FRONTEND_REACT_JS_PATH/Dockerfile.prod" \
"$FRONTEND_REACT_JS_PATH/."
```
- `/bin/frontend/push`. Make It Executable.
```Bash
#! /usr/bin/bash

ECR_FRONTEND_REACT_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/frontend-react-js"
echo $ECR_FRONTEND_REACT_URL

docker tag frontend-react-js:latest $ECR_FRONTEND_REACT_URL:latest
docker push $ECR_FRONTEND_REACT_URL:latest
```
- `/bin/frontend/deploy`. Make It Executable.
```Bash
#! /usr/bin/bash

CLUSTER_NAME="cruddur"
SERVICE_NAME="frontend-react-js"
TASK_DEFINITION_FAMILY="frontend-react-js"

LATEST_TASK_DEFINITION_ARN=$(aws ecs describe-task-definition \
--task-definition $TASK_DEFINITION_FAMILY \
--query 'taskDefinition.taskDefinitionArn' \
--output text)

echo "TASK DEF ARN:"
echo $LATEST_TASK_DEFINITION_ARN

aws ecs update-service \
--cluster $CLUSTER_NAME \
--service $SERVICE_NAME \
--task-definition $LATEST_TASK_DEFINITION_ARN \
--force-new-deployment
```
- `/bin/frontend/connect`. Make It Executable.
```Bash
#! /usr/bin/bash
if [ -z "$1" ]; then
  echo "No TASK_ID argument supplied eg ./bin/ecs/connect-to-frontend-react-js 99b2f8953616495e99545e5a6066fbb5d"
  exit 1
fi
TASK_ID=$1

CONTAINER_NAME=frontend-react-js

echo "TASK ID : $TASK_ID"
echo "Container Name: $CONTAINER_NAME"

aws ecs execute-command  \
--region $AWS_DEFAULT_REGION \
--cluster cruddur \
--task $TASK_ID \
--container $CONTAINER_NAME \
--command "/bin/sh" \
--interactive
```

3.  Postgres directory, a few changes in the pathing used for schema-load, seed, setup and update_cognito_user_ids
- `/bin/postgresdb/schema-load`.
```Bash
# make these changes to the pathing for the file
ABS_PATH=$(readlink -f "$0")
DB_PATH=$(dirname $ABS_PATH)
BIN_PATH=$(dirname $DB_PATH)
PROJECT_PATH=$(dirname $BIN_PATH)
BACKEND_FLASK_PATH="$PROJECT_PATH/backend-flask"
schema_path="$BACKEND_FLASK_PATH/db/schema.sql"
echo $schema_path
```
- `/bin/postgresdb/seed`.
```Bash
# make these changes to the pathing for the file
ABS_PATH=$(readlink -f "$0")
DB_PATH=$(dirname $ABS_PATH)
BIN_PATH=$(dirname $DB_PATH)
PROJECT_PATH=$(dirname $BIN_PATH)
BACKEND_FLASK_PATH="$PROJECT_PATH/backend-flask"
seed_path="$BACKEND_FLASK_PATH/db/seed.sql"
echo $seed_path
```
- `/bin/postgresdb/setup`.
```Bash
#! /usr/bin/bash
set -e # stop if it fails at any point

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-setup"
printf "${CYAN}==== ${LABEL}${NO_COLOR}\n"

ABS_PATH=$(readlink -f "$0")
DB_PATH=$(dirname $ABS_PATH)

source "$DB_PATH/drop"
source "$DB_PATH/create"
source "$DB_PATH/schema-load"
source "$DB_PATH/seed"
python "$DB_PATH/update_cognito_user_ids"
```
- `/bin/postgresdb/update_cognito_user_ids`
```Bash
# change only these lines for the pathing
current_path = os.path.dirname(os.path.abspath(__file__))
parent_path = os.path.abspath(os.path.join(current_path, '..', '..','backend-flask'))
sys.path.append(parent_path)
```

4.  DynamoDB directory, just one change in the pathing for the seed file
- `/bin/dynamodb/seed`.
```Bash
# change only these lines for the pathing
current_path = os.path.dirname(os.path.abspath(__file__))
parent_path = os.path.abspath(os.path.join(current_path, '..', '..','backend-flask'))
sys.path.append(parent_path)
```


#### Updating the Gitpod.yaml file
- With the moving of the `/bin/rds` directory out of the `backend-flask` dir, the pathing too much be changed for the postgres command.
```JSON
 - name: postgres
    before: |
      curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc|sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg
      echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" |sudo tee  /etc/apt/sources.list.d/pgdg.list
      sudo apt update
      sudo apt install -y postgresql-client-13 libpq-dev
    command: |
      export GITPOD_IP=$(curl ifconfig.me)
      source  "$THEIA_WORKSPACE_ROOT/bin/rds/update-sg-rule"
```


#### Fixing database connection issues.
- A number of connections will be made to the databse when trying to connect to it. Sometimes, this can be a headache as they will not allow the smooth connection of the the user to the database.
- To kill all connections, in case they come up, a script to do so. 
- First a `kill-all-connections` SQL script is made in the `/backend-flask/db/kill-all-connections.sql`.
```SQL
SELECT pg_terminate_backend(pid) 
FROM pg_stat_activity 
WHERE 
-- don't kill my own connection!
pid <> pg_backend_pid()
-- don't kill the connections to other databases
AND datname = 'cruddur';
```
- This can be referenced in the `/bin/postgresdb/kill-all` script.
```Bash
#! /usr/bin/bash

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-kill-all"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

ABS_PATH=$(readlink -f "$0")
DB_PATH=$(dirname $ABS_PATH)
BIN_PATH=$(dirname $DB_PATH)
PROJECT_PATH=$(dirname $BIN_PATH)
BACKEND_FLASK_PATH="$PROJECT_PATH/backend-flask"
kill_path="$BACKEND_FLASK_PATH/db/kill-all-connections.sql"
echo $kill_path

psql $CONNECTION_URL cruddur < $kill_path
```


#### Fixing Messaging In Production
- In production, to prevent a 500 Internal Server Error caused by the data being returned not identifiable by the application; we have to return a specific value.
- In the `/backend-flask/lib/postgres.py` file, in the `def query-object_json` function, add a return to the "{}" value.
```Python
if json == None
	return "{}"
```

#### Implementing Refresh Token in Cognito.
- Cognito sometimes times out a user token. To refresh the token so that the user can continue to use that pages without being timed out, these changes have to be made to the existing `/frontend-react-js/src/lib/checkAuth` file. With corresponding changes to other files in the frontend.
- The changes in the `/frontend-react-js/src/lib/checkAuth` :
```Python
import { Auth } from 'aws-amplify';
import { resolvePath } from 'react-router-dom';

export async function getAccessToken(){
  Auth.currentSession()
  .then((cognito_user_session) => {
    const access_token = cognito_user_session.accessToken.jwtToken
    localStorage.setItem("access_token", access_token)
  })
  .catch((err) => console.log(err));
}

export async function checkAuth(setUser){
  Auth.currentAuthenticatedUser({
    // Optional, By default is false. 
    // If set to true, this call will send a 
    // request to Cognito to get the latest user data
    bypassCache: false 
  })
  .then((cognito_user) => {
    console.log('cognito_user',cognito_user);
    setUser({
      display_name: cognito_user.attributes.name,
      handle: cognito_user.attributes.preferred_username
    })
    return Auth.currentSession()
  }).then((cognito_user_session) => {
      console.log('cognito_user_session',cognito_user_session);
      localStorage.setItem("access_token", cognito_user_session.accessToken.jwtToken)
  })
  .catch((err) => console.log(err));
};
```

-  The corresponding changes are made in the following files, to use the `checkAuth` file.
1. `/frontend-react-js/src/pages/HomeFeedPage.js`
```Python
# add this import
import {checkAuth, getAccessToken} from '../lib/CheckAuth';

... const loadData = async () => {
    try {
      const backend_url = `${process.env.REACT_APP_BACKEND_URL}/api/activities/home`
      await getAccessToken()
      const access_token = localStorage.getItem("access_token")
      const res = await fetch(backend_url, {
        headers: {
          Authorization: `Bearer ${access_token}`
        },
        method: "GET"
      });
      let resJson = await res.json();
      if (res.status === 200) {
        setActivities(resJson)
      } else {
        console.log(res)
      }
    } catch (err) {
      console.log(err);
    }
  };

```
2. `/frontend-react-js/src/pages/MessageGroupNewPage.js`
```Python
# add this import
import {checkAuth, getAccessToken} from '../lib/CheckAuth';

...
import './MessageGroupPage.css';
import React from "react";
import { useParams } from 'react-router-dom';

import DesktopNavigation  from '../components/DesktopNavigation';
import MessageGroupFeed from '../components/MessageGroupFeed';
import MessagesFeed from '../components/MessageFeed';
import MessagesForm from '../components/MessageForm';
import {checkAuth, getAccessToken} from '../lib/CheckAuth';

export default function MessageGroupPage() {
  const [otherUser, setOtherUser] = React.useState([]);
  const [messageGroups, setMessageGroups] = React.useState([]);
  const [messages, setMessages] = React.useState([]);
  const [popped, setPopped] = React.useState([]);
  const [user, setUser] = React.useState(null);
  const dataFetchedRef = React.useRef(false);
  const params = useParams();

  const loadUserShortData = async () => {
    try {
      const backend_url = `${process.env.REACT_APP_BACKEND_URL}/api/users/@${params.handle}/short`
      const res = await fetch(backend_url, {
        method: "GET"
      });
      let resJson = await res.json();
      if (res.status === 200) {
        console.log('other user:',resJson)
        setOtherUser(resJson)
      } else {
        console.log(res)
      }
    } catch (err) {
      console.log(err);
    }
  };  

  const loadMessageGroupsData = async () => {
    try {
      const backend_url = `${process.env.REACT_APP_BACKEND_URL}/api/message_groups`
      await getAccessToken()
      const access_token = localStorage.getItem("access_token")
      const res = await fetch(backend_url, {
        headers: {
          Authorization: `Bearer ${access_token}`
        },
        method: "GET"
      });
      let resJson = await res.json();
      if (res.status === 200) {
        setMessageGroups(resJson)
      } else {
        console.log(res)
      }
    } catch (err) {
      console.log(err);
    }
  }; 

  React.useEffect(()=>{
    //prevents double call
    if (dataFetchedRef.current) return;
    dataFetchedRef.current = true;

    loadMessageGroupsData();
    loadUserShortData();
    checkAuth(setUser);
  }, [])
  return (
    <article>
      <DesktopNavigation user={user} active={'home'} setPopped={setPopped} />
      <section className='message_groups'>
        <MessageGroupFeed otherUser={otherUser} message_groups={messageGroups} />
      </section>
      <div className='content messages'>
        <MessagesFeed messages={messages} />
        <MessagesForm setMessages={setMessages} />
      </div>
    </article>
  );
}  
```
3. `/frontend-react-js/src/pages/MessageGroupPage.js`
```Python
# add this import
import {checkAuth, getAccessToken} from '../lib/CheckAuth';

...
import './MessageGroupPage.css';
import React from "react";
import { useParams } from 'react-router-dom';

import {checkAuth, getAccessToken} from '../lib/CheckAuth';
import DesktopNavigation  from '../components/DesktopNavigation';
import MessageGroupFeed from '../components/MessageGroupFeed';
import MessagesFeed from '../components/MessageFeed';
import MessagesForm from '../components/MessageForm';

export default function MessageGroupPage() {
  const [messageGroups, setMessageGroups] = React.useState([]);
  const [messages, setMessages] = React.useState([]);
  const [popped, setPopped] = React.useState([]);
  const [user, setUser] = React.useState(null);
  const dataFetchedRef = React.useRef(false);
  const params = useParams();

  const loadMessageGroupsData = async () => {
    try {
      const backend_url = `${process.env.REACT_APP_BACKEND_URL}/api/message_groups`
      await getAccessToken()
      const access_token = localStorage.getItem("access_token")
      const res = await fetch(backend_url, {
        headers: {
          Authorization: `Bearer ${access_token}`
        },
        method: "GET"
      });
      let resJson = await res.json();
      if (res.status === 200) {
        setMessageGroups(resJson)
      } else {
        console.log(res)
      }
    } catch (err) {
      console.log(err);
    }
  };  

  const loadMessageGroupData = async () => {
    try {
      const backend_url = `${process.env.REACT_APP_BACKEND_URL}/api/messages/${params.message_group_uuid}`
      await getAccessToken()
      const access_token = localStorage.getItem("access_token")
      const res = await fetch(backend_url, {
        headers: {
          Authorization: `Bearer ${access_token}`
        },
        method: "GET"
      });
      let resJson = await res.json();
      if (res.status === 200) {
        setMessages(resJson)
      } else {
        console.log(res)
      }
    } catch (err) {
      console.log(err);
    }
  };    

  React.useEffect(()=>{
    //prevents double call
    if (dataFetchedRef.current) return;
    dataFetchedRef.current = true;
    loadMessageGroupsData();
    loadMessageGroupData();
    checkAuth(setUser);
  }, [])
  return (
    <article>
      <DesktopNavigation user={user} active={'home'} setPopped={setPopped} />
      <section className='message_groups'>
        <MessageGroupFeed message_groups={messageGroups} />
      </section>
      <div className='content messages'>
        <MessagesFeed messages={messages} />
        <MessagesForm setMessages={setMessages} />
      </div>
    </article>
  );
}
```
4. `/frontend-react-js/src/pages/MessageGroupsPage.js`
```Python
# add this import
import {checkAuth, getAccessToken} from '../lib/CheckAuth';

...
import './MessageGroupsPage.css';
import React from "react";

import DesktopNavigation  from '../components/DesktopNavigation';
import MessageGroupFeed from '../components/MessageGroupFeed';
import {checkAuth, getAccessToken} from '../lib/CheckAuth';


export default function MessageGroupsPage() {
  const [messageGroups, setMessageGroups] = React.useState([]);
  const [popped, setPopped] = React.useState([]);
  const [user, setUser] = React.useState(null);
  const dataFetchedRef = React.useRef(false);

  const loadData = async () => {
    try {
      const backend_url = `${process.env.REACT_APP_BACKEND_URL}/api/message_groups`
      await getAccessToken()
      const access_token = localStorage.getItem("access_token")
      const res = await fetch(backend_url, {
        headers: {
          Authorization: `Bearer ${access_token}`
        },
        method: "GET"
      });
      let resJson = await res.json();
      if (res.status === 200) {
        setMessageGroups(resJson)
      } else {
        console.log(res)
      }
    } catch (err) {
      console.log(err);
    }
  };    

  React.useEffect(()=>{
    //prevents double call
    if (dataFetchedRef.current) return;
    dataFetchedRef.current = true;

    loadData();
    checkAuth(setUser);
  }, [])
  return (
    <article>
      <DesktopNavigation user={user} active={'home'} setPopped={setPopped} />
      <section className='message_groups'>
        <MessageGroupFeed message_groups={messageGroups} />
      </section>
      <div className='content'>
      </div>
    </article>
  );
} 

```
5. `/frontend-react-js/src/pages/MessageForm.js`
```Python
# add this import
import {getAccessToken} from '../lib/CheckAuth';
...
const onsubmit = async (event) => {
    event.preventDefault();
    try {
      const backend_url = `${process.env.REACT_APP_BACKEND_URL}/api/messages`
      console.log('onsubmit payload', message)
      let json = { 'message': message }
      if (params.handle) {
        json.handle = params.handle
      } else {
        json.message_group_uuid = params.message_group_uuid
      }
      await getAccessToken()
      const access_token = localStorage.getItem("access_token")
      const res = await fetch(backend_url, {
        method: "POST",
        headers: {
          'Authorization': `Bearer ${access_token}`,
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(json)
      });
      let data = await res.json();
      if (res.status === 200) {
        console.log('data:',data)
        if (data.message_group_uuid) {
          console.log('redirect to message group')
          window.location.href = `/messages/${data.message_group_uuid}`
        } else {
          props.setMessages(current => [...current,data]);
        }
      } else {
        console.log(res)
      }
    } catch (err) {
      console.log(err);
    }
  }
```

-  After all these changes have been made, you can rest them out locally and then deploy them to ECR to be used in production.
- Test in production;
1. build, push and deploy unto ECS.
	- update the backend task definition to have the frontend and backend URLS set to be `https://thetaskmasterernest.cyou` and `https://api.thetaskmasterernest.cyou` respectively. Re-register the task-definition file.
	- rebuild the frontend with some new arguments, `REACT_APP_BACKEND_URL='https://api.thetaskmasterernest.cyou'`. Rebuild the frontend image, and push it to ECR
	- Go to AWS ECS, then to the application's Services, update each service with the Force New Deployment option.
1. when the services are running, connect to RDS (`/bin/postgresdb connect prod`) and load schema to prod and seed to prod.
2. After data has been propagated, you can send messages to them `/messages/new/<username>`.

PRO TIP: To stop the ECS services from deploying another service when one of them is stopped, Update Service and set Desired Count to zero (0).

### Generating an Environment Variables File
- An environment variables file will be to store the env-vars needed to be passed to the application during runtime.
- This is done to make clean the docker-compose file. The env-vars will now be passed via an environment variable file for use during local development and during the building of the application image.
- In this case, the Ruby language will be used to create a template using ERB (Embedded Ruby, a templating language that allows the user to embed Ruby code in plain text files).
- Create a `/bin/erb` directory to hold the ERB env-vars for both the frontend and backend applications.
1. the backend env-var, `/bin/erb/backend-flask.env.erb` template file is shown here; the syntax is changed to match how env-vars are stated using ERB (<%= ... %>).
```RUBY
AWS_ENDPOINT_URL=http://dynamodb-local:8000
CONNECTION_URL=postgresql://postgres:password@postgres:5432/cruddur
FRONTEND_URL=https://3000-<%= ENV['GITPOD_WORKSPACE_ID'] %>.<%= ENV['GITPOD_WORKSPACE_CLUSTER_HOST'] %>
BACKEND_URL=https://4567-<%= ENV['GITPOD_WORKSPACE_ID'] %>.<%= ENV['GITPOD_WORKSPACE_CLUSTER_HOST'] %>
OTEL_SERVICE_NAME=backend-flask
OTEL_EXPORTER_OTLP_ENDPOINT=https://api.honeycomb.io
OTEL_EXPORTER_OTLP_HEADERS=x-honeycomb-team=<%= ENV['HONEYCOMB_API_KEY'] %>
AWS_XRAY_URL=*4567-<%= ENV['GITPOD_WORKSPACE_ID'] %>.<%= ENV['GITPOD_WORKSPACE_CLUSTER_HOST'] %>*
AWS_XRAY_DAEMON_ADDRESS=xray-daemon:2000
AWS_DEFAULT_REGION=<%= ENV['AWS_DEFAULT_REGION'] %>
AWS_ACCESS_KEY_ID=<%= ENV['AWS_ACCESS_KEY_ID'] %>
AWS_SECRET_ACCESS_KEY=<%= ENV['AWS_SECRET_ACCESS_KEY'] %>
ROLLBAR_ACCESS_TOKEN=<%= ENV['ROLLBAR_ACCESS_TOKEN'] %>
AWS_COGNITO_USER_POOL_ID=<%= ENV['AWS_COGNITO_USER_POOL_ID'] %>
AWS_COGNITO_USER_POOL_CLIENT_ID=<%= ENV['AWS_COGNITO_USER_POOL_CLIENT_ID'] %>
```
2. the frontend env-var template, `/bin/erb/frontend-react-js.env.erb` is done, same as above.
```RUBY
REACT_APP_BACKEND_URL=https://4567-<%= ENV['GITPOD_WORKSPACE_ID'] %>.<%= ENV['GITPOD_WORKSPACE_CLUSTER_HOST'] %>
REACT_APP_AWS_PROJECT_REGION=<%= ENV['AWS_DEFAULT_REGION'] %>
REACT_APP_AWS_COGNITO_REGION=<%= ENV['AWS_DEFAULT_REGION'] %>
REACT_APP_AWS_USER_POOLS_ID=<%= ENV['AWS_COGNITO_USER_POOL_ID'] %>
REACT_APP_CLIENT_ID=<%= ENV['AWS_COGNITO_USER_POOL_CLIENT_ID'] %>
```

- Create a script to generate the env-var that will be used to render the template of the environment variables that will be passed to the application.
1. the backend script is in the `/bin/backend/generate-env` file.
```bash
#!/usr/bin/env ruby
# a ruby script to generate an environment variable template to be referenced by the containers.
require 'erb'
template = File.read 'erb/backend-flask.env.erb'
content = ERB.new(template).result(binding)
filename = "backend-flask.env"
File.write(filename, content)
```
2. the frontend script is in the `/bin/frontend/generate-env` file.
```bash
#!/usr/bin/env ruby
# a ruby script to generate an environment variable template to be referenced by the containers.
require 'erb'
template = File.read 'erb/frontend-react-js.env.erb'
content = ERB.new(template).result(binding)
filename = "frontend-react-js.env"
File.write(filename, content)
```

- When these scripts are run, an env-var file is generated which has the name corresponding to the filename stated in the script.
- These files are sensitive, do not publish them. Put them in the .gitignore file.
- Make things easy by changing some config in the `.gitpod.yaml` file to run these scripts anytime the environment is spun up.``
```YAML
 - name: react-js
    command: |
      ruby $THEIA_WORKSPACE_ROOT/bin/frontend/generate-env

- name: flask
    command: |
      ruby $THEIA_WORKSPACE_ROOT/bin/backend/generate-en
```

- This will help mostly with local development when spinning up the docker-compose file to set up the local environment.
