resource "helm_release" "cilium" {
  name            = "cilium"
  chart           = "cilium"
  repository      = "https://helm.cilium.io/"
  version         = "1.19.5"
  namespace       = "kube-system"
  atomic          = true
  cleanup_on_fail = true

  values = [yamlencode({
    ipam = {
      mode = "kubernetes"
    }

    operator = {
      priorityClassName = "system-cluster-critical"
      prometheus = {
        enabled = true
      }
    }

    routingMode                  = "native"
    autoDirectNodeRoutes         = true
    directRoutingSkipUnreachable = true

    bgpControlPlane = {
      enabled = true
    }

    bpf = {
      datapathMode = "netkit"
      masquerade   = true
      distributedLRU = {
        enabled = true
      }
      mapDynamicSizeRatio = "0.08"
    }
    bpfClockProbe = true

    ipMasqAgent = {
      enabled = true
      config = {
        masqLinkLocalIPv6 = false
        nonMasqueradeCIDRs = [
          # Do not masquerade traffic to internal tjo.cloud ULA.
          "fd74:6a6f::/32"
        ]
      }
    }

    ipv4 = { enabled = false }

    ipv6                  = { enabled = true }
    enableIPv6Masquerade  = true
    ipv6NativeRoutingCIDR = var.cluster.pod_cidr.ipv6

    k8s = {
      requireIPv6PodCIDR = true
    }

    kubeProxyReplacement = true

    securityContext = {
      capabilities = {
        ciliumAgent = [
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
          "SETUID",
          "CAP_NET_BIND_SERVICE",
        ]
        cleanCiliumState = [
          "NET_ADMIN",
          "SYS_ADMIN",
          "SYS_RESOURCE",
        ]
      }
    }
    cgroup = {
      hostRoot = "/sys/fs/cgroup"
      autoMount = {
        enabled = false
      }
    }

    k8sServiceHost = "localhost"
    k8sServicePort = 7445

    prometheus = {
      enabled = true
      serviceMonitor = {
        enabled = true
      }
    }

    hubble = {
      enabled = false
    }
    gatewayAPI = {
      enabled = false
    }
    envoy = {
      enabled = false
    }
  })]
}

resource "kubernetes_manifest" "cilium-bgp-cluster-config" {
  depends_on = [helm_release.cilium]

  manifest = {
    apiVersion = "cilium.io/v2"
    kind       = "CiliumBGPClusterConfig"
    metadata = {
      name = "default"
    }
    spec = {
      bgpInstances = [
        {
          name     = "instance-65000"
          localASN = 65000
          peers = [
            {
              name        = "local-router"
              peerASN     = 65000
              peerAddress = "fd74:6a6f:3030:53::53"
              peerConfigRef = {
                name = "default"
              }
            }
          ]
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "cilium-bgp-advertisement" {
  depends_on = [helm_release.cilium]

  manifest = {
    apiVersion = "cilium.io/v2"
    kind       = "CiliumBGPAdvertisement"
    metadata = {
      name = "pods-and-services"
      labels = {
        "k8s.tjo.cloud/default" = "true"
      }
    }
    spec = {
      advertisements = [
        {
          advertisementType = "PodCIDR"
        },
        {
          advertisementType = "Service"
          selector = {
            matchExpressions = [
              # match all services
              { key = "somekey", operator = "NotIn", values = ["never-used-value"] }
            ]
          }
          service = {
            addresses = [
              "ExternalIP",
              "LoadBalancerIP",
            ]
          }
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "cilium-bgp-peer-config" {
  depends_on = [helm_release.cilium]

  manifest = {
    apiVersion = "cilium.io/v2"
    kind       = "CiliumBGPPeerConfig"
    metadata = {
      name = "default"
    }
    spec = {
      timers = {
        connectRetryTimeSeconds = 5
        holdTimeSeconds         = 9
        keepAliveTimeSeconds    = 3
      }
      gracefulRestart = {
        enabled            = true
        restartTimeSeconds = 15
      }
      families = [
        {
          afi  = "ipv6"
          safi = "unicast"
          advertisements = {
            matchLabels = {
              "k8s.tjo.cloud/default" = "true"
            }
          }
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "cilium-load-balancer-ip-pool" {
  depends_on = [helm_release.cilium]

  manifest = {
    apiVersion = "cilium.io/v2"
    kind       = "CiliumLoadBalancerIPPool"
    metadata = {
      name = "default"
    }
    spec = {
      blocks = [
        { cidr = var.cluster.load_balancer_cidr.ipv6 },
      ]
    }
  }
}
