provider "postgresql" {
  
}

terraform {
  backend "kubernetes" {
    config_path = "~/.kube/config"
    secret_suffix = "postgres"
    labels = {
      "owner" = "terraform"
    }
  } 
}

resource "postgres_database" "ingestion_db" {
  name = "ingestion_db"
}

resource "postgres_" "name" {
  
}