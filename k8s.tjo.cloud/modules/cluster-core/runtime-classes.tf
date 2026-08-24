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
        memory = "2250Mi" # 250Mi for VMM + default_memory option
        cpu    = "250m"   # 250m  for VMM
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
