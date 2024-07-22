from airflow.decorators import dag, task
from datetime import datetime

@dag(
    dag_id="finn_ads_ingestion", 
    start_date=datetime(2024, 1, 1), 
    schedule_interval="0 0 * * *",
    catchup=False, 
)
def dag():
    get_ads_metadata_task() >> get_ads_content_task()

@task.virtualenv(
    task_id="get_ads_metadata",
    requirements=["./requirements.txt"],
    system_site_packages=False,
    venv_cache_path="/tmp/venv/cache/job_ads",
    pip_install_options=["--require-virtualenv", "--isolated"]
)
def get_ads_metadata_task():
    from finn_ingestion_lib import get_ads_metadata
    get_ads_metadata(occupation="0.23", published=1)

@task.virtualenv(
    task_id="get_ads_content", 
    requirements=["./requirements.txt"], 
    system_site_packages=False,
    venv_cache_path="/tmp/venv/cache/job_ads",
    pip_install_options=["--require-virtualenv", "--isolated"]
)
def get_ads_content_task():
    from finn_ingestion_lib import get_ads_content
    get_ads_content()

# @task.virtualenv(
#     task_id="transform_data",
#     requirements=["./requirements.txt"], 
#     system_site_packages=False,
# )
# def transform_data_task():
#     from finn_ingestion_lib import transform_data
#     transform_data()

dag()
