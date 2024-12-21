{{
    config(
        enabled=true,
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
    (doc->>'$.type')                    ::VARCHAR       AS "type",
    (doc->'$.id')                       ::UBIGINT       AS id,
    (doc->>'$.main_search_key')         ::VARCHAR       AS main_search_key,
    (doc->>'$.heading')                 ::VARCHAR       AS heading,
    (doc->>'$.location')                ::VARCHAR       AS "location",
    (doc->>'$.image.url')               ::VARCHAR       AS image_url,
    (doc->>'$.image.path')              ::VARCHAR       AS image_path,
    (doc->'$.image.height')             ::UBIGINT       AS image_height,
    (doc->'$.image.width')              ::UBIGINT       AS image_width,
    (doc->'$.image.aspect_ratio')       ::DOUBLE        AS image_aspect_ratio,
    (doc->'$.flags')                    ::VARCHAR[]     AS flags,
    TO_TIMESTAMP((doc->'$.timestamp')   ::UBIGINT/1000) AS "timestamp",
    (doc->'$.coordinates.lat')          ::DOUBLE        AS coordinates_lat,
    (doc->'$.coordinates.lon')          ::DOUBLE        AS coordinates_lon,
    (doc->'$.ad_type')                  ::UBIGINT       AS ad_type,
    (doc->'$.labels')                   ::STRUCT("id" VARCHAR, "text" VARCHAR, "type" VARCHAR)[] AS labels,
    (doc->>'$.canonical_url')           ::VARCHAR       AS canonical_url,
    (doc->'$.extras')                   ::VARCHAR[]     AS extras,
    (doc->'$.price.amount')             ::UBIGINT       AS price_amount,
    (doc->>'$.price.currency_code')     ::VARCHAR       AS price_currency_code,
    (doc->>'$.price.price_unit')        ::VARCHAR       AS price_price_unit,
    (doc->'$.year')                     ::UBIGINT       AS "year",
    (doc->'$.mileage')                  ::DOUBLE        AS mileage,
    (doc->>'$.dealer_segment')          ::VARCHAR       AS dealer_segment,
    (doc->'$.warranty_duration')        ::UBIGINT       AS warranty_duration,
    (doc->'$.service_documents')        ::VARCHAR[]     AS service_documents,
    (doc->>'$.regno')                   ::VARCHAR       AS regno,
    (doc->'$.ad_id')                    ::UBIGINT       AS ad_id,
    (doc->>'$.organisation_name')       ::VARCHAR       AS organisation_name,


    EXTRACT('YEAR' FROM "timestamp") AS _y,
    EXTRACT('MONTH' FROM "timestamp") AS _m,

    filename,

    current_timestamp AS ingestion_ts
    
FROM unnested_docs