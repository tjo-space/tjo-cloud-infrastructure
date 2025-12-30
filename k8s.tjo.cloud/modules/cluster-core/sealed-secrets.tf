resource "helm_release" "sealed-secrets" {
  depends_on = [kubectl_manifest.crds]

  name            = "sealed-secrets"
  chart           = "sealed-secrets"
  repository      = "https://bitnami-labs.github.io/sealed-secrets"
  version         = "2.18.0"
  namespace       = "kube-system"
  atomic          = true
  cleanup_on_fail = true
  skip_crds       = true

  values = [yamlencode({
    metrics = {
      serviceMonitor = {
        enabled = true
      }
    }
    pdb = {
      create       = true
      minAvailable = 1
    }

    priorityClassName = "system-cluster-critical"

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
  })]
}
