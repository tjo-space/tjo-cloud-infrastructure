resource "helm_release" "cert-manager-dnsimple" {
  name            = "cert-manager-webhook-dnsimple"
  chart           = "cert-manager-webhook-dnsimple"
  repository      = "https://puzzle.github.io/cert-manager-webhook-dnsimple"
  version         = "v0.1.6"
  namespace       = kubernetes_namespace.tjo-cloud.metadata[0].name
  atomic          = true
  cleanup_on_fail = true

  values = [<<-EOF
      dnsimple:
        tokenSecretName:  "${kubernetes_secret.dnsimple.metadata[0].name}"
        existingTokenSecret: true
        account_id: "${var.dnsimple_account_id}"
      certManager:
        namespace: "kube-system"
        serviceAccountName: "cert-manager"
    EOF
  ]
}

resource "kubernetes_manifest" "privilieged-issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Issuer"
    metadata = {
      name      = "privileged"
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
                  accountID = var.dnsimple_account_id
                }
              }
            }
            selector = {
              dnsZones = [
                var.domains.privileged
              ]
            }
          }
        ]
      }
    }
  }
}

resource "kubernetes_manifest" "usercontent-issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "usercontent"
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
                  accountID = var.dnsimple_account_id
                }
              }
            }
            selector = {
              dnsZones = [
                var.domains.usercontent
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
              "external-dns.alpha.kubernetes.io/internal-hostname" = "envoy-internal.k8s.tjo.cloud"
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
      name      = "primary"
      namespace = kubernetes_namespace.tjo-cloud.metadata[0].name
      annotations = {
        "cert-manager.io/issuer" = kubernetes_manifest.privilieged-issuer.object.metadata.name
      }
    }
    spec = {
      gatewayClassName = kubernetes_manifest.gateway_class.object.metadata.name
      listeners = [
        {
          name     = "privileged"
          hostname = "*.${var.domains.privileged}"
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
                name = "${kubernetes_manifest.privilieged-issuer.object.metadata.name}-tls"
              }
            ]
          }
        },
        {
          name     = "usercontent"
          hostname = "*.${var.domains.usercontent}"
          protocol = "HTTPS"
          port     = 443
          allowedRoutes = {
            namespaces = {
              from = "All"
            }
          }
          tls = {
            mode = "Terminate"
            certificateRefs = [
              {
                name = "${kubernetes_manifest.usercontent-issuer.object.metadata.name}-tls"
              }
            ]
          }
        },
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
