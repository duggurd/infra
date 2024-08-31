resource "kubernetes_namespace" "minio_ns" {
  metadata {
    name = "minio-ns"
  }
}

resource "kubernetes_persistent_volume_claim" "minio_pvc" {
  metadata {
    name      = "minio-pvc"
    namespace = "airflow"
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "10Gi"
      }
    }
  }
  wait_until_bound = false
}


resource "kubernetes_deployment" "minio_deployment" {
  metadata {
    name = "minio"
    namespace = "airflow"
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        "app" = "minio"
      }
    }
    template {
      metadata {
        labels = {
          "app" = "minio"
        }
      }
      spec {
        container {
          name              = "minio"
          image             = "quay.io/minio/minio:latest"
          image_pull_policy = "IfNotPresent"
          command = [
            "/bin/bash",
            "-c",
            "minio server /data --console-address :9090"
          ]
          volume_mount {
            name       = "minio-data"
            mount_path = "/data"
          }
          resources {
            limits = {
              "memory" = "1024Mi"
              "cpu"    = "500m"
            }
          }
          port {
            name           = "api"
            container_port = 9000
          }
          port {
            name           = "web"
            container_port = 9090
          }
        }
        volume {
          name = "minio-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.minio_pvc.metadata.0.name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "minio_svc" {
  metadata {
    name      = "minio"
    namespace = "airflow"
  }
  spec {
    selector = {
      "app" = "minio"
    }
    type = "NodePort"
    port {
    name = "web"
      port        = 9090
      target_port = 9090
      node_port   = 30090
    }
    port {
      name = "api"
      port        = 9000
      target_port = 9000
      node_port   = 30091
    }
  }
}