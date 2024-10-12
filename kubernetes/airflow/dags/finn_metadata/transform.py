from minio import Minio

import time
import pandas as pd
import io
import os
from minio.commonconfig import Tags
from minio.datatypes import Object
import s3fs

from utils.minio_utils import (
    get_non_ingested_objects, 
    INGESTED_TAG
)

from finn_metadata.metadata_schemas import (
    SEARCH_ID_REALESTATE_LETTINGS, 
    SEARCH_ID_REALESTATE_HOMES, 
    SEARCH_ID_CAR_USED, 
    SEARCH_ID_JOB_FULLTIME
)

from finn_metadata.constants import INGESTION_BUCKET, RAW_BUCKET, BRONZE_BUCKET

def transform_finn_ads_metadata_file(client: Minio, search_key: str, ingest_object: Object):
    print(f"working on {ingest_object.object_name}")

    assert ingest_object.object_name is not None, f"missing object_name, somehow!"

    data = client.get_object(bucket_name=INGESTION_BUCKET, object_name=ingest_object.object_name).json()

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

    table_name = search_key.replace("SEARCH_ID_", "").lower()
    table_path = f"s3://{BRONZE_BUCKET}/finn/ads/{table_name}"

    storage_options = {
        "key": os.environ.get("MINIO_ACCESS_KEY"),
        "secret": os.environ.get("MINIO_SECRET_KEY"),
        "endpoint_url":  f"http://{os.environ.get('MINIO_ENDPOINT')}"
    }

    df.to_parquet(
        table_path,
        storage_options=storage_options,
        index=False, 
        compression="gzip", 
        partition_cols=["year", "month"]
    )

    # all good, mark the original file as ingested
    print(f"tagging {ingest_object.object_name}")

    # tag source file as ingested
    tags = Tags()
    tags[INGESTED_TAG] = "true"

    client.set_object_tags(
        bucket_name=INGESTION_BUCKET,
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