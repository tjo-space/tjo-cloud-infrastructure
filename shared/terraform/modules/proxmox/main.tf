locals {
  nodes = {
    for k, v in var.nodes : k => merge(v, {
      userdata = merge(v.userdata, {
        hostname                  = each.value.name
        fqdn                      = each.value.fqdn
        prefer_fqdn_over_hostname = true
        write_files = [
          {
            path     = "/etc/tjo.cloud/meta.json"
            encoding = "base64"
            content  = base64encode(jsonencode(each.value.meta))
            }, {
            path     = "/tmp/provision.sh"
            encoding = "base64"
            content  = base64encode(var.provision_sh)
          }
        ]
        ssh_authorized_keys = jsonencode(var.ssh_keys)
        packages = [
          "qemu-guest-agent"
        ]
        power_state = {
          mode = "reboot"
        }
        runcmd = [
          "chmod +x /tmp/provision.sh",
          "/tmp/provision.sh",
          "rm /tmp/provision.sh",
        ]
      })
    })
  }

  ipv4_addresses = {
    for key, node in local.nodes : key => {
      for k, v in proxmox_virtual_environment_vm.nodes[key].ipv4_addresses :
      proxmox_virtual_environment_vm.nodes[key].network_interface_names[k] => v
    }
  }
  ipv6_addresses = {
    for key, node in local.nodes : key => {
      for k, v in proxmox_virtual_environment_vm.nodes[key].ipv6_addresses :
      proxmox_virtual_environment_vm.nodes[key].network_interface_names[k] => v
    }
  }

  nodes_with_address = {
    for k, v in local.nodes :
    k => merge(v, {
      ipv4 = lookup(local.ipv4_addresses[k], "ens18", lookup(local.ipv4_addresses[k], "eth0", [""]))[0]
      ipv6 = lookup(local.ipv6_addresses[k], "ens18", lookup(local.ipv6_addresses[k], "eth0", [""]))[0]
    })
  }
}

resource "proxmox_virtual_environment_download_file" "ubuntu" {
  content_type = "iso"
  datastore_id = "synology.storage.tjo.cloud"
  node_name    = "nevaroo"
  file_name    = "${var.domain}-ubuntu-noble-server-cloudimg-amd64.img"
  url          = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
  overwrite    = false
}

resource "proxmox_virtual_environment_file" "userdata" {
  for_each = local.nodes

  node_name    = each.value.host
  content_type = "snippets"
  datastore_id = "synology.storage.tjo.cloud"

  source_raw {
    data      = <<EOF
    #cloud-config
    ${yamlencode(each.value.userdata)}
    EOF
    file_name = "${each.value.fqdn}.userconfig.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "nodes" {
  for_each = local.nodes

  name        = each.value.fqdn
  node_name   = each.value.host
  description = each.value.description

  tags = concat(var.tags, each.value.tags)

  stop_on_destroy     = true
  timeout_start_vm    = 60
  timeout_stop_vm     = 60
  timeout_shutdown_vm = 60
  timeout_reboot      = 60
  timeout_create      = 240

  cpu {
    cores = each.value.cores
    type  = "host"
  }
  memory {
    dedicated = each.value.memory
  }

  boot_order = ["virtio0", "ide3"]

  machine = "q35"
  bios    = "ovmf"
  efi_disk {
    datastore_id = each.value.boot_storage
  }

  operating_system {
    type = "l26"
  }

  agent {
    enabled = true
  }

  network_device {
    bridge = "vmbr1"
  }

  scsi_hardware = "virtio-scsi-single"

  disk {
    file_id      = proxmox_virtual_environment_download_file.ubuntu.id
    interface    = "virtio0"
    datastore_id = each.value.boot_storage
    size         = each.value.boot_size
    backup       = false
    cache        = "none"
    iothread     = true
    discard      = "on"
  }

  dynamic "disk" {
    for_each = each.value.disks
    content {
      interface    = "virtio${each.key}"
      datastore_id = each.value.storage
      size         = each.value.size
      backup       = true
      cache        = "none"
      iothread     = true
    }
  }

  initialization {
    interface    = "scsi0"
    datastore_id = each.value.boot_storage

    user_data_file_id = proxmox_virtual_environment_file.userdata[each.key].id

    dns = {
      servers = ["10.0.0.1", "fd74:6a6f::1"]
    }

    ip_config {
      ipv4 {
        gateway = each.value.ipv4 == "dhcp" ? null : "10.0.0.1"
        address = each.value.ipv4
      }
      ipv6 {
        gateway = each.value.ipv6 == "dhcp" ? null : "fd74:6a6f::1"
        address = each.value.ipv6
      }
    }
  }
}
