data "kubectl_path_documents" "crds" {
  pattern = "${path.module}/crds/*.yaml"
}

resource "kubectl_manifest" "crds" {
  for_each          = data.kubectl_path_documents.crds.manifests
  yaml_body         = each.value
  server_side_apply = true
  wait              = true
}

resource "helm_release" "proxmox-ccm" {
  name            = "proxmox-cloud-controller-manager"
  chart           = "proxmox-cloud-controller-manager"
  repository      = "oci://ghcr.io/sergelogvinov/charts"
  version         = "0.2.8"
  namespace       = "kube-system"
  atomic          = true
  cleanup_on_fail = true

  values = [<<-EOF
    # Deploy CCM only on control-plane nodes
    affinity:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
          - matchExpressions:
            - key: node-role.kubernetes.io/control-plane
              operator: Exists
    tolerations:
      - key: node-role.kubernetes.io/control-plane
        effect: NoSchedule
      - key: node.cloudprovider.kubernetes.io/uninitialized
        effect: NoSchedule

    enabledControllers:
      - cloud-node-lifecycle

    config:
      clusters:
        - url: ${var.proxmox.url}
          insecure: ${var.proxmox.insecure}
          token_id: ${var.proxmox.token.id}
          token_secret: ${var.proxmox.token.secret}
          region: ${var.proxmox.name}
  EOF
  ]
}

resource "helm_release" "talos-ccm" {
  name            = "talos-cloud-controller-manager"
  chart           = "talos-cloud-controller-manager"
  repository      = "oci://ghcr.io/siderolabs/charts"
  version         = "0.4.3"
  namespace       = "kube-system"
  atomic          = true
  cleanup_on_fail = true

  values = [yamlencode({
    enabledControllers = [
      "cloud-node",
      "node-csr-approval",
    ]
  })]
}

resource "helm_release" "metrics-server" {
  name            = "metrics-server"
  chart           = "metrics-server"
  repository      = "https://kubernetes-sigs.github.io/metrics-server/"
  version         = "3.12.2"
  namespace       = "kube-system"
  atomic          = true
  cleanup_on_fail = true

  values = [yamlencode({
    serviceMonitor = {
      enabled = true
    }
  })]
}
