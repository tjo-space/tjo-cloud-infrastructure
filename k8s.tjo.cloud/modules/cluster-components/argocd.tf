resource "helm_release" "argocd" {
  name            = "argo-cd"
  chart           = "argo-cd"
  repository      = "https://argoproj.github.io/argo-helm"
  version         = "8.2.4"
  namespace       = kubernetes_namespace.tjo-cloud.metadata[0].name
  atomic          = true
  cleanup_on_fail = true

  values = [yamlencode({
    crds = {
      install = false
    }
    global = {
      domain = "argocd.k8s.tjo.cloud"
      dualstack = {
        ipFamilyPolicy = "RequireDualStack"
        ipFamilies     = ["IPv4", "IPv6"]
      }
    }
    configs = {
      params = {
        server = {
          insecure = true
        }
      }
      rbac = {
        policy = {
          csv = <<EOF
          g, cloud.tjo.k8s/admin, role:admin
          g, cloud.tjo.k8s/read-only, role:readonly
          EOF
        }
      }
      cm = {
        admin       = { enabled = false }
        statusbadge = { enabled = true }
        dex = {
          config = yamlencode({
            connectors = [
              {
                name = "id.tjo.cloud"
                id   = "id-tjo-cloud"
                type = "oidc"
                config = {
                  issuer               = var.oidc_issuer_url
                  clientID             = var.oidc_client_id
                  clientSecret         = "null"
                  insecureEnableGroups = true
                  scopes               = ["openid", "profile", "email", "groups"]
                }
              }
            ]
          })
        }
      }
      ssh = {
        extraHosts = <<EOF
          code.tjo.space ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDJqsHFLpLlH/RXKJA9YpCxyqfZtZeKfuYhIHfL7wziZSew7Cff6Pt7OyXXq9QtqYAIjXFJD7gLDFBFCQFBg8yvFt9rOcI8yaIlJwKaCVWVqVfyKI7W0hbuUQyGYdgUVS/A71YWIlJsqnMc95ddFK31nmOuoFnayKlB9jpPkYouLuRJ4nlR+mNiUkFGBHq0LD7lPth3djxgyHQteNApQ/zMWdzgnm4x+nOsDZ8DRZ5hsr7jfmmjjqNBHunHJuwP9BiLrzqCpWM/iCsCNqamOV9jIt+F+nJg9622qULWzeHnclBMlawBmuyGSfmk+nCYYW8kGLzKVryy6w7BfcRg/7e6/YujnlVxPzSyFqFgNlaFkY/PuK3nBjv7AjBgPkj0A8uiiP/wuMN4Kd9h6CYozM02ECMlGu1aCCIaG/Xog6UDb1R+bgdvchBIOOx04KomYZblB2XSv9NVE+UIBNBKGEK2FgA1gV+DUizK/jm10PGZDtGXzlzvMxY/PZiFdf6G8VLVt7nNf//jAQRjl+3bPFVLR3DLqpVGxd48nuvljW1jbB6uGIPo/nbzzHGKz7mjX2QwHynb6cwjug55zNxPVCSIBmnye1fYQFS8ESIfP1SXzdoKSB78uinU7MEeCGWh7hFo53OvrocOzHnUMmsy4VaGZlbUdSMMU6lwO0bDg+CYnw==
          EOF
      }
      clusterCredentials = {
        "k8s.tjo.cloud" = {
          server      = "https://kubernetes.default.svc"
          labels      = {}
          annotations = {}
          config      = {}
        }
      }
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
        { name = kubernetes_manifest.gateway.object.metadata.name }
      ]
      hostnames = ["argocd.k8s.tjo.cloud"]
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
        }
      ]
    }
  }
}
