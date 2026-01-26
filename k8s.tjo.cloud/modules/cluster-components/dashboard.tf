resource "helm_release" "headlamp" {
  name            = "headlamp"
  repository      = "https://kubernetes-sigs.github.io/headlamp/"
  chart           = "headlamp"
  version         = "0.39.0"
  namespace       = kubernetes_namespace.k8s-tjo-cloud.metadata[0].name
  atomic          = true
  cleanup_on_fail = true

  values = [yamlencode({
    priorityClassName = "critical"

    affinity = {
      nodeAffinity = {
        requiredDuringSchedulingIgnoredDuringExecution = {
          nodeSelectorTerms = [
            {
              matchExpressions = [{
                key      = "node-role.kubernetes.io/control-plane"
                operator = "Exists"
              }]
            }
          ]
        }
      }
    }

    tolerations = [
      {
        key      = "node-role.kubernetes.io/control-plane"
        effect   = "NoSchedule"
        operator = "Exists"
      }
    ]

    podDisruptionBudget = {
      enabled      = true
      minAvailable = 1
    }

    httpRoute = {
      enabled    = true
      parentRefs = [{ name = kubernetes_manifest.gateway.object.metadata.name }]
      hostnames  = ["dashboard.k8s.tjo.cloud"]
    }

    config = {
      inCluster = true
      oidc = {
        secret = {
          create = true
          name   = "headlamp-oidc"
        }
        issuerURL    = var.oidc_issuer_url
        clientID     = var.oidc_client_id
        clientSecret = "null"
        scopes       = "openid email profile"
        callbackURL  = "https://dashboard.k8s.tjo.cloud/oidc-callback"
      }
    }
  })]
}

// TODO: Can be removed in 0.40.0+ version.
resource "kubernetes_manifest" "dashoard-http-route" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "dashboard"
      namespace = kubernetes_namespace.k8s-tjo-cloud.metadata[0].name
    }
    spec = {
      parentRefs = [
        { name = kubernetes_manifest.gateway.object.metadata.name }
      ]
      hostnames = ["dashboard.k8s.tjo.cloud"]
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
              name = "headlamp"
              port = 80
            }
          ]
        }
      ]
    }
  }
}
