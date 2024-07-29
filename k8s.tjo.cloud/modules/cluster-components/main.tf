resource "kubernetes_namespace" "tjo-cloud" {
  metadata {
    name = "tjo-cloud"
  }
}
