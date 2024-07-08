terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.1-rc3"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "1.4.0"
    }
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.2"
    }
    macaddress = {
      source  = "ivoronin/macaddress"
      version = "0.3.2"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.14.0"
    }
  }
}

provider "proxmox" {
  # FIXME: Traefik/NGINX breaks this! 500 ERROR
  pm_api_url      = "https://178.63.49.225:8006/api2/json"
  pm_tls_insecure = true
}

provider "digitalocean" {
}

provider "helm" {
  kubernetes {
    config_path = "./kubeconfig"
  }
}
