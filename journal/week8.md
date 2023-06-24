# Week 8 — Serverless Image Processing

- The AWS Cloud Development Kit (CDK) is an open-source software development framework developed by Amazon Web Services (AWS) for defining and provisioning cloud infrastructure resources using familiar programming languages. 
- The AWS CDK aims to improve the experience of working with Infrastructure as Code by providing higher-level, reusable constructs that enable developers to create and manage AWS resources more efficiently and with less boilerplate code compared to traditional configuration files like AWS CloudFormation templates.
- The AWS CDK is a powerful tool that can help developers to build and manage cloud infrastructure more efficiently and effectively. It is a valuable addition to the toolkit of any developer who works with AWS.

Here are some of the benefits of using the AWS CDK:
- Increased productivity: The AWS CDK can help you to increase your productivity by providing a high-level abstraction for defining AWS resources. This can save you time and effort, and help you to focus on the more important aspects of your application development.
- Improved reliability: The AWS CDK can help you to improve the reliability of your infrastructure by providing a consistent way to define and deploy your resources. This can help to reduce the risk of errors, and make it easier to troubleshoot problems.
- Enhanced security: The AWS CDK can help you to enhance the security of your infrastructure by providing a secure way to define and deploy your resources. This can help to reduce the risk of unauthorized access, and make it easier to comply with security regulations.

This deployment uses the programming language TypeScript to write the cloud script for the AWS Serverless deployment.

