terraform {
  required_providers {
    dns = {
      source  = "hashicorp/dns"
      version = "3.4.3"
    }
    desec = {
      source  = "Valodim/desec"
      version = "0.6.1"
    }
    technitium = {
      source  = "kevynb/technitium"
      version = "0.4.0"
    }
  }

  required_version = "~> 1.9.0"
}

provider "desec" {
  api_token = var.desec_token
}

provider "technitium" {
  url   = "https://dns.cloud.internal"
  token = var.dns_tjo_cloud_token
}
