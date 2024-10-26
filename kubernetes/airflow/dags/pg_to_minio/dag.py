from airflow.decorators import dag, task
from datetime import datetime


def generate_export_task(bucket, table_fqn, path:str):
    path = path.strip("/")
    @task.virtualenv(
        task_id=f"pg_to_minio.{bucket}.{path.replace('/', '.')}.{table_fqn.split('.')[-1]}", 
        requirements=["./requirements.txt"], 
        system_site_packages=False,
        venv_cache_path="/tmp/venv/cache/pg_export",
        pip_install_options=["--require-virtualenv", "--isolated"]
    )
    def export_task(bucket, table_fqn, path):
        import sys
        sys.path.append('/opt/airflow/dags/finn_metadata')
        sys.path.append('/opt/airflow/dags')
        
        import os
        import io
        import pandas as pd
        from utils.minio_utils import connect_to_minio
        from sqlalchemy import create_engine

        engine = create_engine(os.environ["INGESTION_DB_SQL_ALCHEMY_CONN"])
        
        df = pd.read_sql_table(
            table_name=table_fqn.split(".")[-1], 
            schema=table_fqn.split(".")[-2], 
            con=engine
        )

        # Convert DataFrame to parquet
        parquet_buffer = io.BytesIO()
        df.to_parquet(parquet_buffer, index=False, compression="zstd")
        parquet_buffer.seek(0)

        # Initialize MinIO client
        minio_client = connect_to_minio()

        # Upload parquet file to MinIO
        object_name = f"{path}/{table_fqn.split('.')[-1]}.zst.parquet"

        minio_client.put_object(
            bucket_name=bucket,
            object_name=object_name,
            data=parquet_buffer,
            length=parquet_buffer.getbuffer().nbytes,
            content_type='binary/octet-stream'
        )

        print(f"Data exported successfully to MinIO: {object_name}")

    return export_task

@dag(
    dag_id="postgres_to_minio_export", 
    start_date=datetime(2024, 1, 1), 
    schedule_interval="0 1 * * *",
    catchup=False,
    max_active_runs=1
)
def export_postgres_to_minio():

    export_tables = [
        {"table_fqn": "ingestion_db.finn.finn_job_ads__content", "bucket": "bronze", "path": "finn/ads/job_fulltime_content"}
    ]

    for config in export_tables:
        generate_export_task(**config)(**config)

export_postgres_to_minio()
