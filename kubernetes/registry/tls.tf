resource "kubernetes_secret" "registry_tls" {
  metadata {
    name      = "registry-tls"
    namespace = local.name
  }
  data = {
    crt = file("registry.crt")
    key = file("registry.key")
  }
}