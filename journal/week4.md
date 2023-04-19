# Week 4 — Postgres and RDS
Here is a prerequisite on Amazon RDS:
-  Amazon RDS is a managed service that makes it easy to set up, operate, and scale a relational database in the cloud.
-  It supports six popular database engines: Amazon Aurora, PostgreSQL, MySQL, MariaDB, Oracle Database, and Microsoft SQL Server.
-   With Amazon RDS, you don't have to worry about managing the underlying infrastructure, backups, patches, or software updates. These tasks are all handled by AWS, so you can focus on your application.
-   Amazon RDS provides features like automatic backups, automated software patching, and multi-AZ deployments for high availability.
-   You can scale your database resources up or down with just a few clicks, without any downtime. You can also use features like read replicas to scale out read-heavy workloads.
-   Amazon RDS integrates with other AWS services like Amazon CloudWatch for monitoring, AWS Identity and Access Management (IAM) for access control, and Amazon VPC for network isolation.
-   Amazon RDS also supports features like encryption at rest, encryption in transit, and database auditing to help you meet compliance requirements.
-   You can launch an Amazon RDS instance from the AWS Management Console, the AWS CLI, or using an API call. There are various instance types to choose from, depending on your workload requirements and budget.


## What a Relational Database is:
- A Relational Database Management System (RDBMS) is a software system that allows for the creation, management, and manipulation of relational databases.
- A relational database is a type of database that stores data in tables with rows and columns, where each row represents a record and each column represents a field of that record.
- The RDBMS provides an interface for users to interact with the database, allowing them to perform tasks such as querying, updating, inserting, and deleting data.
- It also provides a set of rules to ensure the consistency and integrity of the data, such as enforcing unique values and constraints, and allowing for the creation of relationships between tables.
- Examples of RDBMS include Oracle, MySQL, Microsoft SQL Server, and PostgreSQL.

## Eyes on PostgresQL
- PostgreSQL is a powerful open-source relational database management system with many advanced features that make it an attractive option for developers and enterprises alike. Here are some of the essential features of PostgreSQL:
	1.  ACID Compliance: PostgreSQL is fully ACID-compliant, which ensures that database transactions are reliable, consistent, and durable.
    
	2.  Data Types: PostgreSQL offers a wide variety of data types, including built-in support for arrays, JSON, and XML.
    
	3.  Concurrency: PostgreSQL uses a multi-version concurrency control (MVCC) system, which allows multiple transactions to access the same data simultaneously without blocking each other.
    
	4.  Extensibility: PostgreSQL is highly extensible, and developers can easily write custom functions, data types, and operators in various programming languages.
    
	5.  Indexing: PostgreSQL provides a variety of indexing options, including B-tree, hash, and GiST (Generalized Search Tree) indexes.
    
	6.  Foreign Data Wrappers: PostgreSQL supports foreign data wrappers (FDWs) that allow users to access data stored in external data sources such as other databases or web services.
    
	7.  Full-Text Search: PostgreSQL provides built-in support for full-text search, which allows users to search for text strings within large bodies of text efficiently.
    
	8.  Replication: PostgreSQL supports various replication solutions, including built-in streaming replication and logical replication using logical decoding.
    
	9.  Security: PostgreSQL offers a robust security model, including SSL support, encrypted password storage, and access control using roles and permissions.
    
	10.  Scalability: PostgreSQL is highly scalable and can handle large amounts of data and high volumes of traffic by utilizing partitioning, sharding, and other techniques.


## Database Schema
- In database management, a schema is a collection of database objects (tables, views, indexes, etc.) associated with a particular database user. Here are some key points to understand:

-   A schema is a way to organize and group database objects together, often based on their purpose or function within the database.
-   Each schema belongs to a specific database user, who has ownership and control over the objects within that schema.
-   A database may have multiple schemas, each with its own set of objects and permissions.

Here are a few examples of how schemas might be used:

-   In a multi-tenant web application, each tenant could have its own schema, containing its own set of tables for storing data.
-   In a large organization, different departments could have their own schemas, containing tables and views relevant to their specific business processes.
-   In a database with many tables, views, and other objects, organizing them into separate schemas can make it easier to manage and maintain the database over time.

Overall, schemas are a powerful way to organize and manage database objects, and can be especially helpful in complex database environments.

## UUIDs in PostgresQL
A primary key is a unique identifier for a specific record in a database table.

UUID stands for Universally Unique Identifier, which is a 128-bit value that is guaranteed to be unique across all space and time. In the context of PostgreSQL, using UUIDs as primary keys for tables provides a number of benefits:

1.  Uniqueness: UUIDs guarantee that no two rows in a table will have the same primary key value, even if the rows are created in different locations or at different times.
    
