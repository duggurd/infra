provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "default"
  insecure       = true
}

terraform {
  backend "kubernetes" {
    secret_suffix = "clickhouse"
    host = "value"
    load_config_file = true
    insecure = true
    namespace = "terraform"
    labels = {
      "owner" = "terraform"
    }
  }     
}

module "clickhouse_mod" {
  source = "./clickhouse/"
}

