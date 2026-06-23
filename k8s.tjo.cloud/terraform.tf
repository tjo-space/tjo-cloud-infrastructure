terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.104.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.11.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.6.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.8.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.1.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.1.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.19.0"
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

  required_version = "~> 1.11.0"
}

provider "proxmox" {
  endpoint  = "https://proxmox.cloud.internal:8006/api2/json"
  api_token = var.proxmox_token
  insecure  = true
  ssh {
    agent    = true
    username = "root"

    node {
      name    = "batuu"
      address = "batuu.proxmox.cloud.internal"
      port    = 22
    }

    node {
      name    = "jakku"
      address = "jakku.proxmox.cloud.internal"
      port    = 22
    }

    node {
      name    = "nevaroo"
      address = "nevaroo.proxmox.cloud.internal"
      port    = 22
    }

    node {
      name    = "mustafar"
      address = "mustafar.proxmox.cloud.internal"
      port    = 22
    }

    node {
      name    = "endor"
      address = "endor.proxmox.cloud.internal"
      port    = 22
    }
  }
}

provider "desec" {
  api_token = var.desec_token
}

provider "kubectl" {
  config_path = "admin.kubeconfig"
  #config_path = module.cluster.kubeconfig_path
}

provider "helm" {
  kubernetes = {
    config_path = "admin.kubeconfig"
    #config_path = module.cluster.kubeconfig_path
  }
}

provider "kubernetes" {
  #config_path = module.cluster.kubeconfig_path
  config_path = "admin.kubeconfig"
}

provider "technitium" {
  url   = "https://dns.tjo.cloud"
  token = var.dns_tjo_cloud_token
}
