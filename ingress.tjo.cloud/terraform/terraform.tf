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
  }

  required_version = "~> 1.7.3"
}

provider "authentik" {
  url   = "https://id.tjo.space"
  token = var.authentik_token
}

provider "tailscale" {
  api_key = var.tailscale_apikey
}

provider "proxmox" {
  # FIXME: Traefik/NGINX breaks this! 500 ERROR
  endpoint  = "https://batuu.system.tjo.cloud:8006/api2/json"
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
  }
}