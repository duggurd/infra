from urllib import parse
from datetime import datetime
import json
import time
import os
import requests

from utils.minio_utils import connect_to_minio, upload_json

from airflow.decorators import dag, task

class Category:
    bakery = "Bakeri"
    bakerywares = "Bakevarer og kjeks"
    kids_products = "Barneprodukter"
    flowers_plants = "Blomster og planter"
    desserts = "Dessert og iskrem"
    drinks = "Drikke"
    animals = "Dyr"
    fish = "Fisk & skalldyr"
    fruits_veggies = "Frukt & grønt"
    home = "Hus & hjem"
    kiosk_wares = "Kioskvarer"
    meat = "Kjøtt"
    chicken = "Kylling og fjærkre"
    dairy_egg = "Meieri & egg"
    dinner = "Middag"
    dinner_addition = "Middagstilbehør"
    cheese = "Ost"
    personal = "Personlige artikler"
    toppings = "Pålegg & frokost"
    snacks_candy = "Snacks & godteri"


root_url = "https://platform-rest-prod.ngdata.no/api"

def url_get_stores(chain_id: int):
    URL = f"{root_url}/handoveroptions/{chain_id}"
    
    return URL

def url_products(
        page: str, 
        chain_id: str = None,
        store_id: str = None,
        category: Category = None, 
        page_size: str = "50", 
    ):
    
    relative = f"/products/{chain_id}"
    
    if chain_id is None and store_id is not None:
        raise Exception("To use store_id, must also have a chain_id")
    else: 
        relative += f"/{store_id}" if store_id is not None else ""

    params = {
        "page": page,
        "page_size": page_size,
        "full_response": "true",
        "fieldset": "maximal",
        "facets": "Category",
        "facet": f"Categories:{category}" if category else "",
        "showNotForSale": "true"
    }

    encoded_params = parse.urlencode(params)
    
    URL = f"{root_url}{relative}?{encoded_params}"
    
    return URL

def url_filter_options(chain_id: int):
    
    params = {
        "page_size": "0",
        "full_response": "true"
    }
    
    encoded_params = parse.urlencode(params)

    URL = f"{root_url}/products/{chain_id}?{encoded_params}"

    return URL

def decode_b64_secret_from_env(env_name):
    from base64 import b64decode
    secret = os.environ.get(env_name)
    assert env_name is not None, f"{env_name} not found!"

    return str(b64decode(secret), encoding="utf-8")

@dag(
    dag_id="food_price_scraper",
    schedule="0 0 1 * *",
    start_date=datetime(2024, 1, 1),
    catchup=False
)
def scrape_food_prices():
    bucket_name = os.environ["INGESTION_BUCKET_NAME"]
    
    client = connect_to_minio(bucket_name)
    
    # TODO: get from and store in minio instead
    with open("/opt/airflow/dags/food_price_scraper_config.json") as f:
        configs = json.load(f)

    print("Config: ", configs)

    for config in configs["configs"]:
        chain_id = config["chain_id"]
        for category in config["categories"]:
            category_name = Category().__getattribute__(category)

            @task(task_id=f"scrape_food_prices_{chain_id}_{category}")
            def scrape_food_price():
                
                object_name = f"food_prices__{chain_id}_{category}_{time.time_ns()}.json"

                URL = url_products(
                    page="1", 
                    chain_id=chain_id,
                    category=category_name,
                    page_size="9999",
                )

                print(f"Scraping url: {URL}")
                
                resp = requests.get(URL)

                if resp.ok:
                    print("successfull request")
                    
                    upload_json(
                        resp.json(), 
                        client, 
                        bucket_name, 
                        object_name
                    )

                else: 
                    raise Exception(f"Request to {URL} failed, error code: {resp.status_code}, message: {resp.content}")
    
            scrape_food_price()

scrape_food_prices()