There are some resources to help get into the world of CDK in AWS: 
1. The AWS CDK Book; [here's a sample of code for the Go version](https://www.go-on-aws.com/infrastructure-as-go/cdk-go/cdk-go-start/create/)
2. The Construct Hub: [here](https://constructs.dev/)
3. The AWS CDK API reference: [here](https://docs.aws.amazon.com/cdk/api/v2/docs/aws-construct-library.html)
4.


## 1. Getting Started
This first stage will be a demo of sorts for getting into using the AWS CDK tool for deploying serverless applications.
- Make a directory called `thumbing-serverless-cdk` and run the command `npm install aws-cdk -g`. The `-g` flag is to install it globally in the environment.
- In the new directory, initialize the CDK for Typescript by running the command, `cdk init app --language typescript`. This will spawn a `/lib/` directory with a `<name>.ts` directory. 
	- This will be typescript CDK with which all IAC can be done using the Typescript language. The file in which the work for the AWS CDK will be done will the name of the directory the CDK was initialized in ie. `thumbing-serverless-cdk-stack.ts`.
- In the `thumbing-serverless-cdk-stack.ts` file, will be sample code that can be modified to start working with the Typescript CDK.
	- Define an S3 bucket for the stack and give it a name. `import * as s3 from 'aws-cdk-lib/aws-s3'`; `const bucketName:string=process-env.THUMBING_BUCKET_NAME as string;`. (the name should lie in the Constructor class).
	- Create a function that creates an s3 bucket, this should lie outside of the constructor class.
	- Back in the constructor class, pass in the bucket that was just created. `const bucket = this.createBucket(bucketName)`.
```Typescript
import * as s3 from 'aws-cdk-lib/aws-s3';
//constructor class
Constructor {
	const bucketName:string=process-env.THUMBING_BUCKET_NAME as string;
	const bucket = this.createBucket(bucketName);
}
//function to create bucket
createBucket(bucketName_: string); s3.IBucket {
	const bucket = new.s3.Bucket(this, 'ThumbingBucket', {
		bucketName: bucketName;
		removalPolicy: cdk.RemovalPolicy.DESTROY
	});
	return bucket;
}
```
- Run the command `cdk-synth` in the `thumbing-serverless-cdk` directory to generate, in YAML, a template of the resources that will be sent to CloudFormation to be deployed into the AWS Account. This output is generated into a `cdk.out` directory that contains all all the information on how the stack is packaged for deployment.
- Before deploying to AWS CDK, the AWS account environment has to be bootstrapped. This is done only once per account, but can be done again when changing the AWS Regions to deploy into. Run the command, `cdk bootstrap "aws://ACCOUNT_ID/AWS_REGION"`.
	- check CloudFormation in the AWS Account + Region, in Stacks, for the CDK toolkit. This contains all the the resources being generated for the AWS CDK Bootstrapping.
- Run the command `cdk deploy` in the environment where to code is to deploy the CDK code to CloudFormation. It takes some time to deploy to CloudFormation, and there is TUI process to guide and affirm the deployment of code to CloudFormation in that specific AWS Account.

## 2. Creating Lambda 
- Import Lambda to be used. This string takes care of it, `import * as lambda from 'aws-cdk-lib/aws-lambda'`.
- Create a function with the Lambda. This, according to the CDK, takes 3 core parameters; Code, Runtime and Handler that must be passed.
	- the Runtime specifies the language and version to be used; the Handler, most of the time, is an `index.handler` string that is passed and the Code is a reference to where the CDK has to take the code from.
	- for this project, the Runtime is going to be a NodeJS runtime; the Code will be a path to where the actual code to be used resides. For this, an environment variable has to be created which will contain the path to the code to be used.
- Define the lambda in the constructor class with `const lambda = this.createLambda(functionPath)`.
```Typescript
import * as lambda from 'aws-cdk-lib/aws-lambda';
//Constructor class
Constructor {
	const functionPath:string = process.env.THUMBING_FUNCTION_PATH as string;
	const lambda = this.createLambda(functionPath);
}
//function to create Lambda
createLambda(functionPath:string): lamnda.IFunction {
	const lamndaFunction = new.lambda.Function(this, 'ThumbLamnda', {
		runtime: lambda.Runtime.NODEJS_18_X,
		handler: 'index.handler',
		code: lambda.Code.fromAsset(functionPath)
	});
	return lambdaFunction;
}
```
- Define a `.env` file which should store the env-vars to be passed into the CDK deployment. `THUMBING_BUCKET` and `THUMBING_FUNCTION_PATH`, the variables should be in double quotes. (The names should be unique, probably something relating to the existing domain name the user already has).
	- install the `dotenv` package; run `npm i dotenv`; import it into the CDK code (`import * as dotenv from 'dotenv'`); then load the env-vars outside of the export class using this code `dotenv.config();`
```.env
THUMBING_BUCKET=""
THUMBING_FUNCTION_PATH=""

//new additions
FOLDER_INPUT="avatar/original"
FOLDER_OUTPUT="avatar/original"
```
- Run the `cdk synth` command again to see the template that will be sent to CloudFormation.
- Add an environment parameter to the `createLambda` function. For every environment variable added, it has to be called and stated in the constructor class of the CDK code. The environment variables must also be specified in the `.env` file to be passed to CloudFormation.
	- define the new env-vars in the constructor class and then call them in the lambda function.
```Typescript
import * as lambda from 'aws-cdk-lib/aws-lambda';
//Constructor class
Constructor {
	const functionPath:string = process.env.THUMBING_FUNCTION_PATH as string;
	const folderInput:string = process.env.THUMBING_S3_FOLDER_INPUT as string;
	const folderOutput:string = process.env.THUMBING_S3_FOLDER_OUTPUT as string;
	
	const lambda = this.createLambda(functionPath, bucketName, folderInput, folderOutput);
	
}
//function to create Lambda
createLambda(functionPath:string, bucketName:string, folderInput:string): lambda.IFunction {
	const lambdaFunction = new.lambda.Function(this, 'ThumbLambda', {
		runtime: lambda.Runtime.NODEJS_18_X,
		handler: 'index.handler',
		code: lambda.Code.fromAsset(functionPath),
		envvironment: {
			DEST_BUCKET_NAME: bucketName,
			FOLDER_INPUT: folderInput,
			FOLDER_OUTPUT: folderOutput,
			PROCESS_WIDTH: '512',
			PROCESS_HEIGHT: '512'
		}
	});
	return lambdaFunction;
}
```
- Run `cdk synth` and then deploy with `cdk deploy` and check the Stacks on CloudFormation in the AWS Account.
	- It should have provisioned an S3 bucket with the name specified and the folder names specified should be present also.

The work done above is an introduction to AWS CDK, almost the same format is going to be used in the next sections but you can wipe it all of the need be.


### REAL WORK
*A lot is going to change in the upcoming session. A lot of naming decisions, architecture decisions etc.*
1. Architectural decision to use two S3 buckets instead of one. This is to house the original amd processes images separately. It was either this or to write a policy that will restrict users from accessing the original images but not the processed images.
	- A lot of code changes have been made to support this decision, including creating two separate buckets, `Uploads Bucket` and `Assets Bucket` to house the original and processed images respectively. The env-vars have been changed to match accordingly.

### Installing a CDK
- Make a new top-level directory `thumbing-serverless-cdk`.
- Install the cdk globally for the entire project.
- State the environment variables in the `.env.example` file in the `thumbing-serverless-cdk` directory.
	- note that the env-vars should correspond to the new env-vars chosen specially for the project.
```shell
UPLOADS_BUCKET_NAME="taskmaster-cruddur-uploaded-avatars"
ASSETS_BUCKET_NAME="assets.thetaskmasterernest.cyou"
THUMBING_S3_FOLDER_INPUT=""
THUMBING_S3_FOLDER_OUTPUT="avatars"
THUMBING_WEBHOOK_URL="https://api.thetaskmasterernest.cyou/webhooks/avatar"
THUMBING_TOPIC_NAME="cruddur-assets"
THUMBING_FUNCTION_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/json/lambda/process-images"
```
- Add this command to the `.gitpod.yaml` file to start up the CDK environment and make the CLI available throughout the project.
```YAML
- name: cdk
	before: |
		npm install aws-cdk -g
		cd thumbing-serverless-cdk
		cp .env.example .env
		npm i
```

### Consuming the Lambda
- Create a directory to contain the lambdas to use it the serverless image processing process. `mkdir /aws/lambdas/process-images`.
- Create an `index.js` that will house old code that is abstracted and used for testing.
```javascript
const process = require('process');
const {getClient, getOriginalImage, processImage, uploadProcessedImage} = require('./s3-image-processing.js')
const path = require('path');

const bucketName = process.env.DEST_BUCKET_NAME
const folderInput = process.env.FOLDER_INPUT
const folderOutput = process.env.FOLDER_OUTPUT
const width = parseInt(process.env.PROCESS_WIDTH)
const height = parseInt(process.env.PROCESS_HEIGHT)

client = getClient();

exports.handler = async (event) => {
  const srcBucket = event.Records[0].s3.bucket.name;
  const srcKey = decodeURIComponent(event.Records[0].s3.object.key.replace(/\+/g, ' '));
  console.log('srcBucket',srcBucket)
  console.log('srcKey',srcKey)

  const dstBucket = bucketName;

  filename = path.parse(srcKey).name
  const dstKey = `${folderOutput}/${filename}.jpg`
  console.log('dstBucket',dstBucket)
  console.log('dstKey',dstKey)

  const originalImage = await getOriginalImage(client,srcBucket,srcKey)
  const processedImage = await processImage(originalImage,width,height)
  await uploadProcessedImage(client,dstBucket,dstKey,processedImage)
};
```

- In line with the old code, there is a `test.js` file in the same directory that houses code to test the code with some hard-coded variables used in the deprecated code.
```javascript
const {getClient, getOriginalImage, processImage, uploadProcessedImage} = require('./s3-image-processing.js')

async function main(){
  client = getClient()
  const srcBucket = 'taskmaster-cruddur-uploaded-avatars'
  const srcKey = 'data.jpg'
  const dstBucket = 'assets.thetaskmasterernest.cyou'
  const dstKey = 'avatars/data.png'
  const width = 256
  const height = 256

  const originalImage = await getOriginalImage(client,srcBucket,srcKey)
  console.log(originalImage)
  const processedImage = await processImage(originalImage,width,height)
  await uploadProcessedImage(client,dstBucket,dstKey,processedImage)
}

main()
```

- to test and work with the code in both updated and deprecated code, there is a `s3-image-processing.js` file that contains code/functions to successfully process the code that will be sent to it.
	- this also doubles as the lambda function that should be passed to AWS Lambda to handle the processing.
```javascript
const sharp = require('sharp');
const { S3Client, PutObjectCommand, GetObjectCommand } = require("@aws-sdk/client-s3");

function getClient(){
  const client = new S3Client();
  return client;
}

async function getOriginalImage(client,srcBucket,srcKey){
  console.log('get==')
  const params = {
    Bucket: srcBucket,
    Key: srcKey
  };
  console.log('params',params)
  const command = new GetObjectCommand(params);
  const response = await client.send(command);

  const chunks = [];
  for await (const chunk of response.Body) {
    chunks.push(chunk);
  }
  const buffer = Buffer.concat(chunks);
  return buffer;
}

async function processImage(image,width,height){
  const processedImage = await sharp(image)
    .resize(width, height)
    .jpeg()
    .toBuffer();
  return processedImage;
}

async function uploadProcessedImage(client,dstBucket,dstKey,image){
  console.log('upload==')
  const params = {
    Bucket: dstBucket,
    Key: dstKey,
    Body: image,
    ContentType: 'image/jpeg'
  };
  console.log('params',params)
  const command = new PutObjectCommand(params);
  const response = await client.send(command);
  console.log('repsonse',response);
  return response;
}

module.exports = {
  getClient: getClient,
  getOriginalImage: getOriginalImage,
  processImage: processImage,
  uploadProcessedImage: uploadProcessedImage
}
```

- Since the Lambda will be used for processing images that will be served as avatars in the Cruddur project, there is a library in Node called `sharp` that is used to process images.
	- install this library using the command `npm install sharp` in the `/lambda/process-image` directory
	- install `npm install @aws-sdk/client-s3` in the same directory.
	- to get the AWS Lambda to work with the sharp library, create a `/bin/avatar/build` file with this code. The `Serverless` here was used as the directory name in the cold code but now changed to `Avatar` but it should work the same as it is only referencing a path.
```bash
#! /usr/bin/bash

ABS_PATH=$(readlink -f "$0")
SERVERLESS_PATH=$(dirname $ABS_PATH)
BIN_PATH=$(dirname $SERVERLESS_PATH)
PROJECT_PATH=$(dirname $BIN_PATH)
SERVERLESS_PROJECT_PATH="$PROJECT_PATH/thumbing-serverless-cdk"

cd $SERVERLESS_PROJECT_PATH

npm install
rm -rf node_modules/sharp
SHARP_IGNORE_GLOBAL_LIBVIPS=1 npm install --arch=x64 --platform=linux --libc=glibc sharp
```

- Enter the `thumbing-serverless-cdk` directory and install the AWS SDK for Javascript to access the S3 client with Node.js using the command
	- exclude the `node_modules` from being sent to git by placing it in the `thumbing-serverless-cdk/.gitignore` file.

- Create S3 notifications to to Lambda.
```typescript
import * as s3n from 'aws-cdk-lib/aws-s3-notifications';
//Constructor class
Constructor {
		// create a lambda
    const lambda = this.createLambda(
      functionPath, 
      uploadsBucketName, 
      assetsBucketName, 
      folderInput, 
      folderOutput
    );

	 // add our s3 event notifications
    this.createS3NotifyToLambda(folderInput,lambda,uploadsBucket)
    this.createS3NotifyToSns(folderOutput,snsTopic,assetsBucket)
}

createS3NotifyToLambda(prefix: string, lambda: lambda.IFunction, bucket: s3.IBucket): void {
	const destination = new s3n.LambdaDestination(lambda);
	bucket.addEventNotification(
		s3.EventType.OBJECT_CREATED_PUT,
		destination//,
		//{prefix: prefix} // folder to contain the original images
  )
}
```

- Create an S3 bucket manually and import it into the CDK stack to be referenced by the code. This is to stop the data from being deleted anytime the CDK redeployed or torn down.
```typescript
//Constructor class
Constructor {
	const uploadsBucket = this.createBucket(uploadsBucketName);
  const assetsBucket = this.importBucket(assetsBucketName);
}

createBucket(bucketName: string): s3.IBucket {
	const bucket = new s3.Bucket(this, 'UploadsBucket', {
		bucketName: bucketName,
		removalPolicy: cdk.RemovalPolicy.DESTROY
	});
	return bucket;
}

importBucket(bucketName: string): s3.IBucket {
	const bucket = s3.Bucket.fromBucketName(this,"AssetsBucket",bucketName);
	return bucket;
}
```

- In the `/bin/avatar/files/data.jpg`, put a photo in this file. The name should be the same.
- In the CDE, make your domain name an environment variable. ie `export DOMAIN_NAME="thetaskmasterernest.cyou"`.
- Create a script in the `/avatar` directory that will be used to upload the data ie. `/avatar/files/data.jpg` into an S3 bucket.
	- the script copies the data from the data path into the S3 bucket on AWS.
	- name of the script should be `/avatar/upload`.
```bash
#! /usr/bin/bash

ABS_PATH=$(readlink -f "$0")
SERVERLESS_PATH=$(dirname $ABS_PATH)
DATA_FILE_PATH="$SERVERLESS_PATH/files/data.jpg"

aws s3 cp "$DATA_FILE_PATH" "s3://taskmaster-cruddur-uploaded-avatars/data.jpg"
```

- In the same vein, create another script to delete the data put into the S3 bucket. Name of script should be `/avatar/clear`.
```bash
#! /usr/bin/bash

ABS_PATH=$(readlink -f "$0")
SERVERLESS_PATH=$(dirname $ABS_PATH)
DATA_FILE_PATH="$SERVERLESS_PATH/files/data.jpg"

aws s3 rm "s3://taskmaster-cruddur-uploaded-avatars/data.jpg"
aws s3 rm "s3://assets.$DOMAIN_NAME/avatars/data.jpg"
```

- Trigger the Lambda by uploading an image to the S3 bucket. 
	- In order to do that, there should exist, an S3ReadWritePolicy to create a bucket policy and a Lambda role that triggers when an object is placed within an S3 bucket.
	- When the event is triggered, in the Properties of the "assets" bucket, the Event Notifications should show that the Lambda was triggered.
```typescript
//constructor class
constructor {

	// create bucket policies
	const s3UploadsReadWritePolicy = this.createPolicyBucketAccess(uploadsBucket.bucketArn)
	const s3AssetsReadWritePolicy = this.createPolicyBucketAccess(assetsBucket.bucketArn)

	// attach policies for bucket permissions
	lambda.addToRolePolicy(s3UploadsReadWritePolicy);
	lambda.addToRolePolicy(s3AssetsReadWritePolicy);
}

//create the Lambda
createLambda(functionPath: string, uploadsBucketName: string, assetsBucketName: string, folderInput: string, folderOutput: string): lambda.IFunction {
	const lambdaFunction = new lambda.Function(this, 'ThumbLambda', {
		runtime: lambda.Runtime.NODEJS_18_X,
		handler: 'index.handler',
		code: lambda.Code.fromAsset(functionPath),
		environment: {
			DEST_BUCKET_NAME: assetsBucketName,
			FOLDER_INPUT: folderInput,
			FOLDER_OUTPUT: folderOutput,
			PROCESS_WIDTH: '512',
			PROCESS_HEIGHT: '512'
		}
	});
	return lambdaFunction;
}

// create access policy for bucket
createPolicyBucketAccess(bucketArn: string){
	const s3ReadWritePolicy = new iam.PolicyStatement({
		actions: [
			's3:GetObject',
			's3:PutObject',
		],
		resources: [
			`${bucketArn}/*`,
		]
	});
	return s3ReadWritePolicy;
}
```

- Create notifications for data using SNS.
	- import the SNS topic, notifications and subscription.
	- create the topic and subscription and notification from s3 to SNS.
	- create a policy to publish SNS (this will be needed no more in the future).
```typescript
//constructor class
constructor {
	const snsPublishPolicy = this.createPolicySnSPublish(snsTopic.topicArn)

	lambda.addToRolePolicy(snsPublishPolicy);

	lambda.addToRolePolicy(snsPublishPolicy);
}

createSnsTopic(topicName: string): sns.ITopic{
	const logicalName = "ThumbingTopic";
	const snsTopic = new sns.Topic(this, logicalName, {
		topicName: topicName
	});
	return snsTopic;
}

createSnsSubscription(snsTopic: sns.ITopic, webhookUrl: string): sns.Subscription {
	const snsSubscription = snsTopic.addSubscription(
		new subscriptions.UrlSubscription(webhookUrl)
	)
	return snsSubscription;
}

createS3NotifyToSns(prefix: string, snsTopic: sns.ITopic, bucket: s3.IBucket): void {
	const destination = new s3n.SnsDestination(snsTopic)
	bucket.addEventNotification(
		s3.EventType.OBJECT_CREATED_PUT, 
		destination,
		{prefix: prefix}
	);
}

  /*
createPolicySnSPublish(topicArn: string){
	const snsPublishPolicy = new iam.PolicyStatement({
		actions: [
			'sns:Publish',
		],
		resources: [
			topicArn
		]
	});
	return snsPublishPolicy;
}
  */
}
```

The full `thumbing-serverless-cdk-stack.ts` code will look like this:
```typescript
import * as cdk from 'aws-cdk-lib';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as s3n from 'aws-cdk-lib/aws-s3-notifications';
import * as subscriptions from 'aws-cdk-lib/aws-sns-subscriptions';
import * as sns from 'aws-cdk-lib/aws-sns';
import { Construct } from 'constructs';
import * as dotenv from 'dotenv';

dotenv.config();

export class ThumbingServerlessCdkStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // The code that defines your stack goes here
    const uploadsBucketName: string = process.env.UPLOADS_BUCKET_NAME as string;
    const assetsBucketName: string = process.env.ASSETS_BUCKET_NAME as string;
    const folderInput: string = process.env.THUMBING_S3_FOLDER_INPUT as string;
    const folderOutput: string = process.env.THUMBING_S3_FOLDER_OUTPUT as string;
    const webhookUrl: string = process.env.THUMBING_WEBHOOK_URL as string;
    const topicName: string = process.env.THUMBING_TOPIC_NAME as string;
    const functionPath: string = process.env.THUMBING_FUNCTION_PATH as string;
    console.log('uploadsBucketName',)
    console.log('assetsBucketName',assetsBucketName)
    console.log('folderInput',folderInput)
    console.log('folderOutput',folderOutput)
    console.log('webhookUrl',webhookUrl)
    console.log('topicName',topicName)
    console.log('functionPath',functionPath)

    const uploadsBucket = this.createBucket(uploadsBucketName);
    const assetsBucket = this.importBucket(assetsBucketName);

    // create a lambda
    const lambda = this.createLambda(
      functionPath, 
      uploadsBucketName, 
      assetsBucketName, 
      folderInput, 
      folderOutput
    );

    // create topic and subscription
    const snsTopic = this.createSnsTopic(topicName)
    this.createSnsSubscription(snsTopic,webhookUrl)

    // add our s3 event notifications
    this.createS3NotifyToLambda(folderInput,lambda,uploadsBucket)
    this.createS3NotifyToSns(folderOutput,snsTopic,assetsBucket)

    // create policies
    const s3UploadsReadWritePolicy = this.createPolicyBucketAccess(uploadsBucket.bucketArn)
    const s3AssetsReadWritePolicy = this.createPolicyBucketAccess(assetsBucket.bucketArn)
    //const snsPublishPolicy = this.createPolicySnSPublish(snsTopic.topicArn)

    // attach policies for permissions
    lambda.addToRolePolicy(s3UploadsReadWritePolicy);
    lambda.addToRolePolicy(s3AssetsReadWritePolicy);
    //lambda.addToRolePolicy(snsPublishPolicy);
}

createBucket(bucketName: string): s3.IBucket {
	const bucket = new s3.Bucket(this, 'UploadsBucket', {
		bucketName: bucketName,
		removalPolicy: cdk.RemovalPolicy.DESTROY
	});
	return bucket;
}

importBucket(bucketName: string): s3.IBucket {
	const bucket = s3.Bucket.fromBucketName(this,"AssetsBucket",bucketName);
	return bucket;
}

createLambda(functionPath: string, uploadsBucketName: string, assetsBucketName: string, folderInput: string, folderOutput: string): lambda.IFunction {
	const lambdaFunction = new lambda.Function(this, 'ThumbLambda', {
		runtime: lambda.Runtime.NODEJS_18_X,
		handler: 'index.handler',
		code: lambda.Code.fromAsset(functionPath),
		environment: {
			DEST_BUCKET_NAME: assetsBucketName,
			FOLDER_INPUT: folderInput,
			FOLDER_OUTPUT: folderOutput,
			PROCESS_WIDTH: '512',
			PROCESS_HEIGHT: '512'
		}
	});
	return lambdaFunction;
} 

createS3NotifyToLambda(prefix: string, lambda: lambda.IFunction, bucket: s3.IBucket): void {
	const destination = new s3n.LambdaDestination(lambda);
	bucket.addEventNotification(
		s3.EventType.OBJECT_CREATED_PUT,
		destination//,
		//{prefix: prefix} // folder to contain the original images
	)
}

createPolicyBucketAccess(bucketArn: string){
	const s3ReadWritePolicy = new iam.PolicyStatement({
		actions: [
			's3:GetObject',
			's3:PutObject',
		],
		resources: [
			`${bucketArn}/*`,
		]
	});
	return s3ReadWritePolicy;
}

createSnsTopic(topicName: string): sns.ITopic{
	const logicalName = "ThumbingTopic";
	const snsTopic = new sns.Topic(this, logicalName, {
		topicName: topicName
	});
	return snsTopic;
}

createSnsSubscription(snsTopic: sns.ITopic, webhookUrl: string): sns.Subscription {
	const snsSubscription = snsTopic.addSubscription(
		new subscriptions.UrlSubscription(webhookUrl)
	)
	return snsSubscription;
}

createS3NotifyToSns(prefix: string, snsTopic: sns.ITopic, bucket: s3.IBucket): void {
	const destination = new s3n.SnsDestination(snsTopic)
	bucket.addEventNotification(
		s3.EventType.OBJECT_CREATED_PUT, 
		destination,
		{prefix: prefix}
	);
}

  /*
createPolicySnSPublish(topicArn: string){
	const snsPublishPolicy = new iam.PolicyStatement({
		actions: [
			'sns:Publish',
		],
		resources: [
			topicArn
		]
	});
	return snsPublishPolicy;
}
  */
}

