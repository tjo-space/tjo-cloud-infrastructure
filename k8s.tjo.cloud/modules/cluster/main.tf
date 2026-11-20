locals {
  public_domain             = "${var.cluster.api.public.subdomain}.${var.cluster.api.public.domain}"
  internal_domain           = "${var.cluster.api.internal.subdomain}.${var.cluster.api.internal.domain}"
  cluster_internal_endpoint = "https://${local.internal_domain}:${var.cluster.api.internal.port}"
  cluster_public_endpoint   = "https://${local.public_domain}:${var.cluster.api.public.port}"

  talos_controlplane_configs = [
    {
      version = "v1alpha1"
      cluster = {
        etcd = {
          advertisedSubnets = [
            "fd74:6a6f:3030::/48",
          ]
          extraArgs = {
            heartbeat-interval = "1000" # Defaults to 100ms. Which is too fast for our network.
            election-timeout   = "5000" # Defaults to 1000ms. Which is too fast for our network.
          }
        }
      }
    },
    {
      apiVersion = "v1alpha1"
      kind       = "KubeAPIServerConfig"
      image      = "registry.k8s.io/kube-apiserver:${var.talos.kubernetes}"
      certExtraSANs = [
        local.public_domain,
        local.internal_domain,
        "localhost:7445",
      ]
    },
    {
      apiVersion = "v1alpha1"
      kind       = "KubeAuthenticationConfig"
      configuration = {
        jwt = [
          {
            issuer = {
              url = "https://id.tjo.cloud/application/o/k8stjocloud/"
              audiences = [
                "HAI6rW0EWtgmSPGKAJ3XXzubQTUut2GMeTRS2spg"
              ]
            }
            claimMappings = {
              username = { claim = "sub", prefix = "oidc:" }
              groups   = { claim = "groups", prefix = "oidc:groups:" }
            }
          }
        ]
      }
    },
    {
      apiVersion = "v1alpha1"
      kind       = "KubeProxyConfig"
      enabled    = false
    },
    {
      apiVersion = "v1alpha1"
      kind       = "KubeTalosAPIAccessConfig"
      allowedRoles = [
        "os:reader"
      ]
      allowedKubernetesNamespaces = [
        "kube-system"
      ]
    },
    {
      apiVersion = "v1alpha1"
      kind       = "KubePrismConfig"
      port       = 7445
    }
  ]

  talos_configs = [
    {
      apiVersion = "v1alpha1"
      kind       = "KubeNetworkConfig"
      podSubnets = [
        var.cluster.pod_cidr.ipv6
      ]
      serviceSubnets = [
        var.cluster.service_cidr.ipv6
      ]
    },
    {
      apiVersion = "v1alpha1"
      kind       = "KubeletConfig"
      image      = "ghcr.io/siderolabs/kubelet:${var.talos.kubernetes}"
      extraArgs = {
        rotate-server-certificates = true
        cloud-provider             = "external"
      }
    },
    {
      apiVersion = "v1alpha1"
      kind       = "ResolverConfig"
      nameservers = [
        { address = "fd74:6a6f:3030:53::53" }
      ]
      hostDNS = {
        enabled              = false
        forwardKubeDNSToHost = false
        resolveMemberNames   = false
      }
    },
    {
      apiVersion = "v1alpha1"
      kind       = "UnattendedInstallConfig"
      installer = {
        image = "factory.talos.dev/nocloud-installer/${talos_image_factory_schematic.this.id}:${var.talos.version}"
      }
      provisioning = {
        diskSelector = {
          match = "disk.dev_path == \"/dev/vda\""
        }
      }
    },
    {
      apiVersion        = "v1alpha1"
      kind              = "SecurityProfileConfig"
      workloadIsolation = true
    },
    ## Required for Kata Containers
    {
      apiVersion = "v1alpha1"
      kind       = "KernelModuleConfig"
      name       = "vhost_net"
    },
    {
      apiVersion = "v1alpha1"
      kind       = "KernelModuleConfig"
      name       = "vhost_vsock"
    },
    ## Disable default Flannel CNI
    {
      apiVersion = "v1alpha1"
      kind       = "KubeFlannelCNIConfig"
      "$patch"   = "delete"
    }
  ]

  talos_node_config = {
    for k, node in local.nodes_with_address : k => [
      {
        apiVersion = "v1alpha1"
        kind       = "KubeNodeConfig"
        nodeIP = {
          validSubnets = [
            "fd74:6a6f:3030::/48"
          ]
        }
        labels = {
          "k8s.tjo.cloud/bgp"     = "true"
          "k8s.tjo.cloud/host"    = node.host
          "k8s.tjo.cloud/proxmox" = var.proxmox.name
        }
      },
      {
        machine = {
          files = [
            {
              path        = "/usr/local/share/kata-containers/configuration.toml"
              content     = file("${path.module}/kata.configuration.toml")
              op          = "overwrite"
              permissions = 444
            }
          ]
        }
      },
    ]
  }
}

