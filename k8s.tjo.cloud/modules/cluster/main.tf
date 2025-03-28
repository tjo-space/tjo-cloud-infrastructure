locals {
  public_domain             = "${var.cluster.api.public.subdomain}.${var.cluster.api.public.domain}"
  internal_domain           = "${var.cluster.api.internal.subdomain}.${var.cluster.api.internal.domain}"
  cluster_internal_endpoint = "https://${local.internal_domain}:${var.cluster.api.internal.port}"
  cluster_public_endpoint   = "https://${local.public_domain}:${var.cluster.api.public.port}"

  talos_controlplane_config = {
    machine = {
      kubelet = {
        extraArgs = {
          rotate-server-certificates = true
        }
      }
      features = {
        rbac                 = true
        apidCheckExtKeyUsage = true
        kubernetesTalosAPIAccess = {
          enabled = true
          allowedRoles = [
            "os:reader"
          ]
          allowedKubernetesNamespaces = [
            "kube-system"
          ]
        }
      }
    }
    cluster = {
      etcd = {
        extraArgs = {
          "heartbeat-timeout" = "1000" # Defaults to 100ms. Which is too fast for our network.
          "election-timeout"  = "5000" # Defaults to 1000ms. Which is too fast for our network.
        }
      }
      apiServer = {
        certSANs = [
          local.public_domain,
          local.internal_domain,
          "localhost:7445",
        ]
        extraArgs = {
          "oidc-issuer-url"      = "https://id.tjo.space/application/o/k8stjocloud/",
          "oidc-client-id"       = "HAI6rW0EWtgmSPGKAJ3XXzubQTUut2GMeTRS2spg",
          "oidc-username-claim"  = "sub",
          "oidc-username-prefix" = "oidc:",
          "oidc-groups-claim"    = "groups",
          "oidc-groups-prefix"   = "oidc:groups:",
        }
      }
      inlineManifests = concat([
        {
          name     = "proxmox-cloud-controller-manager"
          contents = data.helm_template.proxmox-ccm.manifest
        },
        {
          name     = "talos-cloud-controller-manager"
          contents = data.helm_template.talos-ccm.manifest
        },
        {
          name     = "promxmox-csi-plugin"
          contents = data.helm_template.proxmox-csi.manifest
        },
        {
          name     = "hubrid-csi-plugin"
          contents = data.helm_template.hybrid-csi.manifest
        },
        {
          name     = "gateway-api-crds"
          contents = file("${path.module}/manifests/gateway-api.crds.yaml")
        },
        {
          name     = "oidc-admins"
          contents = <<-EOF
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
          name     = "cilium"
          contents = data.helm_template.cilium.manifest
        },
        {
          name     = "cilium-bgp-advertisement"
          contents = <<-EOF
          apiVersion: cilium.io/v2alpha1
          kind: CiliumBGPAdvertisement
          metadata:
            name: pods-and-services
            labels:
              k8s.tjo.cloud/default: "true"
          spec:
            advertisements:
              - advertisementType: "PodCIDR"
              - advertisementType: "Service"
                service:
                  addresses:
                    - ExternalIP
                    - LoadBalancerIP
                  selector:
                    matchExpressions:
                     - {key: somekey, operator: NotIn, values: ['never-used-value']} # match all services
          EOF
        },
        {
          name     = "cilium-bgp-peer-config"
          contents = <<-EOF
          apiVersion: cilium.io/v2alpha1
          kind: CiliumBGPPeerConfig
          metadata:
            name: default
          spec:
            families:
              - afi: ipv4
                safi: unicast
                advertisements:
                  matchLabels:
                    k8s.tjo.cloud/default: "true"
              - afi: ipv6
                safi: unicast
                advertisements:
                  matchLabels:
                    k8s.tjo.cloud/default: "true"
          EOF
        },
        {
          name     = "cilium-load-balancer-ip-pool"
          contents = <<-EOF
          apiVersion: cilium.io/v2alpha1
          kind: CiliumLoadBalancerIPPool
          metadata:
            name: default
          spec:
            blocks:
              - cidr: "${var.cluster.load_balancer_cidr.ipv4}"
              - cidr: "${var.cluster.load_balancer_cidr.ipv6}"
          EOF
        },
        ],
        [for name, attributes in var.hosts : {
          name     = "cilium-bgp-node-config-override-${name}"
          contents = <<-EOF
          apiVersion: cilium.io/v2alpha1
          kind: CiliumBGPClusterConfig
          metadata:
            name: ${name}
          spec:
            gracefulRestart:
              enabled: true
              restartTimeSeconds: 15
            nodeSelector:
              matchLabels:
                k8s.tjo.cloud/bgp: "true"
                k8s.tjo.cloud/host: ${name}
                k8s.tjo.cloud/proxmox: ${var.proxmox.name}
            bgpInstances:
              - name: "${name}"
                localASN: ${attributes.asn}
                peers:
                  - name: "local-router-vip"
                    peerASN: ${attributes.asn}
                    peerAddress: "10.0.0.1"
                    peerConfigRef:
                      name: "default"
          EOF
        }],
        [for name, attributes in var.hosts : {
          name     = "proxmox-cni-storage-class-${name}"
          contents = <<-EOF
          apiVersion: storage.k8s.io/v1
          kind: StorageClass
          metadata:
            name: ${name}
          annotations:
            k8s.tjo.cloud/host: ${name}
            k8s.tjo.cloud/proxmox: ${var.proxmox.name}
          parameters:
            storage: ${attributes.storage}
            csi.storage.k8s.io/fstype: ext4
            cache: none
          provisioner: csi.proxmox.sinextra.dev
          allowVolumeExpansion: true
          reclaimPolicy: Delete
          volumeBindingMode: WaitForFirstConsumer
          allowedTopologies:
          - matchLabelExpressions:
            - key: topology.kubernetes.io/region
              values:
              - ${var.proxmox.name}
            - key: topology.kubernetes.io/zone
              values:
              - ${name}
          EOF
        }],
      )
    }
  }

  talos_worker_config = {
    cluster = {
      network = {
        cni = {
          name = "none"
        }
        podSubnets = [
          var.cluster.pod_cidr.ipv4,
          var.cluster.pod_cidr.ipv6
        ]
        serviceSubnets = [
          var.cluster.service_cidr.ipv4,
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
      }
      install = {
        image = "factory.talos.dev/installer/${talos_image_factory_schematic.this.id}:${var.talos.version}"
        disk  = "/dev/vda"
      }
      features = {
        hostDNS = {
          enabled              = false
          resolveMemberNames   = false
          forwardKubeDNSToHost = false
        }
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
  endpoint = each.value.ipv4

  config_patches = sensitive(concat(
    [
      yamlencode(local.talos_worker_config),
      yamlencode(local.talos_controlplane_config)
    ],
    local.talos_node_config[each.key]
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
  endpoint = each.value.ipv4

  config_patches = sensitive(concat(
    [
      yamlencode(local.talos_worker_config)
    ],
    local.talos_node_config[each.key]
  ))

  timeouts = {
    create = "1m"
    update = "1m"
  }
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [
    talos_machine_configuration_apply.controlplane,
    talos_machine_configuration_apply.worker
  ]

  node                 = local.bootstrap_node.name
  endpoint             = local.bootstrap_node.ipv4
  client_configuration = talos_machine_secrets.this.client_configuration
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on = [
    talos_machine_bootstrap.this
  ]

  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.bootstrap_node.ipv4
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
  endpoints            = values({ for k, v in local.nodes_with_address : k => v if v.type == "controlplane" })[*].ipv4
}

resource "local_file" "talosconfig" {
  count = length(values({ for k, v in local.nodes : k => v if v.type == "controlplane" })) > 0 ? 1 : 0

  content  = nonsensitive(data.talos_client_configuration.this[0].talos_config)
  filename = "${path.root}/admin.talosconfig"
}

resource "dnsimple_zone_record" "api-internal-ipv4" {
  for_each = { for k, v in local.nodes_with_address : k => v if v.type == "controlplane" }

  zone_name = var.cluster.api.internal.domain
  type      = "A"
  name      = var.cluster.api.internal.subdomain
  value     = each.value.ipv4
  ttl       = 30
}

resource "dnsimple_zone_record" "api-internal-ipv6" {
  for_each = { for k, v in local.nodes_with_address : k => v if v.type == "controlplane" }

  zone_name = var.cluster.api.internal.domain
  type      = "AAAA"
  name      = var.cluster.api.internal.subdomain
  value     = each.value.ipv6
  ttl       = 30
}
