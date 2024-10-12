from airflow.decorators import dag, task
from airflow.datasets import Dataset

from datetime import datetime
import json

from utils.minio_utils import connect_to_minio

with open("/opt/airflow/dags/finn_metadata/finn_ingestion_config.json") as f:
    search_keys = json.load(f)["search_keys"]

datasets = [Dataset(search_key) for search_key in search_keys]

@dag(
    dag_id="finn_metadata_ingestion",
    schedule_interval="0 0 * * *", 
    start_date=datetime(2024, 1, 1), 
    catchup=False,
    max_active_runs=1
)
def ingest_finn():

    for search_key in search_keys:
        @task(task_id=f"ingest_{search_key}")
        def ingest(search_key):
            from finn_metadata.ingest import ingest_new_finn_ads
            client = connect_to_minio()
            ingest_new_finn_ads(client, search_key)
    
        @task.virtualenv(
            task_id=f"transform_{search_key}",
            requirements=[
                "pandas",
                "minio",
                "pyarrow",
                "s3fs"
            ],
            system_site_packages=False,
            venv_cache_path="/tmp/venv/cache/finn_metadata",
            pip_install_options=["--require-virtualenv", "--isolated"]
        )
        def transform(search_key):
            print("transforming data")
            import sys
            sys.path.append('/opt/airflow/dags/finn_metadata')
            sys.path.append('/opt/airflow/dags')

            from utils.minio_utils import connect_to_minio
            from finn_metadata.transform import transform_finn_ads_metadata
            client = connect_to_minio()
            transform_finn_ads_metadata(client, search_key)

        ingest(search_key) >> transform(search_key)

ingest_finn()