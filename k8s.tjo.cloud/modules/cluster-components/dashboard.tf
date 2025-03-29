resource "helm_release" "dashboard" {
  name            = "kubernetes-dashboard"
  repository      = "https://kubernetes.github.io/dashboard"
  chart           = "kubernetes-dashboard"
  version         = "7.5.0"
  namespace       = kubernetes_namespace.tjo-cloud.metadata[0].name
  atomic          = true
  cleanup_on_fail = true

  set {
    name  = "kong.enabled"
    value = false
  }
}

resource "kubernetes_manifest" "dashoard-http-route" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "dashboard"
      namespace = kubernetes_namespace.tjo-cloud.metadata[0].name
    }
    spec = {
      parentRefs = [
        {
          name = kubernetes_manifest.gateway.object.metadata.name
        }
      ]
      hostnames = [
        "dashboard.${var.cluster_domain}"
      ]
      rules = [
        {
          matches = [
            {
              path = {
                value = "/"
                type  = "PathPrefix"
              }
            }
          ]
          backendRefs = [
            {
              name = "kubernetes-dashboard-web"
              port = 8000
            }
          ]
        },
        {
          matches = [
            {
              path = {
                value = "/api/v1/login"
                type  = "PathPrefix"
              }
            },
            {
              path = {
                value = "/api/v1/csrftoken/login"
                type  = "PathPrefix"
              }
            },
            {
              path = {
                value = "/api/v1/me"
                type  = "PathPrefix"
              }
            },
          ]
          backendRefs = [
            {
              name = "kubernetes-dashboard-auth"
              port = 8000
            }
          ]
        },
        {
          matches = [
            {
              path = {
                value = "/api"
                type  = "PathPrefix"
              }
            }
          ]
          backendRefs = [
            {
              name = "kubernetes-dashboard-api"
              port = 8000
            }
          ]
        },
      ]
    }
  }
}

resource "kubernetes_secret" "dashboard-oidc" {
  metadata {
    name      = "dashboard-oidc"
    namespace = kubernetes_namespace.tjo-cloud.metadata[0].name
  }
  data = {
    client-secret = "null"
  }
}

resource "kubernetes_manifest" "dashboard-oidc" {
  manifest = {
    apiVersion = "gateway.envoyproxy.io/v1alpha1"
    kind       = "SecurityPolicy"
    metadata = {
      name      = "dashboard-oidc"
      namespace = kubernetes_namespace.tjo-cloud.metadata[0].name
    }
    spec = {
      targetRef = {
        group = "gateway.networking.k8s.io"
        kind  = "HTTPRoute"
        name  = kubernetes_manifest.dashoard-http-route.object.metadata.name
      }
      oidc = {
        provider = {
          issuer = var.oidc_issuer_url
        }
        clientID = var.oidc_client_id
        clientSecret = {
          name = kubernetes_secret.dashboard-oidc.metadata[0].name
        }
        scopes             = ["openid", "email", "profile"]
        forwardAccessToken = true

        redirectURL = "https://dashboard.${var.cluster_domain}/login"
      }
    }
  }
}
