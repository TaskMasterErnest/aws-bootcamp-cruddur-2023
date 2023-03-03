# Week 2 — Distributed Tracing

## What is Distributed Tracing?

- It is the method of tracking application requests as they flow from front-end devices to back-end services and databases.
- It most like like is used in microservices architecture where the request goes through a bunch of microservices and must be tracked in order to obtain useful data from them.

- Two concepts that are needed to understand in order to fully understand distributed tracing are:
	- microservices and 
	- observability

1. **Microservices** are an approach in software development where applications are built in small, independent services that can communicate with each other through APIs.
	- Each microservice is designed to perform a specific function or task, and can be developed, deployed and scaled differently from other services.

2. **Observability** is how well the internal states of a system can be inferred from knowledge from its external outputs. *OR*. It is the ability to gain insights into the internal workings of a software application by observing its outputs.
	- Observability can be achieved through a combination of techniques; logging, metrics and tracing.
	
	A brief introduction to each technique:
	1. **Logging** is the practice of recording events or actions that occur in a software application, for the purpose of tracking and diagnosing issues that may arise.
		- These events are discrete events that are timestamped and kept in n immutable record.
	2. **Metrics** are numerical measurements that are used to track and measure the performance of software application.
		- There are 4 golden signals that are measured suing metrics in a software application: *latency, error rate, traffic and saturation*.
	3. **Tracing** is a method of observing and analyzing the flow of requests through a distributed system, to aid in debugging and performance optimization.
		- tracing requires the tagging of a request with a unique identifier, and tracking and updating that identifier as it travels through different components in the distributed system.
		- each component records information about the request; timestamps, performance metrics and any errors or exceptions that may have occurred.
		- the resulting feedback is called a trace, which allows developers to see the entire path of a request through the system, and check any bottlenecks and issues that may have occurred.
		- A trace is then the representation of a series of causally-related distributed events that encode the end-to-end request flow through a distributed system.
		- Tracing can be paired with logging and metrics to gain a comprehensive view of system performance.
		- There are some best practices to observe when implementing tracing:
			1. clearly define all trace identifiers
			2. instrument all relevant components of the system
			3. set appropriate sampling rates to balance performance and resource usage
			4. use standardized tracing formats to ensure interoperability.


## 1. Tracing Using Honeycomb.io

- I created a Honeycomb.io account and got a test environment and and API key to start putting in my application to start collecting traces.
- There are two ways to use the API key in the applcation:
	1. export the API key in a `HONEYCOMB_API_KEY` environment variable for the application to use or
	2. hardcode the API key into the application code.
- Honeycomb.io uses standardized tracing formats built on OpenTelemetry. Put the following environment variables into the back-end service to use to connect to Honeycomb. Put them in the docker-compose file under the backend-service.
```YAML
OTEL-SERVICE-NAME: 'backend-flask'
OTEL_EXPORTER_OTLP_ENDPOINT: "https://api.honeycomb.io"
OTEL_EXPORTER_OTLP_HEADERS: "x-honeycomb-team=${HONEYCOMB_API_KEY}"
```
- Install the following packages to get Honeycomb.io working in the application:
	- place this in the `/backend-flask/requirements.txt` file.
```Text
opentelemetry-api 
opentelemetry-sdk 
opentelemetry-exporter-otlp-proto-http 
opentelemetry-instrumentation-flask 
opentelemetry-instrumentation-requests
```
- Install these packages using the `pip install -r requirements.txt` command.
- Import the following packages into the code from the OpenTelemetry standardized library that will make tracing possible in the Flask application.
	- place this in the `/backend-flask/app.py` file.
```Python
from opentelemetry import trace
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
```
- Put in this code that will enable tracing and set up an exporter that will send data to Honeycomb.
	- place it in the `/backend-flask/app.py` file.
```Python
provider = TracerProvider()
processor = BatchSpanProcessor(OTLPSpanExporter())
provider.add_span_processor(processor)
trace.set_tracer_provider(provider)
tracer = trace.get_tracer(__name__)
```
- Finally, initialize automatic instrumentation for the Flask application.
	- place this code after the line that starts the Flask application, as shown.
```Python
# Initialize automatic instrumentation with Flask
# app = Flask(__name__)
FlaskInstrumentor().instrument_app(app) 
RequestsInstrumentor().instrument()
```
- Start the application, using the `docker compose up` command, to get all these up and running.
- Hit a few endpoints and visit the Honeycomb account and under the right environment, you'll see the traces.

### Creating a Span in the Flask application
- A span in distributed tracing represents a logical unit of work done in completing a request or transaction. It is a single operation within a trace.
- To get a trace every time we hit the `/api/activities/home` endpoint, put the tracer in the `/backend-flask/services/home_activities.py` file
- In order to get a span in our Flask application, import a tracer and use its span methods create spans in the code.
	- the code should look like this:
