resource "kubernetes_namespace" "trino" {
  metadata {
    name = "trino"
  }
}

resource "kubernetes_deployment" "trino_deployment" {
  metadata {
    name      = "trino-deployment"
    namespace = kubernetes_namespace.trino.metadata[0].name
    labels = {
      "app" = "trino"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        "app" = "trino"
      }
    }
    template {
      metadata {
        labels = {
          "app" = "trino"
        }
      }
      spec {
        container {
          name              = "trino"
          image             = "trinodb/trino"
          image_pull_policy = "IfNotPresent"
          port {
            container_port = 8080
          }
          env {
            name  = "CATALOG_MANAGEMENT"
            value = "dynamic"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "trino_service" {
  metadata {
    labels = {
      "app" = "trino"
    }
    namespace = kubernetes_namespace.trino.metadata[0].name
    name      = "trino"
  }
  spec {
    selector = {
      "app" = "trino"
    }
    type = "NodePort"
    port {
      port        = 8080
      target_port = 8080
      node_port   = 32767
    }
  }
}
