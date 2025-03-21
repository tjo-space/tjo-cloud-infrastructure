module "cluster" {
  source = "./modules/cluster"

  providers = {
    helm.template = helm.template
  }

  talos = {
    version    = "v1.9.0"
    kubernetes = "v1.32.0"
  }

  cluster = {
    name = "k8s-tjo-cloud"
    oidc = {
      client_id  = var.oidc_client_id
      issuer_url = var.oidc_issuer_url
    }
    pod_cidr = {
      ipv4 = "10.0.240.0/22"
      ipv6 = "fd74:6a6f:0:f000::/54"
    }
    service_cidr = {
      ipv4 = "10.0.244.0/22"
      ipv6 = "fd74:6a6f:0:f400::/108"
    }
    load_balancer_cidr = {
      ipv4 = "10.0.248.0/22"
      ipv6 = "fd74:6a6f:0:f800::/54"
    }
  }

  proxmox = {
    name           = "tjo-cloud"
    url            = "https://proxmox.tjo.cloud/api2/json"
    common_storage = "synology.storage.tjo.cloud"
  }

  hosts = {
    nevaroo = {
      asn = 65003
    }
    mustafar = {
      asn = 65004
    }
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
    nevaroo-2 = {
      id      = 6003
      type    = "worker"
      host    = "nevaroo"
      storage = "local-nvme-lvm"
      cores   = 4
      memory  = 4096
    }
    mustafar-3 = {
      id      = 6005
      type    = "controlplane"
      host    = "mustafar"
      storage = "local"
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

  dnsimple_token      = var.dnsimple_token
  dnsimple_account_id = var.dnsimple_account_id

  cluster_name   = module.cluster.name
  cluster_domain = "k8s.tjo.cloud"
}
