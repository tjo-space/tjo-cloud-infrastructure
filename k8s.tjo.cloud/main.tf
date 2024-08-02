locals {
  cluster_domain = "k8s.tjo.cloud"
}

resource "tailscale_tailnet_key" "nodes" {
  reusable      = true
  ephemeral     = true
  preauthorized = true
  tags          = ["tag:kubernetes-tjo-cloud"]

  description = "tailscale key for k8s-tjo-cloud nodes"
}

module "cluster" {
  source = "./modules/cluster"

  providers = {
    helm.template = helm.template
  }

  talos = {
    version    = "v1.7.5"
    kubernetes = "v1.30.0"
  }

  cluster = {
    name = "k8s-tjo-cloud"
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

  tailscale_authkey = tailscale_tailnet_key.nodes.key

  nodes = {
    pink = {
      public  = false
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

data "tailscale_device" "controlpane" {
  for_each = { for k, v in module.cluster.nodes : k => v if v.type == "controlplane" }
  hostname = each.value.name
}
resource "digitalocean_record" "internal-api" {
  for_each = toset(flatten([for key, device in data.tailscale_device.controlpane : device.addresses]))

  domain = local.cluster_domain
  type   = strcontains(each.value, ":") ? "AAAA" : "A"
  name   = "internal.api"
  value  = each.value
  ttl    = 30
}

resource "local_file" "kubeconfig" {
  content  = module.cluster.kubeconfig
  filename = "${path.module}/kubeconfig"
}

module "cluster-core" {
  source = "./modules/cluster-core"

  cluster_name = module.cluster.name
}

module "cluster-components" {
  source = "./modules/cluster-components"

  oidc_issuer_url = var.oidc_issuer_url
  oidc_client_id  = var.oidc_client_id

  digitalocean_token = var.digitalocean_token

  cluster_name   = module.cluster.name
  cluster_domain = "k8s.tjo.cloud"
}
