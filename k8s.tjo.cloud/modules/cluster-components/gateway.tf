data "dns_a_record_set" "ingress" {
  host = "any.ingress.tjo.cloud"
}

data "dns_aaaa_record_set" "ingress" {
  host = "any.ingress.tjo.cloud"
}

resource "kubernetes_manifest" "gateway" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = "primary"
      namespace = kubernetes_namespace.k8s-tjo-cloud.metadata[0].name
      annotations = {
        "cert-manager.io/cluster-issuer"          = "acme"
        "external-dns.alpha.kubernetes.io/target" = "${join(",", data.dns_a_record_set.ingress.addrs)},${join(",", data.dns_aaaa_record_set.ingress.addrs)}"
      }
    }
    spec = {
      gatewayClassName = "envoy"
      listeners = concat(
        # HTTP
        [{
          name     = "http"
          protocol = "HTTP"
          port     = 80
          allowedRoutes = {
            kinds : [
              { kind : "HTTPRoute" },
            ]
            # Only allow HTTPRoute from the same namespace
            # as we only need this for cert-manager.
            # All other namespaces should use HTTPS instead.
            namespaces = { from = "All" }
          }
        }],
        # HTTPS
        ## Precise Domain
        [for key, domain in var.domains : {
          name     = "${key}-precise"
          hostname = domain.domain
          protocol = "HTTPS"
          port     = 443
          tls = {
            mode = "Terminate"
            certificateRefs = [{
              name = "${key}-precise-tls"
            }]
          }
          allowedRoutes = {
            kinds : [
              { kind : "HTTPRoute" },
              { kind : "GRPCRoute" }
            ]
            namespaces = { from = "All" }
          }
        }],
        ## Wildcard Domain
        [for key, domain in var.domains : {
          name     = "${key}-wildcard"
          hostname = "*.${domain.domain}"
          protocol = "HTTPS"
          port     = 443
          tls = {
            mode = "Terminate"
            certificateRefs = [{
              name = "${key}-wildcard-tls"
            }]
          }
          allowedRoutes = {
            kinds : [
              { kind : "HTTPRoute" },
              { kind : "GRPCRoute" }
            ]
            namespaces = { from = "All" }
          }
        } if domain.wildcard == true],
      )
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
