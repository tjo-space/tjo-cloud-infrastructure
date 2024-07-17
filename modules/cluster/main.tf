locals {
  cluster_api_domain = "${var.cluster.api.subdomain}.${var.cluster.domain}"
  cluster_endpoint   = "https://${local.cluster_api_domain}:${var.cluster.api.port}"

  podSubnets = [
    "10.200.0.0/16",
    #"fd9b:5314:fc70::/48",
  ]
  serviceSubnets = [
    "10.201.0.0/16",
    #"fd9b:5314:fc71::/48",
  ]

  # Nodes will use IPs from this subnets
  # for communication between each other.
  tailscaleSubnets = [
    "100.64.0.0/10",
    "fd7a:115c:a1e0::/96"
  ]

  talos_controlplane_config = {
    cluster : {
      etcd : {
        #advertisedSubnets : [
        #  local.tailscaleSubnet
        #]
      }
      allowSchedulingOnControlPlanes : var.allow_scheduling_on_control_planes,
      apiServer : {
        extraArgs : {
          "oidc-issuer-url" : "https://id.tjo.space/application/o/k8stjocloud/",
          "oidc-client-id" : "HAI6rW0EWtgmSPGKAJ3XXzubQTUut2GMeTRS2spg",
          "oidc-username-claim" : "sub",
          "oidc-username-prefix" : "oidc:",
          "oidc-groups-claim" : "groups",
          "oidc-groups-prefix" : "oidc:groups:",
        }
      }
      inlineManifests : [
        {
          name : "oidc-groups"
          contents : <<-EOF
            apiVersion: rbac.authorization.k8s.io/v1
            kind: ClusterRoleBinding
            metadata:
              name: id-tjo-space:admins
            subjects:
            - kind: Group
              name: oidc:groups:k8s.tjo.cloud admin
              apiGroup: rbac.authorization.k8s.io
            roleRef:
              kind: ClusterRole
              name: cluster-admin
              apiGroup: rbac.authorization.k8s.io
            EOF
        },
        {
          name : "cilium"
          contents : data.helm_template.cilium.manifest
        },
        {
          name : "promxmox-csi-plugin"
          contents : data.helm_template.csi.manifest
        },
        {
          name : "proxmox-cloud-controller-manager"
          contents : data.helm_template.ccm.manifest
        }
      ]
      externalCloudProvider : {
        enabled : true
      }
      extraManifests : [
        #"https://raw.githubusercontent.com/alex1989hu/kubelet-serving-cert-approver/v0.8.5/deploy/standalone-install.yaml",
        "https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.7.1/components.yaml",
      ]
    }
  }

  talos_worker_config = {
    cluster : {
      controlPlane : {
        endpoint : local.cluster_endpoint
        localAPIServerPort : var.cluster.api.port
      }
      network : {
        cni : {
          name : "none"
        }
        podSubnets : local.podSubnets
        serviceSubnets : local.serviceSubnets
      }
      proxy : {
        disabled : true
      }
    }
    machine = {
      kubelet = {
        nodeIP : {
          validSubnets : local.tailscaleSubnets
        }
        extraArgs : {
          rotate-server-certificates : true
        }
      }
      install = {
        image = "factory.talos.dev/installer/${var.talos.schematic_id}:${var.talos.version}"
        disk  = "/dev/vda"
      }
    }
  }
}

resource "digitalocean_record" "controlplane-A" {
  for_each = { for k, node in local.nodes_with_address : k => node if node.type == "controlplane" }

  domain = var.cluster.domain
  type   = "A"
  name   = var.cluster.api.subdomain
  value  = each.value.ipv4
  ttl    = 30
}

resource "digitalocean_record" "controlplane-AAAA" {
  for_each = { for k, node in local.nodes_with_address : k => node if node.type == "controlplane" }

  domain = var.cluster.domain
  type   = "AAAA"
  name   = var.cluster.api.subdomain
  value  = each.value.ipv6
  ttl    = 30
}

resource "talos_machine_secrets" "this" {}

data "talos_machine_configuration" "controlplane" {
  cluster_name     = var.cluster.name
  machine_type     = "controlplane"
  cluster_endpoint = local.cluster_endpoint
  machine_secrets  = talos_machine_secrets.this.machine_secrets

  talos_version      = var.talos.version
  kubernetes_version = var.talos.kubernetes

  depends_on = [
    digitalocean_record.controlplane-A,
    digitalocean_record.controlplane-AAAA,
  ]
}

