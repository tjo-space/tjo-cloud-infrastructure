resource "kubernetes_manifest" "tjo-cloud-issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Issuer"
    metadata = {
      name      = "tjo-cloud"
      namespace = kubernetes_namespace.tjo-cloud.metadata[0].name
    }
    spec = {
      acme = {
        email  = "tine@tjo.space"
        server = "https://acme-staging-v02.api.letsencrypt.org/directory"
        privateKeySecretRef = {
          name = "tjo-cloud-acme-account"
        }
        solvers = [
          {
            dns01 = {
              webhook = {
                solverName = "dnsimple"
                groupName  = "acme.dnsimple.com"
                config = {
                  tokenSecretRef = {
                    name = kubernetes_secret.dnsimple.metadata[0].name
                    key  = "token"
                  }
                }
              }
            }
            selector : {
              dnsZones : [
                "tjo.cloud"
              ]
            }
          }
        ]
      }
    }
  }
}

resource "kubernetes_manifest" "gateway_class_config" {
  manifest = {
    apiVersion = "gateway.envoyproxy.io/v1alpha1"
    kind       = "EnvoyProxy"
    metadata = {
      name      = "daemonset"
      namespace = kubernetes_namespace.tjo-cloud.metadata[0].name
    }
    spec = {
      mergeGateways = true
      provider = {
        type = "Kubernetes"
        kubernetes = {
          envoyService = {
            annotations = {
              "external-dns.alpha.kubernetes.io/internal-hostname" = "envoy.internal.k8s.tjo.cloud"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_manifest" "gateway_class" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "GatewayClass"
    metadata = {
      name = "envoy"
    }
    spec = {
      controllerName = "gateway.envoyproxy.io/gatewayclass-controller"
      parametersRef = {
        group     = "gateway.envoyproxy.io"
        kind      = "EnvoyProxy"
        name      = kubernetes_manifest.gateway_class_config.object.metadata.name
        namespace = kubernetes_manifest.gateway_class_config.object.metadata.namespace
      }
    }
  }
}

resource "kubernetes_manifest" "gateway" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = "gateway"
      namespace = kubernetes_namespace.tjo-cloud.metadata[0].name
      annotations = {
        "cert-manager.io/issuer" = "tjo-cloud"
      }
    }
    spec = {
      gatewayClassName = kubernetes_manifest.gateway_class.object.metadata.name
      listeners = [
        {
          name     = "http"
          hostname = "*.${var.cluster_domain}"
          protocol = "HTTPS"
          port     = 443
          allowedRoutes = {
            namespaces = {
              from = "Same"
            }
          }
          tls = {
            mode = "Terminate"
            certificateRefs = [
              {
                name = "tjo-cloud-tls"
              }
            ]
          }
        }
      ]
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
