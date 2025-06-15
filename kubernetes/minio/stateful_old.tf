# # https://min.io/docs/minio/linux/operations/install-deploy-manage/deploy-minio-multi-node-multi-drive.html

# resource "kubernetes_namespace" "minio_old" {
#   metadata {
#     name = "minio-old"
#   }
#   lifecycle {
#     prevent_destroy = true
#   }
# }


# locals {
#   replicas_old = 2
# }


# # resource "kubernetes_persistent_volume" "minio_old" {
# #   for_each = zipmap(range(local.replicas_old), var.nodes)
  
# #   metadata {
# #     name = "data-minio-old-${each.key}"
# #     labels = {
# #       app = "minio-old"
# #     }
# #   }
# #   spec {
# #     access_modes = ["ReadWriteOnce"]
# #     storage_class_name = "local-path"
# #     capacity = {
# #       storage = local.storage
# #     }
    
# #     persistent_volume_reclaim_policy = "Retain"

# #     persistent_volume_source {
# #       local {
# #         path = "/mnt/minio"
# #       }
# #     }

# #     node_affinity {
# #       required {
# #         node_selector_term {
# #           match_expressions {
# #             key      = "kubernetes.io/hostname"   # Node label to match
# #             operator = "In"                       # Using the "In" operator
# #             values   = [each.value]                 # Match the specific node
# #           }
# #         }
# #       }
# #     }
# #   }
# # }

# # resource "kubernetes_persistent_volume_claim" "minio_old" {
# #   for_each = zipmap(range(local.replicas_old), [for pv in kubernetes_persistent_volume.minio_old : "${pv.metadata[0].name}"])
# #   metadata {
# #     name = "data-minio-old-${each.key}"
# #     namespace = kubernetes_namespace.minio_old.metadata[0].name
# #   }
# #   spec {
# #     storage_class_name = "local-path"
# #     volume_name = each.value
# #     access_modes = ["ReadWriteOnce"]
# #     resources {
# #       requests = {
# #         storage = local.storage
# #       }
# #     }
# #   }
# #   wait_until_bound = false
# # }



# resource "kubernetes_service" "minio_old_headless" {
#   metadata {
#     name      = "minio-old-headless" # Choose a distinct name for the headless service
#     namespace = kubernetes_namespace.minio_old.metadata[0].name
#     labels = {
#       app = "minio-old" # This label should match your pod labels
#     }
#   }
#   spec {
#     cluster_ip = "None" # This makes it a headless service
#     selector = {
#       app = "minio-old" # This must match the labels on your minio-old-0 and minio-old-1 pods
#     }
#     port {
#       name        = "api"
#       port        = 9001 # MinIO API port
#       target_port = 9001
#     }
#     port {
#       name        = "console"
#       port        = 9091 # MinIO Console port
#       target_port = 9091
#     }
#   }
# }

# resource "kubernetes_stateful_set" "minio_old" {
#   timeouts {
#     create = "2m"
#   }
#   metadata {
#     name = "minio-old"
#     namespace = kubernetes_namespace.minio_old.metadata[0].name
#     labels = {
#       app = "minio-old"
#     }
#   }

#   spec {
#     service_name = "minio-old-headless"
#     replicas     = local.replicas_old

#     selector {
#       match_labels = {
#         app = "minio-old"
#       }
#     }

#     template {
#       metadata {
#         labels = {
#           app = "minio-old"
#         }
#       }

#       spec {
#         affinity {
#           pod_anti_affinity {
#             required_during_scheduling_ignored_during_execution {
#               label_selector {
#                 match_expressions {
#                   key      = "app"
#                   operator = "In"
#                   values   = ["minio-old"]
#                 }
#               }
#               topology_key = "kubernetes.io/hostname"
#             }
#           }
#         }

#         container {
#           name  = "minio"
#           image = "minio/minio@sha256:a616cd8f37758b0296db62cc9e6af05a074e844cc7b5c0a0e62176d73828d440"
#           args = concat(
#             ["server"],
#             [for i in range(local.replicas_old) : "http://minio-old-${i}.minio-old-headless.minio-old.svc.cluster.local:9001/data"],
#             ["--console-address", ":9091"],
#             ["--address", ":9001"]
#           )
#           image_pull_policy = "IfNotPresent"

#           port {
#             name           = "api"
#             container_port = 9001
#           }
#           port {
#             name           = "web"
#             container_port = 9091
#           }

#           volume_mount {
#             name       = "data"
#             mount_path = "/data"
#           }

#           resources {
#             limits = {
#               cpu    = "1"
#               memory = "1Gi"
#             }
#             requests = {
#               cpu    = "500m"
#               memory = "512Mi"
#             }
#           }
#         }
#       }
#     }
    
#     volume_claim_template {
#       metadata {
#         name = "data"
#       }
#       spec {
#         access_modes = ["ReadWriteOnce"]
#         storage_class_name = "local-path"
#         # selector {
#         #   match_labels = {
#         #     app = "minio-old"
#         #   }
#         # }
#         resources {
#           requests = {
#             storage = local.storage
#           }
#         }
#       }
#     }
#   }
# }

# resource "kubernetes_service" "minio_old" {
#   metadata {
#     name = "minio-old"
#     namespace = kubernetes_namespace.minio_old.metadata[0].name
#   }
#   spec {
#     type = "NodePort"
#     selector = {
#       app = "minio-old"
#     }
#     port {
#       name        = "web"
#       port        = 9091
#       target_port = 9091
#       node_port   = 30092
#     }
#     port {
#       name        = "api"
#       port        = 9001
#       target_port = 9001
#       node_port   = 30093
#     }
#   }
# }

