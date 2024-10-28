from airflow.decorators import dag, task
from datetime import datetime
from airflow.models.param import Param


@task.virtualenv(
    task_id="get_ads_metadata",
    requirements=["./requirements.txt"],
    system_site_packages=False,
    venv_cache_path="/tmp/venv/cache/job_ads",
    pip_install_options=["--require-virtualenv", "--isolated"],
)
def get_job_ads_metadata_task(params= None):
    import sys
    import json
    sys.path.append('/opt/airflow/dags/finn_job_ads')
    sys.path.append('/opt/airflow/dags')

    print(sys.path)

    from utils.general import extract_nested_df_value

    from finn_ingestion_lib import get_job_ads_metadata

    with open("/opt/airflow/dags/finn_job_ads/config.json") as f:
        config = json.load(f)
        occupations = config["occupations"]
    
    # TODO: Make tasks dynamic with occupations
    for occupation in occupations:
        get_job_ads_metadata(occupation=occupation, published="1" if params is not None and params["published_today"] is True else "0")

@task.virtualenv(
    task_id="get_ads_content", 
    requirements=["./requirements.txt"], 
    system_site_packages=False,
    venv_cache_path="/tmp/venv/cache/job_ads",
    pip_install_options=["--require-virtualenv", "--isolated"]
)
def get_ads_content_task():
    import sys
    sys.path.append('/opt/airflow/dags/finn_job_ads')
    sys.path.append('/opt/airflow/dags')

    from finn_ingestion_lib import get_ads_content

    # TODO: Make tasks dynamic and map 1:1 to occupation metadata ingestion tasks
    get_ads_content()


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
    get_job_ads_metadata_task() >> get_ads_content_task()
    
dag()
