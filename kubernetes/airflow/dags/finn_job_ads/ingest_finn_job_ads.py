from airflow.decorators import dag, task
from datetime import datetime
from airflow.models.param import Param
import os

storage_options = None
if os.environ.get("AIRFLOW_HOME") is not None:
    from airflow.hooks.base_hook import BaseHook

    connection = BaseHook.get_connection("homelab-minio")
    
    storage_options = {
        "key": connection.login,
        "secret": connection.password,
        "endpoint_url":  f"http://{connection.host}"
    }
else:
    storage_options = {
        "key": os.environ["MINIO_ACCESS_KEY"],
        "secret": os.environ["MINIO_SECRET_KEY"],
        "endpoint_url":  f"http://{os.environ.get('MINIO_AP')}"
    }


@task.virtualenv(
    task_id="get_ads_metadata",
    requirements=["./requirements.txt"],
    system_site_packages=False,
    venv_cache_path="/tmp/venv/cache/job_ads",
    pip_install_options=["--require-virtualenv", "--isolated"],
)
def get_job_ads_metadata_task(storage_options, published_today):
    import sys
    import json
    sys.path.append('/opt/airflow/dags/finn_job_ads')
    sys.path.append('/opt/airflow/dags')

    print("running metadata_task with published_today: ", published_today)

    from finn_ingestion_lib import get_job_ads_metadata

    with open("/opt/airflow/dags/finn_job_ads/config.json") as f:
        config = json.load(f)
        occupations = config["occupations"]
    
    # TODO: Make tasks dynamic with occupations
    for occupation in occupations:
        get_job_ads_metadata(
            occupation=occupation, 
            published="1" if published_today else "",
            storage_options=storage_options
        )

@task.virtualenv(
    task_id="get_ads_content", 
    requirements=["./requirements.txt"], 
    system_site_packages=False,
    venv_cache_path="/tmp/venv/cache/job_ads",
    pip_install_options=["--require-virtualenv", "--isolated"]
)
def get_ads_content_task(storage_options):
    import sys
    sys.path.append('/opt/airflow/dags/finn_job_ads')
    sys.path.append('/opt/airflow/dags')

    from finn_ingestion_lib import get_ads_content

    # TODO: Make tasks dynamic and map 1:1 to occupation metadata ingestion tasks
    get_ads_content(storage_options=storage_options)


@dag(
    dag_id="finn_ads_ingestion", 
    start_date=datetime(2024, 1, 1), 
    schedule_interval="0 0 * * *",
    catchup=False,
    max_active_runs=1,
    params = {
        "published_today": Param(True, type="boolean")
    }
)
def dag():
    get_job_ads_metadata_task(storage_options, published_today="{{ params.published_today }}") >> get_ads_content_task(storage_options)
    
dag()
