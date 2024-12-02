locals {
  cluster_domain = "k8s.tjo.cloud"
}

module "cluster" {
  source = "./modules/cluster"

  providers = {
    helm.template = helm.template
  }

  talos = {
    version    = "v1.8.3"
    kubernetes = "v1.31.0"
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
    common_storage = "synology.storage.tjo.cloud"
  }

  nodes = {
    pink = {
      type    = "controlplane"
      host    = "nevaroo"
      storage = "local-nvme-lvm"
      cores   = 4
      memory  = 4096
      pod_cidr = {
        ipv4 = "10.0.56.0/20"
        ipv6 = "fd74:6a6f:0:3800::/52"
      }
    }
    blue = {
      type    = "worker"
      host    = "nevaroo"
      storage = "local-nvme-lvm"
      cores   = 8
      memory  = 24576
      pod_cidr = {
        ipv4 = "10.0.52.0/20"
        ipv6 = "fd74:6a6f:0:3400::/52"
      }
    }
    cyan = {
      type    = "worker"
      host    = "mustafar"
      storage = "local"
      cores   = 2
      memory  = 4096
      pod_cidr = {
        ipv4 = "10.0.68.0/20"
        ipv6 = "fd74:6a6f:0:4000::/52"
      }
    }
  }
}

resource "local_file" "kubeconfig" {
  content = templatefile("${path.module}/kubeconfig.tftpl", {
    cluster : {
      name : module.cluster.name,
      endpoint : module.cluster.api.public.endpoint,
      ca : module.cluster.api.ca,
    }
    oidc : {
      issuer : var.oidc_issuer_url,
      id : var.oidc_client_id,
    }
  })
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
