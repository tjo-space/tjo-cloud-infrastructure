locals {
  pod_cidr = {
    ipv4 = "10.10.0.0/20"
    ipv6 = "fd74:6a6f:0:e000::/52"
  }
  load_balancer_cidr = {
    ipv4 = "10.10.16.0/20"
    ipv6 = "fd74:6a6f:10:1000::/52"
  }
  service_cidr = {
    ipv4 = "10.10.252.0/22"
    ipv6 = "fd74:6a6f:10:3e80::/108"
  }
}

module "cluster" {
  source = "./modules/cluster"

  talos = {
    version    = "v1.9.5"
    kubernetes = "v1.32.3"
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
    nevaroo-1 = {
      id      = 6001
      type    = "controlplane"
      host    = "nevaroo"
      storage = "local-nvme-lvm"
      cores   = 4
      memory  = 4096
    }
    nevaroo-3 = {
      id      = 6004
      type    = "controlplane"
      host    = "nevaroo"
      storage = "local-nvme-lvm"
      cores   = 4
      memory  = 4096
    }
    nevaroo-2 = {
      id      = 6003
      type    = "worker"
      host    = "nevaroo"
      storage = "local-nvme-lvm"
      cores   = 4
      memory  = 4096
    }
    mustafar-2 = {
      id      = 6002
      type    = "worker"
      host    = "mustafar"
      storage = "local"
      cores   = 4
      memory  = 4096
    }
    endor-1 = {
      id        = 6006
      type      = "controlplane"
      host      = "endor"
      storage   = "local-nvme"
      cores     = 4
      memory    = 4096
      bootstrap = true
    }
  }
}

resource "local_file" "kubeconfig" {
  content = templatefile("${path.module}/kubeconfig.tftpl", {
    cluster : {
      name : module.cluster.name,
      endpoint : module.cluster.api.internal.endpoint,
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

  cluster = {
    name : module.cluster.name,
    load_balancer_cidr = local.load_balancer_cidr
  }
  hosts = {
    nevaroo = {
      asn     = 65003
      storage = "local-nvme-lvm"
    }
    mustafar = {
      asn     = 65004
      storage = "local"
    }
    endor = {
      asn     = 65005
      storage = "local-nvme"
    }
  }
  proxmox = module.cluster.proxmox
}

# TODO: Move to be managed by argocd
module "cluster-components" {
  source = "./modules/cluster-components"

  oidc_issuer_url = var.oidc_issuer_url
  oidc_client_id  = var.oidc_client_id

  dnsimple = {
    token      = var.dnsimple_token
    account_id = var.dnsimple_account_id
  }

  domains = {
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
