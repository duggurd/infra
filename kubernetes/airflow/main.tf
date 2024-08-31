provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "default"
}

terraform {
  backend "kubernetes" {
    config_path   = "~/.kube/config"
    secret_suffix = "airflow"
    labels = {
      "owner" = "terraform"
    }
  }
}

resource "kubernetes_namespace" "airflow" {
  metadata {
    name = "airflow"
  }
}

resource "kubernetes_config_map" "airflow_config" {
  metadata {
    name      = "airflow-conf"
    namespace = kubernetes_namespace.airflow.metadata[0].name
  }
  data = {
    "POSTGRES_PASSWORD"                   = var.POSTGRES_PASSWORD
    "AIRFLOW__DATABASE__SQL_ALCHEMY_CONN" = var.AIRFLOW__DATABASE__SQL_ALCHEMY_CONN
    "AIRFLOW__CORE__EXECUTOR"             = var.AIRFLOW__CORE__EXECUTOR
    "INGESTION_DB_SQL_ALCHEMY_CONN"       = var.INGESTION_DB_SQL_ALCHEMY_CONN
    "MINIO_ENDPOINT"                      = var.MINIO_ENDPOINT
    "INGESTION_BUCKET_NAME"               = var.INGESTION_BUCKET_NAME
  }
}

resource "kubernetes_persistent_volume_claim" "airflow_dags_pvc" {
  metadata {
    name      = "airflow-pvc"
    namespace = kubernetes_namespace.airflow.metadata[0].name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "256Mi"
      }
      limits = {}
    }
  }
}

resource "kubernetes_persistent_volume_claim" "airflow_logs_pvc" {
  metadata {
    name      = "airflow-logs-pvc"
    namespace = kubernetes_namespace.airflow.metadata[0].name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "2Gi"
      }
      limits = {}
    }
  }
}


resource "kubernetes_deployment" "airflow_depl" {
  metadata {
    name      = "airflow-depl"
    namespace = kubernetes_namespace.airflow.metadata[0].name
    labels = {
      "app" = "airflow"
    }
  }
  wait_for_rollout = true
  spec {
    replicas = 1
    selector {
      match_labels = {
        "app" = "airflow"
      }
    }
    template {
      metadata {
        labels = {
          "app" = "airflow"
        }
      }
      spec {
        hostname = "airflow"
        init_container {
          name              = "init-db"
          image             = "127.0.0.1:30500/airflow:latest"
          image_pull_policy = "Always"
          env_from {
            config_map_ref {
              name = kubernetes_config_map.airflow_config.metadata[0].name
            }
          }
          command = ["sh", "-c", "airflow db migrate"]
        }
        container {
          name              = "airflow"
          image             = "127.0.0.1:30500/airflow:latest"
          image_pull_policy = "Always"
          env_from {
            config_map_ref {
              name = kubernetes_config_map.airflow_config.metadata[0].name
            }
          }
          env {
            name = "MINIO_ACCESS_KEY"
            value_from {
              secret_key_ref {
                name     = "airflow-minio-key"
                key      = "access_key"
                optional = false
              }
            }
          }
          env {
            name = "MINIO_SECRET_KEY"
            value_from {
              secret_key_ref {
                name     = "airflow-minio-key"
                key      = "secret_key"
                optional = false
              }
            }
          }
          volume_mount {
            name       = "dags"
            mount_path = "/opt/airflow/dags"
          }
          volume_mount {
            name       = "logs"
            mount_path = "/opt/airflow/logs"
          }
          command = ["sh", "-c", "airflow standalone"]
          resources {
            requests = {
              memory = "256Mi"
              cpu    = "500m"
            }
            limits = {
              memory = "4096Mi"
              cpu    = "2000m"
            }
          }
        }
        volume {
          name = "dags"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.airflow_dags_pvc.metadata[0].name
          }
        }
        volume {
          name = "logs"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.airflow_logs_pvc.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "airflow_service" {
  metadata {
    labels = {
      "app" = "airflow"
    }
    namespace = kubernetes_namespace.airflow.metadata[0].name
    name      = "airflow"
  }
  spec {
    selector = {
      "app" = "airflow"
    }
    type = "NodePort"
    port {
      port        = 8080
      target_port = 8080
      node_port   = 30080
    }
  }
}