# Week 12 — Modern APIs

## This is a direct continuation from the previous week. Everything ties in with each other.

### 8. Sync tool for Static Website Hosting
- This script is used to cleanup the `frontend-react-js` code, build it, and push it to be served statically on the web in an S3 bucket.
	- check Andrew's code commit for Week-X for the commit title: `setup static building for your application`.
	- run the `/bin/frontend/static-build` script.
- Zip up the contents of the `/frontend-react-js/build` dir, after an optional build, using the command `zip -r build.zip build` and download the zipped code over to the desktop.
	- delete the code from the Gitpod environment, so as not to commit it to GitHub.
- Copy over the contents of the zipped folder to the S3 RootBucket (`thetaskmasterernest.cyou`). Upload the contents after copying and set the bucket permissions to be `very` publicly accessible.
	- Make sure to enable permissions for the bucket to host static websites.
	- After all these, go to the `thetaskmasterernest.cyou` link in browser to check if site is hosted.
Andrew Brown has a library for syncing stuff with S3 buckets called `aws-s3-website-sync`. (Available for public consumption at `teacherseat/aws-s3-website-sync`).
- Make a script in `/bin/frontend` called `sync`.
	- in this code, on the line that has the `silent` attribute, you can set it to either and empty (`""`) string to print all things that the code works with to change in the code to be synced.
- Make a `sync.env.erb` file in the `/erb` directory, with the following:
```yaml
SYNC_S3_BUCKET=
SYNC_CLOUDFRONT_DISTRIBUTION_ID=
SYNC_BUILD_DIR=<%= ENV['THEIA_WORKSPACE_ROOT'] %>/frontend-react-js/build
SYNC_OUTPUT_CHANGESET_PATH=<%=  ENV['THEIA_WORKSPACE_ROOT'] %>/tmp/changeset.json
SYNC_AUTO_APPROVE=false
```
- To generate out the `sync.env` file that will be used, put this code under the `/bin/frontend/generate-env` file:
```bash
#!/usr/bin/env ruby

require 'erb'

template = File.read 'erb/frontend-react-js.env.erb'
content = ERB.new(template).result(binding)
filename = "frontend-react-js.env"
File.write(filename, content)

template = File.read 'erb/sync.env.erb'
content = ERB.new(template).result(binding)
filename = "sync.env"
File.write(filename, content)
```
- Make a `/tmp` directory with a `.keep` file and to make sure that this is kept even after out `.gitignore` has it, we user the command `git add -f /tmp/.keep`.
- Update the script `/bin/frontend/generate-env` to process the `sync.env.erb` file.
- In order for the tool to work, install the `dotenv` package with `gem install dotenv` command  (add this to the `cloudfomation` task in the `.gitpod.yml` file).
- Before you run the sync tool, you mus build the site statically using the `/bin/frontend/static-build` script, then sync with `/bin/frontend/sync` , wait for the CloudFront cache to be invalidated so it can serve the new files.
There is a whole section on trying to prepare a GitHub Actions pipeline that, when activated will cause the backend to the built and deployed and the frontend to be synced. It was abandoned but served as a Homework Challenge.

### 9. Connecting RDS database and Post Confirmation
- In this section, test the connection with the production database via the local development environment. The following have to be done to ensure there is a connection with the production database:
	- Go to the RDS instance's security group for the database `cruddur-instance` and edit the inbound rules to have the following initial values; name=`GITPOD`, IP-Address=`your own ip`, the connection=`PostgreSQL` (this will pre-populate the port value).
	- On the local/development environment, set the `RDS_CONNECTION_URL` to the values used for the `cruddur-instance` database. Get these from the Parameter Store for the instance, if you can. So you run `export RDS_CONNECTION_URL="<value>"` and `gp env RDS_CONNECTION_URL="<value>"`.
	- Get the `security group rule id` of the inbound rule called `GITPOD` in the RDS instance. Set this value to override the `RDS_GITPOD_SG_RULE_ID` in the local Gitpod environment. ie `export RDS_GITPOD_SG_RULE_ID="<value>"` and `gp env RDS_GITPOD_SG_RULE_ID="<value>"`.
	- Get the `security group ID` of the RDS instance itself (`CrudDbRDS`) and also set that as the `RDS_SG_ID` in the local Gitpod environment.
	- Get the `GITPOD_IP` from the local Gitpod environment, export it again to make sure the new value is present. `export GITPOD_IP=$(curl ifconfig.me)`.
	- Now run the `./bin/rds/update-sg-rule` script to connect to the RDS production database and to update its connection details too.
	- You can choose to connect to this database by running the `./bin/postgresdb/connect prod` command.
