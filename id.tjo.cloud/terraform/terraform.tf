terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.50.0"
    }
    desec = {
      source  = "Valodim/desec"
      version = "0.6.1"
    }
  }

  required_version = "~> 1.7.3"
}

provider "hcloud" {
  token = var.id_hcloud_token
}

provider "desec" {
  api_token = var.desec_token
}