```

- With this you can now run `cdk synth` to generate the template that will be issued, and run `cdk deploy` to deploy the template to CloudFormation.
- For the deployment to work, manually create the `assets.thetaskmasterenest.cyou` S3 bucket before deploying the CDK and uploading the data in to the Uploads bucket.


### Serving The Avatar Images via CloudFront
In this section, the images that have been placed in the Uploads S3 bucket will be configured to be served via CloudFront to our application.
The configuration will be done via clickops.

Enter the CloudFront service in the AWS Console and start the configuration as follows:
- Set the Origin domain to be the S3 assets bucket name; `assets.thetaskmasterernest.cyou`.
- Set not Origin path, as there is no URL to append to the domain.
- Use the default name generated.
- For Origin access; restrict bucket to access only CloudFront with the origin access control settings.
	- create the control settings; use the default name, set a description if you want.
	- set the signing behaviour to sign requests; set the origin type to be S3.
- Set no custom headers.
	- this is because the app is not a static site, the pages are going to be dynamically hosted.
- Do not turn on Origin Shield
- For the default cache behaviour;
	- set the path pattern to be the default one
	- set compress objects automatically to YES
	- for viewer protocol policy, redirect HTTP to HTTPS
	- set the allowed HTTP methods to be GET and HEAD
	- do not restrict viewer access; the application is a social site so anyone should be able to see the avatar
- For the cache key and origin requests;
	- set the caching policy to Caching Optimized
	- set the origin request policy to CORS-CustomOrigin.  (This is because the avatars have to be served with the same domain and fetched on the same website)
	- set the response headers policy to use simple CORS
	- do not allow smooth streaming, that is for videos
	- do not enable real-time logs
- Leave all the Function Associations to be of "no association".
- For Settings;
	- choose the "best performance" price class
	- do not serve WAF
	- set up an alternate domain name to serve up the files needed; use `assets.thetaskmasterernest.cyou`
	- Add a custom SSL certificate. This certificate must be present in the US-EAST-1 region.
		- go to the US-EAST-1 region and get to the ACM service.
		- request for a certificate, using the parameters and wildcard configs; `thetaskmasterernest.cyou`  and `*.thetaskmasterernest.cyou`
		- validate the certificate via DNS validation using all the defaults and request a certificate.
		- wait till certificate has been validated.
	- Select the ACM certificate
	- set the supported HTTP version to be HTTP/2
	- do not set a default root object
	- do not set any standard logging
	- turn on IPv6
	- add a description; eg `serve assets for Cruddur`.
- Create the CloudFront distribution and wait for it to be enabled.

- To ensure that the S3 assets are publicly available as intended, add the CloudFront origin domain to the ACM certificate; ie `assets.thetaskmasterernest.cyou`.
	- go to the Hosted Zones (in ACM in the the US-EAST-1 region), create a new record in the certificate.
	- set the record name to be `assets`.
	- set the record's alias to Alias to CloudFront and choose the distribution created.
	- set the routing policy to Simple Routing Policy.
	- create the record.

- Go back to the CloudFront distribution and scroll down to the Origin Access and look for Bucket Policy.
	- copy that Policy.
	- go to the Amazon S3, enter the `assets.thetaskmasterernest.cyou` bucket (aka the assets bucket).
	- go to that bucket's permissions, scroll to Bucket Policy, Edit the policy and paste in the copied policy.
	- save the policy.
With this done, the data file can now be accessed from the the URL `https://assets.thetaskmasterernest.cyou/avatars/data.jpg`.

- A neat little addition to always make sure the latest image / version of the image you have specified is always served;
	- set up Invalidations in the CloudFront distribution, Go to Invalidations > Create Invalidation > Click Add Object Paths
	- in the dialog box, write `/*`, and create the invalidation.

- You can now run the commands. `cdk synth`, and deploy the Stack using `cdk deploy`.
- Upload the data with the `/bin/avatar/upload` script and check whether the data has been propagated in the right directories in the separate S3 buckets.


### Implement Users Profile Photo
The goal of this session is to make the avatars available for each user, to make it appear as their profile photo.
This should be done in the local development environment with the docker containers. 
It would be best to have the images pulled and made available locally so as to not log into ECR to get images.
- Start up all the containers (except for the x-ray daemon container) using the `docker compose` command.
	- for the `/backend-flask/Dockerfile`, a small change of adding `"-u"` to the CMD script to implement an unbuffered output from the changes that occur in the Flask container.
