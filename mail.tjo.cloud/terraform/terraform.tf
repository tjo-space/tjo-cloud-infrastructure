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
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.37.1"
    }
    dotenv = {
      source  = "germanbrew/dotenv"
      version = "1.2.6"
    }
    zerotier = {
      source  = "zerotier/zerotier"
      version = "1.6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.1"
    }
    desec = {
      source  = "Valodim/desec"
      version = "0.6.1"
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
  token = var.mail_hcloud_token
}

provider "kubernetes" {
  config_path = "${path.module}/../../k8s.tjo.cloud/kubeconfig"
}

provider "zerotier" {
  zerotier_central_token = var.zerotier_token
}
