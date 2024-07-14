module "cluster" {
  source = "../../modules/cluster"

  providers = {
    helm.template = helm.template
  }

  nodes = {
    one = {
      public    = true
      type      = "controlplane"
      host      = "hetzner"
      boot_pool = "hetzner-main-data"
    },
    two = {
      public    = true
      type      = "controlplane"
      host      = "hetzner"
      boot_pool = "hetzner-main-data"
    },
    three = {
      public    = true
      type      = "controlplane"
      host      = "hetzner"
      boot_pool = "hetzner-main-data"
    },
    four = {
      public    = false
      type      = "worker"
      host      = "hetzner"
      boot_pool = "hetzner-main-data"
    }
    five = {
      public    = false
      type      = "worker"
      host      = "hetzner"
      boot_pool = "hetzner-main-data"
    }
  }

  versions = {
    talos      = "v1.7.5"
    kubernetes = "v1.30.0"
  }

  iso = "proxmox-backup-tjo-cloud:iso/talos-v1.7.5-tailscale-metal-amd64.iso"

  cluster = {
    name   = "pink"
    domain = "k8s.tjo.cloud"
    oidc = {
      client_id  = var.oidc_client_id
      issuer_url = var.oidc_issuer_url
    }
  }

  tailscale_authkey = var.tailscale_authkey
}

resource "local_file" "kubeconfig" {
  content  = module.cluster.kubeconfig
  filename = "${path.module}/kubeconfig"
}

resource "kubernetes_manifest" "hetzner-nodes-as-loadbalancers" {
  manifest = {
    apiVersion = "cilium.io/v2alpha1"
    kind       = "CiliumLoadBalancerIPPool"
    metadata = {
      name = "hetzner-nodes"
    }
    spec = {
      blocks = concat(
        [for k, node in module.cluster.nodes : { start : node.address_ipv4 } if node.public],
        # [for k, node in module.cluster.nodes : { start : node.address_ipv6 } if node.public],
      )
    }
  }
}

# TODO: Certmanager, externaldns...
resource "helm_release" "cert-manager" {
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
  name       = "kubernetes-dashboard"
  repository = "https://kubernetes.github.io/dashboard"
  chart      = "kubernetes-dashboard"
  version    = "7.5.0"
  namespace  = "kube-system"
}

resource "kubernetes_manifest" "dashoard-http-route" {
  depends_on = [
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
        "dashboard.${module.cluster.name}.${module.cluster.domain}"
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
