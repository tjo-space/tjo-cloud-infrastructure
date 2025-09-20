terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.61.1"
    }
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.50.0"
    }
    authentik = {
      source  = "goauthentik/authentik"
      version = "2025.4.0"
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

  required_version = "~> 1.9.0"
}

provider "desec" {
  api_token = var.desec_token
}

provider "authentik" {
  url   = "https://id.tjo.space"
  token = var.authentik_token
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

provider "proxmox" {
  endpoint  = "https://nevaroo.system.tjo.cloud:8006/api2/json"
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
