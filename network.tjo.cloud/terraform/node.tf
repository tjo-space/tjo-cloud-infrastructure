locals {
  domain = "network.tjo.cloud"

  nodes = {
    for k, v in var.nodes : k => merge(v, {
      domain = local.domain
      hash   = sha1(v.host)

      wan_mac_address     = v.wan_mac_address != null ? v.wan_mac_address : "AA:BB:00:00:${format("%v:%v", substr(sha1(v.host), 0, 2), substr(sha1(v.host), 2, 2))}"
      private_mac_address = "AA:BB:00:11:${format("%v:%v", substr(sha1(v.host), 0, 2), substr(sha1(v.host), 2, 2))}"
    })
  }
}

resource "proxmox_virtual_environment_file" "iso" {
  for_each = local.nodes

  content_type = "iso"
  datastore_id = each.value.iso_storage
  node_name    = each.value.host

  source_file {
    path = "${path.module}/../iso/openwrt.img"
  }
}

resource "proxmox_virtual_environment_vm" "nodes" {
  for_each = local.nodes

  vm_id     = each.value.id
  name      = "${each.value.host}.${each.value.domain}"
  node_name = each.value.host

  description = <<EOT
An network.tjo.cloud instance for ${each.value.host}.

Repo: https://code.tjo.space/tjo-cloud/infrastructure/src/branch/main/network.tjo.cloud
  EOT

  tags = [each.value.domain]

  stop_on_destroy     = true
  timeout_start_vm    = 60
  timeout_stop_vm     = 60
  timeout_shutdown_vm = 60
  timeout_reboot      = 60
  timeout_create      = 600

  cpu {
    cores = each.value.cores
    type  = "host"
  }
  memory {
    dedicated = each.value.memory
  }

  bios = "ovmf"
  efi_disk {
    datastore_id = each.value.boot_storage
  }

  operating_system {
    type = "l26"
  }

  agent {
    enabled = true
    timeout = "10s"
  }

  network_device {
    bridge      = "vmbr0"
    mac_address = each.value.wan_mac_address
  }

  network_device {
    bridge      = "vmbr1"
    mac_address = each.value.private_mac_address
  }

  scsi_hardware = "virtio-scsi-single"
  disk {
    file_id      = proxmox_virtual_environment_file.iso[each.key].id
    interface    = "scsi0"
    datastore_id = each.value.boot_storage
    size         = 8
    backup       = true
    iothread     = true
    file_format  = "raw"
  }

  lifecycle {
    ignore_changes = [disk[0].file_id]
  }
}
