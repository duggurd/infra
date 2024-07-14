provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "default"
  insecure       = true
}
