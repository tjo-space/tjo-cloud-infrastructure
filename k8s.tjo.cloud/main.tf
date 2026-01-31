locals {
  pod_cidr = {
    ipv6 = "fd9b:7c3d:7f6a::/52"
  }
  load_balancer_cidr = {
    ipv6 = "fd9b:7c3d:7f6a:1000::/52"
  }
  service_cidr = {
    ipv6 = "fd9b:7c3d:7f6a:3e80::/108"
  }
}

module "cluster" {
  source = "./modules/cluster"

  talos = {
    version    = "v1.12.2"
    kubernetes = "v1.35.0"
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
    name = "tjo-cloud"
    url  = "https://proxmox.tjo.cloud/api2/json"
  }

  nodes = {
    nevaroo-yellow = {
      id        = 6010
      type      = "controlplane"
      host      = "nevaroo"
      storage   = "local-nvme-lvm"
      cores     = 4
      memory    = 6144
      bootstrap = true
    }
    nevaroo-orange = {
      id      = 6013
      type    = "controlplane"
      host    = "nevaroo"
      storage = "local-nvme-lvm"
      cores   = 4
      memory  = 6144
    }
    endor-yellow = {
      id      = 6022
      type    = "controlplane"
      host    = "endor"
      storage = "local-nvme"
      cores   = 4
      memory  = 6144
    }
    endor-orange = {
      id      = 6023
      type    = "worker"
      host    = "endor"
      storage = "local-nvme"
      cores   = 4
      memory  = 12288
    }
    batuu-yellow = {
      id      = 6032
      type    = "worker"
      host    = "batuu"
      storage = "local-nvme"
      cores   = 4
      memory  = 12288
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
    mustafar = {
      storage = "local"
    }
    batuu = {
      storage = "local-nvme"
    }
    jakku = {
      storage = "local-nvme"
    }
  }
  proxmox = module.cluster.proxmox
}

module "cluster-components" {
  source = "./modules/cluster-components"

  oidc_issuer_url = var.oidc_issuer_url
  oidc_client_id  = var.oidc_client_id

  backup = {
    password             = var.backup.password
    s3_bucket            = "k8s-tjo-cloud-backups"
    s3_endpoint          = "https://api.s3.tjo.cloud"
    s3_access_key_id     = var.backup.s3_access_key_id
    s3_secret_access_key = var.backup.s3_secret_access_key
  }
}
