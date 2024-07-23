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
    common_storage = "proxmox-backup-tjo-cloud"
  }

  tailscale_authkey = var.tailscale_authkey

  nodes = {
    pink = {
      public  = true
      type    = "controlplane"
      host    = "hetzner"
      storage = "main"
      cores   = 4
      memory  = 4096
    }
    blue = {
      public  = false
      type    = "worker"
      host    = "hetzner"
      storage = "main"
      cores   = 6
      memory  = 16384
    }
    cyan = {
      public  = false
      type    = "worker"
      host    = "hetzner"
      storage = "main"
      cores   = 6
      memory  = 16384
    }
  }
}

resource "local_file" "kubeconfig" {
  content  = module.cluster.kubeconfig
  filename = "${path.module}/kubeconfig"
}

module "cluster-core" {
  source = "../modules/cluster-core"
}

module "cluster-components" {
  source = "../modules/cluster-components"

  oidc_issuer_url = var.oidc_issuer_url
  oidc_client_id  = var.oidc_client_id

  digitalocean_token = var.digitalocean_token

  cluster_name   = module.cluster.name
  cluster_domain = module.cluster.domain

  loadbalancer_ips = {
    hetzner-public = {
      ipv4 = [for k, node in module.cluster.nodes : node.ipv4 if node.public]
      ipv6 = [for k, node in module.cluster.nodes : node.ipv6 if node.public]
    }
  }
}
