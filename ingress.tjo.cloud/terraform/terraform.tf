terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.61.1"
    }
    authentik = {
      source  = "goauthentik/authentik"
      version = "2024.8.3"
    }
    tailscale = {
      source  = "tailscale/tailscale"
      version = "0.17.2"
    }
    dnsimple = {
      source  = "dnsimple/dnsimple"
      version = "1.8.0"
    }
  }

  required_version = "~> 1.9.0"
}

provider "dnsimple" {
  token   = var.dnsimple_token
  account = var.dnsimple_account_id
}

provider "authentik" {
  url   = "https://id.tjo.space"
  token = var.authentik_token
}

provider "tailscale" {
  api_key = var.tailscale_apikey
}

provider "proxmox" {
  endpoint  = "https://proxmox.tjo.cloud/api2/json"
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
  }
}
