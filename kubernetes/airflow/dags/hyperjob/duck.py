import duckdb
from datetime import datetime

def setup_duckdb_connection(database, minio_connection):
    
    print("setting up duckdb connection")
    database.execute(f"""
        SET s3_access_key_id = '{minio_connection["key"]}';
        SET s3_secret_access_key = '{minio_connection["secret"]}';
        SET s3_endpoint = '{minio_connection["host"]}';
        SET s3_url_style='path';
        SET s3_use_ssl = false;

        INSTALL httpfs;
        LOAD httpfs;

        INSTALL postgres;
        LOAD postgres;

    """)
    
def get_database(minio_connection):
    assert minio_connection is not None

    database = duckdb.connect("/tmp/hyperjob.db")
    setup_duckdb_connection(database, minio_connection)
    return database

def ingest_ads_content(database, start_date: str|None = None):

    print("ingesting ads content")
    database.execute("""
        CREATE OR REPLACE TABLE ads_content AS (
            SELECT
                id as ad_id,
                article_header,
                article_content,
                keywords,
                timestamp,
                job_type,
                sektor,
                bransje,
                stillingsfunksjon
    
            FROM read_parquet(
                's3://bronze/finn/job_fulltime/ad_content/y=2025/m=6/*',  
                union_by_name=true
            )
        );
    """)


def ingest_ads_metadata(database, start_date: str|None = None):

    print("ingesting ads metadata")

    database.execute("""
        CREATE OR REPLACE TABLE ads_metadata AS (
            SELECT
                cast(id as varchar) as ad_id,
                canonical_url,
                heading,
                location,
                job_title,
                company_name,
                no_of_positions,
                timestamp,
                published
            FROM read_parquet(
                's3://bronze/finn/job_fulltime/ad_metadata/y=2025/m=6/*',
                union_by_name=true
            )
        );
    """)

def ingest_stopwords(database):
    print("ingesting stopwords")
    database.execute("""
        create or replace table stopwords as (
            select *
            from read_parquet(
                's3://bronze/stopwords/**'
            )
        );
    """)

def cleanup_ads_content(database):
    print("cleaning up ads content")
    # cleanup and push to postgres
    
    database.execute("""
        create or replace table ads_content_cleaned as (
            select 
                cast(ad_id as varchar) as ad_id,
                any_value(article_header) as article_header,
                any_value(regexp_replace(regexp_replace(lower(article_content), '[|!\?:;\.\.\\/\-%&]', ' ', 'g'), '\s+', ' ', 'g'))  as article_content,
                any_value(keywords) as keywords,
                any_value(timestamp) as timestamp,
                any_value(job_type) as job_type,
                any_value(sektor) as sektor,
                any_value(bransje) as bransje,
                any_value(stillingsfunksjon) as stillingsfunksjon

            from ads_content
            group by ad_id
        );
    """)


def cleanup_ads_metadata(database):
    print("cleaning up ads metadata")
    database.execute("""
        CREATE OR REPLACE TABLE ads_metadata_cleaned AS (
            SELECT
                cast(ad_id as varchar) as ad_id,
                any_value(canonical_url) as canonical_url,
                any_value(heading) as heading,
                any_value(location) as location,
                any_value(job_title) as job_title,
                any_value(company_name) as company_name,
                any_value(no_of_positions) as no_of_positions,
                any_value(coalesce(timestamp, published)) as published

            FROM ads_metadata

            GROUP BY ad_id
        );
    """)

def join_ads_content_and_metadata(database):
    print("joining ads content and metadata")
    database.execute("""
        CREATE OR REPLACE TABLE ads_content_and_metadata AS (
            SELECT
                m.ad_id,
                m.canonical_url,
                m.heading,
                m.location,
                m.job_title,
                m.company_name,
                m.no_of_positions,
                m.published,

                c.article_header,
                c.article_content,
                regexp_extract_all(
                     lower(c.keywords),
                     '(\w+)'
                ) as keywords,
                c.timestamp,
                c.job_type,
                c.sektor,
                c.bransje,
                split(lower(c.stillingsfunksjon), '/') as stillingsfunksjon

            FROM ads_metadata_cleaned as m
            left JOIN ads_content_cleaned as c
                ON c.ad_id = m.ad_id
        );
    """)

def create_keywords(database):
    print("creating keywords")
    database.execute("""
        create or replace table keywords as (
            with keywords as (
                select
                    unnest(keywords) as keyword
                from ads_content_and_metadata
                group by keyword
            )

            select
                row_number() over (order by keyword) as id,
                keyword
            from keywords
        );
    """)

def create_employers(database):
    print("creating employers")
    database.execute("""
        create or replace table employers as (
            with employers as (
                select
                    company_name,
                    any_value(bransje) as bransje,
                    any_value(sektor) as sektor

                from ads_content_and_metadata
                    
                group by company_name
            )

            select
                row_number() over (order by company_name) as id,
                company_name,
                bransje,
                sektor
            from employers
        );
    """)

