data "helm_template" "cilium" {
  provider = helm.template

  name       = "cilium"
  chart      = "cilium"
  repository = "https://helm.cilium.io/"
  version    = "1.15.6"
  namespace  = "kube-system"

  kube_version = var.talos.kubernetes

  values = [yamlencode({
    ipam : {
      mode : "kubernetes"
    },
    nodeIPAM : {
      enabled : true
    },
    kubeProxyReplacement : "true"
    securityContext : {
      capabilities : {
        ciliumAgent : [
          "CHOWN",
          "KILL",
          "NET_ADMIN",
          "NET_RAW",
          "IPC_LOCK",
          "SYS_ADMIN",
          "SYS_RESOURCE",
          "DAC_OVERRIDE",
          "FOWNER",
          "SETGID",
          "SETUID"
        ],
        cleanCiliumState : [
          "NET_ADMIN",
          "SYS_ADMIN",
          "SYS_RESOURCE"
        ]
      }
    },
    cgroup : {
      autoMount : {
        enabled : false
      },
      hostRoot : "/sys/fs/cgroup"
    },
    k8sServiceHost : local.cluster_api_domain
    k8sServicePort : var.cluster.api.port
    ipv4 : {
      enabled : true
    },
    #ipv6 : {
    #  enabled : true
    #},
    hubble : {
      tls : {
        auto : {
          enabled : true
          method : "cronJob"
          schedule : "0 0 1 */4 *"
        }
      }
      ui : {
        enabled : true
      }
      relay : {
        enabled : true
      }
    },
    gatewayAPI : {
      enabled : false
    }
    envoy : {
      enabled : false
    }
  })]
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
      - name: proxmox
        storage: local-zfs
        reclaimPolicy: Delete
        fstype: ext4
        cache: none

    replicaCount: 1

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
        - operator: Exists
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

data "helm_template" "cert-manager" {
  provider   = helm.template
  name       = "cert-manager"
  chart      = "cert-manager"
  repository = "https://charts.jetstack.io"
  version    = "v1.15.1"
  namespace  = "kube-system"

  kube_version = var.talos.kubernetes
  api_versions = [
    "gateway.networking.k8s.io/v1/GatewayClass",
  ]

  include_crds = true

  set {
    name  = "crds.enabled"
    value = true
  }

  set_list {
    name  = "extraArgs"
    value = ["--enable-gateway-api"]
  }
}

data "helm_template" "envoy" {
  provider   = helm.template
  name       = "envoy"
  chart      = "gateway-helm"
  repository = "oci://docker.io/envoyproxy"
  version    = "v1.1.0-rc.1"
  namespace  = "kube-system"

  kube_version = var.talos.kubernetes
  api_versions = [
    "gateway.networking.k8s.io/v1/GatewayClass",
  ]

  include_crds = true

  values = [
    yamlencode({
      config = {
        envoyGateway = {
          provider = {
            type = "Kubernetes"
            kubernetes = {
              envoyDaemonSet  = {}
              envoyDeployment = null
            }
          }
          gateway = {
            controllerName = "gateway.envoyproxy.io/gatewayclass-controller"
          }
        }
      }
    })
  ]
}