```Dockerfile
FROM 478429420160.dkr.ecr.eu-west-2.amazonaws.com/cruddur-python:3.10-slim-buster
WORKDIR /backend-flask
COPY requirements.txt requirements.txt
RUN pip3 install -r requirements.txt
COPY . .
EXPOSE ${PORT}
ENV PYTHONUNBUFFERED=1
CMD [ "python3", "-m" , "flask", "run",  "--host=0.0.0.0", "--port=4567", "--debug"]
```
- With the containers running, set up the PostgresQL database (`./setup`); and set up the DynamoDB database by loading the schema (`./schema-load`) and seeding the data(`./seed`).

- Go to the AWS Console and into the S3 Assets bucket, `assets.thetaskmasterernest.cyou`, and add a `/banners` directory. 
- Add an image with the name `banner.jpg`. The link to the image will be referenced in creating the Profile heading in the coming sections.
- Drag and drop the `banner.jpg` image into the banners directory in the assets bucket.

- The code in the `/backend-flask/services/user_activities.py` has been mocked. Change this code to personalize the data for every user that logs in. The code references a new SQL code that will be made available soon.
```python
from lib.postgresdb import db
#from aws_xray_sdk.core import xray_recorder
class UserActivities:
  def run(user_handle):
    #try:
    model = {
      'errors': None,
      'data': None
    }
    if user_handle == None or len(user_handle) < 1:
      model['errors'] = ['blank_user_handle']
    else:
      print("else:")
      # this references the location of the SQL code, /users/show file.
      sql = db.template('users','show')
      results = db.query_object_json(sql,{'handle': user_handle})
      model['data'] = results
      #subsegment = xray_recorder.begin_subsegment('mock-data')
      ## xray ---
      #dict = {
      #  "now": now.isoformat(),
      #  "results-size": len(model['data'])
      #}
      #subsegment.put_metadata('key', dict, 'namespace')
      #xray_recorder.end_subsegment()
    #finally:  
    ##  # Close the segment
    #  xray_recorder.end_subsegment()
    return model
```

- Create the SQL code that will be accessed by  `user_activities.py` code. The SQL code path is `/backend-flask/db/sql/users/show.sql`.
	- this code is used to display the user's name, handle, and display_name along with a few activities
```SQL
SELECT 
  (SELECT COALESCE(row_to_json(object_row),'{}'::json) FROM (
    SELECT
      users.uuid,
      users.handle,
      users.display_name,
      (
       SELECT 
        count(true) 
       FROM public.activities
       WHERE
        activities.user_uuid = users.uuid
       ) as cruds_count
  ) object_row) as profile,
  (SELECT COALESCE(array_to_json(array_agg(row_to_json(array_row))),'[]'::json) FROM (
    SELECT
      activities.uuid,
      users.display_name,
      users.handle,
      activities.message,
      activities.created_at,
      activities.expires_at
    FROM public.activities
    WHERE
      activities.user_uuid = users.uuid
    ORDER BY activities.created_at DESC 
    LIMIT 40
  ) array_row) as activities
FROM public.users
WHERE
  users.handle = %(handle)s
```

- The main focus of this section will be to set up the Profile Page for the user in the Cruddur application.
- An EditProfileButton will be added, a ProfileHeading will be added and these changes will be made to reflect on the pages served to the user.

- Starting with the components on the frontend page.
1. `/frontend-react-js/src/components/ActivityFeed.js`
```Javascript
import './ActivityFeed.css';
import ActivityItem from './ActivityItem';

export default function ActivityFeed(props) {
  return (
    <div className='activity_feed_collection'>
      {props.activities.map(activity => {
      return  <ActivityItem setReplyActivity={props.setReplyActivity} setPopped={props.setPopped} key={activity.uuid} activity={activity} />
      })}
    </div>
  );
}
```
2. `/frontend-react-js/src/components/CrudButton.js`
```javascript
import './CrudButton.css';

export default function CrudButton(props) {
  const pop_activities_form = (event) => {
    event.preventDefault();
    props.setPopped(true);
    return false;
  }

  return (
    <button onClick={pop_activities_form} className='post' href="#">Crud</button>
  );
}
```
3. `/frontend-react-js/src/components/EditProfileButton.js`. This is not already present, it has to be created.
```javascript
import './EditProfileButton.css';

export default function EditProfileButton(props) {
  const pop_profile_form = (event) => {
    event.preventDefault();
    console.log('pop profile form')
    props.setPopped(true);
    return false;
  }

  return (
    <button onClick={pop_profile_form} className='profile-edit-button' href="#">Edit Profile</button>
  );
}
```
4. `/frontend-react-js/src/components/EditProfileButton.css`.
```CSS
.profile-edit-button {
  border: solid 1px rgba(255,255,255,0.5);
  padding: 12px 20px;
  font-size: 18px;
  background: none;
  border-radius: 999px;
  color: rgba(255,255,255,0.8);
  cursor: pointer;
}

.profile-edit-button:hover {
  background: rgba(255,255,255,0.3)
}
```
5. `/frontend-react-js/src/components/ProfileHeading.js`
```javascript
import './ProfileHeading.css';
import EditProfileButton from '../components/EditProfileButton';

export default function ProfileHeading(props) {
  const backgroundImage = 'url("https://assets.thetaskmasterernest.cyou/banners/banner.jpg")';
  const styles = {
    backgroundImage: backgroundImage,
    backgroundSize: 'cover',
    backgroundPosition: 'center',
  };
  return (
  <div className='activity_feed_heading profile_heading'>
    <div className='title'>{props.profile.display_name}</div>
    <div className="cruds_count">{props.profile.cruds_count} Cruds</div>
    <div class="banner" style={styles} >
      <div className="avatar">
        <img src="https://assets.thetaskmasterernest.cyou/avatars/data.jpg"></img>
      </div>
    </div>
    <div class="info">
      <div class='id'>
        <div className="display_name">{props.profile.display_name}</div>
        <div className="handle">@{props.profile.handle}</div>
      </div>
      <EditProfileButton setPopped={props.setPopped} />
    </div>

  </div>
  );
}
```
6. `/frontend-react-js/src/components/ProfileHeading.css`
```CSS
.profile_heading {
  padding-bottom: 0px;
}
.profile_heading .avatar {
  position: absolute;
  bottom:-74px;
  left: 16px;
}
.profile_heading .avatar img {
  width: 148px;
  height: 148px;
  border-radius: 999px;
  border: solid 8px var(--fg);
}

.profile_heading .banner {
  position: relative;
  height: 200px;
}

.profile_heading .info {
  display: flex;
  flex-direction: row;
  align-items: start;
  padding: 16px;
}

.profile_heading .info .id {
  padding-top: 70px;
  flex-grow: 1;
}

.profile_heading .info .id .display_name {
  font-size: 24px;
  font-weight: bold;
  color: rgb(255,255,255);
}
.profile_heading .info .id .handle {
  font-size: 16px;
  color: rgba(255,255,255,0.7);
}

.profile_heading .cruds_count {
  color: rgba(255,255,255,0.7);
}
```

- Serving up the changes implemented on the frontend pages
1. `/frontend-react-js/src/pages/HomeFeedPage.js`
	- this code is a section of what the code returns to the user. The focus is on the `<div className='activity_feed'>` portion and below.
```javascript
return (
    <article>
      <DesktopNavigation user={user} active={'home'} setPopped={setPopped} />
      <div className='content'>
        <ActivityForm  
          popped={popped}
          setPopped={setPopped} 
          setActivities={setActivities} 
        />
        <ReplyForm 
          activity={replyActivity} 
          popped={poppedReply} 
          setPopped={setPoppedReply} 
          setActivities={setActivities} 
          activities={activities} 
        />
        <div className='activity_feed'>
          <div className='activity_feed_heading'>
            <div className='title'>Home</div>
          </div>
          <ActivityFeed 
            setReplyActivity={setReplyActivity} 
            setPopped={setPoppedReply} 
            activities={activities} 
          />
        </div>
      </div>
      <DesktopSidebar user={user} />
    </article>
  );
```
2. `/frontend-react-js/src/pages/NotificationsFeedPage.js`
	- the focus here is the same as above, what the code returns for the `<div className='activity_feed'>` and below.
```javascript
return (
    <article>
      <DesktopNavigation user={user} active={'notifications'} setPopped={setPopped} />
      <div className='content'>
        <ActivityForm  
          popped={popped}
          setPopped={setPopped} 
          setActivities={setActivities} 
        />
        <ReplyForm 
          activity={replyActivity} 
          popped={poppedReply} 
          setPopped={setPoppedReply} 
          setActivities={setActivities} 
          activities={activities} 
        />
        <div className='activity_feed'>
          <div className='activity_feed_heading'>
            <div className='title'>Notifications</div>
          </div>
          <ActivityFeed 
            setReplyActivity={setReplyActivity} 
            setPopped={setPoppedReply} 
            activities={activities} 
          />
        </div>
      </div>
      <DesktopSidebar user={user} />
    </article>
  );
```
3. `/frontend-react-js/src/pages/UserFeedPage.js`
	- in this code, the `ProfileHeading` component is imported, the `checkAuth` component is imported for access to clearance from Cognito and the activity feed is set.
```javascript
import './UserFeedPage.css';
import React from "react";
import { useParams } from 'react-router-dom';

import DesktopNavigation  from 'components/DesktopNavigation';
import DesktopSidebar     from 'components/DesktopSidebar';
import ActivityFeed from 'components/ActivityFeed';
import ActivityForm from 'components/ActivityForm';
import ProfileHeading from 'components/ProfileHeading';
import ProfileForm from 'components/ProfileForm';

import {checkAuth, getAccessToken} from 'lib/CheckAuth';

export default function UserFeedPage() {
  const [activities, setActivities] = React.useState([]);
  const [profile, setProfile] = React.useState([]);
  const [popped, setPopped] = React.useState([]);
  const [poppedProfile, setPoppedProfile] = React.useState([]);
  const [user, setUser] = React.useState(null);
  const dataFetchedRef = React.useRef(false);

  const params = useParams();

  const loadData = async () => {
    try {
      const backend_url = `${process.env.REACT_APP_BACKEND_URL}/api/activities/@${params.handle}`
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
        setProfile(resJson.profile)
        setActivities(resJson.activities)
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
      <DesktopNavigation user={user} active={'profile'} setPopped={setPopped} />
      <div className='content'>
        <ActivityForm popped={popped} setActivities={setActivities} />
        <ProfileForm 
          profile={profile}
          popped={poppedProfile} 
          setPopped={setPoppedProfile} 
        />

        <div className='activity_feed'>
          <ProfileHeading setPopped={setPoppedProfile} profile={profile} />
          <ActivityFeed activities={activities} />
        </div>
      </div>
      <DesktopSidebar user={user} />
    </article>
  );
}
```


