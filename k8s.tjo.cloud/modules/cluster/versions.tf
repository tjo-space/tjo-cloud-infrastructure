terraform {
  required_version = ">= 1.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">=0.90.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = ">=0.10.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">=2.5.2"
    }
    desec = {
      source  = "Valodim/desec"
      version = ">=0.6.1"
    }
    random = {
      source  = "hashicorp/random"
      version = ">=3.7.1"
    }
    technitium = {
      source  = "kevynb/technitium"
      version = "0.4.0"
    }
  }
}
