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
    (doc->>"$.type")                              ::VARCHAR AS type,
    (doc->>"$.id")                                ::VARCHAR AS id,
    (doc->>"$.main_search_key")                   ::VARCHAR AS main_search_key,
    (doc->>"$.heading")                           ::VARCHAR AS heading,
    (doc->>"$.location")                          ::VARCHAR AS location,
    (doc->>"$.image.url")                         ::VARCHAR AS image_url,
    (doc->>"$.image.path")                        ::VARCHAR AS image_path,
    (doc->"$.image.height")                       ::UBIGINT AS image_height,
    (doc->"$.image.width")                        ::UBIGINT AS image_width,
    (doc->"$.image.aspect_ratio")                 ::DOUBLE AS image_aspect_ratio,
    (doc->"$.flags")                              ::VARCHAR[] AS flags,
    (doc->"$.styling")                            ::VARCHAR[] AS styling,
    TO_TIMESTAMP((doc->'$.timestamp')             ::UBIGINT/1000) AS "timestamp",
    (doc->"$.labels")                             ::STRUCT("id" VARCHAR,"text" VARCHAR,"type" VARCHAR)[] AS labels,
    (doc->>"$.canonical_url")                     ::VARCHAR AS canonical_url,
    (doc->"$.extras")                             ::VARCHAR[] AS extras,
    (doc->"$.price_suggestion.amount")            ::UBIGINT AS price_suggestion_amount,
    (doc->>"$.price_suggestion.currency_code")    ::VARCHAR AS price_suggestion_currency_code,
    (doc->>"$.price_suggestion.price_unit")       ::VARCHAR AS price_suggestion_price_unit,
    (doc->"$.price_total.amount")                 ::UBIGINT AS price_total_amount,
    (doc->>"$.price_total.currency_code")         ::VARCHAR AS price_total_currency_code,
    (doc->>"$.price_total.price_unit")            ::VARCHAR AS price_total_price_unit,
    (doc->"$.price_shared_cost.amount")           ::UBIGINT AS price_shared_cost_amount,
    (doc->>"$.price_shared_cost.currency_code")   ::VARCHAR AS price_shared_cost_currency_code,
    (doc->>"$.price_shared_cost.price_unit")      ::VARCHAR AS price_shared_cost_price_unit,
    (doc->"$.area_range.size_from")               ::UBIGINT AS area_range_size_from,
    (doc->"$.area_range.size_to")                 ::UBIGINT AS area_range_size_to,
    (doc->>"$.area_range.unit")                   ::VARCHAR AS area_range_unit,
    (doc->>"$.area_range.description")            ::VARCHAR AS area_range_description,
    (doc->"$.area_plot.size")                     ::UBIGINT AS area_plot_size,
    (doc->>"$.area_plot.unit")                    ::VARCHAR AS area_plot_unit,
    (doc->>"$.area_plot.description")             ::VARCHAR AS area_plot_description,
    (doc->>>"$.local_area_name")                  ::VARCHAR AS local_area_name,
    (doc->"$.number_of_bedrooms")                 ::UBIGINT AS number_of_bedrooms,
    (doc->>"$.property_type_description")         ::VARCHAR AS property_type_description,
    (doc->"$.viewing_times")                      ::VARCHAR[] AS viewing_times,
    (doc->"$.coordinates.lat")                    ::DOUBLE AS coordinates_lat,
    (doc->"$.coordinates.lon")                    ::DOUBLE AS coordinates_lon,
    (doc->"$.ad_type")                            ::UBIGINT AS ad_type,
    (doc->"$.image_urls")                         ::VARCHAR[] AS image_urls,
    (doc->>"$.furnished_state")                   ::VARCHAR AS furnished_state,
    (doc->"$.ad_id")                              ::UBIGINT AS ad_id,
    (doc->>"$.logo.url")                          ::VARCHAR AS logo_url,
    (doc->>"$.logo.path")                         ::VARCHAR AS logo_path,
    (doc->>"$.organisation_name")                 ::VARCHAR AS organisation_name,
    (doc->"$.area.size")                          ::UBIGINT AS area_size,
    (doc->>"$.area.unit")                         ::VARCHAR AS area_unit,
    (doc->>"$.area.description")                  ::VARCHAR AS area_description,

    EXTRACT('YEAR' FROM "timestamp") AS _y,
    EXTRACT('MONTH' FROM "timestamp") AS _m,

    filename,

    current_timestamp AS ingestion_ts

FROM unnested_docs