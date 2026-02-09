resource "helm_release" "proxmox-csi" {
  name            = "proxmox-csi-plugin"
  chart           = "proxmox-csi-plugin"
  repository      = "oci://ghcr.io/sergelogvinov/charts"
  version         = "0.5.3"
  namespace       = "kube-system"
  atomic          = true
  cleanup_on_fail = true

  values = [yamlencode({
    config = {
      clusters = [
        {
          url          = var.proxmox.url
          insecure     = var.proxmox.insecure
          token_id     = var.proxmox.token.id
          token_secret = var.proxmox.token.secret
          region       = var.proxmox.name
        }
      ]
    }

    nodeSelector = {
      "node-role.kubernetes.io/control-plane"     = ""
      "node.cloudprovider.kubernetes.io/platform" = "nocloud"
    }
    tolerations = [{
      key    = "node-role.kubernetes.io/control-plane"
      effect = "NoSchedule"
    }]

    node = {
      nodeSelector = {
        "node.cloudprovider.kubernetes.io/platform" = "nocloud"
      }
      tolerations = [{
        key    = "node-role.kubernetes.io/control-plane"
        effect = "NoSchedule"
      }]
    }
  })]
}

resource "helm_release" "hybrid-csi" {
  name            = "hybrid-csi-plugin"
  chart           = "hybrid-csi-plugin"
  repository      = "oci://ghcr.io/sergelogvinov/charts"
  version         = "0.1.10"
  namespace       = "kube-system"
  atomic          = true
  cleanup_on_fail = true

  values = [yamlencode({
    nodeSelector = {
      "node-role.kubernetes.io/control-plane" = ""
    }

    tolerations = [{
      key    = "node-role.kubernetes.io/control-plane"
      effect = "NoSchedule"
    }]
  })]
}

moved {
  from = kubernetes_storage_class.per-host["nevaroo"]
  to   = kubernetes_storage_class.per-host["nevaroo-common-local-nvme-lvm"]
}
moved {
  from = kubernetes_storage_class.per-host["batuu"]
  to   = kubernetes_storage_class.per-host["batuu-common-local-nvme"]
}
moved {
  from = kubernetes_storage_class.per-host["jakku"]
  to   = kubernetes_storage_class.per-host["jakku-common-local-nvme"]
}
moved {
  from = kubernetes_storage_class.per-host["endor"]
  to   = kubernetes_storage_class.per-host["endor-common-local-nvme"]
}
moved {
  from = kubernetes_storage_class.per-host["mustafar"]
  to   = kubernetes_storage_class.per-host["mustafar-common-local"]
}
resource "kubernetes_storage_class" "per-host" {
  depends_on = [helm_release.hybrid-csi, helm_release.proxmox-csi]
  for_each = merge([
    for host, details in var.hosts : {
      for type, storage in details.storage : "${host}-${type}-${storage}" => { host : host, type : type, storage : storage }
    }
  ]...)

  metadata {
    name = each.value.type == "common" ? each.value.host : "${each.value.host}-${each.value.storage}"
    annotations = {
      "k8s.tjo.cloud/host"            = each.value.host
      "k8s.tjo.cloud/storage-type"    = each.value.type
      "k8s.tjo.cloud/proxmox"         = var.proxmox.name
      "k8s.tjo.cloud/proxmox-storage" = each.value.storage
    }
  }

  storage_provisioner    = "csi.proxmox.sinextra.dev"
  allow_volume_expansion = true
  reclaim_policy         = "Delete"
  volume_binding_mode    = "WaitForFirstConsumer"

  parameters = {
    storage                     = each.value.storage
    "csi.storage.k8s.io/fstype" = "ext4"
    cache                       = "none"
  }

  allowed_topologies {
    match_label_expressions {
      key    = "topology.kubernetes.io/region"
      values = [var.proxmox.name]
    }
    match_label_expressions {
      key    = "topology.kubernetes.io/zone"
      values = [each.value.host]
    }
  }
}

resource "kubernetes_storage_class" "common" {
  depends_on = [helm_release.hybrid-csi, helm_release.proxmox-csi]

  metadata {
    name = "common"
    annotations = {
      "k8s.tjo.cloud/proxmox" = var.proxmox.name
    }
  }

  storage_provisioner    = "csi.hybrid.sinextra.dev"
  allow_volume_expansion = true
  reclaim_policy         = "Delete"
  volume_binding_mode    = "WaitForFirstConsumer"

  parameters = {
    storageClasses = join(",", [
      for sc in kubernetes_storage_class.per-host : sc.metadata[0].name
      if sc.metadata[0].annotations["k8s.tjo.cloud/storage-type"] == "common"
    ])
  }
}
