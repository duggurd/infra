provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "default"
}

terraform {
  backend "kubernetes" {
    config_path   = "~/.kube/config"
    secret_suffix = "minio"
    labels = {
      "owner" = "terraform"
    }
  }
  required_providers {
      minio = {
        source = "aminueza/minio"
        version = "2.5.1"
      }
  }
}

provider "minio" {
  minio_server = var.minio_endpoint
  minio_user = var.minio_access_key
  minio_password = var.minio_secret_key
}