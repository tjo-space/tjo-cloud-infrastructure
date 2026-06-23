terraform {
  required_providers {
    authentik = {
      source  = "goauthentik/authentik"
      version = "2025.4.0"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.110.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.3"
    }
  }

  required_version = "~> 1.11.0"
}

provider "authentik" {
  url   = "https://id.tjo.cloud"
  token = var.authentik_token
}

provider "proxmox" {
  endpoint  = "https://nevaroo.proxmox.cloud.internal:8006/api2/json"
  insecure  = true
  api_token = var.proxmox_token

  ssh {
    agent    = true
    username = "root"

    node {
      name    = "batuu"
      address = "batuu.proxmox.cloud.internal"
      port    = 22
    }

    node {
      name    = "jakku"
      address = "jakku.proxmox.cloud.internal"
      port    = 22
    }

    node {
      name    = "nevaroo"
      address = "nevaroo.proxmox.cloud.internal"
      port    = 22
    }

    node {
      name    = "mustafar"
      address = "mustafar.proxmox.cloud.internal"
      port    = 22
    }

    node {
      name    = "endor"
      address = "endor.proxmox.cloud.internal"
      port    = 22
    }
  }
}
