locals {
  pod_cidr = {
    ipv4 = "10.100.0.0/20"
    ipv6 = "fd9b:7c3d:7f6a::/52"
  }
  load_balancer_cidr = {
    ipv4 = "10.100.16.0/20"
    ipv6 = "fd9b:7c3d:7f6a:1000::/52"
  }
  service_cidr = {
    ipv4 = "10.100.252.0/22"
    ipv6 = "fd9b:7c3d:7f6a:3e80::/108"
  }
}

module "cluster" {
  source = "./modules/cluster"

  talos = {
    version    = "v1.10.5"
    kubernetes = "v1.33.2"
  }

  cluster = {
    name = "k8s-tjo-cloud"
    oidc = {
      client_id  = var.oidc_client_id
      issuer_url = var.oidc_issuer_url
    }
    pod_cidr     = local.pod_cidr
    service_cidr = local.service_cidr
  }

  proxmox = {
    name           = "tjo-cloud"
    url            = "https://proxmox.tjo.cloud/api2/json"
    common_storage = "synology.storage.tjo.cloud"
  }

  nodes = {
    nevaroo-cyan = {
      id      = 6011
      type    = "controlplane"
      host    = "nevaroo"
      storage = "local-nvme-lvm"
      cores   = 4
      memory  = 4096
    }
    nevaroo-purple = {
      id      = 6012
      type    = "controlplane"
      host    = "nevaroo"
      storage = "local-nvme-lvm"
      cores   = 4
      memory  = 4096
    }
    endor-pink = {
      id        = 6021
      type      = "controlplane"
      host      = "endor"
      storage   = "local-nvme"
      cores     = 4
      memory    = 4096
      bootstrap = true
    }
    endor-orange = {
      id      = 6022
      type    = "worker"
      host    = "endor"
      storage = "local-nvme"
      cores   = 4
      memory  = 4096
    }
  }
}

resource "local_file" "kubeconfig" {
  content = templatefile("${path.module}/kubeconfig.tftpl", {
    cluster = {
      name     = module.cluster.name,
      endpoint = module.cluster.api.public.endpoint,
      ca       = module.cluster.api.ca,
    }
    oidc = {
      issuer = var.oidc_issuer_url,
      id     = var.oidc_client_id,
    }
  })
  filename = "${path.module}/kubeconfig"
}

resource "local_file" "kubeconfig-internal" {
  content = templatefile("${path.module}/kubeconfig.tftpl", {
    cluster = {
      name     = module.cluster.name,
      endpoint = module.cluster.api.internal.endpoint,
      ca       = module.cluster.api.ca,
    }
    oidc = {
      issuer = var.oidc_issuer_url,
      id     = var.oidc_client_id,
    }
  })
  filename = "${path.module}/kubeconfig-internal"
}

module "cluster-core" {
  source = "./modules/cluster-core"

  cluster = {
    name               = module.cluster.name,
    load_balancer_cidr = local.load_balancer_cidr
    pod_cidr           = local.pod_cidr
  }
  bgp = {
    asn = 65000
  }
  hosts = {
    nevaroo = {
      storage = "local-nvme-lvm"
    }
    endor = {
      storage = "local-nvme"
    }
  }
  proxmox = module.cluster.proxmox
}

module "cluster-components" {
  source = "./modules/cluster-components"

  oidc_issuer_url = var.oidc_issuer_url
  oidc_client_id  = var.oidc_client_id

  desec = {
    token = var.desec_token
  }

  domains = {
    "tjo-space" = {
      zone   = "tjo.space"
      domain = "tjo.space"
    }
    "tjo-cloud" = {
      zone   = "tjo.cloud"
      domain = "tjo.cloud"
    }
    "k8s-tjo-cloud" = {
      zone   = "k8s.tjo.cloud"
      domain = "k8s.tjo.cloud"
    }
  }
}
