resource "helm_release" "k8sup" {
  name            = "k8up"
  chart           = "k8up"
  repository      = "https://k8up-io.github.io/k8up"
  version         = "4.8.6"
  namespace       = kubernetes_namespace.k8s-tjo-cloud.metadata[0].name
  atomic          = true
  cleanup_on_fail = true

  values = [yamlencode({
    k8up = {
      skipWithoutAnnotation = true
    }
    metrics = {
      serviceMonitor = {
        enabled = true
      }
    }

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
  })]
}