resource "talos_machine_secrets" "this" {
  talos_version = var.talos.version
}

data "talos_machine_configuration" "controlplane" {
  cluster_name     = var.cluster.name
  machine_type     = "controlplane"
  cluster_endpoint = local.cluster_internal_endpoint
  machine_secrets  = talos_machine_secrets.this.machine_secrets

  talos_version      = var.talos.version
  kubernetes_version = var.talos.kubernetes
}

data "talos_machine_configuration" "worker" {
  cluster_name     = var.cluster.name
  machine_type     = "worker"
  cluster_endpoint = local.cluster_internal_endpoint
  machine_secrets  = talos_machine_secrets.this.machine_secrets

  talos_version      = var.talos.version
  kubernetes_version = var.talos.kubernetes
}

resource "talos_machine_configuration_apply" "controlplane" {
  for_each = { for k, v in local.nodes_with_address : k => v if v.type == "controlplane" }

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration

  node     = each.value.name
  endpoint = each.value.ipv6

  config_patches = sensitive([for config in concat(
    local.talos_controlplane_configs,
    local.talos_configs,
    local.talos_node_config[each.key],
  ) : yamlencode(config)])

  timeouts = {
    create = "1m"
    update = "1m"
  }
}

resource "talos_machine_configuration_apply" "worker" {
  for_each = { for k, v in local.nodes_with_address : k => v if v.type == "worker" }

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration

  node     = each.value.name
  endpoint = each.value.ipv6

  config_patches = sensitive([for config in concat(
    local.talos_configs,
    local.talos_node_config[each.key],
  ) : yamlencode(config)])

  timeouts = {
    create = "1m"
    update = "1m"
  }
}

resource "talos_machine_bootstrap" "this" {
  count = local.bootstrap_node_key != null ? 1 : 0

  depends_on = [
    talos_machine_configuration_apply.controlplane,
    talos_machine_configuration_apply.worker
  ]

  node                 = local.nodes_with_address[local.bootstrap_node_key].name
  endpoint             = local.nodes_with_address[local.bootstrap_node_key].ipv6
  client_configuration = talos_machine_secrets.this.client_configuration
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on = [
    talos_machine_bootstrap.this
  ]

  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = try(local.nodes_with_address[local.bootstrap_node_key].ipv6, [for k, v in local.nodes_with_address : v.ipv6][0])
}

resource "local_file" "kubeconfig" {
  content  = talos_cluster_kubeconfig.this.kubeconfig_raw
  filename = "${path.root}/admin.kubeconfig"

  lifecycle {
    ignore_changes = [content]
  }
}

data "talos_client_configuration" "this" {
  count = length(values({ for k, v in local.nodes_with_address : k => v if v.type == "controlplane" })) > 0 ? 1 : 0

  cluster_name         = var.cluster.name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = values({ for k, v in local.nodes_with_address : k => v if v.type == "controlplane" })[*].ipv6
}

resource "local_file" "talosconfig" {
  count = length(values({ for k, v in local.nodes : k => v if v.type == "controlplane" })) > 0 ? 1 : 0

  content  = nonsensitive(data.talos_client_configuration.this[0].talos_config)
  filename = "${path.root}/admin.talosconfig"
}


resource "desec_rrset" "api-internal" {
  for_each = {
    AAAA = [for k, v in local.nodes_with_address : v.ipv6 if v.type == "controlplane"]
  }

  domain  = "tjo.cloud"
  subname = "api.internal.k8s"
  type    = each.key
  records = each.value
  ttl     = 3600
}

resource "technitium_record" "api-internal" {
  for_each   = tomap({ for k, v in local.nodes_with_address : k => v.ipv6 if v.type == "controlplane" })
  zone       = var.cluster.api.internal.domain
  domain     = "${var.cluster.api.internal.subdomain}.${var.cluster.api.internal.domain}"
  ttl        = 60
  type       = "AAAA"
  ip_address = each.value
}

resource "desec_rrset" "api-public" {
  domain  = var.cluster.api.public.domain
  subname = var.cluster.api.public.subdomain
  type    = "CNAME"
  records = ["any.ingress.tjo.cloud."]
  ttl     = 3600
}
