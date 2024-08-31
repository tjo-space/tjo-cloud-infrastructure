variable "storage" {
  type    = string
  default = "proxmox-backup-tjo-cloud"
}

variable "node_name" {
  type    = string
  default = "hetzner"
}

variable "proxmox_token" {
  type      = string
  sensitive = true
}

variable "image_path" {
  type = string
}

terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.61.1"
    }
  }
  required_version = "~> 1.7.3"
}

provider "proxmox" {
  # FIXME: Traefik/NGINX breaks this! 500 ERROR
  endpoint  = "https://178.63.49.225:8006/api2/json"
  insecure  = true
  api_token = var.proxmox_token
  ssh {
    agent    = true
    username = "root"
  }
}

resource "proxmox_virtual_environment_file" "nixos-cloudinit" {
  content_type = "iso"
  datastore_id = var.storage
  node_name    = var.node_name

  source_file {
    path      = var.image_path
    file_name = "nixos-cloudinit.img"
  }
}
