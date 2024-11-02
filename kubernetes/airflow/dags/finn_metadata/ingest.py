import uuid
import requests

from utils.minio_utils import upload_json
from finn_metadata.constants import INGESTION_BUCKET


def ingest_new_finn_ads(client, search_key, published_today="True"):
    page = 1
    max_page = 1

    published = "" if published_today == "False" or published_today == False else "1"
    
    data = {"docs": []}
    while page < 51:

        URL = f"https://www.finn.no/api/search-qf?searchkey={search_key}&published={published}&page={page}&vertical=1"
        
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

    category = search_key.replace("SEARCH_ID_", "").lower()

    upload_json(
        json_dict=data,
        client=client,
        bucket_name=INGESTION_BUCKET,
        object_name=f"finn/{category}/ad_metadata/{uuid.uuid1()}.json",
        compress_gzip=True
    )

    print(f"ALL SUCCESS!: scraped '{page}' pages in total")
