# https://min.io/docs/minio/linux/operations/install-deploy-manage/deploy-minio-multi-node-multi-drive.html

resource "kubernetes_namespace" "minio" {
  metadata {
    name = "minio"
  }
  lifecycle {
    prevent_destroy = true
  }
}


locals {
  replicas = 4
  storage = "50Gi"
}


resource "kubernetes_stateful_set" "minio" {
  timeouts {
    create = "2m"
  }
  metadata {
    name = "minio"
    namespace = kubernetes_namespace.minio.metadata[0].name
    labels = {
      app = "minio"
    }
  }

  spec {
    service_name = "minio"
    replicas     = local.replicas

    selector {
      match_labels = {
        app = "minio"
      }
    }

    template {
      metadata {
        namespace = kubernetes_namespace.minio.metadata[0].name
        labels = {
          app = "minio"
        }
      }

      spec {
        affinity {
          pod_anti_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 100
              pod_affinity_term {
                label_selector {
                  match_expressions {
                    key      = "app"
                    operator = "In"
                    values   = ["minio"]
                  }
                }
                topology_key = "kubernetes.io/hostname"
              }
            }
          }
        }

        container {
          name  = "minio"
          image = "minio/minio@sha256:a616cd8f37758b0296db62cc9e6af05a074e844cc7b5c0a0e62176d73828d440"
          image_pull_policy = "IfNotPresent"
          args = concat(
            ["server"],
            [for i in range(local.replicas) : "http://minio-${i}.minio.minio.svc.cluster.local:9000/data"],
            ["--console-address", ":9090"]
          )
          

          port {
            name           = "api"
            container_port = 9000
          }
          port {
            name           = "web"
            container_port = 9090
          }

          volume_mount {
            name       = "data"
            mount_path = "/data"
          }

          resources {
            limits = {
              cpu    = "1"
              memory = "1Gi"
            }
            requests = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }
        }
      }
    }
    volume_claim_template {
      metadata {
        name = "data"
        namespace = kubernetes_namespace.minio.metadata[0].name
      }
      spec {
        storage_class_name = "local-path"
        access_modes = ["ReadWriteOnce"]
        resources {
          requests = {
            storage = local.storage
          }
        }
      }
    }
  }
}


resource "kubernetes_service" "minio" {
  metadata {
    name = "minio-np"
    namespace = kubernetes_namespace.minio.metadata[0].name
  }
  spec {
    type = "NodePort"
    selector = {
      app = "minio"
    }
    port {
      name        = "web"
      port        = 9090
      target_port = 9090
      node_port   = 30090
    }
    port {
      name        = "api"
      port        = 9000
      target_port = 9000
      node_port   = 30091
    }
  }
}

resource "kubernetes_service" "minio_headless" {
  metadata {
    name      = "minio"
    namespace = "minio"  # change as needed
    labels = {
      app = "minio"
    }
  }

  spec {
    cluster_ip = "None"  # This makes it headless

    selector = {
      app = "minio"
    }

    port {
      name       = "api"
      port       = 9000
      target_port = 9000
      protocol   = "TCP"
    }

    port {
      name       = "console"
      port       = 9090
      target_port = 9090
      protocol   = "TCP"
    }
  }
}


# resource "kubernetes_service" "minio_individual" {
#   metadata {
#     name = "minio"
#   }

#   spec {
#     selector = {
#       app = "minio"
#     }
#     t
#     port {
#       port        = 9000
#       target_port = 9000
#     }
#   }
# }

# resource "kubernetes_service" "minio_headless" {
#   metadata {
#     name = "minio-headless"
#     namespace = kubernetes_namespace.minio.metadata[0].name
#   }
#   spec {
#     cluster_ip = "None"
#     selector = {
#       app = "minio"
#     }
#     port {
#       port        = 9000
#       target_port = 9000
#     }
#   }
# }


# resource "kubernetes_service" "minio_individual" {
#   count = kubernetes_stateful_set.minio.spec[0].replicas

#   metadata {
#     name = "minio-${count.index}"
#   }

#   spec {
#     selector = {
#       app = "minio"
#       "statefulset.kubernetes.io/pod-name" = "minio-${count.index}"
#     }
#     port {
#       port        = 9000
#       target_port = 9000
#     }
#   }
# }


# resource "kubernetes_ingress_v1" "minio_ingress" {
#   metadata {
#     name = "minio-ingress"
#     annotations = {
#       "kubernetes.io/ingress.class" = "traefik"
#     }
#   }

#   spec {
#     rule {
#       host = "minio-0.homelab.kiko-ghoul.ts.net"
#       http {
#         path {
#           path = "/"
#           path_type = "Prefix"
#           backend {
#             service {
#               name = "minio-0"
#               port {
#                 number = 9000
#               }
#             }
#           }
#         }
#       }
#     }

#     rule {
#       host = "minio-1.homelab.kiko-ghoul.ts.net"
#       http {
#         path {
#           path = "/"
#           path_type = "Prefix"
#           backend {
#             service {
#               name = "minio-1"
#               port {
#                 number = 9000
#               }
#             }
#           }
#         }
#       }
#     }
#   }
# }