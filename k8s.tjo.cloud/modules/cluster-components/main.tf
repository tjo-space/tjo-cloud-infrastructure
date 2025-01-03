resource "kubernetes_namespace" "tjo-cloud" {
  metadata {
    name = "tjo-cloud"
  }
}

resource "kubernetes_secret" "dnsimple" {
  metadata {
    name      = "dnsimple"
    namespace = kubernetes_namespace.tjo-cloud.metadata[0].name
  }
  data = {
    token = var.dnsimple_token
    account_id = var.dnsimple_account_id
  }
}
