resource "kubernetes_cron_job_v1" "sync_minio_to_s3" {
  metadata {
    name      = "sync-minio-to-s3"
    namespace = kubernetes_namespace.minio.metadata[0].name
  }

  spec {
    schedule = "0 2 * * *"

    job_template {
      metadata {
        name      = "mirror-minio-s3"
        namespace = kubernetes_namespace.minio.metadata[0].name
      }
      spec {
        template {
          metadata {
            name = "mirror-minio-s3"
          }
          spec {
            container {
              name  = "mc"
              image = "minio/mc"

              command = [
                "/bin/sh",
                "-c",
                "mc alias set minio http://minio.minio:9000 $MINIO_ACCESS_KEY $MINIO_SECRET_KEY && mc alias set s3 https://s3.amazonaws.com $AWS_ACCESS_KEY_ID $AWS_SECRET_ACCESS_KEY && mc mirror minio s3/miniorepl"
              ]

              env_from {
                secret_ref {
                  name = kubernetes_secret.minio_s3_sync_credentials.metadata[0].name
                }
              }

              resources {
                limits = {
                  cpu    = "200m"
                  memory = "256Mi"
                }
                requests = {
                  cpu    = "100m"
                  memory = "128Mi"
                }
              }
            }

            restart_policy = "OnFailure"
          }
        }
      }
    }
  }
}
