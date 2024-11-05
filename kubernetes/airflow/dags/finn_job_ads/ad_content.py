from minio import Minio
import pandas as pd
from bs4 import BeautifulSoup as bs4
import io
from minio.commonconfig import Tags
from minio.datatypes import Object

from utils.minio_utils import (
    get_non_ingested_objects, 
    INGESTED_TAG
)

def extract_job_ad_attributes(main_html: str) -> dict:
    record = {}
    
    soup = bs4(main_html, features="html.parser")
    main_article = soup.find("section", {"aria-label": "Jobbdetaljer"})

    article_sections = main_article.find_all("section") # type: ignore

    
    article_header_section = article_sections[1]
    article_body_section = article_sections[2]
    article_about_section = article_sections[3]
    
    # keywords
    if len(article_sections) > 4:
        article_keywords_section = article_sections[4]
        if article_keywords_section.find("p"):
            article_keywords = article_keywords_section.find("p").text
        else:
            article_keywords = None    
    else:
        article_keywords = None


    # Header section
    header = article_header_section.find("h2").text
    employer = article_header_section.find("p").text
    header_attributes = {
        li.contents[0].lower(): li.find("span").text
        for li in article_header_section.find("ul").find_all("li")
    }

    # Main article content
    article_content = (article_body_section
        .get_text(separator="|", strip=True)
        .replace("\xa0", ""))

    # About employeer section
    about_section_text = article_about_section.get_text(separator="|", strip=True).replace("\xa0", "")
    about_section_attributes = {
        li.contents[0].text.replace(":", "").lower(): li.contents[-1].text 
        for li in article_about_section.find("ul", recursive=False).find_all("li")
    }

    
    record["article_header"] = header
    record["arbeidsgiver"] = employer
    record.update(header_attributes)
    record["article_content"] = article_content
    record["about_section_content"] = about_section_text
    record.update(about_section_attributes)
    record["keywords"] = article_keywords

    record["_debug_article_section-counts"] = len(article_sections)

    return record


def extract_positions_job_ad_attributes(main_html: str) -> dict:
    record = {}
    
    soup = bs4(main_html, features="html.parser")
    main_article = soup.find("main").find_all("div", recursive=False)[1] # type: ignore

    header = (main_article
        .find_next("div")
        .find_next("h1", recursive=False)
        .text
        .replace("\xa0", ""))

    upper_props = (main_article
        .find_next("div")
        .find_next("dl", recursive=False))
    
    header_attributes = {
        k.text.lower(): v.text 
        for k, v in zip(
            upper_props.find_all("dt"), 
            upper_props.find_all("dd")
        )
    }

    article_content = (main_article
        .find_next("div", recursive=False)
        .find_next("section", recursive=False)
        .get_text(separator="|", strip=True)
        .replace("\xa0", ""))

    bottom_props = (main_article
        .find_all("div", recursive=False)[1]
        .find_next("dl", recursive=False))
    
    about_section_attributes = {
        k.text.lower(): v.text
        for k, v in zip(
            bottom_props.find_all("dt"), 
            bottom_props.find_all("dd"))
    }


    record["article_header"] = header
    record.update(header_attributes)
    record["article_content"] = article_content
    record["about_section_content"] = None
    record.update(about_section_attributes)
    record["keywords"] = None

    record["_debug_article_section-counts"] = None

    return record


def add_content_columns_to_df(df: pd.DataFrame):
    assert "html_main" in df.columns
    data = []

    for row in df.itertuples():
        if row.job_type in ("fulltime", "management", "parttime"):
            record = extract_job_ad_attributes(row.html_main) # type: ignore
        elif row.job_type == "positions":
            record = extract_positions_job_ad_attributes(row.html_main) # type: ignore
        else:
            raise Exception(f"unsupported job type: {row.job_type}")
        
        record["id"] = row.id
        
        data.append(record)

    content_df = pd.DataFrame(data)

    df = df.merge(content_df, how="left")
    
    return df

def extract_ad_content_from_html(client: Minio, storage_options):

    # we only need to extract the new ad content files
    job_ad_html_df: pd.DataFrame|None = None

    objects = get_non_ingested_objects(client, bucket_name="ingestion", prefix="finn/job_fulltime/ad_html/")

    if objects == []:
        print("no new ad_html objects to ingest, skipping")
        return 0

    for object in objects:
        data = client.get_object(bucket_name="ingestion", object_name=object.object_name).data # type: ignore

        dataIo = io.BytesIO(data)
        df = pd.read_parquet(dataIo)

        if job_ad_html_df is None:
            job_ad_html_df = df
        else:
            job_ad_html_df = pd.concat([job_ad_html_df, df])


    # job_ad_html_df = pd.read_parquet(
    #     "s3://ingestion/finn/job_fulltime/ad_html/",
    #     storage_options=storage_options
    # )

    # we take all the urls to ensure overlap
    job_ad_urls_df = pd.read_parquet(
        "s3://ingestion/finn/job_fulltime/ad_urls/",
        storage_options=storage_options
    )


    # deduplciate content
    job_ad_html_dedup_df = (job_ad_html_df
        .groupby(["html_main", "id"]) # type: ignore
        .min()
        .reset_index())

    # Deduplicate so we only parse and store one copy of the content
    job_ad_urls_dedup_df = (job_ad_urls_df
        .groupby(["id", "canonical_url"])
        .agg(
            timestamp=("timestamp", "min"),
            occupation=("occupation", "first"),
            ingeston_ts_url=("ingeston_ts", "min")
        ).reset_index())

    
    # merge into one table that contains content and metadata, still only keep new content
    job_ad_df = job_ad_urls_dedup_df.merge(job_ad_html_dedup_df, how="inner", on="id") # type: ignore

    job_ad_df["job_type"] = job_ad_df["canonical_url"].apply(
        lambda x: x.replace("https://www.finn.no", "").split("/")[2]
    )

    job_ad_extracted_df = add_content_columns_to_df(job_ad_df)


    job_ad_extracted_df["timestamp"] = pd.to_datetime(job_ad_extracted_df["timestamp"], unit="ms")
    job_ad_extracted_df["y"] = job_ad_extracted_df["timestamp"].dt.year
    job_ad_extracted_df["m"] = job_ad_extracted_df["timestamp"].dt.month


    job_ad_extracted_df.to_parquet(
        "s3://bronze/finn/job_fulltime/ad_content/",
        storage_options=storage_options,
        engine="pyarrow",
        compression="zstd",
        partition_cols=["y", "m"]
    )

    # finally mark ingestion sources as ingested

    for object in objects:
        print(f"tagging {object.object_name}")

        # tag source file as ingested
        tags = Tags()
        tags[INGESTED_TAG] = "true"

        client.set_object_tags(
            bucket_name="ingestion",
            object_name=object.object_name, # type: ignore
            tags=tags
        )

        print(f"successfully tagged {object.object_name}")