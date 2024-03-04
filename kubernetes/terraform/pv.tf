resource "kubernetes_persistent_volume" "airflow_pg_pv" {
    metadata {
        name = "airflow-pg-pv"
    }

    spec {
        volume_mode = "Filesystem"
        persistent_volume_source {
            host_path {
                path = "/mnt/airflow_pg_pv"
                type = "DirectoryOrCreate"
            } 
        }
        capacity = {
            storage = "1Gi"
        }
        access_modes = ["ReadWriteOnce"]
        persistent_volume_reclaim_policy = "Delete"
        storage_class_name = var.storage_class_name
        node_affinity {
            required {
                node_selector_term {
                    match_expressions {
                        key = "kubernetes.io/hostname"
                        operator = "In"
                        values = ["homelab.alpine1"]
                    }
                }
            }
        }
    }
    
  
}

# resource "kubernetes_persistent_volume" "airflow_redis_pv" {
#     metadata {
#         name = "airflow-redis-pv"
#     }

#     spec {
#         volume_mode = "Filesystem"
#         persistent_volume_source {
#             host_path {
#                 path = "/mnt/airflow_redis_pv"
#                 type = "DirectoryOrCreate"
#             } 
#         }
#         capacity = {
#             storage = "1Gi"
#         }
#         access_modes = ["ReadWriteOnce"]
#         persistent_volume_reclaim_policy = "Delete"
#         storage_class_name = var.storage_class_name
#         node_affinity {
#             required {
#                 node_selector_term {
#                     match_expressions {
#                         key = "kubernetes.io/hostname"
#                         operator = "In"
#                         values = ["homelab.alpine1"]
#                     }
#                 }
#             }
#         }
#     }
# }