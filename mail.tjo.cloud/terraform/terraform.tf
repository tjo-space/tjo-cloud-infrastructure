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
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.37.1"
    }
    dotenv = {
      source  = "germanbrew/dotenv"
      version = "1.2.6"
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
  token = var.hcloud_token
}

provider "kubernetes" {
  config_path = "${path.module}/../../k8s.tjo.cloud/kubeconfig"
}