```Python
from datetime import datetime, timedelta, timezone
from opentelemetry import trace

tracer = trace.get_tracer("home.activities") 

class HomeActivities:
	def run():
		with tracer.start_as_current_span("home-actvities-mock-data"):
		span = trace.get_current_span()
		now = datetime.now(timezone.utc).astimezone()
		span.set_attribute("app.now", now.isoformat())
		results = [{
				'uuid': '68f126b0-1ceb-4a33-88be-d90fa7109eee',
				'handle': 'Andrew Brown',
				
			...
		
		}
		]
		span.set_attribute("app.result_length", len(results))
		return results
```

```Python
adding attributes kinda like give you logs in your spans.

`span = trace.get_current_span()`: This line retrieves the current span from the OpenTelemetry tracer.
The `get_current_span()` method returns the current span being executed, which can be used to add attributes, events, and other data to the span.

`span.set_attribute("app.now", now.isoformat())`: This line sets an attribute on the current span to indicate the current time.
The `set_attribute()` method is used to add metadata to a span, which can help provide additional context and insights into the operation being performed.

By adding the "app.now" atribute to the span, it becomes easier to understand when the operation was performed and to correlate it with other events and spans in the distributed system.

span.set_attribute("app.result_length", len(results)) is used to set an attribute on the current span being executed, indicating the length of the `results` list that will be returned from the function, and then returning the `results` list itself.
```
Spin up the application again and hit the `/api/activities/home` endpoint and check the trace in the Honeycomb app.


## 2. Tracing Using AWS X-Ray
- X-Ray is AWS' way to track traces in our applications. It allows the user to analyze and debug distributed applications in real-time.
- To use X-Ray, there has to be a sidecar container running an X-Ray daemon alongside the user application.
	- The X-Ray daemon is a lightweight, open-source application that runs on an EC2 instance, a container, or a Lambda function.
	- The X-Ray daemon collects trace data from the application, including segment and subsegment information, and sends it to the AWS X-Ray service for analysis and visualization.
	- The X-Ray daemon provides flexibility in how you instrument the application, allowing you to use either the X-Ray SDK or the X-Ray daemon's API to capture trace data.
In this case, I am using the X-Ray SDK to instrument tracing for my application.
- Using the aws-xray-sdk for Python documentation as a guide, I started initializing AWS X-Ray.
	1. Add a line of code to the `/backend-flask/requirements.txt` file. Install using the `pip` command.
```Text
aws-xray-sdk
```
   2. Add the following line to the `/backend-flask/app.py` file. 
   - Rewrite the service name to match the particular service we are working with ie. `service='backend-flask'`.
   - this code imports the X-Ray libraries from the aws-xray-sdk for Python.
```Python
# AWS X-RAY ----------
from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.ext.flask.middleware import XRayMiddleware

xray_url = os.getenv("AWS_XRAY_URL")
xray_recorder.configure(service='backend-flask', dynamic_naming=xray_url)
```
   3. Add the following line of code to the `/backend-flask/app.py` file; it should look like this:
```Python
# app = Flask(__name__)
# AWS X-RAY ----------
XRayMiddleware(app, xray_recorder)
```
   4. Add json configuration for sampling traces in x-ray in the `aws/json/xray.json` file; use this: (change ServiceName to backend-flask).
```Json
{
  "SamplingRule": {
      "RuleName": "Cruddur",
      "ResourceARN": "*",
      "Priority": 9000,
      "FixedRate": 0.1,
      "ReservoirSize": 5,
      "ServiceName": "backend-flask",
      "ServiceType": "*",
      "Host": "*",
      "HTTPMethod": "*",
      "URLPath": "*",
      "Version": 1
  }
}
```
   5. Go to AWS X-Ray tab in the AWS console, try to launch a trace but cancel before you actually launch it.
	- it takes you back to the AWS X-Ray page where you can click on Configuration and get a Groups under it.
	- we will now create a log group that will keep all the logs we will be generating from the backend service.
```Shell
aws xray create-group \
	--group-name "Cruddur" \
	--filter-expression "service(\"backend-flask\")"
```
	- make sure service name is `backend-flask` and the group name is `Cruddur`.
	NB: you must have you AWS CLI configured to work with the environment you are working in eg. gitpod
	check out the log group under CloudWatch, under X-Ray Traces, under Traces.
   6. Create a sampling rule using the AWS CLI:
```Shell
aws xray create-sampling-rule --cli-input-json file://aws/json/xray.json
```
	- check to see if the sampling rule is available
   7. At this stage, we want to run X-Ray as a container alongside our backend application.
	- The region has been hardcoded into it.
	- make sure to have the AWS access key and secret access keys available for that environment.
```Shell
xray-daemon:
  image: "amazon/aws-xray-daemon"
  environment:
	AWS_ACCESS_KEY_ID: "${AWS_ACCESS_KEY_ID}"
	AWS_SECRET_ACCESS_KEY: "${AWS_SECRET_ACCESS_KEY}"
	AWS_REGION: "eu-west-2"
  command:
	- "xray -o -b xray-daemon:2000"
  ports:
	- 2000:2000/udp
```

