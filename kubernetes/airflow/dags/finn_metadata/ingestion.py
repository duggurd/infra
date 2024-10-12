import time
import requests

from utils.minio_utils import upload_json
from finn_metadata.constants import INGESTION_BUCKET


def ingest_new_finn_ads(client, search_key):
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
        bucket_name=INGESTION_BUCKET,
        object_name=f"finn/{search_key}/finn_ingestion__{search_key}_{time.time_ns()}.json"
    )

    print(f"ALL SUCCESS!: scraped '{page}' pages in total")
