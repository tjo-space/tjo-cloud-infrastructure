resource "kubernetes_manifest" "gateway" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = "primary"
      namespace = kubernetes_namespace.tjo-cloud.metadata[0].name
      annotations = {
        "cert-manager.io/issuer" = "primary"
      }
    }
    spec = {
      gatewayClassName = "envoy"
      listeners = [for key, domain in var.domains : {
        name     = key
        hostname = "*.${domain.domain}"
        protocol = "HTTPS"
        port     = 443
        tls = {
          mode = "Terminate"
          certificateRefs = [
            {
              name = "${key}-tls"
            }
          ]
        }
        allowedRoutes = {
          kinds : [
            { kind : "HTTPRoute" },
            { kind : "TLSRoute" },
            { kind : "TCPRoute" },
            { kind : "UDPRoute" },
            { kind : "GRPCRoute" },
          ]
          namespaces = {
            from = "All"
          }
        }
      }]
    }
  }
}

resource "kubernetes_manifest" "enable-proxy-protocol-policy" {
  manifest = {
    apiVersion = "gateway.envoyproxy.io/v1alpha1"
    kind       = "ClientTrafficPolicy"
    metadata = {
      name      = "enable-proxy-protocol-policy"
      namespace = kubernetes_namespace.tjo-cloud.metadata[0].name
    }
    spec = {
      targetRef = {
        group = "gateway.networking.k8s.io"
        kind  = "Gateway"
        name  = kubernetes_manifest.gateway.object.metadata.name
      }
      enableProxyProtocol = false
    }
  }
}
