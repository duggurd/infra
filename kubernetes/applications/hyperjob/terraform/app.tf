resource "kubernetes_secret" "postgres_credentials" {
  metadata {
    name      = "postgres-hyperjob-credentials"
    namespace = kubernetes_namespace.hyperjob.metadata[0].name
  }

  data = {
    POSTGRES_PASSWORD = "postgres"
  }

  type = "Opaque"
}

resource "kubernetes_persistent_volume_claim" "postgres_pvc" {
  metadata {
    name      = "postgres-hyperjob-pvc"
    namespace = kubernetes_namespace.hyperjob.metadata[0].name
  }
  wait_until_bound = false
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "local-path"
    resources {
      requests = {
        storage = "2Gi"
      }
    }
  }
}

resource "kubernetes_deployment" "hyperjob" {
  metadata {
    name      = "hyperjob"
    namespace = kubernetes_namespace.hyperjob.metadata[0].name
    labels = {
      app = "hyperjob"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "hyperjob"
      }
    }

    template {
      metadata {
        labels = {
          app = "hyperjob"
        }
      }

      spec {
        container {
          image = "127.0.0.1:30500/hyperjob:latest"
          name  = "hyperjob"
          image_pull_policy = "Always"

          port {
            container_port = 3000
          }
          env_from {
            secret_ref {
              name = kubernetes_secret.postgres_credentials.metadata[0].name
            }
          }
        }

        container {
          image = "postgres:15-alpine"
          name  = "postgres"
          image_pull_policy = "IfNotPresent"

          env_from {
            secret_ref {
              name = kubernetes_secret.postgres_credentials.metadata[0].name
            }
          }

          port {
            container_port = 5432
          }

          volume_mount {
            name       = "postgres-storage"
            mount_path = "/var/lib/postgresql/data"
          }
        }

        volume {
          name = "postgres-storage"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.postgres_pvc.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "hyperjob" {
  metadata {
    name      = "hyperjob"
    namespace = kubernetes_namespace.hyperjob.metadata[0].name
  }

  spec {
    selector = {
      app = "hyperjob"
    }

    port {
      port        = 3000
      target_port = 3000
      node_port   = 30800
    }

    type = "NodePort"
  }
}


resource "kubernetes_service" "hyperjob-pg" {
  metadata {
    name      = "hyperjob-pg"
    namespace = kubernetes_namespace.hyperjob.metadata[0].name
  }

  spec {
    selector = {
      app = "hyperjob"
    }

    port {
      port        = 5432
      target_port = 5432
      node_port   = 30005
    }

    type = "NodePort"
  }
}