### Implementing Migrations Endpoint for the Backend + Adding the Profile Form.
In this section, I will implement a migration of a database and add a Profile form to the Profile page and also rectify a token generation issue.
- First thing to do is to enable the unbuffering of the backend Dockerfile by eliminating the `-u` in the command line and adding `ENV PYTHONUNBUFFERED=1` to the Dockerfile.
- An important thing to do is to add `jsconfig.json` file in the `frontend-react-js` directory.
	- this code ensures that every component in the `/src` directory can be referenced absolutely, allowing the addition of components without a thinking about pathing.
```JSON
{
  "compilerOptions": {
    "baseUrl": "src"
  },
  "include": ["src"]
}
```

- Taking action on the `/frontend-react-js` directory and implementing a Profile form, modifying a Reply form and a PopUp to show our profile info. Then we add link them to the pages on which they should be served.
1.  With the introduction of the `jsconfig.json` file, first modify the `/frontend-react-js/src/components/EditProfileButton.js` and the `/frontend-react-js/src/components/MessageForm.js` files to be rid of pathing.
```javascript
//change from this:
import {getAccessToken} from '../lib/CheckAuth';
//to this:
import {getAccessToken} from 'lib/CheckAuth';
```
2. Implement the Profile Form with this code at `/frontend-react-js/src/components/ProfileForm.js`.
```javascript
import './ProfileForm.css';
import React from "react";
import process from 'process';
import {getAccessToken} from 'lib/CheckAuth';

export default function ProfileForm(props) {
  const [bio, setBio] = React.useState(0);
  const [displayName, setDisplayName] = React.useState(0);

  React.useEffect(()=>{
    console.log('useEffects',props)
    setBio(props.profile.bio);
    setDisplayName(props.profile.display_name);
  }, [props.profile])

  const onsubmit = async (event) => {
    event.preventDefault();
    try {
      const backend_url = `${process.env.REACT_APP_BACKEND_URL}/api/profile/update`
      await getAccessToken()
      const access_token = localStorage.getItem("access_token")
      const res = await fetch(backend_url, {
        method: "POST",
        headers: {
          'Authorization': `Bearer ${access_token}`,
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          bio: bio,
          display_name: displayName
        }),
      });
      let data = await res.json();
      if (res.status === 200) {
        setBio(null)
        setDisplayName(null)
        props.setPopped(false)
      } else {
        console.log(res)
      }
    } catch (err) {
      console.log(err);
    }
  }

  const bio_onchange = (event) => {
    setBio(event.target.value);
  }

  const display_name_onchange = (event) => {
    setDisplayName(event.target.value);
  }

  const close = (event)=> {
    if (event.target.classList.contains("profile_popup")) {
      props.setPopped(false)
    }
  }

  if (props.popped === true) {
    return (
      <div className="popup_form_wrap profile_popup" onClick={close}>
        <form 
          className='profile_form popup_form'
          onSubmit={onsubmit}
        >
          <div class="popup_heading">
            <div class="popup_title">Edit Profile</div>
            <div className='submit'>
              <button type='submit'>Save</button>
            </div>
          </div>
          <div className="popup_content">
            <div className="field display_name">
              <label>Display Name</label>
              <input
                type="text"
                placeholder="Display Name"
                value={displayName}
                onChange={display_name_onchange} 
              />
            </div>
            <div className="field bio">
              <label>Bio</label>
              <textarea
                placeholder="Bio"
                value={bio}
                onChange={bio_onchange} 
              />
            </div>
          </div>
        </form>
      </div>
    );
  }
}
```
3. Add the styling for the ProfileForm with code at `/frontend-react-js/src/components/ProfileForm.css`.
```CSS
form.profile_form input[type='text'],
form.profile_form textarea {
  font-family: Arial, Helvetica, sans-serif;
  font-size: 16px;
  border-radius: 4px;
  border: none;
  outline: none;
  display: block;
  outline: none;
  resize: none;
  width: 100%;
  padding: 16px;
  border: solid 1px var(--field-border);
  background: var(--field-bg);
  color: #fff;
}

.profile_popup .popup_content {
  padding: 16px;
}

form.profile_form .field.display_name {
  margin-bottom: 24px;
}

form.profile_form label {
  color: rgba(255,255,255,0.8);
  padding-bottom: 4px;
  display: block;
}

form.profile_form textarea {
  height: 140px;
}

form.profile_form input[type='text']:hover,
form.profile_form textarea:focus {
  border: solid 1px var(--field-border-focus)
}

.profile_popup button[type='submit'] {
  font-weight: 800;
  outline: none;
  border: none;
  border-radius: 4px;
  padding: 10px 20px;
  font-size: 16px;
  background: rgba(149,0,255,1);
  color: #fff;
}
```
4. With the ProfileForm set up, we set up styling to pop out the ProfileInfo if we want to edit the Profile information.
	- at `/frontend-react-js/src/components/Popup.css`
```CSS
.popup_form_wrap {
  z-index: 100;
  position: fixed;
  height: 100%;
  width: 100%;
  top: 0;
  left: 0;
  display: flex;
  flex-direction: column;
  justify-content: flex-start;
  align-items: center;
  padding-top: 48px;
  background: rgba(255,255,255,0.1)
}

.popup_form {
  background: #000;
  box-shadow: 0px 0px 6px rgba(190, 9, 190, 0.6);
  border-radius: 16px;
  width: 600px;
}

.popup_form .popup_heading {
  display: flex;
  flex-direction: row;
  border-bottom: solid 1px rgba(255,255,255,0.4);
  padding: 16px;
}

.popup_form .popup_heading .popup_title{
  flex-grow: 1;
  color: rgb(255,255,255);
  font-size: 18px;

}
```
4. Modify the ReplyForm to close the popup when you click outside of it at `/frontend-react-js/src/components/ReplyForm.js`
```javascript
//after this block of code 
%%const textarea_onchange = (event) => {
    setCount(event.target.value.length);
    setMessage(event.target.value);
  }%%

//add this:
  const close = ()=> {
    console.log('close')
    //props.setPopped(false)
  }

//let the props.popped method be this
 if (props.popped === true) {
	return (
	//the line below is the one to modify, adding onClick to the original line.
		<div className="popup_form_wrap" onClick={close}>
	
```
5. Modify the ReplyForm's css, `/frontend-react-js/src/components/ReplyForm.css` to be.
```CSS
form.replies_form {
  padding: 16px;
  display: flex;
  flex-direction: column;
}

.activity_wrap {
  padding: 16px;
}

form.replies_form textarea {
  font-family: Arial, Helvetica, sans-serif;
  font-size: 16px;
  border-radius: 4px;
  border: none;
  outline: none;
  display: block;
  outline: none;
  resize: none;
  width: 100%;
  height: 140px;
  padding: 16px;
  border: solid 1px rgba(149,0,255,0.1);
  background: rgba(149,0,255,0.1);
  color: #fff;
}

form.replies_form textarea:focus {
  border: solid 1px rgb(149,0,255,1);
}

form.replies_form .submit {
  display: flex;
  flex-direction: row;
  justify-content: flex-end;
  align-items: center;
  margin-top: 12px;
  font-weight: 600;
}

form.replies_form button[type='submit'] {
  font-weight: 800;
  outline: none;
  border: none;
  border-radius: 4px;
  border-top-right-radius: 0;
  border-bottom-right-radius: 0;
  height: 38px;
  padding: 10px 20px;
  font-size: 16px;
  margin-left: 12px;
  background: rgba(149,0,255,1);
  color: #fff;
}

form.replies_form .count {
  color: rgba(255,255,255,0.3)
}

form.replies_form .count.err {
  color: rgb(255, 0, 0)
}

form.replies_form .expires_at_field {
  display: flex;
  gap: 12px;
  position: relative;
  border-left: solid 1px rgba(149,0,255,0.7);
}

form.replies_form .expires_at_field .icon {
  position: absolute;
  top: 12px;
  left: 8px;
  fill: #fff;
  width: 14px;
  height: 14px;
  z-index: 2;
}
```

- With the addition of the `jsconfig.json` file, we can now modify the pages to a absolutely refer to the components they import.
1. `frontend-react-js/src/pages/UserFeedPage.js`
```javascript
import DesktopNavigation  from 'components/DesktopNavigation';
import DesktopSidebar     from 'components/DesktopSidebar';
import ActivityFeed from 'components/ActivityFeed';
import ActivityForm from 'components/ActivityForm';
import ProfileHeading from 'components/ProfileHeading';
import ProfileForm from 'components/ProfileForm';

import {checkAuth, getAccessToken} from 'lib/CheckAuth';

//and under the Desktop Navigation add
      <DesktopNavigation user={user} active={'profile'} setPopped={setPopped} />
      <div className='content'>
        <ActivityForm popped={popped} setActivities={setActivities} />
        //ProfileForm is the focus here.
        <ProfileForm 
          profile={profile}
          popped={poppedProfile} 
          setPopped={setPoppedProfile} 
        />
```
2. `frontend-react-js/src/pages/HomeFeedPage.js`
```javascript
import DesktopNavigation  from 'components/DesktopNavigation';
import DesktopSidebar     from 'components/DesktopSidebar';
import ActivityFeed from 'components/ActivityFeed';
import ActivityForm from 'components/ActivityForm';
import ReplyForm from 'components/ReplyForm';
import {checkAuth, getAccessToken} from 'lib/CheckAuth';
```

- Now, ensure the the `Popup.css` is rendered in the `frontend-react-js/src/App.js` file.
```javascript
import './App.css';
//import the Popup.css component
import './components/Popup.css';
```

#### Now to the migration of the database.
First, we cater for the scripts that will be used to generate, migrate and rollback the database migrations.
The database the migrations will be run on is the PostgresQL database.
1. `/bin/generate/migration`
	- running this generates a numbered migration file that stores the state of the last successful migration so it can be used as a reference top select which migration files to run.
	- this numbered file is stored in file we specified in a directory specified by the pathing.
