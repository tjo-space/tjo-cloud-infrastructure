resource "kubernetes_namespace" "k8s-tjo-cloud" {
  metadata {
    name = "k8s-tjo-cloud"
  }
}

resource "kubernetes_secret" "desec" {
  metadata {
    name      = "desec"
    namespace = kubernetes_namespace.k8s-tjo-cloud.metadata[0].name
  }
  data = {
    token = var.desec.token
  }
}

resource "helm_release" "external-dns" {
  name       = "external-dns"
  chart      = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  version    = "v1.19.0"
  namespace  = kubernetes_namespace.k8s-tjo-cloud.metadata[0].name

  values = [yamlencode({
    provider = {
      name = "webhook"
      webhook = {
        image = {
          repository = "ghcr.io/michelangelomo/external-dns-desec-provider"
          tag        = "v0.1.1"
        }
        env = [
          {
            name = "WEBHOOK_APITOKEN"
            valueFrom = {
              secretKeyRef = {
                name = "desec"
                key  = "token"
              }
            }
          },
          {
            name  = "WEBHOOK_DOMAINFILTERS"
            value = join(",", [for domain in var.domains : domain.zone])
          }
        ]
        livenessProbe = {
          httpGet = {
            path = "/healthz"
            port = "http-webhook"
          }
          initialDelaySeconds = 10
          timeoutSeconds      = 5
        }
        readinessProbe = {
          httpGet = {
            path = "/readyz"
            port = "http-webhook"
          }
          initialDelaySeconds = 10
          timeoutSeconds      = 5
        }
      }
    }
    # Adjust interval, events and caching
    # to reduce number of API calls done.
    # Ref: https://github.com/michelangelomo/external-dns-desec-provider/issues/8
    # Ref: https://github.com/kubernetes-sigs/external-dns/issues/5796#issuecomment-3303361778
    interval           = "10m"
    triggerLoopOnEvent = true
    extraArgs = [
      "--provider-cache-time=30m",
      "--txt-cache-interval=1m",
      "--min-event-sync-interval=1m",
    ]
    sources = [
      "ingress",
      "service",
      "gateway-httproute",
      "gateway-grpcroute",
      "gateway-tlsroute",
      "gateway-tcproute"
    ]
    domainFilters = [for domain in var.domains : domain.domain]
  })]
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
        email  = "tine@tjo.space"
        server = "https://acme-v02.api.letsencrypt.org/directory"
        privateKeySecretRef = {
          name = "k8s-tjo-cloud-acme-account"
        }
        solvers = [
          {
            http01 = {
              gatewayHTTPRoute = {
                parentRefs = [{
                  name = kubernetes_manifest.gateway.object.metadata.name
                  kind = "Gateway"
                }]
              }
            }
          }
        ]
      }
    }
  }
}
