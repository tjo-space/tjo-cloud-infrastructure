resource "kubernetes_secret_v1" "k8sup" {
  metadata {
    name      = "k8up"
    namespace = kubernetes_namespace.k8s-tjo-cloud.metadata[0].name
  }
  data = {
    repo-password        = var.backup.password
    s3-access-key-id     = var.backup.s3_access_key_id
    s3-secret-access-key = var.backup.s3_secret_access_key
    s3-bucket            = var.backup.s3_bucket
    s3-endpoint          = var.backup.s3_endpoint
  }
}

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
      envVars = [
        {
          name      = "BACKUP_GLOBALREPOPASSWORD"
          valueFrom = { secretKeyRef = { name = "k8up", key = "repo-password" } }
        },
        {
          name      = "BACKUP_GLOBALACCESSKEYID"
          valueFrom = { secretKeyRef = { name = "k8up", key = "s3-access-key-id" } }
        },
        {
          name      = "BACKUP_GLOBALSECRETACCESSKEY"
          valueFrom = { secretKeyRef = { name = "k8up", key = "s3-secret-access-key" } }
        },
        {
          name      = "BACKUP_GLOBALS3BUCKET"
          valueFrom = { secretKeyRef = { name = "k8up", key = "s3-bucket" } }
        },
        {
          name      = "BACKUP_GLOBALS3ENDPOINT"
          valueFrom = { secretKeyRef = { name = "k8up", key = "s3-endpoint" } }
        },
      ]
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
