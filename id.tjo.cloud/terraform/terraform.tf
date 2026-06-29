terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.50.0"
    }
    authentik = {
      source  = "goauthentik/authentik"
      version = "2026.5.0"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.110.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.3"
    }
    technitium = {
      source  = "kevynb/technitium"
      version = "0.4.0"
    }
    desec = {
      source  = "Valodim/desec"
      version = "0.6.1"
    }
  }

  required_version = "~> 1.11.0"
}

provider "hcloud" {
  token = var.id_hcloud_token
}

provider "desec" {
  api_token = var.desec_token
}

provider "authentik" {
  url      = "https://id.cloud.internal"
  token    = var.authentik_token
  insecure = true
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

provider "technitium" {
  url   = "https://dns.tjo.cloud"
  token = var.dns_tjo_cloud_token
}
