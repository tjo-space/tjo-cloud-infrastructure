terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.110.0"
    }
  }

  required_version = "~> 1.11.0"
}

provider "proxmox" {
  endpoint  = "https://nevaroo-proxmox-cloud-internal.corgi-hamlet.ts.net:8006/api2/json"
  insecure  = true
  api_token = var.proxmox_token

  ssh {
    agent    = true
    username = "root"

    node {
      name    = "batuu"
      address = "batuu-proxmox-cloud-internal.corgi-hamlet.ts.net"
      port    = 22
    }

    node {
      name    = "jakku"
      address = "jakku-proxmox-cloud-internal.corgi-hamlet.ts.net"
      port    = 22
    }

    node {
      name    = "nevaroo"
      address = "nevaroo-proxmox-cloud-internal.corgi-hamlet.ts.net"
      port    = 22
    }

    node {
      name    = "mustafar"
      address = "mustafar-proxmox-cloud-internal.corgi-hamlet.ts.net"
      port    = 22
    }

    node {
      name    = "endor"
      address = "endor-proxmox-cloud-internal.corgi-hamlet.ts.net"
      port    = 22
    }
  }
}
