resource "kubernetes_manifest" "gateway" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = "primary"
      namespace = kubernetes_namespace.k8s-tjo-cloud.metadata[0].name
      annotations = {
        "cert-manager.io/issuer"                  = "primary"
        "external-dns.alpha.kubernetes.io/target" = "any.ingress.tjo.cloud"
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
            { kind : "GRPCRoute" },
          ]
          namespaces = {
            from = "All"
          }
        }
      }]
    }
  }

  wait {
    fields = {
      "status.addresses[0].type"  = "IPAddress"
      "status.addresses[0].value" = "^(\\d+(\\.|$)){4}"
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
