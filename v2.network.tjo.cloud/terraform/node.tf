locals {
  domain = "network.tjo.cloud"

  nodes = {
    for k, v in var.nodes : k => merge(v, {
      domain = local.domain
      hash   = sha1(k)
    })
  }
}

resource "proxmox_virtual_environment_file" "iso" {
  for_each = toset([for node in local.nodes : node.host])

  content_type = "iso"
  datastore_id = "local"
  node_name    = each.key

  source_file {
    path = "${path.module}/../iso/openwrt_25.12.5_amd64.img"
  }
}

resource "proxmox_virtual_environment_vm" "nodes" {
  for_each = local.nodes

  vm_id     = each.value.id
  name      = "${each.key}.${each.value.domain}"
  node_name = each.value.host

  description = <<EOT
An network.tjo.cloud instance for ${each.value.host}.

Repo: https://code.tjo.space/tjo-cloud/infrastructure/src/branch/main/network.tjo.cloud
  EOT

  tags = [each.value.domain, each.value.role]

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
    bridge      = "vmbr3"
    mac_address = "AA:BB:00:22:${format("%v:%v", substr(sha1(each.key), 0, 2), substr(sha1(each.key), 2, 2))}"
  }

  network_device {
    bridge      = "vmbr0"
    mac_address = each.value.internet_mac_address != null ? each.value.internet_mac_address : "AA:BB:00:00:${format("%v:%v", substr(sha1(each.key), 0, 2), substr(sha1(each.key), 2, 2))}"
  }

  scsi_hardware = "virtio-scsi-single"
  disk {
    file_id      = proxmox_virtual_environment_file.iso[each.value.host].id
    interface    = "virtio0"
    datastore_id = each.value.boot_storage
    size         = 1
    backup       = true
    iothread     = true
    file_format  = "raw"
  }
}
