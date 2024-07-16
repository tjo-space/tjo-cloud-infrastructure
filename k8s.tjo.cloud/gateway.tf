resource "kubernetes_secret" "digitalocean-token" {
  metadata {
    name      = "digitalocean-token"
    namespace = kubernetes_namespace.tjo-cloud.metadata[0].name
  }
  data = {
    token = var.digitalocean_token
  }
}

resource "helm_release" "cert-manager" {
  name       = "cert-manager"
  chart      = "cert-manager"
  repository = "https://charts.jetstack.io"
  version    = "v1.15.1"
  namespace  = kubernetes_namespace.tjo-cloud.metadata[0].name

  set {
    name  = "crds.enabled"
    value = true
  }

  set_list {
    name  = "extraArgs"
    value = ["--enable-gateway-api"]
  }
}

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
              digitalocean = {
                tokenSecretRef = {
                  name = kubernetes_secret.digitalocean-token.metadata[0].name
                  key  = "token"
                }
              }
            }
          }
        ]
      }
    }
  }
}

resource "helm_release" "envoy" {
  name       = "envoy"
  chart      = "gateway-helm"
  repository = "oci://docker.io/envoyproxy"
  version    = "v1.1.0-rc.1"
  namespace  = "kube-system"

  values = [
    yamlencode({
      config = {
        envoyGateway = {
          provider = {
            type = "Kubernetes"
            kubernetes = {
              envoyDaemonSet  = {}
              envoyDeployment = null
            }
          }
          gateway = {
            controllerName = "gateway.envoyproxy.io/gatewayclass-controller"
          }
          logging = {
            level = {
              default = "info"
            }
          }
        }
      }
    })
  ]
}

resource "kubernetes_manifest" "gateway-class" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "GatewayClass"
    metadata = {
      name = "envoy"
    }
    spec = {
      controllerName : "gateway.envoyproxy.io/gatewayclass-controller"
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
        "cert-manager.io/issuer" : "tjo-cloud"
      }
    }
    spec = {
      gatewayClassName = "envoy"
      listeners = [
        {
          name : "http"
          hostname : "*.${module.cluster.name}.${module.cluster.domain}"
          protocol : "HTTPS"
          port : 443
          allowedRoutes : {
            namespaces : {
              from : "Same"
            }
          }
          tls : {
            mode : "Terminate"
            certificateRefs : [
              {
                name : "tjo-cloud-tls"
              }
            ]
          }
        }
      ]
    }
  }
}
