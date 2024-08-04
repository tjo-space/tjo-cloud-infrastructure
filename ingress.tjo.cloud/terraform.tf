terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    dns = {
      source  = "hashicorp/dns"
      version = "~> 3.4.1"
    }
  }

  required_version = "~> 1.7.3"
}

provider "digitalocean" {
  token = var.digitalocean_token
}
