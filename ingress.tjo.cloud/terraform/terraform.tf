terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.50.0"
    }
    authentik = {
      source  = "goauthentik/authentik"
      version = "2025.4.0"
    }
    zerotier = {
      source  = "zerotier/zerotier"
      version = "1.6.0"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.61.1"
    }
    desec = {
      source  = "Valodim/desec"
      version = "0.6.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.3"
    }
  }

  required_version = "~> 1.9.0"
}

provider "desec" {
  api_token = var.desec_token
}

provider "authentik" {
  url   = "https://id.tjo.cloud"
  token = var.authentik_token
}

provider "hcloud" {
  token = var.ingress_hcloud_token
}

provider "zerotier" {
  zerotier_central_token = var.zerotier_token
}

provider "proxmox" {
  endpoint  = "https://nevaroo.system.tjo.cloud:8006/api2/json"
  insecure  = true
  api_token = var.proxmox_token

  ssh {
    agent    = true
    username = "root"

    node {
      name    = "batuu"
      address = "batuu.system.tjo.cloud"
      port    = 22
    }

    node {
      name    = "jakku"
      address = "jakku.system.tjo.cloud"
      port    = 22
    }

    node {
      name    = "nevaroo"
      address = "nevaroo.system.tjo.cloud"
      port    = 22
    }

    node {
      name    = "mustafar"
      address = "mustafar.system.tjo.cloud"
      port    = 22
    }

    node {
      name    = "endor"
      address = "endor.system.tjo.cloud"
      port    = 22
    }
  }
}
