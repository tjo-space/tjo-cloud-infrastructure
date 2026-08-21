resource "kubernetes_runtime_class_v1" "kata" {
  metadata {
    name = "kata"
  }
  handler = "kata"
}

resource "kubernetes_runtime_class_v1" "wasmedge" {
  metadata {
    name = "wasmedge"
  }
  handler = "wasmedge"
}
