provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "default"
}

terraform {
  backend "kubernetes" {
    config_path   = "~/.kube/config"
    secret_suffix = "jenkins"
    labels = {
      "owner" = "terraform"
    }
  }
}


resource "kubernetes_namespace" "jenkins_ns" {
  metadata {
    name = "jenkins-ns"
  }
}

resource "kubernetes_role" "jenkins_admin" {
  metadata {
    name      = "jenkins-admin"
    namespace = kubernetes_namespace.jenkins_ns.metadata.0.name
  }
  rule {
    api_groups = [""]
    resources  = ["*"]
    verbs      = ["*"]
  }
}

resource "kubernetes_service_account" "jenkins_admin" {
  metadata {
    name      = "jenkins-admin"
    namespace = kubernetes_namespace.jenkins_ns.metadata.0.name
  }
}

resource "kubernetes_role_binding" "jenkins_admin" {
  metadata {
    name      = "jenkins-admin"
    namespace = kubernetes_namespace.jenkins_ns.metadata.0.name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "jenkins-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "jenkins-admin"
    namespace = kubernetes_namespace.jenkins_ns.metadata.0.name
  }
}


resource "kubernetes_persistent_volume" "jenkins_pv" {
  metadata {
    name = "jenkins-pv"
  }
  spec {
    # storage_class_name = "local-storage"
    capacity = {
      storage = "5Gi"
    }
    access_modes = ["ReadWriteOnce"]
    persistent_volume_source {
      local {
        path = "/mnt/jenkins"
      }
    }
    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key      = "kubernetes.io/hostname"
            operator = "In"
            values   = ["homelab.alpine2"]
          }
        }
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "jenkins_pvc" {
  metadata {
    name      = "jenkins-pvc"
    namespace = kubernetes_namespace.jenkins_ns.metadata.0.name
  }
  spec {
    # storage_class_name = "local-storage"
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "5Gi"
      }
    }
  }
  wait_until_bound = false
}

resource "kubernetes_deployment" "jenkins_depl" {
  metadata {
    name      = "jenkins-depl"
    namespace = kubernetes_namespace.jenkins_ns.metadata.0.name
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        "app" = "jenkins-server"
      }
    }
    template {
      metadata {
        labels = {
          "app" = "jenkins-server"
        }
      }
      spec {
        security_context {
          fs_group    = 1000
          run_as_user = 1000
        }
        service_account_name = kubernetes_service_account.jenkins_admin.metadata.0.name
        container {
          name  = "jenkins"
          image = "jenkins/jenkins"
          resources {
            limits = {
              "memory" = "2Gi"
              "cpu"    = "1000m"
            }
            requests = {
              "memory" = "500Mi"
              "cpu"    = "500m"
            }
          }
          port {
            name           = "httpport"
            container_port = 8080
          }
          port {
            name           = "jnlpport"
            container_port = 50000
          }
          liveness_probe {
            http_get {
              path = "/login"
              port = 8080
            }
            initial_delay_seconds = 90
            period_seconds        = 60
            timeout_seconds       = 5
            failure_threshold     = 5
          }
          readiness_probe {
            http_get {
              path = "/login"
              port = 8080
            }
            initial_delay_seconds = 60
            period_seconds        = 60
            timeout_seconds       = 5
            failure_threshold     = 5
          }
          volume_mount {
            name       = "jenkins-data"
            mount_path = "/var/jenkins_home"
          }
        }
        volume {
          name = "jenkins-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.jenkins_pvc.metadata.0.name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "jenkins_svc" {
  metadata {
    name      = "jenkins-svc"
    namespace = kubernetes_namespace.jenkins_ns.metadata.0.name
  }
  spec {
    selector = {
      "app" = "jenkins-server"
    }
    type = "NodePort"
    port {
      port        = 8080
      target_port = 8080
      node_port   = 32000
    }
  }
}
