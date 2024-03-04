resource "kubernetes_persistent_volume_claim" "airflow_pg_pvc" {
    metadata {
        name = "airflow-pg-pvc"
        # namespace = kubernetes_namespace.airflow.metadata[0].name
    }
    wait_until_bound = false
    spec {
        volume_name = kubernetes_persistent_volume.airflow_pg_pv.metadata[0].name  
        storage_class_name = var.storage_class_name
        access_modes = [ "ReadWriteOnce" ]
        resources {
            requests = {
              storage = "1Gi"
            }
        }
    }
}


# resource "kubernetes_persistent_volume_claim" "airflow_redis_pvc" {
#     metadata {
#         name = "airflow-redis-pvc"
#         # namespace = kubernetes_namespace.airflow.metadata[0].name
#     }
#     wait_until_bound = false
#     spec {
#         volume_name = kubernetes_persistent_volume.airflow_redis_pv.metadata[0].name  
#         storage_class_name = var.storage_class_name
#         access_modes = [ "ReadWriteOnce" ]
#         resources {
#             requests = {
#               storage = "1Gi"
#             }
#         }
#     }
# }