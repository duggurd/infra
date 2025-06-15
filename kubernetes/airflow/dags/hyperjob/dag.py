
from airflow.decorators import dag, task
from datetime import datetime
from airflow.models.param import Param
import os

storage_options = None
if os.environ.get("AIRFLOW_HOME") is not None:
    from airflow.hooks.base_hook import BaseHook

    minio_connection = BaseHook.get_connection("homelab-minio")
    postgres_connection = BaseHook.get_connection("postgres-hyperjob")

    minio_connection = {
        "key": minio_connection.login,
        "secret": minio_connection.password,
        "host":  minio_connection.host
    }

    postgres_connection = {
        "schema": postgres_connection.schema,
        "login": postgres_connection.login,
        "password": postgres_connection.password,
        "port": postgres_connection.port,
        "host": postgres_connection.host
    }
    
    storage_options = {
        "key": minio_connection["key"],
        "secret": minio_connection["secret"],
        "endpoint_url":  f"http://{minio_connection["host"]}"
    }
else:
    storage_options = {
        "key": os.environ["MINIO_ACCESS_KEY"],
        "secret": os.environ["MINIO_SECRET_KEY"],
        "endpoint_url":  f"http://{os.environ.get('MINIO_AP')}"
    }


@task.virtualenv(
    task_id="get_latest_dates_pg",
    requirements=["./requirements.txt"],
    system_site_packages=False,
    venv_cache_path="/tmp/venv/cache/hyperjob",
    pip_install_options=["--require-virtualenv", "--isolated"],
)
def get_latest_dates_task():
    import sys
    import json
    sys.path.append('/opt/airflow/dags/hyperjob')
    sys.path.append('/opt/airflow/dags')


@task.virtualenv(
    task_id="ingest", 
    requirements=["./requirements.txt"], 
    system_site_packages=False,
    venv_cache_path="/tmp/venv/cache/hyperjob",
    pip_install_options=["--require-virtualenv", "--isolated"]
)
def ingest(minio_connection):
    import sys
    sys.path.append('/opt/airflow/dags/hyperjob')
    sys.path.append('/opt/airflow/dags')

    assert minio_connection is not None

    from duck import get_database, ingest_ads_content, ingest_ads_metadata, ingest_stopwords

    database = get_database(minio_connection)

    ingest_ads_content(database)
    ingest_ads_metadata(database)
    ingest_stopwords(database)


@task.virtualenv(
    task_id="transform", 
    requirements=["./requirements.txt"], 
    system_site_packages=False,
    venv_cache_path="/tmp/venv/cache/hyperjob",
    pip_install_options=["--require-virtualenv", "--isolated"]
)
def transform(minio_connection):
    import sys
    sys.path.append('/opt/airflow/dags/hyperjob')
    sys.path.append('/opt/airflow/dags')

    assert minio_connection is not None

    from duck import get_database, create_keywords, create_employers, create_stillingsfunksjon, create_stillingsfunksjon_ads_bridge, create_keyword_ads_bridge, create_ads_with_id, create_ngrams,cleanup_ads_content, cleanup_ads_metadata, join_ads_content_and_metadata

    database = get_database(minio_connection)

    # cleanup ingested data
    cleanup_ads_content(database)
    cleanup_ads_metadata(database)
    join_ads_content_and_metadata(database)
    
    # create dimension tables
    create_keywords(database)
    create_employers(database)
    create_stillingsfunksjon(database)

    # create bridge tables
    create_stillingsfunksjon_ads_bridge(database)
    create_keyword_ads_bridge(database)
    
    # create unified table with ids
    create_ads_with_id(database)



    create_ngrams(database)


@task.virtualenv(
    task_id="export", 
    requirements=["./requirements.txt"], 
    system_site_packages=False,
    venv_cache_path="/tmp/venv/cache/hyperjob",
    pip_install_options=["--require-virtualenv", "--isolated"]
)
def export(minio_connection, postgres_connection):
    import sys
    sys.path.append('/opt/airflow/dags/hyperjob')
    sys.path.append('/opt/airflow/dags')

    assert minio_connection is not None
    assert postgres_connection is not None

    from duck import get_database, export_to_postgres

    database = get_database(minio_connection)

    export_to_postgres(database, postgres_connection)



@dag(
    dag_id="hyperjob", 
    start_date=datetime(2024, 1, 1), 
    schedule_interval="0 0 * * *",
    catchup=False,
    max_active_runs=1,
    params = {
        "full_refresh": Param(True, type="boolean")
    }
)
def dag():
    ingest(minio_connection) >> transform(minio_connection) >> export(minio_connection, postgres_connection)
    
dag()
