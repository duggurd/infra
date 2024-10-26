resource "kubernetes_secret" "airflow_minio_secrets" {
  metadata {
    namespace = kubernetes_namespace.airflow.metadata[0].name
    name      = "airflow-minio-secrets"
  }

  data = {
    MINIO_ACCESS_KEY = var.MINIO_ACCESS_KEY
    MINIO_SECRET_KEY = var.MINIO_SECRET_KEY
    MINIO_ENDPOINT   = var.MINIO_ENDPOINT
  }
}
