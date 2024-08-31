provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "default"
}

terraform {
  backend "kubernetes" {
    config_path   = "~/.kube/config"
    secret_suffix = "postgres"
    labels = {
      "owner" = "terraform"
    }
  }
}

resource "kubernetes_namespace" "postgres_ns" {
  metadata {
    name = "postgres"
  }
}

resource "kubernetes_persistent_volume_claim" "postgres_pvc" {
  metadata {
    name      = "postgres-pvc"
    namespace = kubernetes_namespace.postgres_ns.metadata[0].name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "10Gi"
      }
    }
  }
}

resource "kubernetes_secret" "postgres_password" {
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace.postgres_ns.metadata[0].name
  }
  type = "Opaque"
  data = {
    POSTGRES_PASSWORD = var.postgres_password
  }
}

resource "kubernetes_deployment" "postgres_depl" {
  depends_on = [kubernetes_secret.postgres_password]
  metadata {
    name      = "postgres-depl"
    namespace = kubernetes_namespace.postgres_ns.metadata[0].name
    labels = {
      app = "postgres"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = var.app_selector
      }
    }
    template {
      metadata {
        labels = {
          app = var.app_selector
        }
      }
      spec {
        container {
          name              = "postgres"
          image             = "postgres:alpine"
          image_pull_policy = "IfNotPresent"
          env_from {
            secret_ref {
              name = kubernetes_secret.postgres_password.metadata[0].name
            }
          }
          port {
            container_port = 5432
          }
          volume_mount {
            name       = "postgres-data"
            mount_path = "/var/lib/postgresql/data"
          }
          resources {
            limits = {
              cpu    = "256m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "64m"
              memory = "256Mi"
            }
          }
        }
        volume {
          name = "postgres-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.postgres_pvc.metadata[0].name
          }
        }
      }
    }
  }
}


resource "kubernetes_service" "postgres_svc" {
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace.postgres_ns.metadata[0].name
    labels = {
      app = var.app_selector
    }
  }
  spec {
    selector = {
      app = var.app_selector
    }
    type = "NodePort"
    port {
      port        = 5432
      target_port = 5432
      node_port   = 30433
    }
  }
}