```bash
#!/usr/bin/env python3
import time
import os
import sys

if len(sys.argv) == 2:
  name = sys.argv[1]
else:
  print("pass a filename: eg. ./bin/generate/migration add_bio_column")
  exit(0)

timestamp = str(time.time()).replace(".","")

filename = f"{timestamp}_{name}.py"

# covert undername name to title case eg. add_bio_column -> AddBioColumn
klass = name.replace('_', ' ').title().replace(' ','')

file_content = f"""
from lib.db import db

class {klass}Migration:
  def migrate_sql():
    data = \"\"\"
    \"\"\"
    return data
  def rollback_sql():
    data = \"\"\"
    \"\"\"
    return data

  def migrate():
    db.query_commit({klass}Migration.migrate_sql(),{{
    }})

  def rollback():
    db.query_commit({klass}Migration.rollback_sql(),{{
    }})

migration = AddBioColumnMigration
"""
#remove leading and trailing new lines
file_content = file_content.lstrip('\n').rstrip('\n')

current_path = os.path.dirname(os.path.abspath(__file__))
file_path = os.path.abspath(os.path.join(current_path, '..', '..','backend-flask','db','migrations',filename))
print(file_path)

with open(file_path, 'w') as f:
  f.write(file_content)
```

- Create a directory `/backend-flask/db/migrations`.
- Run the script in the `/bin/generate/migration`, it writes a numbered output file in the `/backend-flask/db/migrations` dir.
	- copy the contents of that script, create a `/backend-flask/db/migrations/.keep` file and populate it with the contents of the numbered output file. (remember it is a `.keep` file, and remember to check that the first line is `from lib.postgresdb import db`).
	- There are some SQL commands to add, some `ALTER TABLE` commands to add a bio column in the database.
```python
from lib.db import db

class AddBioColumnMigration:
  def migrate_sql():
    data = """
      ALTER TABLE public.users ADD COLUMN bio text;
    """
    return data
  def rollback_sql():
    data = """
      ALTER TABLE public.users DROP COLUMN;
    """
    return data

  def migrate():
    db.query_commit(AddBioColumnMigration.migrate_sql(),{
    })

  def rollback():
    db.query_commit(AddBioColumnMigration.rollback_sql(),{
    })

migration = AddBioColumnMigration
```

- These following scripts are used to run the generated files in the `/db/migrations` directory.
- Make these scripts available in the `/bin` directory in the root directory.
1. `bin/postgresdb/migrate`
```bash
#!/usr/bin/env python3

import os
import sys
import glob
import re
import time
import importlib

current_path = os.path.dirname(os.path.abspath(__file__))
parent_path = os.path.abspath(os.path.join(current_path, '..', '..','backend-flask'))
sys.path.append(parent_path)
from lib.db import db

def get_last_successful_run():
  sql = """
    SELECT last_successful_run
    FROM public.schema_information
    LIMIT 1
  """
  return int(db.query_value(sql,{},verbose=False))

def set_last_successful_run(value):
  sql = """
  UPDATE schema_information
  SET last_successful_run = %(last_successful_run)s
  WHERE id = 1
  """
  db.query_commit(sql,{'last_successful_run': value},verbose=False)
  return value

last_successful_run = get_last_successful_run()

migrations_path = os.path.abspath(os.path.join(current_path, '..', '..','backend-flask','db','migrations'))
sys.path.append(migrations_path)
migration_files = glob.glob(f"{migrations_path}/*")


for migration_file in migration_files:
  filename = os.path.basename(migration_file)
  module_name = os.path.splitext(filename)[0]
  match = re.match(r'^\d+', filename)
  if match:
    file_time = int(match.group())
    if last_successful_run <= file_time:
      mod = importlib.import_module(module_name)
      print('=== running migration: ',module_name)
      mod.migration.migrate()
      timestamp = str(time.time()).replace(".","")
      last_successful_run = set_last_successful_run(timestamp)
```
3.  `bin/postgresdb/rollback`
```bash
#!/usr/bin/env python3

import os
import sys
import glob
import re
import time
import importlib

current_path = os.path.dirname(os.path.abspath(__file__))
parent_path = os.path.abspath(os.path.join(current_path, '..', '..','backend-flask'))
sys.path.append(parent_path)
from lib.db import db

def get_last_successful_run():
  sql = """
    SELECT last_successful_run
    FROM public.schema_information
    LIMIT 1
  """
  return int(db.query_value(sql,{},verbose=False))

def set_last_successful_run(value):
  sql = """
  UPDATE schema_information
  SET last_successful_run = %(last_successful_run)s
  WHERE id = 1
  """
  db.query_commit(sql,{'last_successful_run': value})
  return value

last_successful_run = get_last_successful_run()

migrations_path = os.path.abspath(os.path.join(current_path, '..', '..','backend-flask','db','migrations'))
sys.path.append(migrations_path)
migration_files = glob.glob(f"{migrations_path}/*")


last_migration_file = None
for migration_file in migration_files:
  if last_migration_file == None:
    filename = os.path.basename(migration_file)
    module_name = os.path.splitext(filename)[0]
    match = re.match(r'^\d+', filename)
    if match:
      file_time = int(match.group())
      print("==<><>")
      print(last_successful_run, file_time)
      print(last_successful_run > file_time)
      if last_successful_run > file_time:
        last_migration_file = module_name
        mod = importlib.import_module(module_name)
        print('=== rolling back: ',module_name)
        mod.migration.rollback()
        set_last_successful_run(file_time)
```

- Modify three SQL scripts to; one to add the `bio` column/table and the other to make sure the `bio` is shown in the Profile page and providcode to handle the updates.
1. `/backend-flask/db/schema.sql`.
	- insert into already existing code.
```SQL
CREATE TABLE IF NOT EXISTS public.schema_information (
  id integer UNIQUE,
  last_successful_run text
);
INSERT INTO public.schema_information (id, last_successful_run)
VALUES(1, '0')
ON CONFLICT (id) DO NOTHING;
```
2. `backend-flask/db/sql/users/show.sql`.
	- the focus here is making the `users.bio` available in the code.
```SQL
SELECT 
  (SELECT COALESCE(row_to_json(object_row),'{}'::json) FROM (
    SELECT
      users.uuid,
      users.cognito_user_id as cognito_user_uuid,
      users.handle,
      users.display_name,
      users.bio,
      (
       SELECT 
        count(true) 
       FROM public.activities
       WHERE
        activities.user_uuid = users.uuid
       ) as cruds_count
  ) object_row) as profile,
```
3. `backend-flask/db/sql/users/update.sql`
```SQL
UPDATE public.users 
SET 
  bio = %(bio)s,
  display_name= %(display_name)s
WHERE 
  users.cognito_user_id = %(cognito_user_id)s
RETURNING handle;
```

- To programmatically see that the SQL codes are working as preferred, we make some changes to the `/backend-flask/lib/postgresdb.py` file.
	- we do this by adding `verbose=True` to some functions in the code.
```python
from psycopg_pool import ConnectionPool
import os
import re
import sys
from flask import current_app as app

class Db:
  def __init__(self):
    self.init_pool()

  def template(self,*args):
    pathing = list((app.root_path,'db','sql',) + args)
    pathing[-1] = pathing[-1] + ".sql"

    template_path = os.path.join(*pathing)

    green = '\033[92m'
    no_color = '\033[0m'
    print("\n")
    print(f'{green} Load SQL Template: {template_path} {no_color}')

    with open(template_path, 'r') as f:
      template_content = f.read()
    return template_content

  def init_pool(self):
    connection_url = os.getenv("CONNECTION_URL")
    self.pool = ConnectionPool(connection_url)
  # we want to commit data such as an insert
  # be sure to check for RETURNING in all uppercases
  def print_params(self,params):
    blue = '\033[94m'
    no_color = '\033[0m'
    print(f'{blue} SQL Params:{no_color}')
    for key, value in params.items():
      print(key, ":", value)

  def print_sql(self,title,sql,params={}):
    cyan = '\033[96m'
    no_color = '\033[0m'
    print(f'{cyan} SQL STATEMENT-[{title}]------{no_color}')
    print(sql,params)
  def query_commit(self,sql,params={},verbose=True):
    if verbose:
      self.print_sql('commit with returning',sql,params)

    pattern = r"\bRETURNING\b"
    is_returning_id = re.search(pattern, sql)

    try:
      with self.pool.connection() as conn:
        cur =  conn.cursor()
        cur.execute(sql,params)
        if is_returning_id:
          returning_id = cur.fetchone()[0]
        conn.commit() 
        if is_returning_id:
          return returning_id
    except Exception as err:
      self.print_sql_err(err)
  # when we want to return a json object
  def query_array_json(self,sql,params={},verbose=True):
    if verbose:
      self.print_sql('array',sql,params)

    wrapped_sql = self.query_wrap_array(sql)
    with self.pool.connection() as conn:
      with conn.cursor() as cur:
        cur.execute(wrapped_sql,params)
        json = cur.fetchone()
        return json[0]
  # When we want to return an array of json objects
  def query_object_json(self,sql,params={},verbose=True):
    if verbose:
      self.print_sql('json',sql,params)
      self.print_params(params)

    wrapped_sql = self.query_wrap_object(sql)

    with self.pool.connection() as conn:
      with conn.cursor() as cur:
        cur.execute(wrapped_sql,params)
        json = cur.fetchone()
        if json == None:
          return "{}"
        else:
          return json[0]
  def query_value(self,sql,params={},verbose=True):
    if verbose:
      self.print_sql('value',sql,params)

    with self.pool.connection() as conn:
      with conn.cursor() as cur:
        cur.execute(sql,params)
        json = cur.fetchone()
        return json[0]
  def query_wrap_object(self,template):
    sql = f"""
    (SELECT COALESCE(row_to_json(object_row),'{{}}'::json) FROM (
    {template}
    ) object_row);
    """
    return sql
  def query_wrap_array(self,template):
    sql = f"""
    (SELECT COALESCE(array_to_json(array_agg(row_to_json(array_row))),'[]'::json) FROM (
    {template}
    ) array_row);
    """
    return sql
  def print_sql_err(self,err):
    # get details about the exception
    err_type, err_obj, traceback = sys.exc_info()

    # get the line number when exception occured
    line_num = traceback.tb_lineno

    # print the connect() error
    print ("\npsycopg ERROR:", err, "on line number:", line_num)
    print ("psycopg traceback:", traceback, "-- type:", err_type)

    # print the pgcode and pgerror exceptions
    print ("pgerror:", err.pgerror)
    print ("pgcode:", err.pgcode, "\n")

db = Db()
```

