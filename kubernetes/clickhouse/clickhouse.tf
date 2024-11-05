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
          image             = "clickhouse/clickhouse-server:head-alpine"
          image_pull_policy = "IfNotPresent"
          port {
            host_port      = 8123
            container_port = 8123
          }
          volume_mount {
            name       = "clickhouse-data"
            mount_path = "/var/lib/clickhouse/"
          }
          resources {
            requests = {
              cpu    = "1"
              memory = "512m"
            }
            limits = {
              cpu    = "2"
              memory = "2Gi"
            }
          }
        }
        volume {
          name = "clickhouse-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.clickhouse.metadata[0].name
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
      port        = 8123
      target_port = 8123
      node_port   = 30123
    }
  }
}

