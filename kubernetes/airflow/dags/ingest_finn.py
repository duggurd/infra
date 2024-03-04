from airflow.decorators import dag, task
from datetime import datetime
# from airflow.hooks.base import BaseHook
import requests
import json
import os
import time

from utils.minio_utils import connect_to_minio, upload_json


from airflow.datasets import Dataset

with open("/opt/airflow/dags/finn_ingestion_config.json") as f:
    search_keys = json.load(f)["search_keys"]


datasets = [Dataset(search_key) for search_key in search_keys]

def ingest_new_finn_ads(client, search_key, bucket_name):
    page = 1
    max_page = 1
    
    data = {"docs": []}
    while page < 51:

        URL = f"https://www.finn.no/api/search-qf?searchkey={search_key}&published=1&page={page}&vertical=1"
        
        print(f"getting data from finn: {URL}")
        
        resp = requests.get(URL)
        
        if resp.ok:
            j = resp.json()
            max_page = j["metadata"]["paging"]["last"]
            data["docs"].extend(j["docs"])

        else:
            raise Exception(f"Failed to get data from finn: {resp.content}")
        
        if page >= max_page:
            break

        page+=1
    
    print("uploading data to minio")

    upload_json(
        json_dict=data,
        client=client,
        bucket_name=bucket_name,
        object_name=f"finn_ingestion__{search_key}_{time.time_ns()}.json"
    )

    print(f"ALL SUCCESS!: scraped '{page}' pages in total")

@dag(
    dag_id="finn_ingestion",
    schedule_interval="0 0 * * *", 
    start_date=datetime(2024, 1, 1), 
    catchup=False, 
)
def ingest_finn():
    bucket_name = os.environ["INGESTION_BUCKET_NAME"]
    client = connect_to_minio(bucket_name)

    for search_key in search_keys:
        @task(task_id=search_key)
        def extract(search_key):
            ingest_new_finn_ads(client, search_key, bucket_name)

        extract(search_key)

ingest_finn()