- We can now set up the RDS `cruddur-instance` database by running the the command `./bin/postgresdb/setup` to populate it with our schema and data, and also conduct migrations to it. `./bin/postgresdb/schema-load prod`, `./bin/postgresdb/seed prod`  `CONNECTION_URL=$RDS_CONNECTION_URL ./bin/postgresdb/migrate` should take care of setting up the database.
	- Check the tables in the RDS PostgreSQL database to verify the existence of the migrated columns. `\d users; or \d activities;`.
- Here, clear all existing users from the Cognito user pool, as they are already registered to work with our other databases, they will not work with the new database.
- Add `CustomErrorResponses` to the `cloudformation/frontend` template. (already added).
- Visit the Lambda `cognito-post-confirmation` and change the `CONNECTION_URL` env-var to match the new RDS connection URL. In the same Lambda, there are a few configurations to make to make sure data is routed to this Lambda.
	- Go to Configuration > VPC and Edit the VPC
	- Set the VPC to use the new `CrudNetVPC` and add only the PublicSubnets.
	- >> Take a detour to the EC2 service to create a new Security Group for the Lambda.
		- name the new security group, `CognitoLambdaSG`, add a description
		- add NO inbound/outbound rules.
		- Go to the RDS instance's security group (`RDSdbSSG`) and add a inbound rule.
		- The new inbound rule should be of type `PostgreSQL`, set the source to be `CognitoLambdaSG` and the name should be `COGNITO-POST-CONFAM`.
	- <<< Out of detour. In the Security Groups tab, add the newly created `CognitoLambdaSG` and update the Lambda.
	- Wait until the Lambda has been fully validated and deployed.
- A user can now enter and Crud.

### 10. Managing CORS
- Set the environment variables in the `/cloudformation/service /template.yaml & /config.toml`. Specify the frontend and backend URLs and dd the `https` protocol in front of them.

