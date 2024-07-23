locals {
  cluster_api_domain = "${var.cluster.api.subdomain}.${var.cluster.domain}"
  cluster_endpoint   = "https://${local.cluster_api_domain}:${var.cluster.api.port}"

  podSubnets = [
    "10.200.0.0/16",
    #"fd9b:5314:fc70::/64",
  ]
  serviceSubnets = [
    "10.201.0.0/16",
    #"fd9b:5314:fc71::/108",
  ]

  # Nodes will use IPs from this subnets
  # for communication between each other.
  tailscaleSubnets = [
    "100.64.0.0/10",
    "fd7a:115c:a1e0::/96"
  ]

  talos_controlplane_config = {
    machine : {
      features : {
        rbac : true
        apidCheckExtKeyUsage : true
        kubernetesTalosAPIAccess : {
          enabled : true
          allowedRoles : [
            "os:reader"
          ]
          allowedKubernetesNamespaces : [
            "kube-system"
          ]
        }
      }
    }
    cluster : {
      etcd : {
        advertisedSubnets : local.tailscaleSubnets
        listenSubnets : local.tailscaleSubnets
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
          name : "proxmox-cloud-controller-manager"
          contents : data.helm_template.proxmox-ccm.manifest
        },
        {
          name : "talos-cloud-controller-manager"
          contents : data.helm_template.talos-ccm.manifest
        },
        {
          name : "promxmox-csi-plugin"
          contents : data.helm_template.proxmox-csi.manifest
        },
        {
          name : "gateway-api-crds"
          contents : file("${path.module}/manifests/gateway-api.crds.yaml")
        },
        {
          name : "metrics-server"
          contents : file("${path.module}/manifests/metrics-server.yaml")
        },
        {
          name : "cilium"
          contents : data.helm_template.cilium.manifest
        },
        {
          name : "oidc-admins"
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
      ]
    }
  }

  talos_worker_config = {
    cluster : {
      externalCloudProvider : {
        enabled : true
      }
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
      install = {
        image = "factory.talos.dev/installer/${var.talos.schematic_id}:${var.talos.version}"
        disk  = "/dev/vda"
      }
    }
  }

  talos_node_config = {
    for k, node in local.nodes_with_address : k => [
      yamlencode({
        machine = {
          network = {
            hostname = node.name
          }
          nodeLabels = {
            "k8s.tjo.cloud/public"  = node.public ? "true" : "false"
            "k8s.tjo.cloud/host"    = node.host
            "k8s.tjo.cloud/proxmox" = var.proxmox.name
          }
          sysctls = {
            "net.ipv4.ip_forward"          = "1"
            "net.ipv6.conf.all.forwarding" = "1"
          }
        }
      }),
      yamlencode(
        {
          apiVersion : "v1alpha1"
          kind : "ExtensionServiceConfig"
          name : "tailscale"
          environment : [
            "TS_AUTHKEY=${var.tailscale_authkey}",
            "TS_HOSTNAME=${node.name}",
            "TS_ROUTES=${join(",", local.podSubnets)},${join(",", local.serviceSubnets)}",
            "TS_EXTRA_ARGS=--accept-routes --snat-subnet-routes",
          ]
      })
    ]
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

resource "talos_machine_secrets" "this" {
  talos_version = var.talos.version
}

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

resource "talos_machine_configuration_apply" "controlplane" {
  for_each = { for k, v in local.nodes_with_address : k => v if v.type == "controlplane" }

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration

  node     = each.value.name
  endpoint = each.value.ipv4

  apply_mode = "reboot"

  config_patches = concat(
    [
      yamlencode(local.talos_worker_config),
      yamlencode(local.talos_controlplane_config)
    ],
    local.talos_node_config[each.key]
  )
}

resource "talos_machine_configuration_apply" "worker" {
  for_each = { for k, v in local.nodes_with_address : k => v if v.type == "worker" }

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration

  node     = each.value.name
  endpoint = each.value.ipv4

  apply_mode = "reboot"

  config_patches = concat(
    [
      yamlencode(local.talos_worker_config)
    ],
    local.talos_node_config[each.key]
  )
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

resource "local_file" "kubeconfig" {
  content  = data.talos_cluster_kubeconfig.this.kubeconfig_raw
  filename = "${path.root}/admin.kubeconfig"
}

data "talos_client_configuration" "this" {
  count = length(values({ for k, v in local.nodes_with_address : k => v if v.type == "controlplane" })) > 0 ? 1 : 0

  cluster_name         = var.cluster.name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = values({ for k, v in local.nodes_with_address : k => v if v.type == "controlplane" })[*].ipv4
}

resource "local_file" "talosconfig" {
  count = length(values({ for k, v in local.nodes : k => v if v.type == "controlplane" })) > 0 ? 1 : 0

  content  = nonsensitive(data.talos_client_configuration.this[0].talos_config)
  filename = "${path.root}/admin.talosconfig"
}
