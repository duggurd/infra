resource "kubernetes_namespace" "clickhouse_ns" {
  metadata {
    name = "clickhouse-ns"
  }
}

resource "kubernetes_persistent_volume_claim" "clickhouse_pvc" {
   metadata {
       name = "clickhouse-pvc"
       namespace = kubernetes_namespace.clickhouse_ns.metadata.0.name 
   }
   spec {
       access_modes = ["ReadWriteOnce"]
        resources {
          requests = {
            storage = "50Gi"
          }
        }
      # volume_name = "${kubernetes_persistent_volume.clickhouse_pv.metadata.0.name}"
   }
   wait_until_bound = false
}


resource "kubernetes_pod" "clickhouse_pod" {
  metadata {
    name = "clickhouse-pod"
    namespace = kubernetes_namespace.clickhouse_ns.metadata.0.name
    labels = {
      "app" = "clickhouse" 
    }
  }
  spec {
    container {
      name = "clickhouse"    
      image = "clickhouse/clickhouse-server:head-alpine"
      image_pull_policy = "IfNotPresent"

      port {
       container_port = 8123 
      }

      volume_mount {
       mount_path = "/var/lib/clickhouse/" 
       name = "clickhouse-data"
      }
    }

    volume {
      name = "clickhouse-data"
      persistent_volume_claim {
       claim_name = kubernetes_persistent_volume_claim.clickhouse_pvc.metadata.0.name 
      } 
    }
  } 
}


resource "kubernetes_service" "clickhouse_svc" {
 metadata {
  name = "clickhouse-svc" 
  namespace = kubernetes_namespace.clickhouse_ns.metadata.0.name
 }   
 spec {
   selector = {
     "app" = "clickhouse"
   }
  type = "NodePort"  
  port {
    port = 8123
    target_port = 8123
  }
 }
}

