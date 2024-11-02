resource "minio_s3_bucket" "ingestion" {
    bucket = "ingestion"
}


resource "minio_s3_bucket" "bronze" {
    bucket = "bronze"
}