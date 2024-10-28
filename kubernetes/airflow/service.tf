locals {
  name    = "airflow"
  db_name = "postgres"
}

resource "kubernetes_namespace" "airflow" {
  metadata {
    name = local.name
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "kubernetes_config_map" "airflow_config" {
  metadata {
    name      = "airflow-conf"
    namespace = kubernetes_namespace.airflow.metadata[0].name
  }
  data = {
    "AIRFLOW__DATABASE__SQL_ALCHEMY_CONN" = "postgresql+psycopg2://airflow:${var.POSTGRES_PASSWORD}@localhost:5432/airflow"
    "AIRFLOW__CORE__EXECUTOR"             = "LocalExecutor"
  }
}

resource "kubernetes_persistent_volume_claim" "airflow_dags_pvc" {
  metadata {
    name      = "airflow-dags"
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
  wait_until_bound = false
}

resource "kubernetes_persistent_volume_claim" "airflow_logs_pvc" {
  metadata {
    name      = "airflow-logs"
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
  wait_until_bound = false
}



resource "kubernetes_persistent_volume" "airflow_db_pv" {
  metadata {
    name = "airflow-db"
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    capacity = {
      storage = "4Gi"
    }
    persistent_volume_reclaim_policy = "Retain"
    persistent_volume_source {
      local {
        path = "/mnt/airflow_db"
      }
    }
    storage_class_name = "local-path"
    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            operator = "In"
            key      = "kubernetes.io/hostname"
            values   = ["homelab.alpine1"]
          }
        }
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "airflow_db_pvc" {
  metadata {
    name      = "airflow-db-pvc"
    namespace = kubernetes_namespace.airflow.metadata[0].name
  }
  spec {
    storage_class_name = "local-path"
    volume_name  = kubernetes_persistent_volume.airflow_db_pv.metadata[0].name
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = kubernetes_persistent_volume.airflow_db_pv.spec[0].capacity.storage
      }
      limits = {}
    }
  }
  wait_until_bound = false
}


resource "kubernetes_deployment" "airflow" {
  timeouts {
    create = "2m"
  }
  metadata {
    name      = "airflow-depl"
    namespace = kubernetes_namespace.airflow.metadata[0].name
    labels = {
      app = local.name
    }
  }
  wait_for_rollout = true
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = local.name
      }
    }
    template {
      metadata {
        labels = {
          app = local.name
        }
      }
      spec {
        container {
          name  = local.db_name
          image = "postgres:alpine"
          env {
            name  = "POSTGRES_USER"
            value = "airflow"
          }
          env {
            name  = "POSTGRES_PASSWORD"
            value = var.POSTGRES_PASSWORD
          }
          env {
            name  = "POSTGRES_DB"
            value = "airflow"
          }
          port {
            container_port = 5432
          }
          volume_mount {
            name       = "postgres-data"
            mount_path = "/var/lib/postgresql/data"
          }
          readiness_probe {
            exec {
              command = ["pg_isready", "-U", "airflow"]
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
          resources {
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }
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
          volume_mount {
            name       = "dags"
            mount_path = "/opt/airflow/dags"
          }
          volume_mount {
            name       = "logs"
            mount_path = "/opt/airflow/logs"
          }
          command = ["sh", "-c", "sleep 20; airflow db migrate && airflow standalone"]
          resources {
            requests = {
              memory = "256Mi"
              cpu    = "500m"
            }
            limits = {
              memory = "4096Mi"
              cpu    = "2"
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
        volume {
          name = "postgres-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.airflow_db_pvc.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "airflow_service" {
  metadata {
    name      = local.name
    namespace = kubernetes_namespace.airflow.metadata[0].name
    labels = {
      app = local.name
    }
  }
  spec {
    selector = {
      app = local.name
    }
    type = "NodePort"
    port {
      port        = 8080
      target_port = 8080
      node_port   = 30080
    }
  }
}