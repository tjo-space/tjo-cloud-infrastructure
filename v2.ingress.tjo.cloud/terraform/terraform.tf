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
    dnsimple = {
      source  = "dnsimple/dnsimple"
      version = "1.8.0"
    }
    zerotier = {
      source  = "zerotier/zerotier"
      version = "1.6.0"
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

provider "hcloud" {
  token = var.ingress_hcloud_token
}

provider "zerotier" {
  zerotier_central_token = var.zerotier_token
}
