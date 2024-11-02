from minio import Minio
from minio.datatypes import Object
from io import BytesIO
import json
import pandas
import gzip

def connect_to_minio(storage_options: dict) -> Minio:
    minio_endpoint = storage_options["endpoint_url"]
    minio_access_key = storage_options["key"]
    minio_secret_key = storage_options["secret"]

    client = Minio(
        endpoint=minio_endpoint.replace("http://", ""),
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

def upload_json(json_dict: dict, client: Minio, bucket_name: str, object_name: str, compress_gzip=False):

    json_string = json.dumps(json_dict)
    if compress_gzip:
        compressed_json_string = gzip.compress(json_string.encode("utf-8"))
        data = BytesIO(compressed_json_string)
        object_name += ".gz"
    else:
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