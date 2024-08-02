data "helm_template" "cilium" {
  provider = helm.template

  name       = "cilium"
  chart      = "cilium"
  repository = "https://helm.cilium.io/"
  version    = "1.15.6"
  namespace  = "kube-system"

  kube_version = var.talos.kubernetes

  values = [<<-EOF
    ipam:
      mode: "kubernetes"
    nodeIPAM:
      enabled: true

    bpf:
      masquerade: true

    enableIPv4Masquerade: true
    ipv4:
      enabled: true

    enableIPv6Masquerade: true
    ipv6:
      enabled: true

    kubeProxyReplacement: "true"
    securityContext:
      capabilities:
        ciliumAgent:
          - "CHOWN"
          - "KILL"
          - "NET_ADMIN"
          - "NET_RAW"
          - "IPC_LOCK"
          - "SYS_ADMIN"
          - "SYS_RESOURCE"
          - "DAC_OVERRIDE"
          - "FOWNER"
          - "SETGID"
          - "SETUID"
        cleanCiliumState:
          - "NET_ADMIN"
          - "SYS_ADMIN"
          - "SYS_RESOURCE"
    cgroup:
      hostRoot: "/sys/fs/cgroup"
      autoMount:
        enabled: false

    k8sServiceHost: ${var.cluster.api.domain}
    k8sServicePort: ${var.cluster.api.port}

    hubble:
      ui:
        enabled: true
      relay:
        enabled: true
      tls:
        auto:
          enabled: true
          method: "cronJob"
          schedule: "0 0 1 */4 *"
    gatewayAPI:
      enabled: false
    envoy:
      enabled: false
    EOF
  ]
}

data "helm_template" "proxmox-csi" {
  provider = helm.template

  name       = "proxmox-csi-plugin"
  chart      = "proxmox-csi-plugin"
  repository = "oci://ghcr.io/sergelogvinov/charts"
  version    = "0.2.5"
  namespace  = "kube-system"

  kube_version = var.talos.kubernetes

  values = [<<-EOF
    config:
      clusters:
        - url: ${var.proxmox.url}
          insecure: ${var.proxmox.insecure}
          token_id: "${proxmox_virtual_environment_user_token.csi.id}"
          token_secret: "${split("=", proxmox_virtual_environment_user_token.csi.value)[1]}"
          region: "${var.proxmox.name}"

    storageClass:
      - name: proxmox-main
        storage: main
        reclaimPolicy: Delete
        fstype: ext4
        cache: none

    nodeSelector:
      node-role.kubernetes.io/control-plane: ""
      node.cloudprovider.kubernetes.io/platform: nocloud
    tolerations:
      - key: node-role.kubernetes.io/control-plane
        effect: NoSchedule

    node:
      nodeSelector:
        node.cloudprovider.kubernetes.io/platform: nocloud
      tolerations:
        - key: node-role.kubernetes.io/control-plane
          effect: NoSchedule
  EOF
  ]
}

data "helm_template" "proxmox-ccm" {
  provider   = helm.template
  name       = "proxmox-cloud-controller-manager"
  chart      = "proxmox-cloud-controller-manager"
  repository = "oci://ghcr.io/sergelogvinov/charts"
  version    = "0.2.3"
  namespace  = "kube-system"

  kube_version = var.talos.kubernetes

  values = [<<-EOF
    nodeSelector:
      node-role.kubernetes.io/control-plane: ""
    enabledControllers:
      - cloud-node-lifecycle
    config:
      clusters:
        - url: ${var.proxmox.url}
          insecure: ${var.proxmox.insecure}
          token_id: ${proxmox_virtual_environment_user_token.ccm.id}
          token_secret: ${split("=", proxmox_virtual_environment_user_token.ccm.value)[1]}
          region: ${var.proxmox.name}
  EOF
  ]
}

data "helm_template" "talos-ccm" {
  provider   = helm.template
  name       = "talos-cloud-controller-manager"
  chart      = "talos-cloud-controller-manager"
  repository = "oci://ghcr.io/siderolabs/charts"
  version    = "0.3.1"
  namespace  = "kube-system"

  kube_version = var.talos.kubernetes
}
