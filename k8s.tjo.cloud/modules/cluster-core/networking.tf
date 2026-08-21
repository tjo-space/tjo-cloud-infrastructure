resource "helm_release" "cilium" {
  name            = "cilium"
  chart           = "cilium"
  repository      = "oci://quay.io/cilium/charts"
  version         = "1.20.0"
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
        serviceMonitor = {
          enabled = true
        }
      }
    }

    resources = {
      limits = {
        memory = "1Gi"
      }
      requests = {
        memory = "256Mi"
      }
    }

    routingMode = "native"

    bgpControlPlane = {
      enabled = true
    }

    bpf = {
      # Required to use kata-containers
      # Ref: https://github.com/kata-containers/kata-containers/issues/12159
      datapathMode = "veth"
      masquerade   = true
      distributedLRU = {
        enabled = true
      }
      mapDynamicSizeRatio = "0.0025"
      preallocateMaps     = true
    }
    bpfClockProbe = true

    ipMasqAgent = {
      enabled = true
      config = {
        masqLinkLocalIPv6 = false
        nonMasqueradeCIDRs = [
          # Do not masquerade traffic to internal tjo.cloud ULA.
          "fd74:6a6f:3030::/48"
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
    # Required for Kata Containers
    # Ref: https://docs.cilium.io/en/stable/network/kubernetes/kubeproxy-free/#socket-loadbalancer-bypass-in-pod-namespace
    socketLB = {
      hostNamespaceOnly = true
    }

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
      ui = {
        enabled           = true
        priorityClassName = "system-cluster-critical"
      }
      relay = {
        enabled           = true
        priorityClassName = "system-cluster-critical"
      }
      metrics = {
        enabled = [
          "dns",
          "drop",
          "tcp",
          "flow",
          "port-distribution",
          "icmp",
          "httpV2:exemplars=true;labelsContext=source_ip,source_namespace,source_workload,destination_ip,destination_namespace,destination_workload,traffic_direction"
        ]
        enableOpenMetrics = true
        serviceMonitor = {
          enabled = true
        }
      }
      tls = {
        auto = {
          enabled              = true
          method               = "helm"
          certValidityDuration = 1095
        }
      }
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