def create_stillingsfunksjon(database):
    print("creating stillingsfunksjon")
    database.execute("""
        create or replace table stillingsfunksjon as (
            with stillingsfunksjon as (
                select
                    distinct
                    unnest(stillingsfunksjon) as stillingsfunksjon
                from ads_content_and_metadata
            )

            select
                row_number() over (order by stillingsfunksjon) as id,
                stillingsfunksjon

            from stillingsfunksjon
        );
    """)

def create_stillingsfunksjon_ads_bridge(database):
    print("creating stillingsfunksjon ads bridge")
    database.execute("""
        create or replace table stillingsfunksjon_ads_bridge as (
            with stillingsfunksjon_ads_bridge as (
                select
                    distinct
                    a.ad_id,
                    s.id as stillingsfunksjon_id

                from stillingsfunksjon as s
                left join ads_content_and_metadata as a
                    on list_contains(a.stillingsfunksjon, s.stillingsfunksjon)
            )
            select
                concat(ad_id, '_', stillingsfunksjon_id) as id,
                ad_id,
                stillingsfunksjon_id
            from stillingsfunksjon_ads_bridge
        );
    """)

def create_keyword_ads_bridge(database):
    print("creating keyword ads bridge")
    database.execute("""
        create or replace table keyword_ads_bridge as (
            with keyword_ads_bridge as (
                select
                    distinct
                    a.ad_id,
                    k.id as keyword_id

                from keywords as k
                left join ads_content_and_metadata as a
                    on list_contains(a.keywords, k.keyword)
            )
            select
                concat(ad_id, '_', keyword_id) as id,
                ad_id,
                keyword_id
            from keyword_ads_bridge
        );
    """)

def create_ads_with_id(database):
    print("creating ads with id")
    database.execute("""
        create or replace table ads_with_id as (
            select
                c.ad_id,
                c.canonical_url,
                c.heading,
                c.location,
                c.job_title,
                e.id as employer_id,
                c.no_of_positions,
                c.published,
                c.article_header,
                c.article_content,
                k.id as keyword_bridge_id,
                c.timestamp,
                c.job_type,
                s.id as stillingsfunksjon_bridge_id

            from ads_content_and_metadata as c
                     
            left join employers as e
                on c.company_name = e.company_name

            left join keyword_ads_bridge as k
                on c.ad_id = k.ad_id

            left join stillingsfunksjon_ads_bridge as s
                on c.ad_id = s.ad_id
        );
    """)

def create_ngrams(database):
    print("creating ngrams")
    database.execute("""
        create or replace table ngrams as (
            with words as (
                select
                    unnest(regexp_extract_all(article_content, '(\w+)')) as words,
                    ad_id,
                    keyword_bridge_id,
                    stillingsfunksjon_bridge_id,
                    employer_id
                    
                from ads_with_id
            ),

            minus_stopwords as (
                select 
                    words,
                    ad_id,
                    keyword_bridge_id,
                    stillingsfunksjon_bridge_id,
                    employer_id

                from words as w
                anti join stopwords as s
                    on w.words = s.stopword
            ),

            single_words as (
                select
                    words,
                    1 as ngram_size,
                    ad_id,
                    keyword_bridge_id,
                    stillingsfunksjon_bridge_id,
                    employer_id
                from minus_stopwords
            ),

            combined_words as (
                select
                    string_agg(words, ' ') as words,
                    ad_id,
                    keyword_bridge_id,
                    stillingsfunksjon_bridge_id,
                    employer_id

                from minus_stopwords
                group by ad_id, keyword_bridge_id, stillingsfunksjon_bridge_id, employer_id
            ),


            double_words as (
                select 
                    list_distinct(regexp_extract_all(words, '(\w+)\s+(\w+)')) as word_pairs,
                    ad_id,
                    keyword_bridge_id,
                    stillingsfunksjon_bridge_id,
                    employer_id

                from combined_words
            ),

            double_words_unnested as (
                select
                    unnest(word_pairs) as words,
                    2 as ngram_size,
                    ad_id,
                    keyword_bridge_id,
                    stillingsfunksjon_bridge_id,
                    employer_id
                from double_words
            )


            -- ,
            -- with triple_words as (
            --     select
            --         regexp_split_to_table(article_content, '\w\s\w\s\w') as words,
            --         3 as ngram_size
            --     from job_ad_content_cleaned
            --     union all
            --     select
            --         regexp_split_to_table(article_content, '\s\w\s\w\s\w') as words,
            --         3 as ngram_size
            --     from job_ad_content_cleaned
            --     union all
            --     select
            --         regexp_split_to_table(article_content, '\s\w\s\w\s\w') as words,
            --         3 as ngram_size
            --     from job_ad_content_cleaned
            --     union all
            --     select
            --         regexp_split_to_table(article_content, '\s\w\s\w\s\w') as words,
            -- )

            select
                row_number() over(order by words),
                     *
            from (
                     
            select * from single_words
            union all
            select * from double_words_unnested
            -- union all
            -- select * from triple_words
                     )
        );
""")
    

