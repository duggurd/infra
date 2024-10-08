from httpx import head
from minio import Minio
from minio.datatypes import Object
import os
from io import BytesIO
import json

import pandas

def connect_to_minio(bucket_name) -> Minio:
    minio_access_key = os.environ.get("MINIO_ACCESS_KEY")
    minio_secret_key = os.environ.get("MINIO_SECRET_KEY")
    minio_endpoint = os.environ.get("MINIO_ENDPOINT")

    assert minio_access_key is not None, "Missing minio access key"
    assert minio_secret_key is not None, "Missing minio secret key"
    assert minio_endpoint is not None, "Missing minio endpoint variable"
    assert bucket_name is not None, "Missing bucket name variable"

    print("connecting to minio")

    client = Minio(
        endpoint=minio_endpoint,
        access_key=minio_access_key,
        secret_key=minio_secret_key,
        secure=False
    )

    print("Connected to minio")


    # Need to move this outside of this function
    if not client.bucket_exists(bucket_name):
        client.make_bucket(bucket_name)
        print(f"created bucket: {bucket_name}")
    else:
        print(f"bucket: {bucket_name} already exists")

    RAW_BUCKET_NAME="raw"
    if not client.bucket_exists(RAW_BUCKET_NAME):
        client.make_bucket(RAW_BUCKET_NAME)
        print(f"created bucket: {RAW_BUCKET_NAME}")
    else:
        print(f"bucket: {RAW_BUCKET_NAME} already exists")
    
    return client


def upload_csv_df(df: pandas.DataFrame, client: Minio, bucket_name: str, object_name: str):
    data = BytesIO()
    
    df.to_csv(data, index=False, header=True)

    print("uploading CSV data to MinIO")

    client.put_object(
        bucket_name=bucket_name,
        object_name=object_name,
        data=data,
        length=-1,
        part_size=20*1024*1024,
        content_type="text/csv",
    )

    print("successfull data upload to MinIO")

def upload_json(json_dict: dict, client: Minio, bucket_name: str, object_name: str):

    json_string = json.dumps(json_dict)
    data = BytesIO(bytes(json_string, encoding="utf-8"))
                    
    print("uploading data")
    
    client.put_object(
        bucket_name=bucket_name, 
        object_name=object_name, 
        data=data, 
        length=-1, 
        part_size=20*1024*1024,
        content_type="text/plain"
    )

    print("successfull JSON data upload to MinIO")



INGESTED_TAG = "ingested"
def get_non_ingested_objects(client: Minio, bucket_name: str, prefix: str) -> list[Object]:
    """
    Returns a list of objects in the bucket that are not ingested
    """
    objects = client.list_objects(bucket_name, prefix=prefix, include_user_meta=True)
    non_ingested = []
    
    for object in objects:
        if object.tags is None or INGESTED_TAG not in object.tags: 
            non_ingested.append(object)

    return non_ingested