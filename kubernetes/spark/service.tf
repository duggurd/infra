resource "kubernetes_namespace" "spark" {
  metadata {
    name = "spark"
  }
  lifecycle {
    prevent_destroy = true
  }
}


resource "kubernetes_deployment" "spark" {
    timeouts {
      create = "2m"
    }
  metadata {
    name = "spark"
    namespace = kubernetes_namespace.spark.metadata[0].name
    labels = {
      app = "spark"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "spark"
      }
    }
    template {
      metadata {
        labels = {
          app = "spark"
        }
      }
      spec {
        container {
          name              = "spark"
          image             = "spark:3.4.4-python3"
          image_pull_policy = "IfNotPresent"

          command = ["/bin/bash", "-c", "cd /opt/spark/sbin && ./start-master.sh --port 7077 --webui-port 8080 && ./start-thriftserver.sh && tail -f /dev/null"]
          port {
            name           = "service"
            container_port = 7077
            host_port      = 7077
          }
          port {
            name           = "webui"
            container_port = 8080
            host_port      = 8080
          }
          resources {
            requests = {
              cpu    = "500m"
              memory = "2Gi"
            }
            limits = {
              cpu    = "2"
              memory = "4Gi"
            }
          }
        }
      }
    }
  }
}


resource "kubernetes_service" "spark" {
  metadata {
    name = "spark"
    namespace = kubernetes_namespace.spark.metadata[0].name
    labels = {
      app = "spark"
    }
  }
  spec {
    selector = {
      app = "spark"
    }
    type = "NodePort"
    port {
      name        = "webui"
      port        = 8080
      target_port = 8080
      node_port   = 30180
    }
    port {
      name        = "service"
      port        = 7070
      target_port = 7070
      node_port   = 30170
    }
  }
}