data "talos_machine_configuration" "worker" {
  cluster_name     = var.cluster.name
  machine_type     = "worker"
  cluster_endpoint = local.cluster_endpoint
  machine_secrets  = talos_machine_secrets.this.machine_secrets

  talos_version      = var.talos.version
  kubernetes_version = var.talos.kubernetes

  depends_on = [
    digitalocean_record.controlplane-A,
    digitalocean_record.controlplane-AAAA
  ]
}

data "helm_template" "cilium" {
  provider = helm.template

  name       = "cilium"
  chart      = "cilium"
  repository = "https://helm.cilium.io/"
  version    = "1.15.6"
  namespace  = "kube-system"

  kube_version = var.talos.kubernetes
  api_versions = [
    "gateway.networking.k8s.io/v1/GatewayClass",
  ]

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

data "helm_template" "csi" {
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
          token_secret: "${proxmox_virtual_environment_user_token.csi.value}"
          region: "${var.proxmox.name}"

    storageClass:
      - name: default
        storage: local-storage
        reclaimPolicy: Delete
        fstype: xfs
  EOF
  ]
}

data "helm_template" "ccm" {
  provider   = helm.template
  name       = "proxmox-cloud-controller-manager"
  chart      = "proxmox-cloud-controller-manager"
  repository = "oci://ghcr.io/sergelogvinov/charts"
  version    = "0.2.3"
  namespace  = "kube-system"

  kube_version = var.talos.kubernetes

  values = [<<-EOF
    config:
      clusters:
        - url: ${var.proxmox.url}
          insecure: ${var.proxmox.insecure}
          token_id: "${proxmox_virtual_environment_user_token.ccm.id}"
          token_secret: "${proxmox_virtual_environment_user_token.ccm.value}"
          region: "${var.proxmox.name}"
  EOF
  ]
}

resource "talos_machine_configuration_apply" "controlplane" {
  for_each = { for k, v in local.nodes_with_address : k => v if v.type == "controlplane" }

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration

  node     = each.value.name
  endpoint = each.value.ipv4

  apply_mode = "reboot"

  config_patches = [
    yamlencode(merge(local.talos_worker_config, local.talos_controlplane_config, {
      machine = {
        network = {
          hostname = each.value.name
        }
        nodeLabels = {
          "k8s.tjo.cloud/public"  = each.value.public ? "true" : "false"
          "k8s.tjo.cloud/host"    = each.value.host
          "k8s.tjo.cloud/proxmox" = var.proxmox.name
        }
      }

    })),
    yamlencode(
      {
        apiVersion : "v1alpha1"
        kind : "ExtensionServiceConfig"
        name : "tailscale"
        environment : [
          "TS_AUTHKEY=${var.tailscale_authkey}",
          "TS_HOSTNAME=${each.value.name}",
        ]
    })
  ]
}

resource "talos_machine_configuration_apply" "worker" {
  for_each = { for k, v in local.nodes_with_address : k => v if v.type == "worker" }

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration

  node     = each.value.name
  endpoint = each.value.ipv4

  apply_mode = "reboot"

  config_patches = [
    yamlencode(merge(local.talos_worker_config, {
      machine = {
        network = {
          hostname = each.value.name
        }
        nodeLabels = {
          "k8s.tjo.cloud/public"  = each.value.public ? "true" : "false"
          "k8s.tjo.cloud/host"    = each.value.host
          "k8s.tjo.cloud/proxmox" = var.proxmox.name
        }
      }
    })),
    yamlencode(
      {
        apiVersion : "v1alpha1"
        kind : "ExtensionServiceConfig"
        name : "tailscale"
        environment : [
          "TS_AUTHKEY=${var.tailscale_authkey}",
          "TS_HOSTNAME=${each.value.name}",
        ]
    })
  ]
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [
    talos_machine_configuration_apply.controlplane,
    talos_machine_configuration_apply.worker
  ]

  node                 = local.first_controlplane_node.name
  endpoint             = local.first_controlplane_node.ipv4
  client_configuration = talos_machine_secrets.this.client_configuration
}

data "talos_cluster_kubeconfig" "this" {
  depends_on = [
    talos_machine_bootstrap.this
  ]

  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.first_controlplane_node.ipv4
}
