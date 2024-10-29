from airflow.hooks.base_hook import BaseHook

from minio import Minio
from minio.datatypes import Object
from io import BytesIO
import json
import pandas

def connect_to_minio() -> Minio:
    connection = BaseHook.get_connection("homelab-minio")
    minio_endpoint = connection.host
    minio_access_key = connection.login
    minio_secret_key = connection.password

    client = Minio(
        endpoint=minio_endpoint,
        access_key=minio_access_key,
        secret_key=minio_secret_key,
        secure=False
    )
    
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