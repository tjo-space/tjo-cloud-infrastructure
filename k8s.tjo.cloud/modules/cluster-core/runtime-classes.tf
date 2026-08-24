resource "kubernetes_manifest" "kata" {
  manifest = {
    apiVersion = "node.k8s.io/v1"
    kind       = "RuntimeClass"
    metadata = {
      name = "kata"
    }
    handler = "kata"
    overhead = {
      podFixed = {
        memory = "130Mi"
        cpu    = "200m"
      }
    }
  }
}

resource "kubernetes_manifest" "wasmedge" {
  manifest = {
    apiVersion = "node.k8s.io/v1"
    kind       = "RuntimeClass"
    metadata = {
      name = "wasmedge"
    }
    handler = "wasmedge"
  }
}
