resource "kubernetes_manifest" "acme-gateway" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = "acme"
      namespace = kubernetes_namespace.k8s-tjo-cloud.metadata[0].name
    }
    spec = {
      gatewayClassName = "envoy"
      listeners = [{
        name     = "http"
        protocol = "HTTP"
        port     = 80
        allowedRoutes = {
          kinds : [{ kind : "HTTPRoute" }]
          namespaces = { from = "All" }
        }
      }],
    }
  }

  wait {
    fields = {
      "status.addresses[0].type" = "IPAddress"
    }
  }
}

resource "kubernetes_manifest" "acme-enable-proxy-protocol-policy" {
  manifest = {
    apiVersion = "gateway.envoyproxy.io/v1alpha1"
    kind       = "ClientTrafficPolicy"
    metadata = {
      name      = "acme-enable-proxy-protocol-policy"
      namespace = kubernetes_namespace.k8s-tjo-cloud.metadata[0].name
    }
    spec = {
      targetRef = {
        group = "gateway.networking.k8s.io"
        kind  = "Gateway"
        name  = kubernetes_manifest.acme-gateway.object.metadata.name
      }
      enableProxyProtocol = true
    }
  }
}

resource "kubernetes_manifest" "issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "acme"
    }
    spec = {
      acme = {
        email  = "hostmaster@tjo.cloud"
        server = "https://acme-v02.api.letsencrypt.org/directory"
        privateKeySecretRef = {
          name = "k8s-tjo-cloud-acme-account"
        }
        solvers = [
          {
            http01 = {
              gatewayHTTPRoute = {
                parentRefs = [{
                  name      = kubernetes_manifest.acme-gateway.object.metadata.name
                  namespace = kubernetes_manifest.acme-gateway.object.metadata.namespace
                  kind      = "Gateway"
                }]
              }
            }
          }
        ]
      }
    }
  }
}