2.  Performance: UUIDs can be generated client-side, which reduces the load on the database server and can improve performance.
    
3.  Security: Using UUIDs as primary keys can make it harder for attackers to guess the primary key values of other rows in the same table, which can help protect against certain types of attacks.
    
4.  Scalability: UUIDs can be generated across multiple servers without the risk of collisions, making it easier to shard the database and improve scalability.




## Working With RDS (AWS BOOTCAMP)
sidenote: check out devcontainers in VSCode.

- It's better configuring RDS through the CLI. Use that instead of using the Console. It does take some time to spin up though. The code is here:
```Shell
aws rds create-db-instance \
  --db-instance-identifier cruddur-db-instance \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version  14.6 \
  --master-username username \
  --master-user-password password \
  --allocated-storage 20 \
  --availability-zone eu-west-2b \
  --backup-retention-period 0 \
  --port 5432 \
  --no-multi-az \
  --db-name cruddur \
  --storage-type gp3 \
  --publicly-accessible \
  --storage-encrypted \
  --enable-performance-insights \
  --performance-insights-retention-period 7 \
  --no-deletion-protection
```
- check and make any changes; look at the username and password (password should have printable ASCII chars besides @ / "" ''), the availability-zone (be specific as possible eg us-west-2a). make changes as you see fit.
- There are some few things to set, the character-set to use and the timezone for the db (important to set, must be done when in production...leave this out on the first try for now.)
- Look over the console to get some more insights to what make up a good RDS instance deployment.
- Check the storage-type (GP3 can be useful, check if free to use)
- Launch the code in the AWS CLI, on gitpod (wherever).
- Start up the docker-compose ignoring dynamodb but including the postgresdb.
- Stop the RDS database temporarily (up to 7 days and it starts up automatically.)


- Using PostgresQL: Get into the postgres database/docker container with the command:
```Shell
psql -U postgres --host localhost
```
```Text
`psql` is a command-line tool that is used to interact with a PostgreSQL database. It is an interactive terminal-based program that allows users to execute SQL statements and manage their PostgreSQL database.
With `psql`, users can connect to a PostgreSQL server, create or modify database objects, run queries, import and export data, and perform various administrative tasks such as user management, database backup, and restore.
```
- Some useful postgresql commands to use:
```Postgresql
\x on -- expanded display when looking at data
\q -- Quit PSQL
\l -- List all databases
\c database_name -- Connect to a specific database
\dt -- List all tables in the current database
\d table_name -- Describe a specific table
\du -- List all users and their roles
\dn -- List all schemas in the current database
CREATE DATABASE database_name; -- Create a new database
DROP DATABASE database_name; -- Delete a database
CREATE TABLE table_name (column1 datatype1, column2 datatype2, ...); -- Create a new table
DROP TABLE table_name; -- Delete a table
SELECT column1, column2, ... FROM table_name WHERE condition; -- Select data from a table
INSERT INTO table_name (column1, column2, ...) VALUES (value1, value2, ...); -- Insert data into a table
UPDATE table_name SET column1 = value1, column2 = value2, ... WHERE condition; -- Update data in a table
DELETE FROM table_name WHERE condition; -- Delete data from a table
```
- Create a database in the psql client using the `create database cruddur;` command.
```Postgresql
create database cruddur;
```
- Create a schema for this database in the backend-flask directory. create a directory called `db` and create a file called `schema.sql` in the db directory. (essentially `/backend-flask/db/schema.sql`)
- Create a UUID for the database (it is essential to create UUIDs, check out why we have to do this: check up top). Place this command in the `schema.sql` file and initiate the database.
```PostgresQL
	CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

// you can use this next one if you want to create the uuid manually using the psql command line
	CREATE EXTENSION "uuid-ossp";
```
- Exit out of the database / psql, and use this command to import the schema into the database and run it:
```PostgresQL
psql cruddur < backend-flask/db/schema.sql -h localhost -U postgres

// this imports the schema into the cruddur database created using the postgres user created.
```
- A better way of authenticating and connecting to the database with all the essentials is to use a connection URL.
```Shell
postgresql://[user[:password]@][netloc][:port][,...][/dbname][?param1=value1&...] // this is the URL to use

//the actual connection URL to use is in this form
export CONNECTION_URL="postgresql://postgres:password@localhost:5432/cruddur"
//set to gitpod environment
gp env CONNECTION_URL="postgresql://postgres:password@localhost:5432/cruddur"

//create one for the production RDS database as well, grab the password and username and endpoints from RDS to connect to.
export RDS_CONNECTION_URL="postgresql://username:password@cruddur-instance-string/cruddur"

```
- Export that env-var and use it with the `psql` command to connect and authenticate into the Postgresql database:
```Shell
psql $CONNECTION_URL
```
- The next part is to create a `/bin` directory in the `/backend-flask` dir and create the following files in it; `db-create` , `db-drop` and `db-load-schema`.
- preload this files with `#!/usr/bin/bash` (you can get this by typing `whereis bash` on the terminal).
- change permissions for them so that only the user can execute them (chmod 644 <file_name> or chmod u+x <file_name>).
- write a script that drops the database that we put into it.
```Bash
#! /usr/bin/bash
echo "drop db"
#uses the stream editor to remove the dbname (/cruddur) from the connection string as it is being passed
NO_DB_CONNECTION_URL=$(sed 's/\/cruddur//g' <<< "$CONNECTION_URL")
psql $NO_DB_CONNECTION_URL -c "drop database cruddur;"
```
- run the bash script using the command.
```Bash
./bin/db-drop
```
- write a script that creates a database with a name we define for it:
```Bash
#! /usr/bin/bash
echo "create db"

NO_DB_CONNECTION_URL=$(sed 's/\/cruddur//g' <<< "$CONNECTION_URL")
# with our connection url already set into place, we have to remove the name of the database.
# add in the new name by connecting to postgres and creating a database within it.
psql $NO_DB_CONNECTION_URL -c "create database cruddur;"
```
- write a script that loads the schema path into the database:
```Bash
#! /usr/bin/bash
echo "schema-db-load"

# find the absolute path where the schema.sql file is located
schema_path="$(realpath .)/db/schema.sql"
echo "$schema_path"

# connect to database and load the schema path into it
psql $CONNECTION_URL cruddur < $schema_path
```
- try to execute all files in the `/backend-flask` directory only.

