POSTGRES_PASSWORD                   = "123"
AIRFLOW__DATABASE__SQL_ALCHEMY_CONN = "postgresql://airflow:123@postgres:5432/airflow_db"
AIRFLOW__CORE__EXECUTOR             = "LocalExecutor"
INGESTION_DB_SQL_ALCHEMY_CONN       = "postgresql://ingestion:123@postgres:5432/ingestion_db"
MINIO_ENDPOINT                      = "minio:9000"
INGESTION_BUCKET_NAME               = "ingestion"