### 11. Adding Auth, Error-Handling, Fetching Requests Refactoring Routes & Fixing Rollbar
- A lot of the code has to me modified in order to get the application working. It's too much to actually list one after the other, so I will just list all the modifications that have been made.
	- this section lists all modifications to the backend service.
	- `/backend-flask/services/create_activity.py`
	- `/services/create_message.py`
	- `/db/sql/activities/create.sql`
	- `app.py`
	- `/lib/cognito_jwt_token.py`
	- `/lib/rollbar.py`
	- `/lib/xray.py`
	- `/lib/cors.py`
	- `/lib/honeycomb.py`
	- `/lib/cloudwatch.py`
	- new dir `/backend-flask/routes/`
	- `/lib/helpers.py`
	- `/routes/activities.py`
	- `/routes/users.py`
	- `/routes/general.py`
	- `/services/create_reply.py`
	- `/db/sql/activities/reply.sql`
	- `/db/sql/activities/object.sql`
	- `/db/sql/activities/home.sql`
	- `/db/sql/activities/show.sql`
	- `/db/sql/users/show.sql`
	- `/db/schema.sql`
	- `/services/show_activity.py`
	- `/db/seed.sql`
	- `/lib/dynamodb.py`

	- this section lists all modifications to the frontend service
	- `/frontend-react-js/src/components/ReplyForm.js`
	- `/pages/NotificationsFeedPage.js`
	- `/components/ActivityForm.js`
	- `/components/ActivityItem.js`  & `/components/ActivityItem.css`
	- `/components/ActivityActionReply.js`
	- `/components/ActivityItem.js` & `/components/ActivityItem.css` (fix: `activity_main`)
	- `/components/ActivityFeed.js` & `/components/ActivityFeed.css`
	- `/components/FormErrors.js` & `/components/FormErrors.css`
	- `/pages/SignUpPage.js` & `/pages/SignUpPage.css`
	- `/pages/SignInPage.js` & `/pages/SignInPage.css`
	- `/src/lib/Requests.js`
	- `/components/MessageForm.js`
	- `/components/ProfileForm.js`
	- `/pages/UserFeedPage.js`
	- `/pages/HomeFeedPage.js`
	- `/pages/MessageGroupPage.js`
	- `/pages/MessageGroupNewPage.js`
	- `/pages/MessageGroupsPage.js`
	- `/components/ActivityContent.js` & `/components/ActivityContent.css`
	-  `/components/ActivityActionShare.js`
	-  `/components/ActivityActionRepost.js`
	-  `/components/ActivityActionLike.js`
	- `/pages/ActivityShowPage.js` &  `/pages/ActivityShowPage.css`
	-  `/components/Replies.js` &  `/components/Replies.css`
	- `App.js`
	- `/lib/DateTimeFormat.js`
	- `/components/MessageItem.js`  & `/components/MessageItem.css`
	-  `/components/MessageGroupItem.js`
	- `/components/ProfileHeading.css`
	- `/components/ActivityShowItem.js`

	- these are modifications to the scripts
	- `/bin/postgresdb/migrate` (fix: ` if last_successful_run < file_time:`)
	- `/bin/postgresdb/seed`
	- `/bin/dynamodb.seed`

### 12. Setting Up A Machine User
- The purpose of a machine-user is to have an entity that will make requests to AWS services. We give it an IAM role to take care of regulating the actions of DynamoDB in this application.
- Create a new template at `/aws/cloudformation/machine-user`. Add a `template.yaml` and `config.toml` file.
- Create a script to provision it to AWS CloudFormation with the `/bin/cloudformation/machineuser-provision`.
- Create the changeset in CloudFormation and make sure the user has been provisioned.
- Click into the `machine-user` created and to go "Security Credentials" and opt to create security credentials for it.
	- Select CLI as the place to be using the keys; set a description and retrieve the access keys.
- Once the Access Keys have been generated,  go to the Parameter Store and change out the `/backend-flask/AWS_SECRET_ACCESS_KEY` for the newly generated ones.
- DynamoDB that has been provisioned already has the permissions it needs to function in production.

### 13. Rollbar Fixes
-  Much of the rollbar fixes have been presented in the code beforehand.
- In the `/erb/backend-flask.env.erb` file, add a new env-var `FLASK_ENV=development`  and regenerate the files using the `/bin/backend/generate-env` in order to have it in the working local environment.
- I did not get the chance to add this but the following should also be added to the `/erb/backend-flask.env.erb file`, that is `DDB_MESSAGE_TABLE=cruddur-messages`.
- Make some changes in the `/cloudformation/service/template.yaml` file as this in the parameters
```yaml
EnvFlaskEnv:
	Type: String
	Default: "production"
```
- In the same file, add this under the TaskDefinition:
```yaml
Environment:
	- Name: FLASK_ENV
    Value: !Ref EnvFlaskEnv
```
- Push this as to create a changeset and execute the changeset.
- All these will cause Rollbar to be useful in development and production.

For the later parts when working with Week-X, I would recommend working with this guide
1. make all code changes
2. change and rework templates and add all neccessary code changes.
3. create all CloudFormation changesets
4. clear out Cognito database to prepare for new users.
5. push and sync all code.
6. start a new environment so all the configs are installed as they should
7. start a local environment to test the code, database and all
8. clear out Cognito again
9. start another environment, build and sync the frontend code.
10. test the code in production.
