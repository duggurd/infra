{{
    config(
        enabled=false,
        materialized="external",
        location="s3://bronze/duckdb/{{ this.table }}/ad_metadata",
        format="parquet",
        options={
            "compression": "zstd",
            "partition_by": "(_y, _m)",
            "format": "parquet",
            "append": true,
            "filename_pattern": "'{uuid}.zst'"
        }
    )
}}

WITH unnested_docs AS (
    SELECT
        unnest(docs) as doc,
        filename

    FROM {{ source("finn_ad_metadata", this.table) }}
)

SELECT
    (doc->>"$.type")                    ::VARCHAR AS type,
    (doc->"$.id")                       ::UBIGINT AS id,
    (doc->>"$.main_search_key")         ::VARCHAR AS main_search_key,
    (doc->>"$.heading")                 ::VARCHAR AS heading,
    (doc->>"$.location")                ::VARCHAR AS location,
    (doc->"$.flags")                    ::VARCHAR[] AS flags,
    TO_TIMESTAMP((doc->'$.timestamp')   ::UBIGINT/1000) AS "timestamp",
    (doc->"$.coordinates.lat")          ::DOUBLE AS coordinates_lat,
    (doc->"$.coordinates.lon")          ::DOUBLE AS coordinates_lon,
    (doc->"$.ad_type")                  ::UBIGINT AS ad_type,
    (doc->"$.labels")                   ::STRUCT("id" VARCHAR,"text" VARCHAR,"type" VARCHAR)[] AS labels,
    (doc->>"$.canonical_url")           ::VARCHAR AS canonical_url,
    (doc->"$.extras")                   ::VARCHAR[] AS extras,
    (doc->>"$.logo.url")                ::VARCHAR AS logo_url,
    (doc->>"$.logo.path")               ::VARCHAR AS logo_path,
    (doc->>"$.job_title")               ::VARCHAR AS job_title,
    TO_TIMESTAMP((doc->'$.deadline')    ::UBIGINT/1000) AS deadline,
    TO_TIMESTAMP((doc->'$.published')   ::UBIGINT/1000) AS published,
    (doc->>"$.company_name")            ::VARCHAR AS company_name,
    (doc->"$.no_of_positions")          ::UBIGINT AS no_of_positions,
    (doc->"$.ad_id")                    ::UBIGINT AS ad_id,
    (doc->>"$.image.url")               ::VARCHAR AS image_url,
    (doc->>"$.image.path")              ::VARCHAR AS image_path,

    EXTRACT('YEAR' FROM "timestamp") AS _y,
    EXTRACT('MONTH' FROM "timestamp") AS _m,

    filename,

    current_timestamp AS ingestion_ts

FROM unnested_docs