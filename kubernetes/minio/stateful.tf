resource "kubernetes_stateful_set" "minio" {
  metadata {
    name = "minio"
    labels = {
      app = "minio"
    }
  }

  spec {
    service_name = "minio"
    replicas     = 2

    selector {
      match_labels = {
        app = "minio"
      }
    }

    template {
      metadata {
        labels = {
          app = "minio"
        }
      }

      spec {
        affinity {
          pod_anti_affinity {
            required_during_scheduling_ignored_during_execution {
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

        container {
          name  = "minio"
          image = "minio/minio:latest"

          args = ["server", "/data", "--console-address", ":9090"]

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
              memory = "2Gi"
            }
            requests = {
              cpu    = "500m"
              memory = "1Gi"
            }
          }
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "data"
      }
      spec {
        access_modes = ["ReadWriteOnce"]
        resources {
          requests = {
            storage = "50Gi"
          }
        }
      }
    }
  }
}


resource "kubernetes_service" "minio" {
  metadata {
    name = "minio"
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
      node_port   = 30009
    }
    port {
      name        = "api"
      port        = 9000
      target_port = 9000
      node_port   = 30010
    }
  }
}

resource "kubernetes_service" "minio_headless" {
  metadata {
    name = "minio-headless"
  }
  spec {
    cluster_ip = "None"
    selector = {
      app = "minio"
    }
    port {
      port        = 9000
      target_port = 9000
    }
  }
}


resource "kubernetes_service" "minio_individual" {
  count = kubernetes_stateful_set.minio.spec[0].replicas

  metadata {
    name = "minio-${count.index}"
  }

  spec {
    selector = {
      app = "minio"
      "statefulset.kubernetes.io/pod-name" = "minio-${count.index}"
    }
    port {
      port        = 9000
      target_port = 9000
    }
  }
}


resource "kubernetes_ingress_v1" "minio_ingress" {
  metadata {
    name = "minio-ingress"
    annotations = {
      "kubernetes.io/ingress.class" = "traefik"
    }
  }

  spec {
    rule {
      host = "minio-0.homelab.kiko-ghoul.ts.net"
      http {
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "minio-0"
              port {
                number = 9000
              }
            }
          }
        }
      }
    }

    rule {
      host = "minio-1.homelab.kiko-ghoul.ts.net"
      http {
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "minio-1"
              port {
                number = 9000
              }
            }
          }
        }
      }
    }
  }
}