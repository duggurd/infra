resource "kubernetes_secret" "minio_s3_sync_credentials" {
  metadata {
    name      = "minio-s3-sync-credentials"
    namespace = "airflow"
  }

  data = {
    AWS_ACCESS_KEY_ID     = var.aws_access_key_id
    AWS_SECRET_ACCESS_KEY = var.aws_secret_access_key
    MINIO_ACCESS_KEY      = var.minio_access_key
    MINIO_SECRET_KEY      = var.minio_secret_key
  }
}