locals {
  # Downloaded from factory.talos.dev
  # https://factory.talos.dev/?arch=amd64&board=undefined&cmdline-set=true&extensions=-&extensions=siderolabs%2Fqemu-guest-agent&extensions=siderolabs%2Ftailscale&platform=metal&secureboot=undefined&target=metal&version=1.7.0
  iso = "proxmox-backup-tjo-cloud:iso/talos-${var.talos_version}-tailscale-metal-amd64.iso"

  boot_pool = "hetzner-main-data"

  cluster_domain   = "api.${var.cluster_name}.${var.domain}"
  cluster_port     = 6443
  cluster_endpoint = "https://${local.cluster_domain}:${local.cluster_port}"

  nodes                     = { for k, v in var.nodes : k => merge(v, { name = "${k}.node.${var.cluster_name}.${var.domain}" }) }
  nodes_with_address        = { for k, v in local.nodes : k => merge(v, { address_ipv4 = proxmox_vm_qemu.this[k].default_ipv4_address, address_ipv6 = proxmox_vm_qemu.this[k].default_ipv6_address }) }
  first_controlplane_node   = values({ for k, v in local.nodes_with_address : k => v if v.type == "controlplane" })[0]
  nodes_public_controlplane = { for k, v in proxmox_vm_qemu.this : k => v if var.nodes[k].public && var.nodes[k].type == "controlplane" }

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

  apply_mode = "reboot"
}

resource "macaddress" "this" {
  for_each = local.nodes
}

resource "proxmox_vm_qemu" "this" {
  for_each = local.nodes

  name        = each.value.name
  target_node = each.value.host
  tags = join(";", concat(
    ["kubernetes", "terraform"],
    each.value.public ? ["public"] : ["private"],
  ))

  cores  = 4
  memory = 4096

  scsihw  = "virtio-scsi-pci"
  qemu_os = "l26"

  agent = 1

  network {
    model   = "virtio"
    bridge  = each.value.public ? "vmpublic0" : "vmprivate0"
    macaddr = macaddress.this[each.key].address
  }

  disks {
    scsi {
      scsi0 {
        cdrom {
          iso = local.iso
        }
      }
    }
    virtio {
      virtio0 {
        disk {
          size    = "32G"
          storage = local.boot_pool
        }
      }
    }
  }
}

resource "digitalocean_record" "controlplane-A" {
  for_each = { for k, v in proxmox_vm_qemu.this : k => v if var.nodes[k].public && var.nodes[k].type == "controlplane" }

  domain = var.domain
  type   = "A"
  name   = "api.${var.cluster_name}"
  value  = each.value.default_ipv4_address
  ttl    = 30
}

resource "digitalocean_record" "controlplane-AAAA" {
  for_each = { for k, v in proxmox_vm_qemu.this : k => v if var.nodes[k].public && var.nodes[k].type == "controlplane" }

  domain = var.domain
  type   = "AAAA"
  name   = "api.${var.cluster_name}"
  value  = each.value.default_ipv6_address
  ttl    = 30
}

resource "talos_machine_secrets" "this" {}

data "talos_machine_configuration" "controlplane" {
  cluster_name     = var.cluster_name
  machine_type     = "controlplane"
  cluster_endpoint = local.cluster_endpoint
  machine_secrets  = talos_machine_secrets.this.machine_secrets

  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version

  depends_on = [
    digitalocean_record.controlplane-A,
    digitalocean_record.controlplane-AAAA,
  ]
}

data "talos_machine_configuration" "worker" {
  cluster_name     = var.cluster_name
  machine_type     = "worker"
  cluster_endpoint = local.cluster_endpoint
  machine_secrets  = talos_machine_secrets.this.machine_secrets

  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version

  depends_on = [
    digitalocean_record.controlplane-A,
    digitalocean_record.controlplane-AAAA
  ]
}

data "talos_machine_disks" "boot" {
  for_each = local.nodes_with_address

  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = each.value.name
  endpoint             = each.value.address_ipv4

  filters = {
    size = "< 60GB"
  }
}

data "helm_template" "cilium" {
  provider = helm.template

  name       = "cilium"
  chart      = "cilium"
  repository = "https://helm.cilium.io/"
  version    = "1.15.6"
  namespace  = "kube-system"

  kube_version = var.kubernetes_version
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
    k8sServiceHost : local.cluster_domain
    k8sServicePort : local.cluster_port
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
    # Ingress gateway
    gatewayAPI : {
      enabled : true
      hostNetwork : {
        enabled : true
        nodes : {
          matchLabels : {
            "k8s.tjo.cloud/gateway" : "true"
          }
        }
      }
    }
    envoy : {
      enabled : true
      securityContext : {
        capabilities : {
          keepCapNetBindService : true
          envoy : [
            "NET_ADMIN",
            "SYS_ADMIN",
            "NET_BIND_SERVICE"
          ]
        }
      }
    }
  })]
}

