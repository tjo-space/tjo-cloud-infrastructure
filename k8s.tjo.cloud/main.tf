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
    nevaroo-cp = {
      id      = 6001
      type    = "controlplane"
      host    = "nevaroo"
      storage = "local-nvme-lvm"
      cores   = 4
      memory  = 4096
    }
    #mustafar-cp = {
    #  id      = 6000
    #  type    = "controlplane"
    #  host    = "mustafar"
    #  storage = "local"
    #  cores   = 2
    #  memory  = 4096
    #}
    #jakku-cp = {
    #  id      = 6000
    #  type    = "controlplane"
    #  host    = "jakku"
    #  storage = "local-nvme"
    #  cores   = 2
    #  memory  = 4096
    #}
    #batuu-cp = {
    #  id      = 6000
    #  type    = "controlplane"
    #  host    = "batuu"
    #  storage = "local-nvme"
    #  cores   = 2
    #  memory  = 4096
    #}

    nevaro-w1 = {
      id      = 6002
      type    = "worker"
      host    = "nevaroo"
      storage = "local-nvme-lvm"
      cores   = 8
      memory  = 24576
    }
    mustafar-1 = {
      id      = 6000
      type    = "worker"
      host    = "mustafar"
      storage = "local"
      cores   = 2
      memory  = 4096
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
