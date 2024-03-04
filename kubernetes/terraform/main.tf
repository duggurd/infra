terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25.2"
    }
    # docker = {
    #   source  = "kreuzwerker/docker"
    #   version = "3.0.2"
    # }
  }
}

# provider "docker" {
#   host = var.docker_host
# }

provider "kubernetes" {
    config_path = "~/.kube/config"	
    config_context = var.kubernetes_context
}

module "registry" {
  source = "./registry"
  storage_class_name = module.storage.local_storage_class
}

module "airflow" {
  source = "./airflow"
  storage_class_name = module.storage.local_storage_class
  postgres_password = var.postgres_password
}

module "storage" {
  source = "./storage"
}