- and we add these env-vars to the backend service in the same docker-compose file
```Shell
AWS_XRAY_URL: "*4567-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}*"
AWS_XRAY_DAEMON_ADDRESS: "xray-daemon:2000"
```
   8. Run the docker-compose file to run up all the containers.
   9. Go to the AWS X-Ray console, click on Traces, the traces will be there.


## 3. Using CloudWatch Logs

 - Add `watchtower` to the requirements.txt file in the `/backend-flask` folder and install the requirements.
 - Add the following code to the `app.py` file to configure CloudWatch logging for the app.
```Python
import watchtower
import logging
from time import strftime

...

# Configuring Logger to Use CloudWatch
LOGGER = logging.getLogger(__name__)
LOGGER.setLevel(logging.DEBUG)
console_handler = logging.StreamHandler()
cw_handler = watchtower.CloudWatchLogHandler(log_group='cruddur')
LOGGER.addHandler(console_handler)
LOGGER.addHandler(cw_handler)
LOGGER.info("Test Log")
```

- After every request, we want to log the request and an error, so we put on this code to do that after every request. This should go just before the `@app.route("/api/message_groups", methods=['GET'])` endpoint.
```Python
@app.after_request
def after_request(response):
    timestamp = strftime('[%Y-%b-%d %H:%M]')
    LOGGER.error('%s %s %s %s %s %s', timestamp, request.remote_addr, request.method, request.scheme, request.full_path, response.status)
    return response
```
- Brace yourself, we are going to activate a lot of things here.
- We are now going to implement logging in the `home_activites.py` file. The code in `home_activities.py` should look like this:
```Python
from datetime import datetime, timedelta, timezone
from opentelemetry import trace

tracer = trace.get_tracer("home.activities")

class HomeActivities:
	def run(Logger):
		logger.info("Home Activities")
		with tracer.start_as_current_span("home-actvities-mock-data"):
		span = trace.get_current_span()
```
- The code in `app.py` should look like this; in the `@app.route("/api/activities/home", methods...` endpoint code
```Python
@app.route("/api/activities/home", methods=['GET'])
def data_home():
	data = HomeActivities.run(logger=LOGGER)
	return data, 200
```
- Essentially, we are parsing the Logger function to pick up and register logs when we hit the `/api/activities/home` endpoint. 
- We get a response(s) that is(are) logged into CloudWatch logs.
- In order for CloudWatch to have access to our AWS environment and log in there, we add these env-vars to take care of that; put them in the docker-compose file, under the backend service.
```Shell
AWS_DEFAULT_REGION: "${AWS_DEFAULT_REGION}"
AWS_ACCESS_KEY_ID: "${AWS_ACCESS_KEY_ID}"
AWS_SECRET_ACCESS_KEY: "${AWS_SECRET_ACCESS_KEY}"
```

## 4. Rollbar Logs
- Rollbar. create an account and go through the process.
- Skip add apps, and in the Add SDK section, select Flask and continue.
- Ignore the setup-SDK page and add the following into the `/backend-flask/requirements.txt` file.

```Shell
blinker
rollbar
```

- install them with the `pip install -r requirements.txt` command.

- Set the Rollbar Access Token; access token is found on the page that lets you set up the SDK. Pick that access token.

```Shell
export ROLLBAR_ACCESS_TOKEN="[*redacted*]"
gp env ROLLBAR_ACCESS_TOKEN="[*redacted*]"
```
- Reference the access token in the docker-compose file in the backend service.
```YAML
ROLLBAR_ACCESS_TOKEN: "${ROLLBAR_ACCESS_TOKEN}"
```
- Initialize rollbar in the `app.py` file, with the following code:
```Python
import os
import rollbar
import rollbar.contrib.flask
from flask import got_request_exception
```
- Put this code into the `app.py` file under the Flask run app, like this:
```Python
app = Flask(__name__)

rollbar_access_token = os.getenv('ROLLBAR_ACCESS_TOKEN')
@app.before_first_request
def init_rollbar():
    """init rollbar module"""
    rollbar.init(
        # access token
        rollbar_access_token,
        # environment name
        'production',
        # server root directory, makes tracebacks prettier
        root=os.path.dirname(os.path.realpath(__file__)),
        # flask already sets up logging
        allow_logging_basic_config=False)

    # send exceptions from `app` to rollbar, using flask's signal system.
    got_request_exception.connect(rollbar.contrib.flask.report_exception, app)
```
- this code sets up Rollbar to log exceptions and errors that occur within the Flask app, using the provided Rollbar access token and environment name. It also configures Rollbar to use Flask's built-in signal system to catch exceptions and send them to the Rollbar logging service.
- Add an endpoint to test the rollbar app when it comes up and is hit:
	- place this code right under the code above.
```Python
@app.route('/rollbar/test')
def rollbar_test():
    rollbar.report_message('Hello World!', 'warning')
    return "Hello World!"
```
- Start up the application.
