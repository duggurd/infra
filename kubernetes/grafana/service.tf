resource "kubernetes_namespace" "grafana" {
  metadata {
    name = "grafana"
  }
}

resource "kubernetes_persistent_volume" "grafana" {
  metadata {
    name = "grafana"
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    capacity = {
      storage = "1Gi"
    }
    persistent_volume_reclaim_policy = "Retain"
    storage_class_name               = "local-path"
    persistent_volume_source {
      local {
        path = "/mnt/grafana"
      }
    }
    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key      = "kubernetes.io/hostname"
            operator = "In"
            values   = ["homelab.alpine1"]
          }
        }
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "grafana" {
  metadata {
    name      = "grafana"
    namespace = kubernetes_namespace.grafana.metadata[0].name
  }
  spec {
    storage_class_name = "local-path"
    access_modes       = ["ReadWriteOnce"]
    volume_name        = kubernetes_persistent_volume.grafana.metadata[0].name
    resources {
      requests = {
        storage = "1Gi"
      }
      limits = {}
    }
  }
  wait_until_bound = false
}


resource "kubernetes_persistent_volume_claim" "postgres" {
  metadata {
    name = "postgres"
    namespace = kubernetes_namespace.grafana.metadata[0].name
  }
  spec {
    storage_class_name = "local-path"
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "1Gi"
      }
      limits = {}
    }
  }
  wait_until_bound = false
} 

resource "kubernetes_deployment" "grafana" {

  metadata {
    name      = "grafana"
    namespace = kubernetes_namespace.grafana.metadata[0].name
    labels = {
      app = "grafana"
    }
  }

  timeouts {
    create = "2m"
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "grafana"
      }
    }
    template {
      metadata {
        labels = {
          app = "grafana"
        }
      }
      spec {
        container {
          name              = "grafana"
          image             = "grafana/grafana:11.3.0"
          image_pull_policy = "IfNotPresent"
          # env {
          #  name  = "GF_INSTALL_PLUGINS"
          #  value = "grafana-clickhouse-datasource"
          # }
          port {
            name           = "web"
            container_port = 3000
            host_port      = 3000
          }
          volume_mount {
            name       = "grafana-data"
            mount_path = "/var/lib/grafana"
          }
        }
        container {
          name = "postgres"
          image = "postgres:slim"
          image_pull_policy = "IfNotPresent"
          env {
            name = POSTGRES_PASSWORD
            value = "123"
          }
          port {
            name = "postgres"
            container_port = 5432
            host_port  = 5555
          }
          volume_mount {
            name = "postgres-data"
            mount_path = "var/lib/postgresql/data"
          }
        }
        volume {
          name = "grafana-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.grafana.metadata[0].name
          }
        }
        volume {
          name = "postgres-data"
          persistent_volume_claim {
            claim_name = "kubernetes_persistent_volume_claim.postgres.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "grafana" {
  metadata {
    name      = "grafana"
    namespace = kubernetes_namespace.grafana.metadata[0].name
  }
  spec {
    selector = {
      app = "grafana"
    }
    type = "NodePort"
    port {
      port        = 3000
      target_port = 3000
      node_port   = 30333
    }
    port {
      target_port = 5555
      node_port = 30555
    }
  }
}