variable "MINIO_ACCESS_KEY" {
  type = string
}

variable "MINIO_SECRET__KEY" {
  type = string
  sensitive = true
}

resource "kubernetes_secret" "minio_credentials" {
  metadata {
    name = "minio-credentials"
    namespace = kubernetes_namespace.clickhouse.metadata[0].name
  }
  data = {
    "MINIO_ACCESS_KEY" = var.MINIO_ACCESS_KEY
    "MINIO_SECRET_KEY" = var.MINIO_SECRET__KEY
  }
}

resource "kubernetes_namespace" "clickhouse" {
  metadata {
    name = "clickhouse"
  }
}

resource "kubernetes_persistent_volume" "clickhouse" {
  metadata {
    name = "clickhouse"
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    capacity = {
      storage = "50Gi"
    }
    persistent_volume_reclaim_policy = "Retain"
    storage_class_name               = "local-path"
    persistent_volume_source {
      local {
        path = "/mnt/clickhouse"
      }
    }
    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key      = "kubernetes.io/hostname"
            operator = "In"
            values   = ["homelab.alpine2"]
          }
        }
      }
    }
  }
}

resource "kubernetes_persistent_volume" "clickhouse_conf" {
  metadata {
    name = "clickhouse-conf"
  }
  spec {
    access_modes = [ "ReadWriteOnce" ]
    capacity = {
      storage = "128Mi" 
    }
    persistent_volume_reclaim_policy = "Retain"
    storage_class_name = "local-path"
    persistent_volume_source {
      local {
        path = "/mnt/clickhouse-conf"
      }
    }
    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key      = "kubernetes.io/hostname"
            operator = "In"
            values   = ["homelab.alpine2"]
          }
        }
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "clickhouse" {
  metadata {
    name      = "clickhouse"
    namespace = kubernetes_namespace.clickhouse.metadata.0.name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "50Gi"
      }
    }
    volume_name        = kubernetes_persistent_volume.clickhouse.metadata.0.name
    storage_class_name = "local-path"
  }
  wait_until_bound = false
}


resource "kubernetes_persistent_volume_claim" "clickhouse_conf" {
  metadata {
    name = "clickhouse-conf"
    namespace = kubernetes_namespace.clickhouse.metadata.0.name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "128Mi"
      }
    }
    volume_name = kubernetes_persistent_volume.clickhouse_conf.metadata[0].name
    storage_class_name = "local-path"
  } 
  wait_until_bound = false
}


resource "kubernetes_persistent_volume_claim" "clickhouse_logs" {
  metadata {
    name = "clickhouse-logs"
    namespace = kubernetes_namespace.clickhouse.metadata.0.name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "128Mi" 
      }
    }
  }
  wait_until_bound = false
}

resource "kubernetes_deployment" "clickhouse" {
  timeouts {
    create = "2m"
  }
  metadata {
    name      = "clickhouse"
    namespace = kubernetes_namespace.clickhouse.metadata[0].name
    labels = {
      app = "clickhouse"
    }
  }
  spec {
    replicas = 1
    strategy {
      type = "Recreate"
    }
    selector {
      match_labels = {
        app = "clickhouse"
      }
    }
    template {
      metadata {
        labels = {
          app = "clickhouse"
        }
      }
      spec {
        node_selector = {
          "kubernetes.io/hostname" = "homelab.alpine2"
        }
        container {
          name              = "clickhouse"
          image             = "clickhouse/clickhouse-server:24.10.1.2812-alpine"
          image_pull_policy = "IfNotPresent"
          env_from {
            secret_ref {
              name = kubernetes_secret.minio_credentials.metadata[0].name
            }
          }
          port {
            name = "interface"
            host_port      = 8123
            container_port = 8123
          }
          port {
            name = "client"
            host_port      = 9000
            container_port = 9000
          }
          volume_mount {
            name       = "clickhouse-data"
            mount_path = "/var/lib/clickhouse/"
          }
          volume_mount {
            name = "clickhouse-conf"
            mount_path = "/etc/clickhouse-server/"
          }
          volume_mount {
            name = "clickhouse-logs"
            mount_path = "/var/log/clickhouse-server/"
          }
          resources {
            requests = {
              cpu    = "1"
              memory = "3Gi"
            }
            limits = {
              cpu    = "4"
              memory = "5Gi"
            }
          }
        }
        volume {
          name = "clickhouse-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.clickhouse.metadata[0].name
          }
        }
        volume {
          name = "clickhouse-conf" 
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume.clickhouse_conf.metadata[0].name
          }
        }
        volume {
          name = "clickhouse-logs"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.clickhouse_logs.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "clickhouse" {
  metadata {
    name      = "clickhouse-svc"
    namespace = kubernetes_namespace.clickhouse.metadata.0.name
  }
  spec {
    selector = {
      "app" = "clickhouse"
    }
    type = "NodePort"
    port {
      name = "interface"
      port        = 8123
      target_port = 8123
      node_port   = 30123
    }
    port {
      name = "client"
      port        = 9000
      target_port = 9000
      node_port   = 30129
    }
  }
}

