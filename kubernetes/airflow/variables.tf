variable "POSTGRES_PASSWORD" {
  type = string
}

variable "AIRFLOW__DATABASE__SQL_ALCHEMY_CONN" {
  type = string
}

variable "AIRFLOW__CORE__EXECUTOR" {
  type = string
}

variable "INGESTION_DB_SQL_ALCHEMY_CONN" {
  type = string
}

variable "MINIO_ENDPOINT" {
  type = string
}

variable "MINIO_ACCESS_KEY" {
  type = string
  sensitive = true
}

variable "MINIO_SECRET_KEY" {
  type = string
  sensitive = true
} 

variable "INGESTION_BUCKET_NAME" {
  type = string
}
