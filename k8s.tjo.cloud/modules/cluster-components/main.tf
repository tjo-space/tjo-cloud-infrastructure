resource "kubernetes_namespace" "tjo-cloud" {
  metadata {
    name = "tjo-cloud"
  }
}

resource "kubernetes_secret" "digitalocean-token" {
  metadata {
    name      = "digitalocean-token"
    namespace = kubernetes_namespace.tjo-cloud.metadata[0].name
  }
  data = {
    token = var.digitalocean_token
  }
}
