locals {
  cluster_api_domain = "${var.cluster.api.subdomain}.${var.cluster.domain}"
  cluster_endpoint   = "https://${local.cluster_api_domain}:${var.cluster.api.port}"

  nodes = { for k, v in var.nodes : k => merge(v, { name = replace("${k}.${v.type}.${var.cluster.domain}", ".", "-") }) }

  nodes_with_address = { for k, v in local.nodes : k => merge(v, { ipv4 = try(proxmox_vm_qemu.this[k].default_ipv4_address, false), ipv6 = try(proxmox_vm_qemu.this[k].default_ipv6_address, false) }) }

  first_controlplane_node = values({ for k, v in local.nodes_with_address : k => v if v.type == "controlplane" })[0]

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

  proxmox-cloud-controller-manager = {
    clusters : [{
      region : var.proxmox.name,
      url : var.proxmox.url,
      insecure : var.proxmox.insecure,
      token_id : var.proxmox.ccm.username,
      token_secret : var.proxmox.ccm.token,
    }]
  }
}

resource "macaddress" "private" {
  for_each = local.nodes
}
resource "macaddress" "public" {
  for_each = local.nodes
}

resource "proxmox_vm_qemu" "this" {
  for_each = local.nodes

  name        = each.value.name
  target_node = each.value.host
  tags = join(";", concat(
    ["kubernetes", "terraform"],
    each.value.public ? ["public"] : ["private"],
    [each.value.type]
  ))

  cores  = each.value.cores
  memory = each.value.memory

  scsihw  = "virtio-scsi-pci"
  qemu_os = "l26"

  agent = 1

  network {
    model   = "virtio"
    bridge  = each.value.public ? "vmpublic0" : "vmprivate0"
    macaddr = macaddress.private[each.key].address
  }

  disks {
    scsi {
      scsi0 {
        cdrom {
          iso = var.iso
        }
      }
    }
    virtio {
      virtio0 {
        disk {
          size    = each.value.boot_size
          storage = each.value.boot_pool
        }
      }
    }
  }
}

resource "digitalocean_record" "controlplane-A" {
  for_each = { for k, v in proxmox_vm_qemu.this : k => v if try(var.nodes[k].public && var.nodes[k].type == "controlplane", false) }

  domain = var.cluster.domain
  type   = "A"
  name   = var.cluster.api.subdomain
  value  = each.value.default_ipv4_address
  ttl    = 30
}

resource "digitalocean_record" "controlplane-AAAA" {
  for_each = { for k, v in proxmox_vm_qemu.this : k => v if try(var.nodes[k].public && var.nodes[k].type == "controlplane", false) }

  domain = var.cluster.domain
  type   = "AAAA"
  name   = var.cluster.api.subdomain
  value  = each.value.default_ipv6_address
  ttl    = 30
}

resource "talos_machine_secrets" "this" {}

data "talos_machine_configuration" "controlplane" {
  cluster_name     = var.cluster.name
  machine_type     = "controlplane"
  cluster_endpoint = local.cluster_endpoint
  machine_secrets  = talos_machine_secrets.this.machine_secrets

  talos_version      = var.versions.talos
  kubernetes_version = var.versions.kubernetes

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

  talos_version      = var.versions.talos
  kubernetes_version = var.versions.kubernetes

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

  kube_version = var.versions.kubernetes
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

resource "talos_machine_configuration_apply" "controlplane" {
  for_each = { for k, v in local.nodes_with_address : k => v if v.type == "controlplane" }

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration

  node     = each.value.name
  endpoint = each.value.ipv4

  apply_mode = "reboot"

  config_patches = [
    yamlencode({
      cluster : {
        controlPlane : {
          endpoint : local.cluster_endpoint
          localAPIServerPort : var.cluster.api.port
        }
        etcd : {
          #advertisedSubnets : [
          #  local.tailscaleSubnet
          #]
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
            name : "proxmox-cloud-controller-manager"
            contents : <<-EOF
            apiVersion: v1
            kind: Secret
            metadata:
              name: proxmox-cloud-controller-manager
              namespace: kube-system
            data:
              config.yaml: ${base64encode(yamlencode(local.proxmox-cloud-controller-manager))}
            EOF
          }
        ]
        externalCloudProvider : {
          enabled : true
          manifests : [
            "https://raw.githubusercontent.com/sergelogvinov/proxmox-csi-plugin/v0.7.0/docs/deploy/proxmox-csi-plugin-talos.yml",
            "https://raw.githubusercontent.com/sergelogvinov/proxmox-cloud-controller-manager/v0.4.2/docs/deploy/cloud-controller-manager-talos.yml"
          ]
        }
        extraManifests : [
          #"https://raw.githubusercontent.com/alex1989hu/kubelet-serving-cert-approver/v0.8.5/deploy/standalone-install.yaml",
          "https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.7.1/components.yaml",
        ]
      }
      machine = {
        kubelet = {
          nodeIP : {
            validSubnets : local.tailscaleSubnets
          }
          extraArgs : {
            rotate-server-certificates : true
            cloud-provider : "external"
          }
        }
        network = {
          hostname = each.value.name
        }
        install = {
          image = "factory.talos.dev/installer/7d4c31cbd96db9f90c874990697c523482b2bae27fb4631d5583dcd9c281b1ff:${var.versions.talos}"
          disk  = "/dev/vda"
        }
        nodeLabels = {
          "k8s.tjo.cloud/public"  = each.value.public ? "true" : "false"
          "k8s.tjo.cloud/host"    = each.value.host
          "k8s.tjo.cloud/proxmox" = var.proxmox.name
        }
      }
    }),
    yamlencode({
      apiVersion : "v1alpha1"
      kind : "ExtensionServiceConfig"
      name : "tailscale"
      environment : [
        "TS_AUTHKEY=${var.tailscale_authkey}",
        "TS_HOSTNAME=${replace(each.value.name, ".", "-")}",
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
    yamlencode({
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
            cloud-provider : "external"
          }
        }
        network = {
          hostname = each.value.name
        }
        install = {
          image = "factory.talos.dev/installer/7d4c31cbd96db9f90c874990697c523482b2bae27fb4631d5583dcd9c281b1ff:${var.versions.talos}"
          disk  = "/dev/vda"
        }
        nodeLabels = {
          "k8s.tjo.cloud/public"  = each.value.public ? "true" : "false"
          "k8s.tjo.cloud/host"    = each.value.host
          "k8s.tjo.cloud/proxmox" = var.proxmox.name
        }
      }
    }),
    yamlencode({
      apiVersion : "v1alpha1"
      kind : "ExtensionServiceConfig"
      name : "tailscale"
      environment : [
        "TS_AUTHKEY=${var.tailscale_authkey}",
        "TS_HOSTNAME=${replace(each.value.name, ".", "-")}",
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