- Create a new service to cater for the profile updates via the backend.
1. `backend-flask/services/update_profile.py`
```python
from lib.postgresdb import db

class UpdateProfile:
  def run(cognito_user_id,bio,display_name):
    model = {
      'errors': None,
      'data': None
    }

    if display_name == None or len(display_name) < 1:
      model['errors'] = ['display_name_blank']

    if model['errors']:
      model['data'] = {
        'bio': bio,
        'display_name': display_name
      }
    else:
      handle = UpdateProfile.update_profile(bio,display_name,cognito_user_id)
      data = UpdateProfile.query_users_short(handle)
      model['data'] = data
    return model

  def update_profile(bio,display_name,cognito_user_id):
    if bio == None:    
      bio = ''

    sql = db.template('users','update')
    handle = db.query_commit(sql,{
      'cognito_user_id': cognito_user_id,
      'bio': bio,
      'display_name': display_name
    })
  def query_users_short(handle):
    sql = db.template('users','short')
    data = db.query_object_json(sql,{
      'handle': handle
    })
    return data
```

- Modify the `/backend-flask/app.py` code to contain the following to handle the profile updates.
	- import the profile update and route the profile updates.
```python
from services.update_profile import *

@app.route("/api/profile/update", methods=['POST','OPTIONS'])
@cross_origin()
def data_update_profile():
  bio          = request.json.get('bio',None)
  display_name = request.json.get('display_name',None)
  access_token = extract_access_token(request.headers)
  try:
    claims = cognito_jwt_token.verify(access_token)
    cognito_user_id = claims['sub']
    model = UpdateProfile.run(
      cognito_user_id=cognito_user_id,
      bio=bio,
      display_name=display_name
    )
    if model['errors'] is not None:
      return model['errors'], 422
    else:
      return model['data'], 200
  except TokenVerifyError as e:
    # unauthenicatied request
    app.logger.debug(e)
    return {}, 401


if __name__ == "__main__":
  app.run(debug=True)
```

- Catering for a little bit more of code to be added to these files in the frontend
1. `frontend-react-js/src/components/ProfileHeading.css`
```CSS
.profile_heading .bio {
  padding: 16px;
  color: rgba(255,255,255,0.7);
}
```
2. `frontend-react-js/src/components/ProfileHeading.js
	- the focus is on the profile.bio div.
```javascript
      <EditProfileButton setPopped={props.setPopped} />
    </div>
    <div class="bio">{props.profile.bio}</div>
```
3. `frontend-react-js/src/components/ReplyForm.css`
	- this will be the only one for now.
```CSS
form.replies_form {
  padding: 16px;
  display: flex;
  flex-direction: column;
}
```

- At this point, take a break and check if the code is running the way it supposed to run.
	- run the `/bin/postgresdb/migrate` script, with a param `add_bio-column`.
	- check whether the generated file in the `/backend-flask/db/migration` directory has propagated, with the param as part of its name.
	- set up the Postgres database, run the `/bin/postgresdb/setup` command.
	- run the `/bin/postgresdb/migrate` script
	- then roll back using the `/bin/postgresdb/rollback` script.


### Implementing Client-Side S3 Bucket Uploads
- In the `/frontend-react-js` directory, install the `@aws-sdk/client-s3` to enable the propagation of an S3 bucket for client-side uploads. Meaning, this will give the user power to upload contents into the S3 bucket assigned for that purpose.
- For this, a presigned URL has be generated to be used by the client. This will be used to request data from the application's endpoints.
	- A presigned URL is a URL that has been signed by an AWS account holder. This allows the account holder to grant temporary access to an S3 object to someone who does not have AWS credentials.
- In this case, use an API Gateway and a Lambda function to make this happen.

#### LAMBDA FUNCTION
1. Select the HTTP API as the API to be used in the API Gateway. This is because it can hold JWT authorization tokens that will be used to authorize the client.
2. Make a new Lambda function, name = `CruddurAvatarUpload`, select runtime to be `Ruby` and the default role to be `create a new role with basic Lambda permissions`.
	1. Write the code for the function. In the `/aws/json/lambda/cruddur-upload-avatars/function.rb`, a Ruby file that contains Ruby code that serves as the Lambda code.
	2. In the same directory, `/cruddur-upload-avatars`, generate the libraries to be used by running `bundle init`. In the Gemfile generated, add these line `gem "aws-sdk-s3"`, `gem "ox"`, `gem "jwt"` and run the `bundle install` command. 
		1. The `ox` gem is and XML parser library. An XML parser is a software program that reads an XML document and creates a data structure that represents the document's content and structure. Use do to read the XML generated by the function call to the API.
	3. In the lambda,make sure the function name stays as `function.rb`. Check the Runtime Settings on the Code page and make sure the handler function name is set to `function.handler`.
3. Test out the Lambda by running the command `bundle exec ruby function.rb`. This generates the presigned URL that is used to authorize the client to do client-side S3 uploads. The generated presigned URL will be used in later code to ascertain the path the code should use in authenticating the S3 client upload request.	
```ruby
require 'aws-sdk-s3'
require 'json'
require 'jwt'

def handler(event:, context:)
  puts event
  # return cors headers for preflight check
  if event['routeKey'] == "OPTIONS /{proxy+}"
    puts({step: 'preflight', message: 'preflight CORS check'}.to_json)
    { 
      headers: {
        "Access-Control-Allow-Headers": "*, Authorization",
        "Access-Control-Allow-Origin": "my-very-own-gitpod-http-address",
        "Access-Control-Allow-Methods": "OPTIONS,GET,POST"
      },
      statusCode: 200
    }
  else
    token = event['headers']['authorization'].split(' ')[1]
    puts({step: 'presignedurl', access_token: token}.to_json)

    body_hash = JSON.parse(event["body"])
    extension = body_hash["extension"]

    decoded_token = JWT.decode token, nil, false
    cognito_user_uuid = decoded_token[0]['sub']

    s3 = Aws::S3::Resource.new
    bucket_name = ENV["UPLOADS_BUCKET_NAME"]
    object_key = "#{cognito_user_uuid}.#{extension}"

    puts({object_key: object_key}.to_json)

    obj = s3.bucket(bucket_name).object(object_key)
    url = obj.presigned_url(:put, expires_in: 60 * 5)
    url # this is the data that will be returned
    body = {url: url}.to_json
    { 
      headers: {
        "Access-Control-Allow-Headers": "*, Authorization",
        "Access-Control-Allow-Origin": "my-very-own-gitpod-http-address",
        "Access-Control-Allow-Methods": "OPTIONS,GET,POST"
      },
      statusCode: 200, 
      body: body 
    }
  end # if 
end # def handler
```
4. As an aside, install the ThunderClient API extension in the gitpod VSCode environment and use that to test the API connection. 
	1. Add a sample image to the `/cruddur-uploads-avatar` file and in the ThunderClient app, go to Body, then Binary and then Upload File.
	2. Choose the sample image, copy the presigned URL into the search box, select a PUT request and activate the function. This should put data in the S3 Uploads bucket ie. `taskmaster-cruddur-uploaded-avatars` bucket, as a file with name `mock.jpg`.
5. Set some permissions on the `CruddurAvatarUpload` Lambda function.
	1. Go to the Lambda console > Configurations > Permissions and click on the Execution Role. This takes you to the IAM Roles and Policies page.
	2. In the IAM Roles and Policies page, attach an inline Policy to the current execution role.
	3. The policy should be a `PutObject` in an S3 bucket; Resources should be the Uploads Bucket name, ie `taskmatser-cruddur-upload-avatars` and specify that ANY resource is subjected to the policy by using `*`.
	4. Apply these conditions, name it `PresignedAvatarURLBucketPolicy`. Copy over this code to keep in the workspace environment and place in this path, `/aws/policies/s3-upload-avatar-presigned-url-policy.json`.
```json
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Sid": "VisualEditor0",
          "Effect": "Allow",
          "Action": "s3:PutObject",
          "Resource": "arn:aws:s3:::taskmaster-cruddur-uploaded-avatars/*"
      }
  ]
}
```
6. Set an environment variable in the `CruddurAvatarUpload` Lambda function.
	1. go to Lambda function > Environment Variables, and set `UPLOADS_BUCKET_NAME` as the key and `taskmaster-cruddur-uploaded-avatars` as the value.

The Lambda has to be authenticated by a JWT authorization function before it is ready to be linked with the API Gateway.
1. create a `/lambda/lambda-authorizer` directory to house the code that will be used to verify the JWT token.
2. install the `aws-jwt-verify` library using `npm install aws-jwt-verify --save` command.
3. in same directory, create an `./index.js` file. This will contain code to verify JWTs.
4. download everything inside the `/lambda-authorizer` directory , node_modules inclusive to a desktop and zip it up.
5. go to AWS Lambda and create a new function called `CruddurApiGatewayLambdaAuthorizer`, runtime should be NodeJS18. Wait for function to become available and upload the zipped `lambda-authorizer.zip` code into the function.
6. Add the `USER_POOL_ID` and `CLIENT_ID` environment variables to the lambda. These are the Cognito User Pool ID and the Cognito Client ID respectively.
```javascript
"use strict";
const { CognitoJwtVerifier } = require("aws-jwt-verify");
//const { assertStringEquals } = require("aws-jwt-verify/assert");

const jwtVerifier = CognitoJwtVerifier.create({
  userPoolId: process.env.USER_POOL_ID,
  tokenUse: "access",
  clientId: process.env.CLIENT_ID//,
  //customJwtCheck: ({ payload }) => {
  //  assertStringEquals("e-mail", payload["email"], process.env.USER_EMAIL);
  //},
});

