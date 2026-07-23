variable "name" {
  type = string
}
variable "tags" {
  type = set(string)
}
variable "host" {
  type = string
}
variable "cores" {
  type = number
}
variable "memory" {
  type = number
}
variable "boot" {
  type = object({
    storage = string
    file_id = string
  })
}
variable "wan" {
  type = object({
    bridge      = string
    mac_address = string
  })
}
variable "lan" {
  type = object({
    bridge      = string
    mac_address = string
  })
}

resource "proxmox_virtual_environment_vm" "this" {
  name      = var.name
  node_name = var.host

  description = <<EOT
An network.tjo.cloud instance for ${var.host}.

Repo: https://code.tjo.space/tjo-cloud/infrastructure/src/branch/main/network.tjo.cloud
  EOT

  tags = var.tags

  stop_on_destroy     = true
  timeout_start_vm    = 60
  timeout_stop_vm     = 60
  timeout_shutdown_vm = 60
  timeout_reboot      = 60
  timeout_create      = 600

  cpu {
    cores = var.cores
    type  = "host"
  }
  memory {
    dedicated = var.memory
  }

  bios = "ovmf"
  efi_disk {
    datastore_id = var.boot.storage
  }

  operating_system {
    type = "l26"
  }

  agent {
    enabled = true
    timeout = "10s"
  }

  network_device {
    bridge      = var.lan.bridge
    mac_address = var.lan.mac_address
  }

  network_device {
    bridge      = var.wan.bridge
    mac_address = var.wan.mac_address
  }

  scsi_hardware = "virtio-scsi-single"
  disk {
    file_id      = var.boot.file_id
    interface    = "virtio0"
    datastore_id = var.boot.storage
    size         = 1
    backup       = true
    iothread     = true
    file_format  = "raw"
  }
}

locals {
  ipv4_addresses = {
    for k, v in proxmox_virtual_environment_vm.this.ipv4_addresses :
    proxmox_virtual_environment_vm.this.network_interface_names[k] => v
  }
  ipv6_addresses = {
    for k, v in proxmox_virtual_environment_vm.this.ipv6_addresses :
    proxmox_virtual_environment_vm.this.network_interface_names[k] => v
  }
}

output "address" {
  value = {
    wan_ipv4       = flatten([for iface, ips in local.ipv4_addresses : ips if iface == "eth1"])
    wan_ipv6       = flatten([for iface, ips in local.ipv6_addresses : ips if iface == "eth1"])
    tailscale_ipv6 = flatten([for iface, ips in local.ipv6_addresses : ips if iface == "tailscale0"])
  }
  description = "Network Addresses"
}
