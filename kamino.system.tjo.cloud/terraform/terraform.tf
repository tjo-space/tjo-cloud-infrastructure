terraform {
  required_providers {
    authentik = {
      source  = "goauthentik/authentik"
      version = "2025.4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.3"
    }
  }

  required_version = "~> 1.9.0"
}

provider "authentik" {
  url   = "https://id.tjo.cloud"
  token = var.authentik_token
}
