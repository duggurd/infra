provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "default"
}

terraform {
  backend "kubernetes" {
    config_path = "~/.kube/config"
    secret_suffix = "airflow"
    labels = {
      "owner" = "terraform"
    }
  }     
}

resource "kubernetes_namespace" "airflow" {
  metadata {
    name = "airflow"
  }
}

resource "kubernetes_config_map" "airflow_config" {
  metadata {
    name = "airflow-conf"
    namespace = kubernetes_namespace.airflow.metadata[0].name
  }
  
}