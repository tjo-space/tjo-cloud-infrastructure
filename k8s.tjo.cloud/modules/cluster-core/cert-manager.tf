resource "helm_release" "cert-manager" {
  name            = "cert-manager"
  chart           = "cert-manager"
  repository      = "https://charts.jetstack.io"
  version         = "v1.18.2"
  namespace       = "kube-system"
  atomic          = true
  cleanup_on_fail = true

  values = [yamlencode({
    global = {
      priorityClassName = "system-cluster-critical"
    }

    extraArgs = ["--enable-gateway-api"]

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

    config = {
      apiVersion       = "controller.config.cert-manager.io/v1alpha1"
      kind             = "ControllerConfiguration"
      enableGatewayAPI = true
    }

    prometheus = {
      enabled = true
      servicemonitor = {
        enabled = true
      }
    }
  })]
}
