FROM 478429420160.dkr.ecr.eu-west-2.amazonaws.com/cruddur-python:3.10-slim-buster

WORKDIR /backend-flask

COPY requirements.txt requirements.txt

RUN pip3 install -r requirements.txt

COPY . .

EXPOSE ${PORT}

ENV PYTHONUNBUFFERED=1

CMD [ "python", "-m", "flask", "run", "--host=0.0.0.0", "--port=4567", "--debug" ]
