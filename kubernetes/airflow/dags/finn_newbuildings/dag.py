from airflow.decorators import dag, task
from airflow.datasets import Dataset
from airflow.models.param import Param
import os

from datetime import datetime
import json

storage_options = {}
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

@dag(
    dag_id="finn_newbuildings_metadata_ingestion",
    schedule_interval="0 0 * * *", 
    start_date=datetime(2024, 1, 1), 
    catchup=False,
    max_active_runs=1,
    params = {
        "published_today": Param(True, type="boolean")
    }

)
def ingest_finn():
    # search_key = "NEWBUILDINGS"
    search_key = "SEARCH_ID_REALESTATE_NEWBUILDINGS"

    task_conf = {
        "requirements":[
            "pandas",
            "minio",
            "pyarrow",
            "s3fs",
            "requests"
        ],
        "system_site_packages":False,
        "venv_cache_path":"/tmp/venv/cache/finn_metadata",
        "pip_install_options":["--require-virtualenv", "--isolated"]
    }

    @task.virtualenv(
        task_id=f"ingest_{search_key}",
        **task_conf
    )
    def ingest(search_key, storage_options, published_today):
        print("ingesting: ", search_key, "with ", storage_options, published_today)
        
        import sys
        sys.path.append('/opt/airflow/dags/finn_newbuildings')
        sys.path.append('/opt/airflow/dags')
        from utils.minio_utils import connect_to_minio
        from finn_newbuildings.ingest import ingest_new_finn_ads
        client = connect_to_minio(storage_options)
        ingest_new_finn_ads(client, search_key, published_today=published_today)

    @task.virtualenv(
        task_id=f"transform_{search_key}",
        **task_conf
    )
    def transform(search_key, storage_options):
        print("transforming data")
        import sys
        sys.path.append('/opt/airflow/dags/finn_newbuildings')
        sys.path.append('/opt/airflow/dags')

        from utils.minio_utils import connect_to_minio
        from finn_newbuildings.transform import transform_finn_ads_metadata
        

        client = connect_to_minio(storage_options)
        transform_finn_ads_metadata(client, search_key, storage_options)

    ingest(search_key, storage_options=storage_options, published_today="{{ params.published_today }}") >> transform(search_key, storage_options=storage_options)

ingest_finn()