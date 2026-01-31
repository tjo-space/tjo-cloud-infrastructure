resource "kubernetes_manifest" "gateway" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = "k8s-tjo-cloud"
      namespace = kubernetes_namespace.k8s-tjo-cloud.metadata[0].name
      annotations = {
        "cert-manager.io/cluster-issuer" = "acme"
      }
    }
    spec = {
      gatewayClassName = "envoy"
      listeners = concat(
        # HTTPS
        [for domain in [
          "argocd.k8s.tjo.cloud",
          "dashboard.k8s.tjo.cloud",
          ] : {
          name     = domain
          hostname = domain
          protocol = "HTTPS"
          port     = 443
          tls = {
            mode = "Terminate"
            certificateRefs = [{
              name = "${domain}-tls"
            }]
          }
          allowedRoutes = {
            kinds : [
              { kind : "HTTPRoute" },
              { kind : "GRPCRoute" }
            ]
            namespaces = { from = "Same" }
          }
        }],
      )
    }
  }

  wait {
    fields = {
      "status.addresses[0].type" = "IPAddress"
    }
  }
}

resource "kubernetes_manifest" "enable-proxy-protocol-policy" {
  manifest = {
    apiVersion = "gateway.envoyproxy.io/v1alpha1"
    kind       = "ClientTrafficPolicy"
    metadata = {
      name      = "enable-proxy-protocol-policy"
      namespace = kubernetes_namespace.k8s-tjo-cloud.metadata[0].name
    }
    spec = {
      targetRef = {
        group = "gateway.networking.k8s.io"
        kind  = "Gateway"
        name  = kubernetes_manifest.gateway.object.metadata.name
      }
      enableProxyProtocol = true
    }
  }
}
