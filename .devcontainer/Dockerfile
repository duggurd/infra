FROM python:3.11-slim
COPY ./requirements.txt /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt
RUN apt-get update \
    && apt-get install -y git \
    && apt-get clean