exports.handler = async (event) => {
  console.log("request:", JSON.stringify(event, undefined, 2));

  const token = JSON.stringify(event.headers["authorization"]).split(" ")[1].replace(/['"]+/g, '');
  try {
    const payload = await jwtVerifier.verify(token);
    console.log("Access allowed. JWT payload:", payload);
  } catch (err) {
    console.error("Access forbidden:", err);
    return {
      isAuthorized: false,
    };
  }
  return {
    isAuthorized: true,
  };
};
```

##### Do These After Configuring the API Gateway and Making Changes to the Frontend Profile Code.
7. Using Lambda Layers to Verify JWT tokens. This is done so we can extract a vital element, the Cognito user ID, from the request that is been sent. This ID will then be used as the name for the image that will be uploaded to the client-side bucket. So essentially, when the user issues a change of the images in the application, the user ID is taken from the authorization token and used as the name for the new image the user wants.
8. Create a `/bin/lambda-layers` directory with the filename `./ruby-jwt`. In this file is a script to install the JWT library and zip it to be deployed unto AWS Lambda.
	1. add commands to install the jwt library and zip the it into a directory with a name of choice.
	2. add the AWS CLI command to publish layers to AWS Lambda. This code takes up the zipped file and publishes it. Name the file `jwt`.
```bash
#! /usr/bin/bash

gem i jwt -Ni /tmp/lambda-layers/ruby-jwt/ruby/gems/2.7.0
cd /tmp/lambda-layers/ruby-jwt

zip -r lambda-layers . -x ".*" -x "*/.*"
zipinfo -t lambda-layers

aws lambda publish-layer-version \
  --layer-name jwt \
  --description "Lambda Layer for JWT" \
  --license-info "MIT" \
  --zip-file fileb://lambda-layers.zip \
  --compatible-runtimes ruby2.7
```
9. In the AWS Lambda console for the `CruddurAvatarUpload` function, go to Code > Layers and Add a Layer. 
	1. choose to use custom layers, select the `jwt` layer published as a lambda-layer and select a version, 1 is appropriate.
	2. deploy the Lambda.
10. Go to the application > Profile and click on Edit Profile. Select the file to upload. 
	1. Go to the Cloudwatch logs of the `CruddurAvatarUpload` lambda function and check to see if there have been any errors, and if the jwt has been passed successfully.
	2. if you inspect the browser and in the `key_upload` POST section, It should have returned an response that is the presigned URL.

#### SETTING UP API GATEWAY + FIX CORS
Together with AWS Lambda, API Gateway forms the app-facing part of the AWS serverless infrastructure. For an app to call publicly available AWS services, you can use Lambda to interact with required services and expose Lambda functions through API methods in API Gateway.
1. Go to API Gateway and create an API. Select the HTTP API for use for the client-side API Gateway, this is chosen because we are using JWT to authorize the client requests and HTTP APIs support this.
2. Set the integrations to be Lambda, select the appropriate region and select the `CruddurAvatarUpload` lambda function to use. Name it `api.thetaskmasterernest.cyou`.
	1. In the Configure Routes section, use a `POST` method. Set the Resource Path to `/avatars/key_upload` and its integration target should be `CruddurAvatarUpload` lambda function.
	2. In the Define stages, use  `$default` as the stage name
	3. review and create the gateway.
	4. Go to Develop > Authorization and click on Use Lambda Authorization. Set the name to be `CruddurJWTAuthorizer`; select the appropriate region; set the function to be the `CruddurApiGatewayLambdaAuthorizer` function; set response mode to Simple; turn off Authorizer caching; keep permissions and create the Authorization.
	5. Go to Routes, click on the POST route and select `Create and attach an authorizer`; select the `CruddurJWTAuthorizer` as the authorizer and attach it.
	6. Go to Deploy > Stages and copy the invoke URL, this will be the gateway URL to pass to the ProfileForm.
	7. Configure another route, a proxy route, resource path should be `/{proxy+}` and the method on it should be `OPTIONS`. This can be done on the same Route as the `/avatars/key_upload` route.
		1. in Routes, there is a Create button besides the heading (`Routes for api.<your-configured-host-address>`), click on it.
		2. It will go to a page where you are asked to create a route, select the OPTIONS method, do not specify any route and it will default to the `$default` route that we have opted for.
3.  At this point, make changes in the `CruddurAvatarUpload` , `function.rb` lambda code to include headers in the body of the lambda. This will mitigate the CORS issue for the function.
	1. the headers, especially the origin header must match the current gitpod.io frontend URL since we are working in development now. it will be changed accordingly in production.
```
{ 
	headers: {
		"Access-Control-Allow-Headers": "*, Authorization",
		"Access-Control-Allow-Origin": "https://3000-omenking-awsbootcampcru-2n1d6e0bd1f.ws-us94.gitpod.io",
		"Access-Control-Allow-Methods": "OPTIONS,GET,POST"
	},
	statusCode: 200
}
```

4. To further mitigate CORS, set up a CORS policy for the S3 Uploads Bucket. You can make sure to block or not to block the public access to the bucket, it works fine either way apparently.
	1. the code is in the workspace in `/aws/s3/uploads-bucket-cors.json`.
	3. go to the Cross Origin Resource Sharing section of the Uploads bucket and add the policy from the `uploads-bucket-cors.json`.
```json
[
  {
      "AllowedHeaders": [
          "*"
      ],
      "AllowedMethods": [
          "PUT"
      ],
      "AllowedOrigins": [
          "https://*.gitpod.io"
      ],
      "ExposeHeaders": [
          "x-amz-server-side-encryption",
          "x-amz-request-id",
          "x-amz-id-2"
      ],
      "MaxAgeSeconds": 3000
  }
]
```


#### MODIFYING FRONTEND FOR CLIENT-SIDE S3 UPLOADS
1. First we do some cleanup on previous code in the `./ProfileHeading.js` file. 
	1. Change the divs that have "class" only to "className".
	2. remove the line of code `console.log('UseEffects'.props)` under the `React.UseEffects` code block.
2. Cleanup in the the `./lib/CheckAuth.js` code.
	1. remove the lines of code to that console.log the `cognito_user` and `cognito_user_session`.
3. Cleanup in the `./ProfileForm.js` code
	1. under the  `function ProfileForm(props)` code, change the code to match this; `const [bio, setBio] = React.useState('');` and `const [displayName, setDisplayName] = React.useState('');`.
4. Add the following to the `.env` file generated and to the the `.erb` files to generate them; the frontend gitpod HTTP address and the API Gateway address.
	1. this is for the `/bin/erb/frontend-react-js.env.erb`.
```ruby
REACT_APP_FRONTEND_URL=https://3000-<%= ENV['GITPOD_WORKSPACE_ID'] %>.<%= ENV['GITPOD_WORKSPACE_CLUSTER_HOST'] %>
REACT_APP_API_GATEWAY_ENDPOINT_URL=my-api-gateway-url
```
5. Create a new component to take care of updating the avatars on the profile, in the `../src/components/ProfileAvatar.js` code.
```javascript
import './ProfileAvatar.css';

export default function ProfileAvatar(props) {
  const backgroundImage = `url("https://assets.cruddur.com/avatars/${props.id}.jpg")`;
  const styles = {
    backgroundImage: backgroundImage,
    backgroundSize: 'cover',
    backgroundPosition: 'center',
  };

  return (
    <div 
      className="profile-avatar"
      style={styles}
    ></div>
  );
}
```
6. Add the associated `../src/components/ProfileAvatar.css` code for styling.
7. Import the ProfileAvatar code into the `./ProfileHeading.js` code.
```javascript
import './ProfileHeading.css';
import EditProfileButton from '../components/EditProfileButton';

import ProfileAvatar from 'components/ProfileAvatar'

export default function ProfileHeading(props) {
  const backgroundImage = 'url("https://assets.cruddur.com/banners/banner.jpg")';
  const styles = {
    backgroundImage: backgroundImage,
    backgroundSize: 'cover',
    backgroundPosition: 'center',
  };
  return (
  <div className='activity_feed_heading profile_heading'>
    <div className='title'>{props.profile.display_name}</div>
    <div className="cruds_count">{props.profile.cruds_count} Cruds</div>
    <div className="banner" style={styles} >
      <ProfileAvatar id={props.profile.cognito_user_uuid} />
    </div>
    <div className="info">
      <div className='id'>
        <div className="display_name">{props.profile.display_name}</div>
        <div className="handle">@{props.profile.handle}</div>
      </div>
      <EditProfileButton setPopped={props.setPopped} />
    </div>
    <div className="bio">{props.profile.bio}</div>

  </div>
  );
}
```
8. Import the ProfileAvatar code into the `./ProfileInfo.js` code.
```javascript
import ProfileAvatar from 'components/ProfileAvatar'

<div className="profile-info" onClick={click_pop}>
	//change from this
	<div className="profile-avatar"></div>
	//to this
	<ProfileAvatar id={props.user.cognito_user_uuid} />
	<div className="profile-desc">
		<div className="profile-display-name">{props.user.display_name || "My Name" }</div>
		<div className="profile-username">@{props.user.handle || "handle"}</div>
```
9. Make a change in the `./ProfileHeading.css` code to match the className returned by the ProfileAvatar code.
```css
//chcange from this
.profile_heading .avatar {
//to this
.profile_heading .profile-avatar {
  position: absolute;
  bottom:-74px;
  left: 16px;
```
10. Add code in the `./lib/CheckAuth` code to set the user's cognito user id to UID gotten from the decoded token from the JWT authorization token that authorizes a user a to do client-side uploads.
```javascript
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
    setUser({
      cognito_user_uuid: cognito_user.attributes.sub,
      display_name: cognito_user.attributes.name,
      handle: cognito_user.attributes.preferred_username
    })
    return Auth.currentSession()
  }).then((cognito_user_session) => {
      localStorage.setItem("access_token", cognito_user_session.accessToken.jwtToken)
  })
  .catch((err) => console.log(err));
};
```


#### MODIFYING THE BACKEND CODE
1. Add a line of code to perform migrations to the PostgreSQL database when setting it up
```bash
source "$DB_PATH/seed"
python "$DB_PATH/update_cognito_user_ids"
python "$DB_PATH/migrate"
```
2. Add code in the `/backend-flask/db/sql/users/show.sql` to include the cognito user id.
```sql
(SELECT COALESCE(row_to_json(object_row),'{}'::json) FROM (
    SELECT
      users.uuid,
      users.cognito_user_id as cognito_user_uuid,
      users.handle,
      users.display_name,
      users.bio,
```
