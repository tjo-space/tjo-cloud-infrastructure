terraform {
  required_providers {
    authentik = {
      source  = "goauthentik/authentik"
      version = "2026.5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.3"
    }
  }

  required_version = "~> 1.11.0"
}

provider "authentik" {
  url      = "https://id.cloud.internal"
  token    = var.authentik_token
  insecure = true
}