- In other news, if we have the RDS up and running (which is our prod environment), to connect to is and load our schema into it, we do:
	- if this bash script is run with "prod" as an argument, it connects to RDS and imports the schema into RDS.
```Bash
#! /usr/bin/bash

#these print out the echo in a different color to make things fancier
CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-schema-load"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

echo "== schema-db-load"
schema_path="$(realpath .)/db/schema.sql"
echo "$schema_path"

if [ "$1" == 'prod']; then
	echo "Running in production mode..."
	URL=$RDS_CONNECTION_URL
else
	URL=$LOCAL_CONNECTION_URL
fi

psql $URL cruddur < $schema_path
```

- In our schema, we would like to create some tables, a user table and an activities table. We make these tables in the public space (Postgresql will automatically do that if we don't specify but specification is good)
	- And we want to add in code to drop tables if already created and create them again; due to the fact that we will be running the Postgres up and down frequently.
	- we put this in the `/db/schema.sql` file
```PostgreSQL
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

DROP TABLE IF EXISTS public.users;

DROP TABLE IF EXISTS public.activities;

CREATE TABLE public.users (
  uuid UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  display_name text,
  handle text,
  cognito_user_id text,
  created_at TIMESTAMP default current_timestamp NOT NULL
);

CREATE TABLE public.activities (
  uuid UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_uuid UUID NOT NULL,
  message text NOT NULL,
  replies_count integer DEFAULT 0,
  reposts_count integer DEFAULT 0,
  likes_count integer DEFAULT 0,
  reply_to_activity_uuid integer,
  expires_at TIMESTAMP,
  created_at TIMESTAMP default current_timestamp NOT NULL
);

```

- Write a script to connect to the database instead of typing everything; call it `db-connect`. place it in the `/backend-flask/bin` dir.
```Bash
#! /usr/bin/bash

psql $LOCAL_CONNECTION_URL

#check bottom of page for new mod for this file when trying to connecting to the prod database.
```
make sure to open permissions on the `db-connect` file in order to run it. `chmod u+x <path_to_file>` 

- We will now seed some data into the databases and we have to write a script to take care of that: `/bin/db-seed` file.
- the `db-seed` file needs to take data from our seed file; create a `/db/seed.sql` file.
- Lets do them in that order:
```Bash
#! /usr/bin/bash

#these print out the echo in a different color to make things fancier
CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-seed"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

seed_path="$(realpath .)/db/seed.sql"
echo "$seed_path"

if [ "$1" == 'prod']; then
	echo "Running in production mode..."
	URL=$RDS_CONNECTION_URL
else
	URL=$LOCAL_CONNECTION_URL
fi

psql $URL cruddur < $schema_path
```

```PostgreSQL
-- this file was manually created (because we might auto generate it in future)
INSERT INTO public.users (display_name, email, handle, cognito_user_id)
VALUES
  ('Andrew Brown', 'andrew@exampro.co', 'andrewbrown' ,'MOCK'),
  ('Andrew Bayko', 'bayko@exampro.co', 'bayko' ,'MOCK');

INSERT INTO public.activities (user_uuid, message, expires_at)
VALUES
  (
    (SELECT uuid from public.users WHERE users.handle = 'andrewbrown' LIMIT 1),
    'This was imported as seed data!',
    current_timestamp + interval '10 day'
  )
```
- Order in which to run the code, load the schema first and then seed the data.


### More Connection Configuration
When using the Gitpod/VSCode tab to view databases, the postgres password is `password`.
- Connect to the database and view the content of the database. The `\x auto` or `\x on` command gives an expanded view so that the data looks better when displayed.
- To drop a database, if other users are using it, it will not drop until the connection to other users is ceased. To see what connections are using the database, use this command:
	- making a shell script out of them and naming it `db-sessions`, you have the code like this:
	- change permissions for it using `chmod u+x db-session` or however to get the permissions right.
```Bash
#!/usr/bin/bash

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-sessions"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

if [ "$1" == 'prod']; then
	echo "Running in production mode..."
	URL=$RDS_CONNECTION_URL
else
	URL=$LOCAL_CONNECTION_URL
fi

NO_DB_CONNECTION_URL=$(sed 's/\/cruddur//g' <<<"$URL")
psql $NO_DB_CONNECTION_URL -c "select pid as process_id, \
       usename as user,  \
       datname as db, \
       client_addr, \
       application_name as app,\
       state \
	from pg_stat_activity;"
 ```

- I will now create a script that will allow me to setup my database in a faster way by calling all the other scripts. call it `db-setup`.
	- modify the permissions for it using `chmod u+x db-setup`.
```Bash
#!/usr/bin/bash
-e # stop if it fails at any point

#echo "==== db-setup"

bin_path="$(realpath .)/bin"

source "$bin_path/db-drop"
source "$bin_path/db-create"
source "$bin_path/db-schema-load"
source "$bin_path/db-seed"
```
- commit the changes and voila.

## Getting SQL to work
- For the SQL to work in Python, we need to install the driver for the PostgreSQL for Python, it is called `psycopg3` package. [Psycopg for PostgreSQL](https://www.psycopg.org/psycopg3/)
- We need to install it in the Python code as a binary and one for database connection pools.
```Bash
psycopg[binary]
psycopg[pool]
```
and run the `pip install -r requirements.txt` to install them.
understand what a database connection pool is. [research]
- Create a new file called `backend-flask/lib/db.py` and fill it:
```Python
from psycopg_pool import ConnectionPool
import os

connection_url = os.getenv("CONNECTION_URL")
pool = ConnectionPool(connection_url)
```
- Add the connection URL to the backend-flask service in the docker-compose file as:
```Bash
CONNECTION_URL: "${CONNECTION_URL}"
```
- Rewrite the `home_activities.py` so that it contains the following:
	- comment out all the code related to tracing; remove all existing result code so that the data looks like this.
```Python
from datetime import datetime, timedelta, timezone
from opentelemetry import trace
from lib.postgresdb import pool, query_wrap_object, query_wrap_array

tracer = trace.get_tracer("home.activities")

class HomeActivities:
  def run(cognito_user_id=None):
    #logger.info("HomeActivities")
    with tracer.start_as_current_span("home-activites-mock-data"):
      span = trace.get_current_span()
      now = datetime.now(timezone.utc).astimezone()
      span.set_attribute("app.now", now.isoformat())

      sql = query_wrap_array("""
      SELECT
        activities.uuid,
        users.display_name,
        users.handle,
        activities.message,
        activities.replies_count,
        activities.reposts_count,
        activities.likes_count,
        activities.reply_to_activity_uuid,
        activities.expires_at,
        activities.created_at
      FROM public.activities
      LEFT JOIN public.users ON users.uuid = activities.user_uuid
      ORDER BY activities.created_at DESC
      """)
      print(sql)
      with pool.connection() as conn:
        with conn.cursor() as cur:
          cur.execute(sql)
          # this will return a tuple
          # the first field being the data
          json = cur.fetchone()
      return json[0]
```
- And the `db.py` file should look like this:
```Python
from psycopg_pool import ConnectionPool
import os

def query_wrap_object(template):
  sql = f"""
  (SELECT COALESCE(row_to_json(object_row),'{{}}'::json) FROM (
  {template}
  ) object_row);
  """
  return sql

def query_wrap_array(template):
  sql = f"""
  (SELECT COALESCE(array_to_json(array_agg(row_to_json(array_row))),'[]'::json) FROM (
  {template}
  ) object_row);
  """
  return sql

connection_url = os.getenv("LOCAL_CONNECTION_URL")
pool = ConnectionPool(connection_url)
```
- With this, the data should have been populated in the database and should show up on the frontend of the cruddur app.

### Connecting into RDS database
- get the RDS connection URL and connect to the database; make sure the database is up and running.
- edit the inbound rules for the RDS database security group to contain an PostgresQL port and add the Gitpod IP address.
- Get the Gitpod IP address using the `curl ifconfig.me`, set it as a Gitpod IP in this way `export GITPOD_IP=$(curl ifconfig.me)`. Get the IP address and place it in the rules to allow connection from gitpod. Check the databse once you are in. Name it GITPOD
- A way to automate the connection between the database and the gitpod environment can be done using two things; the security group ID of the postgres to gitpod inbound rule and the RDS database security group ID.
	- Set these and proceed.
```Bash
export RDS_SG_ID="sg-<id>"
gp env RDS_SG_ID="sg-<id>"

export RDS_GITPOD_SG_RULE_ID="sgr-<id>"
gp env RDS_GITPOD_SG_RULE_ID="sgr-<id>"
```
- Another way to do this is using the command line with some AWS CLI commands:
```bash
aws ec2 modify-security-group-rules \
	--group-id $RDS_SG_ID \
	--security-group-rules "SecurityGroupRuleId=$RDS_GITPOD_SG_RULE_ID,SecurityGroupRule={Description=GITPOD,IpProtocol=tcp,FromPort=5432,ToPort=5432,CidrIpv4=$GITPOD_IP/32}"
```
- A better way will be to place the command above into a shell script that can be used. in the /bin directory, call it `rds-update-sg-rule`.
```Bash
#!/usr/bin/bash
-e # stop if it fails at any point

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="rds-update-sg-rule"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

aws ec2 modify-security-group-rules \
	--group-id $RDS_SG_ID \
	--security-group-rules "SecurityGroupRuleId=$RDS_GITPOD_SG_RULE_ID,SecurityGroupRule={Description=GITPOD,IpProtocol=tcp,FromPort=5432,ToPort=5432,CidrIpv4=$GITPOD_IP/32}"
```

- Update the postgres service in the docker-compose file to contain this:
```bash
command: |
  export GITPOD_IP=$(curl ifconfig.me)
  source "$THEIA_WORKSPACE_ROOT/backend/bin/rds-update-sg-rule"
```
exit out of Gitpod and come back later to check whether this code has run successfully.

- We now want to connect to the RDS Postgres database from the Gitpod environment using the `db-connect` script.
	- the update `db-connect` script file is: run the command with a `prod` argument to get it to connect to the prod database.
```bash
#!/usr/bin/bash

if [ "$1" == "prod"]; then
	echo "Running in production mode..."
	URL=$RDS_CONNECTION_URL
else
	URL=$CONNECTION_URL
fi

psql $URL
```


### Cognito Post confirmation using Lambda
- In the `seed-data.sql` function, we have to input a Cognito userid that will be used to authenticate the user as we seed the data into the table. This will be done using a lambda. This will probably be a python function.
```Text
In software engineering, a lambda function is a small piece of code that performs a specific task, usually within a larger system or application. 
It is a type of function that is defined and invoked inline, without the need for a separate function declaration. 
Lambda functions are often used for event-driven or serverless computing, where they can be triggered automatically in response to specific events or inputs.
```
- Go to AWS and type in "Lambda" and create a lambda using python3.8 and x86arch, call it `cognito-post-confirmation`.
- Grab the code to insert the lambda and put it in the `aws/lambda` with the same name above. modify it to look like this:
```Python
import json
import psycopg2
import os

def lambda_handler(event, context):
	user = event['request']['userAttributes']
    print('userAttributes') # to display and check in CloudWatch Logs
    print(user)

    user_display_name  = user['name']
    user_email         = user['email']
    user_handle        = user['preferred_username']
    user_cognito_id    = user['sub']
    try:
      sql = f"""
         INSERT INTO public.users (
          display_name, 
          email,
          handle, 
          cognito_user_id
          ) 
        VALUES(
          '{user_display_name}',
          '{user_email}',
          '{user_handle}',
          '{user_cognito_id}'
        )
      """
      print('SQL Statement ----')
      print(sql)
      conn = psycopg2.connect(os.getenv('RDS_CONNECTION_URL'))
      cur = conn.cursor()
      cur.execute(sql)
      conn.commit() 

    except (Exception, psycopg2.DatabaseError) as error:
      print(error)
    finally:
      if conn is not None:
          cur.close()
          conn.close()
          print('Database connection closed.')
    return event
```
- modify the `schema.sql` file to contain an email field, like the one set in the code above.
- Update the `backend-flask/db/schema.sql` file and update it to look like this: here, we are adding the handle element.
```PostgreSQL
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
DROP TABLE IF EXISTS public.users;
DROP TABLE IF EXISTS public.activities;


CREATE TABLE public.users (
  uuid UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  display_name text NOT NULL,
  handle text NOT NULL,
  email text NOT NULL,
  cognito_user_id text NOT NULL,
  created_at TIMESTAMP default current_timestamp NOT NULL
);

CREATE TABLE public.activities (
  uuid UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_uuid UUID NOT NULL,
  message text NOT NULL,
  replies_count integer DEFAULT 0,
  reposts_count integer DEFAULT 0,
  likes_count integer DEFAULT 0,
  reply_to_activity_uuid integer,
  expires_at TIMESTAMP,
  created_at TIMESTAMP default current_timestamp NOT NULL
);
```
- Note that in production, a lambda proxy will have to be set to handle all the connections to the RDS database so as not to flood the database with requests >>>
```Text
Lambda proxy integration is a type of integration available in AWS API Gateway that allows you to use an AWS Lambda function as a backend for your API Gateway resource. 
In the context of AWS RDS, a Lambda proxy can be used to provide a serverless backend for your API Gateway, allowing you to execute database queries and operations on an RDS instance in response to incoming API requests.

For example, you can create a Lambda function that receives an incoming HTTP request, performs a SQL query to fetch data from an RDS database, and returns the results to the caller through the API Gateway. By using a Lambda proxy integration, you can handle the API request and response transformations, authentication and authorization, and error handling in your Lambda function, while allowing the API Gateway to act as a simple HTTP proxy that forwards requests and responses to your Lambda function. This approach can simplify the development and deployment of your API, as well as improve the scalability and security of your architecture.

In more simpler terms;
Lambda proxy is a feature in AWS Lambda that allows Lambda to act as a proxy between the client and backend service. When using Lambda proxy integration, the incoming HTTP request is passed to a Lambda function, which processes the request and returns an HTTP response. This means that the Lambda function acts as the front-end interface for the backend service, allowing for better control and customization of the API Gateway. When using Lambda proxy with AWS RDS, the Lambda function can be used to access the database and perform CRUD operations on the data.
```
- Go into the newly created Lambda, add the code. Deploy it. 
- Go to the Configuration section and under environment variables, set an env-var for it to communicate with the RDS database using the RDS_CONNECTION_URL (KEY= RDS_CONNECTION_URL, paste in the connection URL). 
- Add a layer to the Lambda function. (Understand AWS Lambda layers like a 15-year old?).
- Specify the Layer ARN for my region: It should probably look like this: `arn:aws:lambda:eu-west-2:898466741470:layer:psycopg2-py38:1`, verify it and add it.
```Text

An AWS Lambda Layer is a distribution mechanism for libraries, custom runtimes, and other function dependencies in AWS Lambda.

A layer is a ZIP archive that contains libraries, a custom runtime, or other dependencies. When you include a layer in a function, its contents are extracted to the /opt directory in the Lambda execution environment.

This allows you to manage your in-development function code separately from the unchanging code and resources that it uses. You can reuse layers across multiple functions, which can simplify your development and deployment process, and reduce the size of your deployment package.



Sure! So imagine you want to create a program that can do something really cool, like read and analyze data from the internet. You could write all the code yourself, but that would take a long time and be really complicated.

Instead, you can use a service called AWS Lambda, which is like a magic box that can run code for you without you having to worry about things like servers and infrastructure. With Lambda, you just write your code, upload it to AWS, and let Lambda take care of the rest.

Now, let's say your code depends on some external libraries or packages, like a fancy data analysis tool that someone else wrote. You could try to package everything together and upload it to AWS, but that can get messy and confusing.

This is where AWS Lambda Layers come in. A Layer is like a pre-packaged set of code that you can attach to your Lambda function, kind of like adding toppings to a pizza. So instead of trying to upload everything together, you can just upload your own code to Lambda and then attach a Layer with the external libraries you need.

This makes it easier to manage your code and ensures that you're using the same version of the external libraries every time you run your Lambda function. Plus, Layers are reusable, so you can attach them to multiple Lambda functions if you need to.

```
- Now we add a trigger for the Lambda function. We got to AWS Cognito, and under 'User Pool Properties', add the newly created Lambda function. Refresh it.
- Try to connect to the Cruddur frontend application by Signing Up on Cruddur, It should throw an error. The error is because we have not given the Lambda the required network interface related permissions and some other ones to create logs, log-groups and log-streams
	- In order to deploy a lambda, it has to be put into a VPC. 
	- Before we do that, create a custom Role Policy in IAM called `AWSLambdaVPCAccessExecutionRoleCruddurRDS`. Better still, go to the Configuration tab in the Lambda page, click on Permissions and click on the role name under Execution Role.
	- This takes you to the Roles under AWS IAM, create a new policy with the name above and enter this in the json section.
	- Add a description if you see fit, and create the policy.
	- Go back to Lambda, enter the Configuration > Permissions > Execution Role and click on the role again, now attach the newly created policy to it.
	- CHECK IF THE CLOUDWATCH LOGS ARE AVAILABLE, IF THEY ARE, DO NOT ADD ANY CODE OF THE JSON UNDER THE FIRST STATEMENT, IF NOT, ADD EVERYTHING ESPECIALLY THE LAST TWO ONES.
```JSON
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
              "ec2:CreateNetworkInterface",
              "ec2:DescribeNetworkInterfaces",
              "ec2:DeleteNetworkInterface",
              "ec2:DescribeInstances",
              "ec2:AttachNetworkInterface"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeSubnets",
                "ec2:DescribeVpcs"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "arn:aws:logs:*:*:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:*:*:/aws/lambda/cruddur-post-confirmation"
            ]
        },
    ]
}

```
- After here, go to Configurations > VPC and fill in the VPsubnets and security groups to use. These security groups should strictly be the same one the RDS database is in. (The RDS databse must be running too).
IT SHOULD NOW WORK IF YOU COMMIT TO THE CRUDDUR APP, MAKE SURE TO DELETE THE USER CREATED IN COGNITO AND START AGAIN.
- Update the `backend-flask/db/schema.sql` file and update it to look like this:
```PostgreSQL
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
DROP TABLE IF EXISTS public.users;
DROP TABLE IF EXISTS public.activities;


CREATE TABLE public.users (
  uuid UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  display_name text NOT NULL,
  handle text NOT NULL,
  email text NOT NULL,
  cognito_user_id text NOT NULL,
  created_at TIMESTAMP default current_timestamp NOT NULL
);

CREATE TABLE public.activities (
  uuid UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_uuid UUID NOT NULL,
  message text NOT NULL,
  replies_count integer DEFAULT 0,
  reposts_count integer DEFAULT 0,
  likes_count integer DEFAULT 0,
  reply_to_activity_uuid integer,
  expires_at TIMESTAMP,
  created_at TIMESTAMP default current_timestamp NOT NULL
);
```
- Connect to the RDS database from gitpod And get everything from every table in cruddur with `SELECT * FROM USERS;`. the table should be populated with everythin specified in schema.sql file.


## Creating Activities (creating a CRUD in Cruddur)
- Refactoring code in `/lib/db.py` for database connections and calling them in `/services/create_activity.py`.
Refactored code in `/lib/db.py`.
```Python
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

  def print_params(self,params):
    blue = '\033[94m'
    no_color = '\033[0m'
    print(f'{blue} SQL Params:{no_color}')
    for key, value in params.items():
      print(key, ":", value)

  def print_sql(self,title,sql):
    cyan = '\033[96m'
    no_color = '\033[0m'
    print(f'{cyan} SQL STATEMENT-[{title}]------{no_color}')
    print(sql)

  # we want to commit data such as an insert
  # be sure to check for RETURNING in all uppercases
  def query_commit(self,sql,params={}):
	    self.print_sql('commit with returning',sql)
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
  def query_array_json(self,sql,params={}):
    self.print_sql('array',sql)

    wrapped_sql = self.query_wrap_array(sql)
    with self.pool.connection() as conn:
      with conn.cursor() as cur:
        cur.execute(wrapped_sql,params)
        json = cur.fetchone()
        return json[0]
        
  # When we want to return an array of json objects
  def query_object_json(self,sql,params={}):
  
    self.print_sql('json',sql)
    self.print_params(params)
    wrapped_sql = self.query_wrap_object(sql)

    with self.pool.connection() as conn:
      with conn.cursor() as cur:
        cur.execute(wrapped_sql,params)
        json = cur.fetchone()
        if json == None:
          "{}"
        else:
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

The `/services/create_activity.py` code should look like this:
```Python
from datetime import datetime, timedelta, timezone

from lib.postgresdb import db

class CreateActivity:
  def run(message, user_handle, ttl):
    model = {
      'errors': None,
      'data': None
    }

    now = datetime.now(timezone.utc).astimezone()

    if (ttl == '30-days'):
      ttl_offset = timedelta(days=30) 
    elif (ttl == '7-days'):
      ttl_offset = timedelta(days=7) 
    elif (ttl == '3-days'):
      ttl_offset = timedelta(days=3) 
    elif (ttl == '1-day'):
      ttl_offset = timedelta(days=1) 
    elif (ttl == '12-hours'):
      ttl_offset = timedelta(hours=12) 
    elif (ttl == '3-hours'):
      ttl_offset = timedelta(hours=3) 
    elif (ttl == '1-hour'):
      ttl_offset = timedelta(hours=1) 
    else:
      model['errors'] = ['ttl_blank']

    if user_handle == None or len(user_handle) < 1:
      model['errors'] = ['user_handle_blank']

    if message == None or len(message) < 1:
      model['errors'] = ['message_blank'] 
    elif len(message) > 280:
      model['errors'] = ['message_exceed_max_chars'] 

    if model['errors']:
      model['data'] = {
        'handle':  user_handle,
        'message': message
      }   
    else:
      expires_at = (now + ttl_offset)
      uuid = CreateActivity.create_activity(user_handle,message,expires_at)

      object_json = CreateActivity.query_object_activity(uuid)
      model['data'] = object_json
    return model

  def create_activity(handle, message, expires_at):
    sql = db.template('activities','create')
    uuid = db.query_commit(sql,{
      'handle': handle,
      'message': message,
      'expires_at': expires_at
    })
    return uuid
    
  def query_object_activity(uuid):
    sql = db.template('activities','object')
    return db.query_object_json(sql,{
      'uuid': uuid
    })
```

Update the lambda function to look like this; this is to prevent SQL injection, by sanitizing the SQL being put into the code. Deploy it. 
```Python
import json
import psycopg2
import os

def lambda_handler(event, context):
    user = event['request']['userAttributes']
    print('userAttributes')
    print(user)

    user_display_name  = user['name']
    user_email         = user['email']
    user_handle        = user['preferred_username']
    user_cognito_id    = user['sub']
    
    try:
      sql = f"""
         INSERT INTO public.users (
          display_name, 
          email,
          handle, 
          cognito_user_id
          ) 
        VALUES(%s,%s,%s,%s)
      """
      print('SQL Statement ----')
      print(sql)
      conn = psycopg2.connect(os.getenv('CONNECTION_URL'))
      cur = conn.cursor()
      params = [
        user_display_name,
        user_email,
        user_handle,
        user_cognito_id
      ]
      cur.execute(sql,*params)
      conn.commit() 

    except (Exception, psycopg2.DatabaseError) as error:
      print(error)
    finally:
      if conn is not None:
          cur.close()
          conn.close()
          print('Database connection closed.')
    return event
```

- Create a new dir under `db` call it `sql`, create another dir, call it `activities` and add the SQL files, `create.sql`, `object.sql`
	1. `create.sql`
```SQL
INSERT INTO public.activities (
  user_uuid,
  message,
  expires_at
)
VALUES (
  (SELECT uuid 
    FROM public.users 
    WHERE users.handle = %(handle)s
    LIMIT 1
  ),
  %(message)s,
  %(expires_at)s
) RETURNING uuid;
```
This code is passed into the `create_activity` method in the `create_activity.py` file to replace the SQL code hard-coded to push data into the `public.activities` table.


2. `object.sql`
```SQL
SELECT
  activities.uuid,
  users.display_name,
  users.handle,
  activities.message,
  activities.created_at,
  activities.expires_at
FROM public.activities
INNER JOIN public.users ON users.uuid = activities.user_uuid 
WHERE 
  activities.uuid = %(uuid)s
```
Here the `object_json_query` method references this code above to put in the `object_json` variable in the `create_activity.py` code; this replaces the verbose model data previously hard-coded.


3. `home.sql`
```SQL
SELECT
  activities.uuid,
  users.display_name,
  users.handle,
  activities.message,
  activities.replies_count,
  activities.reposts_count,
  activities.likes_count,
  activities.reply_to_activity_uuid,
  activities.expires_at,
  activities.created_at
FROM public.activities
LEFT JOIN public.users ON users.uuid = activities.user_uuid
ORDER BY activities.created_at DESC
```
The code is taken from `home_activities.py`. the SQL is taken away and replaced like this:
```Python
from datetime import datetime, timedelta, timezone
from opentelemetry import trace

from lib.postgresdb import db

#tracer = trace.get_tracer("home.activities")

class HomeActivities:
  def run(cognito_user_id=None):
    #logger.info("HomeActivities")
    #with tracer.start_as_current_span("home-activites-mock-data"):
    #  span = trace.get_current_span()
    #  now = datetime.now(timezone.utc).astimezone()
    #  span.set_attribute("app.now", now.isoformat())
    sql = db.template('activities','home')
    results = db.query_array_json(sql)
    return results
```
