resource "kubernetes_namespace" "monitoring-system" {
  metadata {
    name = "monitoring-system"
    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
    }
  }
}

resource "helm_release" "argocd" {
  name            = "argo-cd"
  chart           = "argo-cd"
  repository      = "https://argoproj.github.io/argo-helm"
  version         = "7.8.27"
  namespace       = kubernetes_namespace.monitoring-system.metadata[0].name
  atomic          = true
  cleanup_on_fail = true

  values = [yamlencode({
    crds = {
      install = false
    }

    global = {
      domain = "argocd.k8s.tjo.cloud"
    }

    redis-ha = {
      enabled = true
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
