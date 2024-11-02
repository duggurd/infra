from minio import Minio

import pandas as pd
import os
from minio.commonconfig import Tags
from minio.datatypes import Object
import gzip
import s3fs
import json

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

def transform_finn_ads_metadata_file(client: Minio, search_key: str, ingest_object: Object, storage_options):
    object_name = ingest_object.object_name
    print(f"working on {object_name}")

    assert object_name is not None, f"missing object_name, somehow!"

    data = client.get_object(bucket_name=INGESTION_BUCKET, object_name=object_name).data

    if ".gz" in object_name:
        decompressed = gzip.decompress(data)
        json_data = json.loads(decompressed)
    else:
        json_data = json.loads(data)

    df = pd.DataFrame(json_data["docs"])

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
    table_path = f"s3://{BRONZE_BUCKET}/finn/{table_name}/ad_metadata/"

    df.to_parquet(
        table_path,
        storage_options=storage_options,
        index=False, 
        compression="zstd", 
        partition_cols=["y", "m"]
    )

    # all good, mark the original file as ingested
    print(f"tagging {ingest_object.object_name}")

    # tag source file as ingested
    tags = Tags()
    tags[INGESTED_TAG] = "true"

    client.set_object_tags(
        bucket_name=INGESTION_BUCKET,
        object_name=object_name,
        tags=tags
    )

    print(f"successfully tagged {ingest_object.object_name}")


def transform_finn_ads_metadata(client: Minio, search_key, storage_options):

    print("transforming data")


    # ingest and transform non ingested files
    # Treat upload and tagging as a single transaction if either fails, roll back

    category = search_key.replace("SEARCH_ID_", "").lower() 
    prefix = f"finn/{category}/ad_metadata/"

    objects = get_non_ingested_objects(client, bucket_name="ingestion", prefix=prefix)

    if objects != []:
        print(f"Transforming {[object.object_name for object in objects]}")
    else:
        print("No objects to transform, skipping")
        return
    
    for ingest_object in objects:
        transform_finn_ads_metadata_file(client, search_key, ingest_object, storage_options)