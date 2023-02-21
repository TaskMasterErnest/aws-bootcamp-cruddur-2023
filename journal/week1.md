# Week 1 — App Containerization

## Running the Python Backend Locally
- Test the Python backend code to see it its running locally
- Set the backend and frontend URLs so that we get some information.
- The backend returns a json file so watch out for that.
	```Shell
	# enter the backend directory
	cd backend-flask
	# set the enviroment variables
	export FRONTEND_URL="*"
	export BACKEND_URL="*"
	# install all dependencies
	pip3 install -r requirements.txt
	# run the python code with the flask module, set the host IP 
	flask run --host=0.0.0.0
	```
- To access the information the backend is putting out in JSON, append `/api/activities/home` to the end of the URL the Flask server is running on. eg, `http://127.0.0.1:5000/api/activities/home`
- Uninstall the dependencies installed using `pip3 uninstall -r requirements.txt -y `.

## Creating a Dockerfile
- A Dockerfile is a configuration document that lists all the commands that Docker runs in order to create a container for a specific application.
- Create a file called `Dockerfile` in the `/backend-flask` directory.
- Add the following code to the Dockerfile:
	```Dockerfile
	FROM python:3.10-slim-buster

	WORKDIR /backend-flask

	COPY requirements.txt requirements.txt
	RUN pip3 install -r requirements.txt

	COPY . .

	ENV FLASK_ENV=development

	EXPOSE ${PORT}
	CMD [ "python3", "-m" , "flask", "run", "--host=0.0.0.0", "--port=4567"]
	```

## Build the Container
- Building a container is to create a necessary environment that contains all the dependencies the application will need to run successfully.
- See it as creating a perfect local environment for running an application.
- Build the container image from the Dockerfile with the tag, backend-flask, using this command
	```Bash
	docker build -t backend-flask .
	```
- It is important to run this command directly in the directory where the Dockerfile is situated; in this case, `/backend-flask` dir.

## Run the Container
- Running a container is starting it, essentially starting the environment in which it was built.
- With Docker, there are soo many ways to run a container. For this container, we are going to add a few flags taht are useful to run it:
	1. ensure container is removed when stopped with the `--rm` flag.
	2. add ports for container to use with the `-p` flag.
	3. add environment variables to use in container with `-e` flag.
	4. ensure container is running in background with the `-d` flag.
- The command to run the container turn out like this;
	```Shell
	docker run --rm -it -d -p 4567:4567 -e BACKEND_URL="*" -e FRONTEND_URL="*" backend-flask
	```
- You specify the image you want to run as the container at the end of the `run` command eg. backend-flask.

