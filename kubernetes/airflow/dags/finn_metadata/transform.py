from minio import Minio

import time
import pandas as pd
import io
from minio.commonconfig import Tags
from minio.datatypes import Object

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

from finn_metadata.constants import INGESTION_BUCKET, RAW_BUCKET
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
        bucket_name=RAW_BUCKET,
        object_name=raw_object_name,
        data=parquet_buffer,
        length=-1,
        part_size=20*1024*1024,
        content_type="application/vnd.apache.parquet",
    )
    print(f"successfully uploaded {raw_object_name}")

    # assert object was created successfully, then tag original source object
    
    stat = client.stat_object(bucket_name=RAW_BUCKET, object_name=raw_object_name)

    if stat.size is None or stat.size == 0:        
        # cleanup
        # remove the empty object, if it was created
        try:
            client.remove_object(bucket_name=RAW_BUCKET, object_name=raw_object_name)
        except Exception as e:
            print(e)
        
        raise Exception(f"failed to upload {raw_object_name}, size is 0")

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