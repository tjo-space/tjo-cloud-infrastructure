resource "kubernetes_namespace" "tjo-cloud" {
  metadata {
    name = "tjo-cloud"
  }
}

resource "kubernetes_manifest" "loadbalancer_ips" {
  for_each = var.loadbalancer_ips

  manifest = {
    apiVersion = "cilium.io/v2alpha1"
    kind       = "CiliumLoadBalancerIPPool"
    metadata = {
      name = each.key
    }
    spec = {
      blocks = [for ip in each.value.ipv4 : { start : ip }]
    }
  }
}
