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
