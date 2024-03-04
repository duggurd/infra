from minio import Minio
import os
from io import BytesIO
import json

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

    if not client.bucket_exists(bucket_name):
        client.make_bucket(bucket_name)
        print(f"created bucket: {bucket_name}")
    else:
        print(f"bucket: {bucket_name} already exists")
    
    return client


def upload_json(json_dict: dict, client: Minio, bucket_name: str, object_name: str):

    json_string = json.dumps(json_dict)
    data = BytesIO(bytes(json_string, encoding="utf-8"))
                    
    print("uploading data")
    
    client.put_object(
        bucket_name, 
        object_name, 
        data, 
        -1, 
        part_size=20*1024*1024,
        content_type="text/plain"
    )

    print("successfull data upload")