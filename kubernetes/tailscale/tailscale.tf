resource "kubernetes_namespace" "tailscale" {
  metadata {
    name = "tailscale"
  }
}

resource "kubernetes_deployment" "tailscale_operator" {
  metadata {
    name      = "tailscale-operator"
    namespace = kubernetes_namespace.tailscale.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        name = "tailscale-operator"
      }
    }

    template {
      metadata {
        labels = {
          name = "tailscale-operator"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.tailscale_operator.metadata[0].name

        container {
          name  = "tailscale-operator"
          image = "tailscale/k8s-operator:latest"

          env {
            name = "OPERATOR_NAMESPACE"
            value_from {
              field_ref {
                field_path = "metadata.namespace"
              }
            }
          }

          env {
            name = "TAILSCALE_AUTH_KEY"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.tailscale_auth.metadata[0].name
                key  = "AUTH_KEY"
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_account" "tailscale_operator" {
  metadata {
    name      = "tailscale-operator"
    namespace = kubernetes_namespace.tailscale.metadata[0].name
  }
}

resource "kubernetes_cluster_role" "tailscale_operator" {
  metadata {
    name = "tailscale-operator"
  }
  rule {
    api_groups = [""]
    resources  = ["pods", "services", "secrets", "namespaces"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "daemonsets"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["networkpolicies"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["coordination.k8s.io"]
    resources  = ["leases"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }
}

resource "kubernetes_cluster_role_binding" "tailscale_operator" {
  metadata {
    name = "tailscale-operator"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.tailscale_operator.metadata[0].name
    namespace = kubernetes_namespace.tailscale.metadata[0].name
  }

  role_ref {
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.tailscale_operator.metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_secret" "tailscale_auth" {
  metadata {
    name      = "tailscale-auth"
    namespace = kubernetes_namespace.tailscale.metadata[0].name
  }

  type = "Opaque"

  data = {
    AUTH_KEY = var.tailscale_auth_key
  }
}
