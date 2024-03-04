FROM apache/airflow:slim-latest
COPY --chown=airflow ./requirements.txt /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt --no-cache-dir --no-color