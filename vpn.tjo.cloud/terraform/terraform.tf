terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.66.0"
    }
    authentik = {
      source  = "goauthentik/authentik"
      version = "2026.5.0"
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

  required_version = "~> 1.11.0"
}

provider "desec" {
  api_token = var.desec_token
}

provider "authentik" {
  url      = "https://id.cloud.internal"
  token    = var.authentik_token
  insecure = true
}

provider "hcloud" {
  token = var.vpn_hcloud_token
}
