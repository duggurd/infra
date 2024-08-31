from minio import Minio
from airflow.decorators import dag, task
from airflow.datasets import Dataset

from datetime import datetime
import requests
import json
import os
import time
import pandas as pd
import io
from minio.commonconfig import Tags
from minio.datatypes import Object

from utils.minio_utils import (
    connect_to_minio, 
    upload_json, 
    get_non_ingested_objects, 
    INGESTED_TAG
)
from finn_metadata.metadata_schemas import (
    SEARCH_ID_REALESTATE_LETTINGS, 
    SEARCH_ID_REALESTATE_HOMES, 
    SEARCH_ID_CAR_USED, 
    SEARCH_ID_JOB_FULLTIME
)

with open("/opt/airflow/dags/finn_metadata/finn_ingestion_config.json") as f:
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
        object_name=f"finn/{search_key}/finn_ingestion__{search_key}_{time.time_ns()}.json"
    )

    print(f"ALL SUCCESS!: scraped '{page}' pages in total")


def transform_finn_ads_metadata_file(client: Minio, search_key: str, ingest_object: Object):
    print(f"working on {ingest_object.object_name}")

    assert ingest_object.object_name is not None, f"missing object_name, somehow!"

    data = client.get_object(bucket_name="ingestion", object_name=ingest_object.object_name).json()

    df = pd.DataFrame(data["docs"])

    # main transformations
    print("main transformation")
    if search_key == "SEARCH_ID_REALESTATE_LETTINGS":
        df = SEARCH_ID_REALESTATE_LETTINGS(df)

    elif search_key == "SEARCH_ID_REALESTATE_HOMES":
        df = SEARCH_ID_REALESTATE_HOMES(df)

    elif search_key == "SEARCH_ID_CAR_USED":
        df = SEARCH_ID_CAR_USED(df)

    elif search_key == "SEARCH_ID_JOB_FULLTIME":
        df = SEARCH_ID_JOB_FULLTIME(df)
    
    print("main transformation completed")

    df["source_file"] = ingest_object.object_name

    # all good, we upload the file and mark the original file as ingested
    
    print("creating parquet buffer")
    parquet_buffer = io.BytesIO()
    
    # this failed to raise and excepption when no parquet pacakge was available
    try:
        df.to_parquet(parquet_buffer, index=False, compression="gzip")
    except Exception as e:
        print(e)
        raise e

    parquet_buffer.seek(0)

    raw_object_name = f"finn/finn_ads_metadata/{search_key}/finn_ads_metadata__{search_key}_{time.time_ns()}.gzip.parquet"

    print(f"uploading {raw_object_name}")
    
    # throws if failed
    client.put_object(
        bucket_name="raw",
        object_name=raw_object_name,
        data=parquet_buffer,
        length=-1,
        part_size=20*1024*1024,
        content_type="application/vnd.apache.parquet",
    )
    print(f"successfully uploaded {raw_object_name}")

    # assert object was created successfully, then tag original source object
    

    stat = client.stat_object(bucket_name="raw", object_name=raw_object_name)

    if stat.size is not None and stat.size > 0:        
        # cleanup
        # remove the empty object, if it was created
        try:
            client.remove_object("raw", raw_object_name)
        except Exception as e:
            print(e)
        
        raise Exception(f"failed to upload {raw_object_name}, size is 0")

    print(f"tagging {ingest_object.object_name}")

    # tag source file as ingested
    tags = Tags()
    tags[INGESTED_TAG] = "true"

    client.set_object_tags(
        bucket_name="ingestion",
        object_name=ingest_object.object_name,
        tags=tags
    )

    print(f"successfully tagged {ingest_object.object_name}")


def transform_finn_ads_metadata(client: Minio, search_key):

    print("transforming data")


    # ingest and transform non ingested files
    # Treat upload and tagging as a single transaction if either fails, roll back

    objects = get_non_ingested_objects(client, "ingestion", f"finn/{search_key}/")

    if objects != []:
        print(f"Transforming {[object.object_name for object in objects]}")
    else:
        print("No objects to transform, skipping")
        return
    
    for ingest_object in objects:
        transform_finn_ads_metadata_file(client, search_key, ingest_object)

@dag(
    dag_id="finn_metadata_ingestion",
    schedule_interval="0 0 * * *", 
    start_date=datetime(2024, 1, 1), 
    catchup=False,
    max_active_runs=1
)
def ingest_finn():
    bucket_name = os.environ["INGESTION_BUCKET_NAME"]
    client = connect_to_minio(bucket_name)

    for search_key in search_keys:
        @task(task_id=f"ingest_{search_key}")
        def ingest(search_key):
            ingest_new_finn_ads(client, search_key, bucket_name)

        @task(task_id=f"transform_{search_key}")
        def transform(search_key):
            transform_finn_ads_metadata(client, search_key)

        ingest(search_key) >> transform(search_key)

ingest_finn()