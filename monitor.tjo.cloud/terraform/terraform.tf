terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.84.0"
    }
    authentik = {
      source  = "goauthentik/authentik"
      version = "2025.4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.3"
    }
    technitium = {
      source  = "kevynb/technitium"
      version = "0.4.0"
    }
  }

  required_version = "~> 1.9.0"
}

provider "authentik" {
  url   = "https://id.tjo.cloud"
  token = var.authentik_token
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

    node {
      name    = "endor"
      address = "endor.system.tjo.cloud"
      port    = 22
    }
  }
}

provider "technitium" {
  url   = "https://dns.tjo.cloud"
  token = var.dns_tjo_cloud_token
}
