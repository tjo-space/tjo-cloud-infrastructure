locals {
  nodes_with_name = {
    for k, v in var.nodes : k => merge(v, {
      name = k
      fqdn = "${k}.${var.domain}"
    })
  }

  nodes = {
    for k, v in local.nodes_with_name : k => merge(v, {
      meta = {
        cloud_region = v.host
        service_name = var.domain
        service_account = {
          username = authentik_user.service_account[k].username
          password = authentik_token.service_account[k].key
        }
      }
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
      ipv4 = local.ipv4_addresses[k]["eth0"][0]
      ipv6 = local.ipv6_addresses[k]["eth0"][0]
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
    data      = <<-EOF
    #cloud-config
    hostname: ${each.value.name}
    fqdn: ${each.value.fqdn}
    prefer_fqdn_over_hostname: true

    disk_setup:
      /dev/vdb:
        table_type: 'gpt'
        layout:
          - 100
      /dev/vdc:
        table_type: 'gpt'
        layout:
          - 100

    fs_setup:
      - label: data
        filesystem: 'ext4'
        device: '/dev/vdb'
        cmd: mkfs -t %(filesystem)s -L %(label)s %(device)s
      - label: backup
        filesystem: 'ext4'
        device: '/dev/vdc'
        cmd: mkfs -t %(filesystem)s -L %(label)s %(device)s

    mounts:
      - [ /dev/vdb1, /srv/data ]
      - [ /dev/vdc1, /srv/backup ]

    write_files:
    - path: /etc/tjo.cloud/meta.json
      encoding: base64
      content: ${base64encode(jsonencode(each.value.meta))}
    - path: /tmp/provision.sh
      encoding: base64
      content: ${base64encode(file("${path.module}/../provision.sh"))}

    ssh_authorized_keys: ${jsonencode(var.ssh_keys)}

    packages:
      - qemu-guest-agent

    power_state:
      mode: reboot

    runcmd:
      - "chmod +x /tmp/provision.sh"
      - "/tmp/provision.sh"
      - "rm /tmp/provision.sh"
    EOF
    file_name = "${each.value.fqdn}.userconfig.yaml"
  }

  lifecycle {
    ignore_changes = [
      source_raw,
    ]
  }
}

resource "proxmox_virtual_environment_vm" "nodes" {
  for_each = local.nodes

  name      = each.value.fqdn
  node_name = each.value.host

  description = <<EOT
An ${var.domain} instance for ${each.value.name}.

Repo: https://code.tjo.space/tjo-cloud/infrastructure/postgresql.tjo.cloud
  EOT

  tags = [var.domain]

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

  bios = "ovmf"
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
  }

  disk {
    interface    = "virtio1"
    datastore_id = each.value.data_storage
    size         = each.value.data_size
    backup       = true
    cache        = "none"
    iothread     = true
  }

  disk {
    interface    = "virtio2"
    datastore_id = each.value.backup_storage
    size         = each.value.backup_size
    backup       = true
    cache        = "none"
    iothread     = true
  }

  initialization {
    interface         = "scsi0"
    datastore_id      = each.value.boot_storage
    user_data_file_id = proxmox_virtual_environment_file.userdata[each.key].id

    ip_config {
      ipv4 {
        gateway = "10.0.0.1"
        address = each.value.ipv4
      }
      ipv6 {
        gateway = "fd74:6a6f::1"
        address = each.value.ipv6
      }
    }
  }

  lifecycle {
    ignore_changes = [
      initialization[0].user_data_file_id,
      disk[0].file_id,
    ]
  }
}
