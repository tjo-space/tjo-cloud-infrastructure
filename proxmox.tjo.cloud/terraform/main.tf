locals {
  nodes = { for key, value in var.nodes : key => merge(value, {
    name = key
    fqdn = "${key}.${var.domain}"
    })
  }

  images = {
    "ubuntu_2404_server_cloudimg_amd64.img" = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
    "ubuntu_2510_server_cloudimg_amd64.img" = "https://cloud-images.ubuntu.com/questing/current/questing-server-cloudimg-amd64.img"
    "debian_13_server_cloudimg_amd64.img"   = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-generic-amd64.qcow2"
    "rocky_10_1_server_cloudimg_amd64.img"  = "https://dl.rockylinux.org/pub/rocky/10/images/x86_64/Rocky-10-GenericCloud-Base-10.1-20251116.0.x86_64.qcow2"
  }
}

resource "proxmox_virtual_environment_download_file" "images" {
  for_each = { for pair in setproduct(toset(keys(local.nodes)), toset(keys(local.images))) :
    "${pair[0]}-${pair[1]}" => {
      node         = pair[0]
      datastore_id = "local"
      image        = pair[1]
      url          = local.images[pair[1]]
    }
  }

  content_type = "iso"
  datastore_id = each.value.datastore_id
  node_name    = each.value.node
  file_name    = each.value.image
  url          = each.value.url
  overwrite    = false
}

import {
  to = proxmox_virtual_environment_network_linux_bridge.vmbr0["nevaroo"]
  id = "nevaroo:vmbr0"
}
import {
  to = proxmox_virtual_environment_network_linux_bridge.vmbr1["nevaroo"]
  id = "nevaroo:vmbr1"
}

resource "proxmox_virtual_environment_network_linux_bridge" "vmbr0" {
  for_each = local.nodes

  node_name = each.value.name
  name      = "vmbr0"
  comment   = "Proxmox Host network interface."

  address = each.value.vmbr0.ipv4.address
  gateway = each.value.vmbr0.ipv4.gateway

  address6 = each.value.vmbr0.ipv6.address
  gateway6 = each.value.vmbr0.ipv6.gateway

  ports = each.value.vmbr0.interfaces
}

resource "proxmox_virtual_environment_network_linux_bridge" "vmbr1" {
  for_each = local.nodes

  node_name = each.value.name
  name      = "vmbr1"
  comment   = "Private network for VMs."
  // Must be left as empty list!
  ports = []
}

resource "proxmox_virtual_environment_user" "prometheus-pve-exporter" {
  comment = "Managed by Terraform"
  user_id = "prometheus-pve-exporter@pve"
  enabled = true
  acl {
    path      = "/"
    propagate = true
    role_id   = "PVEAuditor"
  }
}
resource "proxmox_virtual_environment_user_token" "prometheus-pve-exporter" {
  comment    = "Managed by Terraform"
  token_name = "prometheus-pve-exporter"
  user_id    = proxmox_virtual_environment_user.prometheus-pve-exporter.user_id
}

resource "proxmox_virtual_environment_acl" "prometheus-pve-exporter" {
  token_id  = proxmox_virtual_environment_user_token.prometheus-pve-exporter.id
  role_id   = "PVEAuditor"
  path      = "/"
  propagate = true
}
