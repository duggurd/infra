import uuid
from bs4 import BeautifulSoup as bs
import os
import pandas as pd
from datetime import datetime
import requests
from enum import Enum
import s3fs

# from utils.general import extract_nested_df_value


class AdType(Enum):
    POSITION = "position"
    OTHER = "other"


def get_url(url):
    resp = requests.get(url)
    print(f"[{resp.status_code}]", url)
    if not resp.ok:
        raise Exception(f"Error fetching data from {url}: {resp.content}")
    
    return resp


def get_finn_metdata_page(page, occupation, published:str = "1"):
    url = f"https://www.finn.no/api/search-qf?searchkey=SEARCH_ID_JOB_FULLTIME&occupation={occupation}&q=&published={published}&vertical=job&page={page}"
    resp = get_url(url)  
    return resp.json()

def get_ad_html(ad_url: str):
    resp = get_url(ad_url)
    content = resp.content
    # some ads contain null bytes
    content = content.replace("\x00".encode("utf-8"), "\uFFFD".encode("utf-8")) 
    return content


def parse_ad_html(html, ad_type: AdType):
    """
    ad_type: "position" | "other"
    """
    record = {}
    soup = bs(html, "html.parser")

    main_element = soup.find("main")
    
    """
    if ad_type == AdType.POSITION:
        article = soup.find("main").find_all("div", recursive=False)[1] # type: ignore

        general_info = article.find("dl")
        main_article = article.find("section")
        extra_info = article.find_all("div", recursive=False)[1]

        # parse general info
        general_info = {key.text.lower(): value.text for key, value in zip(
            general_info.find_all("dt"),
            general_info.find_all("dd"))
        }
        
        # parse extra info 
        extra_info = {key.text.lower().replace(" ", "_"): value.text for key, value in zip(
            extra_info.find_all("dt"),
            extra_info.find_all("dd"))
        }
            
        record.update(general_info)
        record.update(extra_info)

    else:
        general_info = soup.find_all("section")[1]
        main_article = soup.find_all("section")[2]
        job_provider_info = soup.find_all("section")[3]
        keywords_section = soup.find_all("section")[4]
        
        # keywords
        keywords = keywords_section.find("p").text if keywords_section.find("p") else None
        record["keywords"] = keywords
        
        # general info
        if job_provider_info.find("ul", recursive=False) is not None:
            for li in job_provider_info.find("ul", recursive=False):
                kv = li.text.split(":")
                key = kv[0].strip().lower().replace(" ", "_")
            
                value = kv[1].strip()
                record[key] = value
            
                # due_date
                work_title = general_info.find("div").find("h2").text
                record["job_title"] = work_title
    
    # ad content
    if main_article is not None:
        ad_content = main_article.find("div")
        
        if ad_content is not None:
            contents = []
            for object in ad_content:
                if object.name == "ul":
                    for li in object.find_all("li"):
                        contents.append(li.text)
                else:
                    contents.append(object.text)
            
            record["content"] = " ".join(contents)

    """
    record["html_main"] = str(main_element)

    return record

def get_job_ads_metadata(occupation, storage_options, published:str="1"):
    print("getting job ads metadata with published: ", published)
    # Bootstrapping for metadata
    data = get_finn_metdata_page(1, occupation, published)

    if data["docs"] is None or data["docs"] == []:
        print("No ads found")
        return 
    
    print(f"Found {len(data['docs'])} ads")
    df = pd.DataFrame(data["docs"])

    paging = data["metadata"]["paging"]

    if paging["last"] > 1:
        for page in range(1, paging["last"] + 1):
            data = get_finn_metdata_page(page, occupation, published)
            df = pd.concat([df, pd.DataFrame(data["docs"])])
    

    df = df[["id", "timestamp", "canonical_url"]]
    df["occupation"] = occupation
    df["ingeston_ts"] = datetime.now()

    # if "coordinates" in df.columns:
    #     extract_nested_df_value(df, "longitude", "coordinates", "lon")
    #     extract_nested_df_value(df, "latitude", "coordinates", "lat")
    

    # df = df.drop(columns=["coordinates", "logo", "labels", "flags", "image", "extras"], errors="ignore")

    # if "timestamp" in df.columns:
    #     df["timestamp"] = pd.to_datetime(df["timestamp"]/1000)
    # else: 
    #     df["timestamp"] = None
    # if "published" in df.columns:
    #     df["published"] = pd.to_datetime(df["published"]/1000)
    # else:
    #     df["published"] = None

    # if "deadline" in df.columns:
    #     df["deadline"] = pd.to_datetime(df["deadline"]/1000)
    # else:
    #     df["deadline"] = None

    df.to_parquet(
        f"s3://ingestion/finn/job_fulltime/ad_urls/{uuid.uuid1()}.zst.parquet",
        storage_options=storage_options,
        compression="zstd",
        index=False
    )

def get_ads_content(storage_options):
    # get urls of ads that havent been ingested yet
    all_ads_df = pd.read_parquet(
        "s3://ingestion/finn/job_fulltime/ad_urls",
        storage_options=storage_options,
        columns=["id", "canonical_url"]
    )

    try:
        ingested_ads_df = pd.read_parquet(
            "s3://ingestion/finn/job_fulltime/ad_html",
            storage_options=storage_options,
            columns=["id"]
        )

        new_ads = all_ads_df.merge(ingested_ads_df, how="left", on="id", indicator=True).query("_merge == 'left_only'")
    except FileNotFoundError:
        new_ads = all_ads_df

    ad_content_df = None

    for _, row in new_ads.iterrows():

        data = []
        canonical_url = row["canonical_url"]
        finnkode = row["id"]
   
        try:
            html = get_ad_html(canonical_url)
        except Exception as e:
            print(e)
            continue
        
        ad_type = AdType.POSITION if "position" in canonical_url else AdType.OTHER

        record = parse_ad_html(html, ad_type)

        record["id"] = finnkode
        record["ingestion_ts"] = datetime.now()

        data.append(record)

        if ad_content_df is None:
            ad_content_df = pd.DataFrame(data)
        else:
            ad_content_df = pd.concat([ad_content_df, pd.DataFrame(data)])

    if ad_content_df is not None:
        ad_content_df.to_parquet(
            f"s3://ingestion/finn/job_fulltime/ad_html/{uuid.uuid1()}.zst.parquet",
            storage_options=storage_options,
            compression="zstd",
            index=False
        )
    else:
        print("No new ad content, skipping ingestion")