def export_to_postgres(database, postgres_connection):
    print("exporting to postgres")
        #-- attach 'dbname={postgres_connection["schema"]} user={postgres_connection["login"]} password={postgres_connection["password"]} port={postgres_connection["port"]} host={postgres_connection["host"]}' as postgres_db (TYPE postgres);

    print(f"attaching to postgres_db {postgres_connection}")
    database.execute(f"""
        attach 'dbname=postgres user=postgres password=postgres port=5432 host=hyperjob-pg.hyperjob.svc.cluster.local' as postgres_db (TYPE postgres);
    """)

    # insert keywords
    print("inserting keywords")
    database.execute("""
        DROP TABLE IF EXISTS postgres_db.keywords;
        CREATE TABLE postgres_db.keywords (
            id INT PRIMARY KEY,
            keyword TEXT UNIQUE
        );

        INSERT INTO postgres_db.keywords (id, keyword)
        SELECT id, keyword FROM keywords;

        CREATE INDEX IF NOT EXISTS idx_keywords_keyword ON postgres_db.keywords (keyword);
    """)

    # insert employers
    print("inserting employers")
    database.execute("""
        DROP TABLE IF EXISTS postgres_db.employers;
        CREATE TABLE postgres_db.employers (
            id INT PRIMARY KEY,
            company_name TEXT UNIQUE,
            bransje TEXT,
            sektor TEXT
        );

        INSERT INTO postgres_db.employers (id, company_name, bransje, sektor)
        SELECT id, company_name, bransje, sektor FROM employers;

        CREATE INDEX IF NOT EXISTS idx_employers_company_name ON postgres_db.employers (company_name);
    """)

    # insert stillingsfunksjon
    print("inserting stillingsfunksjon")
    database.execute("""
        DROP TABLE IF EXISTS postgres_db.stillingsfunksjon;
        CREATE TABLE postgres_db.stillingsfunksjon (
            id INT PRIMARY KEY,
            stillingsfunksjon TEXT UNIQUE
        );

        INSERT INTO postgres_db.stillingsfunksjon (id, stillingsfunksjon)
        SELECT id, stillingsfunksjon FROM stillingsfunksjon;

        CREATE INDEX IF NOT EXISTS idx_stillingsfunksjon_stillingsfunksjon ON postgres_db.stillingsfunksjon (stillingsfunksjon);
    """)

    # insert ads_with_id
    print("inserting ads_with_id")
    database.execute("""
        DROP TABLE IF EXISTS postgres_db.ads_with_id;
        CREATE TABLE postgres_db.ads_with_id (
            ad_id TEXT,
            canonical_url TEXT,
            heading TEXT,
            location TEXT,
            job_title TEXT,
            employer_id INTEGER,
            no_of_positions INTEGER,
            published TIMESTAMP,
            article_header TEXT,
            article_content TEXT,
            keyword_bridge_id VARCHAR,
            timestamp TIMESTAMP,
            job_type TEXT,
            stillingsfunksjon_bridge_id VARCHAR
        );

        INSERT INTO postgres_db.ads_with_id (ad_id, canonical_url, heading, location, job_title, employer_id, no_of_positions, published, article_header, article_content, keyword_bridge_id, timestamp, job_type, stillingsfunksjon_bridge_id)
        SELECT ad_id, canonical_url, heading, location, job_title, employer_id, no_of_positions, published, article_header, article_content, keyword_bridge_id, timestamp, job_type, stillingsfunksjon_bridge_id FROM ads_with_id;

        CREATE INDEX IF NOT EXISTS idx_ads_with_id_ad_id ON postgres_db.ads_with_id (ad_id);
    """)

    # insert ngrams
    print("inserting ngrams")
    database.execute("""
        DROP TABLE IF EXISTS postgres_db.ngrams;
        CREATE TABLE postgres_db.ngrams (
            id INT,
            words TEXT,
            ngram_size INTEGER,
            ad_id TEXT,
            keyword_bridge_id VARCHAR,
            stillingsfunksjon_bridge_id VARCHAR,
            employer_id INTEGER
        );

        INSERT INTO postgres_db.ngrams (words, ngram_size, ad_id, keyword_bridge_id, stillingsfunksjon_bridge_id, employer_id)
        SELECT words, ngram_size, ad_id, keyword_bridge_id, stillingsfunksjon_bridge_id, employer_id FROM ngrams;

        CREATE INDEX IF NOT EXISTS idx_ngrams_words ON postgres_db.ngrams (words);
        CREATE INDEX IF NOT EXISTS idx_ngrams_ad_id ON postgres_db.ngrams (ad_id);
    """)

    print("inserting keyword_ads_bridge")
    database.execute("""
        DROP TABLE IF EXISTS postgres_db.keyword_ads_bridge;
        CREATE TABLE postgres_db.keyword_ads_bridge (
            id VARCHAR,
            ad_id TEXT,
            keyword_id INTEGER
        );
    """)