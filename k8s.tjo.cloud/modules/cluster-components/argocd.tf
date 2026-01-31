resource "kubernetes_service_account_v1" "argocd-auth-manager" {
  metadata {
    name      = "argocd-manager"
    namespace = kubernetes_namespace.k8s-tjo-cloud.metadata[0].name
  }
}
resource "kubernetes_secret_v1" "argocd_secret" {
  metadata {
    name      = "argocd-manager-token"
    namespace = kubernetes_namespace.k8s-tjo-cloud.metadata[0].name
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account_v1.argocd-auth-manager.metadata[0].name
    }
  }
  type                           = "kubernetes.io/service-account-token"
  wait_for_service_account_token = true
}
resource "kubernetes_cluster_role_v1" "argocd" {
  metadata {
    name = "argocd-manager-role"
  }
  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }
}
resource "kubernetes_cluster_role_binding_v1" "argocd" {
  metadata {
    name = "argocd-manager-role-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.argocd.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.argocd-auth-manager.metadata[0].name
    namespace = kubernetes_namespace.k8s-tjo-cloud.metadata[0].name
  }
}

resource "helm_release" "argocd" {
  name            = "argo-cd"
  chart           = "argo-cd"
  repository      = "https://argoproj.github.io/argo-helm"
  version         = "9.2.3"
  namespace       = kubernetes_namespace.k8s-tjo-cloud.metadata[0].name
  atomic          = true
  cleanup_on_fail = true

  values = [yamlencode({
    crds = {
      install = false
    }
    global = {
      domain            = "argocd.k8s.tjo.cloud"
      priorityClassName = "critical"
      affinity = {
        nodeAffinity = {
          requiredDuringSchedulingIgnoredDuringExecution = {
            nodeSelectorTerms = [{
              matchExpressions = [{
                key      = "node-role.kubernetes.io/control-plane"
                operator = "Exists"
              }]
            }]
          }
        }
      }
      tolerations = [{
        key    = "node-role.kubernetes.io/control-plane"
        effect = "NoSchedule"
      }]
    }
    configs = {
      params = {
        "server.insecure" = true
      }
      rbac = {
        "policy.csv" = <<EOF
          g, cloud.tjo.k8s/admin, role:admin
          g, cloud.tjo.k8s/read-only, role:readonly
          EOF
      }
      cm = {
        "admin.enabled"       = false
        "statusbadge.enabled" = true
        "dex.config" = yamlencode({
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
      ssh = {
        extraHosts = <<EOF
          # code.tjo.space
          code.tjo.space ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDJqsHFLpLlH/RXKJA9YpCxyqfZtZeKfuYhIHfL7wziZSew7Cff6Pt7OyXXq9QtqYAIjXFJD7gLDFBFCQFBg8yvFt9rOcI8yaIlJwKaCVWVqVfyKI7W0hbuUQyGYdgUVS/A71YWIlJsqnMc95ddFK31nmOuoFnayKlB9jpPkYouLuRJ4nlR+mNiUkFGBHq0LD7lPth3djxgyHQteNApQ/zMWdzgnm4x+nOsDZ8DRZ5hsr7jfmmjjqNBHunHJuwP9BiLrzqCpWM/iCsCNqamOV9jIt+F+nJg9622qULWzeHnclBMlawBmuyGSfmk+nCYYW8kGLzKVryy6w7BfcRg/7e6/YujnlVxPzSyFqFgNlaFkY/PuK3nBjv7AjBgPkj0A8uiiP/wuMN4Kd9h6CYozM02ECMlGu1aCCIaG/Xog6UDb1R+bgdvchBIOOx04KomYZblB2XSv9NVE+UIBNBKGEK2FgA1gV+DUizK/jm10PGZDtGXzlzvMxY/PZiFdf6G8VLVt7nNf//jAQRjl+3bPFVLR3DLqpVGxd48nuvljW1jbB6uGIPo/nbzzHGKz7mjX2QwHynb6cwjug55zNxPVCSIBmnye1fYQFS8ESIfP1SXzdoKSB78uinU7MEeCGWh7hFo53OvrocOzHnUMmsy4VaGZlbUdSMMU6lwO0bDg+CYnw==
          EOF
      }
      clusterCredentials = {
        "k8s-tjo-cloud" = {
          server = "https://api.internal.k8s.tjo.cloud:6443"
          config = {
            bearerToken = kubernetes_secret_v1.argocd_secret.data["token"]
            tlsClientConfig = {
              insecure = false
              caData   = base64encode(kubernetes_secret_v1.argocd_secret.data["ca.crt"])
            }
          }
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
      namespace = kubernetes_namespace.k8s-tjo-cloud.metadata[0].name
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

resource "kubernetes_manifest" "argocd-projects" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "projects"
      namespace = kubernetes_namespace.k8s-tjo-cloud.metadata[0].name
      finalizers = [
        "resources-finalizer.argocd.argoproj.io"
      ]
    }
    spec = {
      project = "default"
      info = [
        { name = "Defined in", value = "https://code.tjo.space/tjo-cloud/infrastructure" },
        { name = "Description", value = "Provisions ArgoCD Projects." },
      ]
      source = {
        repoURL        = "https://code.tjo.space/tjo-cloud/projects.git"
        targetRevision = "HEAD"
        path           = "src"
      }
      destination = {
        name      = "k8s-tjo-cloud"
        namespace = kubernetes_namespace.k8s-tjo-cloud.metadata[0].name
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        retry = {
          limit = 5
          backoff = {
            duration    = "5s"
            factor      = 2
            maxDuration = "5m"
          }
        }
      }
    }
  }
}
