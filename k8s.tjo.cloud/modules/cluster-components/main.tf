resource "kubernetes_namespace" "k8s-tjo-cloud" {
  metadata {
    name = "k8s-tjo-cloud"
  }
}
