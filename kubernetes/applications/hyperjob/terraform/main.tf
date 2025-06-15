provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "default"
}

terraform {
  backend "kubernetes" {
    config_path   = "~/.kube/config"
    secret_suffix = "hyperjob"
    labels = {
      "owner" = "terraform"
    }
  }
}

resource "kubernetes_namespace" "hyperjob" {
  metadata {
    name = "hyperjob"
  }
}
