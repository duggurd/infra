provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "default"
  insecure       = true
}

terraform {
  required_providers {
    clickhouse = {
      source = "ivanofthings/clickhouse"
    }
  }
}

provider "clickhouse" {
  port = 31671
  host = "homelab.kiko-ghoul.ts.net"
  username = "default"
  password = ""
}

resource "clickhouse_db" "test_db" {
 name = "test_db" 
 cluster = "cluster"
}


module "clickhouse_mod" {
  source = "./clickhouse/"
}