resource "talos_machine_configuration_apply" "controlplane" {
  for_each = { for k, v in local.nodes_with_address : k => v if v.type == "controlplane" }

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration

  node     = each.value.name
  endpoint = each.value.address_ipv4

  apply_mode = local.apply_mode

  config_patches = [
    yamlencode({
      cluster : {
        controlPlane : {
          endpoint : local.cluster_endpoint
          localAPIServerPort : local.cluster_port
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
        allowSchedulingOnControlPlanes : true,
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
            name : "gateway-api-crds"
            contents : file("${path.module}/manifests/gateway-api-crds.yaml")
          },
          {
            name : "cilium"
            contents : data.helm_template.cilium.manifest
          }
        ],
      }
      machine = {
        kubelet = {
          nodeIP : {
            validSubnets : local.tailscaleSubnets
          }
        }
        network = {
          hostname = each.value.name
        }
        install = {
          image = "factory.talos.dev/installer/7d4c31cbd96db9f90c874990697c523482b2bae27fb4631d5583dcd9c281b1ff:${var.talos_version}"
          disk  = data.talos_machine_disks.boot[each.key].disks[0].name
        }
        nodeLabels = {
          "k8s.tjo.cloud/gateway" = "true"
        }
      }
    }),
    yamlencode({
      apiVersion : "v1alpha1"
      kind : "ExtensionServiceConfig"
      name : "tailscale"
      environment : [
        "TS_AUTHKEY=${var.tailscale_authkey}"
      ]
    })
  ]
}

resource "talos_machine_configuration_apply" "worker" {
  for_each = { for k, v in local.nodes_with_address : k => v if v.type == "worker" }

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration

  node     = each.value.name
  endpoint = each.value.address_ipv4

  apply_mode = local.apply_mode

  config_patches = [
    yamlencode({
      cluster : {
        controlPlane : {
          endpoint : local.cluster_endpoint
          localAPIServerPort : local.cluster_port
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
        allowSchedulingOnControlPlanes : true
        apiServer : {
          extraArgs : {
            "oidc-issuer-url" : var.oidc_issuer_url
            "oidc-client-id" : var.oidc_client_id
            "oidc-username-claim" : "sub"
            "oidc-username-prefix" : "oidc:"
            "oidc-groups-claim" : "groups"
            "oidc-groups-prefix" : "oidc:groups:"
          }
        }
      }
      machine = {
        kubelet = {
          nodeIP : {
            validSubnets : local.tailscaleSubnets
          }
        }
        network = {
          hostname = each.value.name
        }
        install = {
          image = "factory.talos.dev/installer/7d4c31cbd96db9f90c874990697c523482b2bae27fb4631d5583dcd9c281b1ff:${var.talos_version}"
          disk  = data.talos_machine_disks.boot[each.key].disks[0].name
        }
      }
    }),
    yamlencode({
      apiVersion : "v1alpha1"
      kind : "ExtensionServiceConfig"
      name : "tailscale"
      environment : [
        "TS_AUTHKEY=${var.tailscale_authkey}"
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
  endpoint             = local.first_controlplane_node.address_ipv4
  client_configuration = talos_machine_secrets.this.client_configuration
}

data "talos_cluster_kubeconfig" "this" {
  depends_on = [
    talos_machine_bootstrap.this
  ]

  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = values(local.nodes_public_controlplane)[0].default_ipv4_address
}

resource "local_file" "kubeconfig" {
  content = templatefile("${path.module}/templates/kubeconfig.tftpl", {
    cluster : {
      name : var.cluster_name,
      endpoint : local.cluster_endpoint,
      ca : data.talos_cluster_kubeconfig.this.kubernetes_client_configuration.ca_certificate,
    }
    oidc : {
      issuer : var.oidc_issuer_url,
      id : var.oidc_client_id,
    }
  })
  filename = "${path.module}/kubeconfig"
}

resource "kubernetes_manifest" "hetzner-nodes-as-loadbalancers" {
  depends_on = [
    talos_machine_bootstrap.this
  ]

  manifest = {
    apiVersion = "cilium.io/v2alpha1"
    kind       = "CiliumLoadBalancerIPPool"
    metadata = {
      name = "hetzner-nodes"
    }
    spec = {
      blocks = concat(
        [for k, v in proxmox_vm_qemu.this : { start : v.default_ipv4_address } if var.nodes[k].public],
        #[for k, v in proxmox_vm_qemu.this : { start : v.default_ipv6_address } if var.nodes[k].public],
      )
    }
  }
}

# TODO: Certmanager, externaldns...
resource "helm_release" "cert-manager" {
  depends_on = [
    talos_machine_bootstrap.this
  ]

  name       = "cert-manager"
  chart      = "cert-manager"
  repository = "https://charts.jetstack.io"
  version    = "v1.15.1"
  namespace  = "kube-system"

  set {
    name  = "crds.enabled"
    value = true
  }
}

resource "kubernetes_manifest" "gateway" {
  depends_on = [
    talos_machine_bootstrap.this
  ]

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = "gateway"
      namespace = "kube-system"
    }
    spec = {
      gatewayClassName = "cilium"
      listeners = [
        { name : "http", protocol : "HTTP", port : 80 },
        { name : "https", protocol : "HTTPS", port : 443 },
      ]
    }
  }
}

resource "helm_release" "dashboard" {
  depends_on = [
    talos_machine_bootstrap.this
  ]

  name       = "kubernetes-dashboard"
  repository = "https://kubernetes.github.io/dashboard"
  chart      = "kubernetes-dashboard"
  version    = "7.5.0"
  namespace  = "kube-system"
}

resource "kubernetes_manifest" "dashoard-http-route" {
  depends_on = [
    talos_machine_bootstrap.this,
    kubernetes_manifest.gateway,
  ]

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "dashboard"
      namespace = "kube-system"
    }
    spec = {
      parentRefs = [
        { name : "gateway" }
      ]
      hostnames = [
        "dashboard.${var.cluster_name}.${var.domain}"
      ]
      rules = [
        {
          matches = [
            {
              path : {
                value : "/"
                type : "PathPrefix"
              }
            }
          ]
          backendRefs = [
            {
              name : "kubernetes-dashboard-kong-proxy"
              port : 443
            }
          ]
        }
      ]

    }
  }
}
