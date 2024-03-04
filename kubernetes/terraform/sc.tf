resource "kubernetes_storage_class" "local_storage" {
    metadata {
        name = "local-storage"
    }
    storage_provisioner = "kubernetes.io/no-provisioner"
    volume_binding_mode = "WaitForFirstConsumer"
}


output "local_storage_class" {
  value = kubernetes_storage_class.local_storage.metadata[0].name
}