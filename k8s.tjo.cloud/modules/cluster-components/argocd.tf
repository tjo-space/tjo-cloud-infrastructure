resource "helm_release" "argocd" {
  name            = "argo-cd"
  chart           = "argo-cd"
  repository      = "https://argoproj.github.io/argo-helm"
  version         = "7.8.27"
  namespace       = kubernetes_namespace.tjo-cloud.metadata[0].name
  atomic          = true
  cleanup_on_fail = true

  values = [yamlencode({
    crds = {
      install = false
    }

    global = {
      domain = "argocd.k8s.tjo.cloud"
    }

    configs = {
      cm = {
        params = {
          server = {
            insecure = true
          }
        }
      }
    }

    dex = {
      config = yamlencode({
        connectors = [{
          name = "id.tjo.cloud"
          type = "oidc"
          id   = "id-tjo-cloud"
          config = {
            issuer               = var.oidc_issuer_url
            clientID             = var.oidc_client_id
            clientSecret         = "null"
            insecureEnableGroups = true
            logoutURL            = "https://id.tjo.space/application/o/k8stjocloud/end-session/"
            scopes               = ["openid", "profile", "email"]
          }
        }]
      })
    }

    controller = {
      replicas = 1
    }

    server = {
      replicas = 2
    }

    repoServer = {
      replicas = 2
    }

    applicationSet = {
      replicas = 2
    }
  })]
}

resource "kubernetes_manifest" "argocd-http-route" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "argocd"
      namespace = kubernetes_namespace.tjo-cloud.metadata[0].name
    }
    spec = {
      parentRefs = [
        {
          name = kubernetes_manifest.gateway.object.metadata.name
        }
      ]
      hostnames = [
        "argocd.k8s.tjo.cloud"
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
              name = "argo-cd-argocd-server"
              port = 80
            }
          ]
        },
      ]
    }
  }
}
