FROM python:3.11-slim
COPY ./requirements.txt /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt
RUN apt-get update \
    && apt-get install -y git curl unzip \
    && cd /tmp \
    && curl -OL https://github.com/duckdb/duckdb/releases/download/v1.1.3/duckdb_cli-linux-amd64.zip \
    && unzip duckdb_cli-linux-amd64.zip \
    && rm /tmp/duckdb_cli-linux-amd64.zip \
    && mv ./duckdb /usr/bin \
    && apt-get clean