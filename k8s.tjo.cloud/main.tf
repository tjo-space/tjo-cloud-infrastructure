module "cluster" {
  source = "../modules/cluster"

  providers = {
    helm.template = helm.template
  }

  talos = {
    version    = "v1.7.5"
    kubernetes = "v1.30.0"
  }

  cluster = {
    name   = "tjo-cloud"
    domain = "k8s.tjo.cloud"
    oidc = {
      client_id  = var.oidc_client_id
      issuer_url = var.oidc_issuer_url
    }
  }

  proxmox = {
    name           = "tjo-cloud"
    url            = "https://proxmox.tjo.cloud/api2/json"
    iso_storage_id = "proxmox-backup-tjo-cloud"
  }

  tailscale_authkey = var.tailscale_authkey

  allow_scheduling_on_control_planes = true
  nodes = {
    pink = {
      public    = true
      type      = "controlplane"
      host      = "hetzner"
      boot_pool = "hetzner-main-data"
      cores     = 4
      memory    = 4096
    }
    purple = {
      public    = true
      type      = "controlplane"
      host      = "hetzner"
      boot_pool = "hetzner-main-data"
      cores     = 4
      memory    = 4096
    }
    violet = {
      public    = true
      type      = "controlplane"
      host      = "hetzner"
      boot_pool = "hetzner-main-data"
      cores     = 4
      memory    = 4096
    }
    blue = {
      public    = false
      type      = "worker"
      host      = "hetzner"
      boot_pool = "hetzner-main-data"
      cores     = 4
      memory    = 16384
    }
    cyan = {
      public    = false
      type      = "worker"
      host      = "hetzner"
      boot_pool = "hetzner-main-data"
      cores     = 4
      memory    = 16384
    }
    green = {
      public    = false
      type      = "worker"
      host      = "hetzner"
      boot_pool = "hetzner-main-data"
      cores     = 4
      memory    = 16384
    }
  }
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
        [for k, node in module.cluster.nodes : { start : node.ipv4 } if node.public],
        # [for k, node in module.cluster.nodes : { start : node.ipv6 } if node.public],
      )
    }
  }
}

resource "kubernetes_namespace" "tjo-cloud" {
  metadata {
    name = "tjo-cloud"
  }
}
