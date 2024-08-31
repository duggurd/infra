provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "default"
}

terraform {
  backend "kubernetes" {
    config_path   = "~/.kube/config"
    secret_suffix = "gitea"
    labels = {
      "owner" = "terraform"
    }
  }
}

resource "kubernetes_namespace" "gitea" {
  metadata {
    name = "gitea"
  }
}

resource "kubernetes_config_map" "gitea_config" {
  metadata {
    name      = "gitea-conf"
    namespace = kubernetes_namespace.gitea.metadata[0].name
  }
  data = {
    "GITEA__database__DB_TYPE" = "postgres"
    "GITEA__database__HOST"    = "postgres:5432"
    "GITEA__database__NAME"    = "gitea"
    "GITEA__database__USER"    = "gitea"
    "GITEA__database__PASSWD"  = "gitea"
  }
}

# resource "kubernetes_config_map" "gitea_act_runner_config" {
#   metadata {
#     name      = "gitea-act-runner-conf"
#     namespace = kubernetes_namespace.gitea.metadata[0].name
#   }
#   data = {
#     GITEA_INSTANCE_URL = "http://gitea:3000"
#     GITEA_RUNNER_REGISTRATION_TOKEN = "<gitea-runner-registration-token>"
#     GITEA_RUNNER_NAME = "act_runner_1"
#   }
# }


resource "kubernetes_persistent_volume_claim" "gitea_data_pvc" {
    metadata {
      name      = "gitea-pvc"
      namespace = kubernetes_namespace.gitea.metadata[0].name
    }
    spec {
      access_modes = ["ReadWriteOnce"]
      resources {
        requests = {
          storage = "5Gi"
        }
        limits = {}
      }
    }
}

# resource "kubernetes_persistent_volume_claim" "gitea_act_runner_pvc" {
#   metadata {
#     name      = "gitea-act-runner-pvc"
#     namespace = kubernetes_namespace.gitea.metadata[0].name
#   }
#   spec {
#     access_modes = ["ReadWriteOnce"]
#     resources {
#       requests = {
#         storage = "1Gi"
#       }
#       limits = {}
#     }
#   } 
# }

resource "kubernetes_deployment" "gitea_deployment" {
  metadata {
    name      = "gitea-depl"
    namespace = kubernetes_namespace.gitea.metadata[0].name
    labels = {
      "app" = "gitea"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        "app" = "gitea"
      }
    }
    template {
      metadata {
        labels = {
          "app" = "gitea"
        }
      }
      spec {
        container {
          name              = "gitea"
          image             = "gitea/gitea:1.13.1"
          image_pull_policy = "Always"
          env_from {
            config_map_ref {
              name = kubernetes_config_map.gitea_config.metadata[0].name
            }
          }
          resources {
            requests = {
              memory = "128Mi"
              cpu    = "250m"
            }
            limits = {
              memory = "256Mi"
              cpu    = "500m"
            }
          }
          volume_mount {
            name       = "gitea-data"
            mount_path = "/data"
          }
          port {
            name           = "ssh"
            container_port = 22
          }
          port {
            name           = "http"
            container_port = 3000
          }
        }

        # TODO: Add act runner
        # container {
        #   name = "act-runner"
        #   image = "gitea/gitea-runner:latest"
        #   image_pull_policy = "IfNotPresent"
        #   env_from {
        #     config_map_ref {
        #       name = kubernetes_config_map.gitea_config.metadata[0].name
        #     }
        #   }
        #   resources {
        #     requests = {
        #       memory = "128Mi"
        #       cpu    = "250m"
        #     }
        #     limits = {
        #       memory = "256Mi"
        #       cpu    = "500m"
        #     }
        #   }
        # }

        volume {
          name = "gitea-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.gitea_data_pvc.metadata[0].name
          }
        }
      }
    }
  }
}


# resource "kubernetes_deployment" "gitea_act_runner_deployment" {
#   metadata {
#     name      = "gitea-act-runner-depl"
#     namespace = kubernetes_namespace.gitea.metadata[0].name
#     labels = {
#       "app" = "gitea-act-runner"
#     }
#   }
#   spec {
#     replicas = 1
#     selector {
#       match_labels = {
#         "app" = "gitea-act-runner"
#       }
#     }
#     template {
#       metadata {
#         labels = {
#           "app" = "gitea-act-runner"
#         }
#       }
#       spec {
#         container {
#           name              = "act-runner"
#           image             = "gitea/gitea-runner:latest"
#           image_pull_policy = "IfNotPresent"
#           env_from {
#             config_map_ref {
#               name = kubernetes_config_map.gitea_act_runner_config.metadata[0].name
#             }
#           }
#           env {
#             name = "DOCKER_HOST"
#             value = "tcp://localhost:2376"
#           }
#           env {
#             name = "DOCKER_CERT_PATH"
#             value = "/certs/client"
#           }
#           env {
#             name = "DOCKER_TLS_VERIFY"
#             value = "1"
#           }
#           env {
#             name = "GITEA_INSTANCE_URL"
#             value = "http://gitea:3000"
#           }
#           env {
#             name = "GITEA_RUNNER_REGISTRATION_TOKEN"
#             value = "<gitea-runner-registration-token>"
#           }
#           resources {
#             limits = {
#               memory = "1024Mi"
#               cpu    = "1000m"
#             }
#             requests = {
#               memory = "256Mi"
#               cpu    = "500m"
#             }
#           }
#           security_context {
#             privileged = true
#           }
#           volume_mount {
#             name       = "act-runner-data"
#             mount_path = "/data"
#           }
#         }
#         security_context {
#           fs_group = 1000
#         }
#         volume {
#           name = "act-runner-data"
#           persistent_volume_claim {
#             claim_name = kubernetes_persistent_volume_claim.gitea_act_runner_pvc.metadata[0].name
#           }
#         }
#       }
#     }
#   }
# }

resource "kubernetes_service" "gitea_service" {
  metadata {
    labels = {
      "app" = "gitea"
    }
    namespace = kubernetes_namespace.gitea.metadata[0].name
    name      = "gitea"
  }
  spec {
    selector = {
      "app" = "gitea"
    }
    type = "NodePort"
    port {
      port        = 22
      target_port = 22
      node_port   = 30322
    }
    port {
      port        = 3000
      target_port = 3000
      node_port   = 30300
    }
  } 
}