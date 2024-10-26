resource "kubernetes_namespace" "registry" {
  metadata {
    name = "registry"
  }
}

resource "kubernetes_persistent_volume_claim" "registry" {
  metadata {
    name      = "registry"
    namespace = "registry"
  }
  wait_until_bound = false
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "10Gi"
      }
    }
  }
}

locals {
  name = "registry"
}

resource "kubernetes_deployment" "registry" {
  metadata {
    name      = local.name
    namespace = kubernetes_namespace.registry.metadata[0].name
    labels = {
      app = "registry"
    }
  }
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
          name  = local.name
          image = "registry"
          resources {
            limits = {
              memory = "128Mi"
              cpu    = "500m"
            }
          }
        #   env {
        #     name  = "REGISTRY_HTTP_ADDR"
        #     value = "0.0.0.0:5000"
        #   }
        #   env {
        #     name = "REGISTRY_HTTP_TLS_CERTIFICATE"
        #     value = "/etc/tls/registry.crt"
        #   }
        #   env {
        #     name = "REGISTRY_HTTP_TLS_KEY"
        #     value = "/etc/tls/registry.key"
        #   }
          port {
            container_port = 5000 # 443
          }
        #   volume_mount {
        #     mount_path = "/etc/tls"
        #     name = "tls"
        #   }
          volume_mount {
            name       = kubernetes_persistent_volume_claim.registry.metadata[0].name
            mount_path = "/var/lib/registry"
          }
        }
        # volume {
        #     name = "tls"
        #   secret {
        #     secret_name = kubernetes_secret.registry_tls.metadata[0].name
        #     items {
        #       key = "crt"
        #       path = "registry.crt"
        #     }
        #     items {
        #       key = "key"
        #       path = "registry.key"
        #     }
        #   }
        # }
        volume {
          name = kubernetes_persistent_volume_claim.registry.metadata[0].name
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.registry.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "registry" {
  metadata {
    name      = local.name
    namespace = kubernetes_namespace.registry.metadata[0].name
  }
  spec {
    selector = {
      app = local.name
    }
    type = "NodePort"
    port {
      node_port   = 30500
      port        = 5000 # 443
      target_port = 5000 # 443
    }
  }
}