locals {
  public_domain             = "${var.cluster.api.public.subdomain}.${var.cluster.api.public.domain}"
  internal_domain           = "${var.cluster.api.internal.subdomain}.${var.cluster.api.internal.domain}"
  cluster_internal_endpoint = "https://${local.internal_domain}:${var.cluster.api.internal.port}"
  cluster_public_endpoint   = "https://${local.public_domain}:${var.cluster.api.public.port}"

  talos_controlplane_config = {
    version = "v1alpha1"
    machine = {
      kubelet = {
        extraArgs = {
          rotate-server-certificates = true
        }
        nodeIP = {
          validSubnets = [
            "fd74:6a6f::/32",
          ]
        }
      }
      features = {
        kubernetesTalosAPIAccess = {
          enabled = true
          allowedRoles = [
            "os:reader"
          ]
          allowedKubernetesNamespaces = [
            "kube-system"
          ]
        }
        hostDNS = {
          enabled              = false
          forwardKubeDNSToHost = false
          resolveMemberNames   = false
        }
      }
      network = {
        nameservers = ["fd74:6a6f::1"]
      }
    }
    cluster = {
      etcd = {
        advertisedSubnets = [
          "fd74:6a6f::/32",
        ]
        extraArgs = {
          heartbeat-interval = "1000" # Defaults to 100ms. Which is too fast for our network.
          election-timeout   = "5000" # Defaults to 1000ms. Which is too fast for our network.
        }
      }
      apiServer = {
        certSANs = [
          local.public_domain,
          local.internal_domain,
          "localhost:7445",
        ]
        extraArgs = {
          "oidc-issuer-url"      = "https://id.tjo.cloud/application/o/k8stjocloud/",
          "oidc-client-id"       = "HAI6rW0EWtgmSPGKAJ3XXzubQTUut2GMeTRS2spg",
          "oidc-username-claim"  = "sub",
          "oidc-username-prefix" = "oidc:",
          "oidc-groups-claim"    = "groups",
          "oidc-groups-prefix"   = "oidc:groups:",
        }
      }
    }
  }

  talos_worker_config = {
    version = "v1alpha1"
    cluster = {
      network = {
        cni = {
          name = "none"
        }
        podSubnets = [
          var.cluster.pod_cidr.ipv6
        ]
        serviceSubnets = [
          var.cluster.service_cidr.ipv6
        ]
      }
      proxy = {
        disabled = true
      }
    }
    machine = {
      kubelet = {
        extraArgs = {
          rotate-server-certificates = true
          cloud-provider             = "external"
        }
        nodeIP = {
          validSubnets = [
            "fd74:6a6f::/32",
          ]
        }
      }
      install = {
        image = "factory.talos.dev/nocloud-installer/${talos_image_factory_schematic.this.id}:${var.talos.version}"
        disk  = "/dev/vda"
      }
      features = {
        hostDNS = {
          enabled              = false
          forwardKubeDNSToHost = false
          resolveMemberNames   = false
        }
      }
      network = {
        nameservers = ["fd74:6a6f::1"]
      }
    }
  }

  talos_node_config = {
    for k, node in local.nodes_with_address : k => [
      yamlencode({
        machine = {
          nodeLabels = {
            "k8s.tjo.cloud/bgp"     = "true"
            "k8s.tjo.cloud/host"    = node.host
            "k8s.tjo.cloud/proxmox" = var.proxmox.name
          }
        }
      }),
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

  config_patches = sensitive(concat(
    [
      yamlencode(local.talos_worker_config),
      yamlencode(local.talos_controlplane_config)
    ],
    local.talos_node_config[each.key],
  ))

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

  config_patches = sensitive(concat(
    [
      yamlencode(local.talos_worker_config)
    ],
    local.talos_node_config[each.key],
  ))

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

  domain  = var.cluster.api.internal.domain
  subname = var.cluster.api.internal.subdomain
  type    = each.key
  records = each.value
  ttl     = 3600
}

resource "desec_rrset" "api-public" {
  domain  = var.cluster.api.public.domain
  subname = var.cluster.api.public.subdomain
  type    = "CNAME"
  records = ["any.ingress.tjo.cloud."]
  ttl     = 3600
}
