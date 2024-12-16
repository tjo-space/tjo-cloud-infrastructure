data "helm_template" "cilium" {
  provider = helm.template

  name       = "cilium"
  chart      = "cilium"
  repository = "https://helm.cilium.io/"
  version    = "1.16.4"
  namespace  = "kube-system"

  kube_version = var.talos.kubernetes

  values = [<<-EOF
    ipam:
      mode: "kubernetes"

    operator:
      priorityClassName: "system-cluster-critical"

    routingMode: "native"
    autoDirectNodeRoutes: true
    directRoutingSkipUnreachable: true

    bgpControlPlane:
      enabled: true

    bpf:
      masquerade: true

    ipv4:
      enabled: true
    ipv4NativeRoutingCIDR: "${var.cluster.pod_cidr.ipv4}"

    ipv6:
      enabled: false
    ipv6NativeRoutingCIDR: "${var.cluster.pod_cidr.ipv6}"

    kubeProxyReplacement: true

    # This breaks it??
    #k8s:
    #  requireIPv4PodCIDR: true
    #  requireIPv6PodCIDR: true

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

    k8sServiceHost: localhost
    k8sServicePort: 7445

    hubble:
      ui:
        enabled: false
      relay:
        enabled: false
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
  version    = "0.2.14"
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
      - name: proxmox-local-nvme
        storage: local-nvme
        reclaimPolicy: Delete
        fstype: ext4
        cache: none
      - name: proxmox-local
        storage: local
        reclaimPolicy: Delete
        fstype: ext4
        cache: none
      - name: proxmox-local-nvme-lvm
        storage: local-nvme-lvm
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
  version    = "0.2.8"
  namespace  = "kube-system"

  kube_version = var.talos.kubernetes

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
  version    = "0.4.3"
  namespace  = "kube-system"

  kube_version = var.talos.kubernetes

  values = [<<-EOF
    enabledControllers:
      - cloud-node
      - node-csr-approval
  EOF
  ]
}
