locals {
  domain = "postgresql.tjo.cloud"

  nodes = {
    for k, v in var.nodes : k => merge(v, {
      domain = local.domain
      meta = {
        name   = v.host
        domain = local.domain
        service_account = {
          username = authentik_user.service_account[k].username
          password = authentik_token.service_account[k].key
        }
      }
    })
  }
}

resource "proxmox_virtual_environment_download_file" "ubuntu" {
  for_each = local.nodes

  content_type = "iso"
  datastore_id = each.value.iso_storage
  node_name    = each.value.host
  url          = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
  overwrite    = true
}

resource "proxmox_virtual_environment_file" "userdata" {
  for_each = local.nodes

  node_name    = each.value.host
  content_type = "snippets"
  datastore_id = each.value.iso_storage

  source_raw {
    data      = <<-EOF
    #cloud-config
    hostname: ${each.value.host}
    fqdn: ${each.value.host}.${each.value.domain}
    prefer_fqdn_over_hostname: true
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
    swap:
      filename: /swapfile
      size: 512M
    runcmd:
      - "chmod +x /tmp/provision.sh"
      - "/tmp/provision.sh"
      - "rm /tmp/provision.sh"
    EOF
    file_name = "${each.value.host}.${each.value.domain}.userconfig.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "nodes" {
  for_each = local.nodes

  vm_id     = each.value.id
  name      = "${each.value.host}.${each.value.domain}"
  node_name = each.value.host

  description = <<EOT
An ${each.value.domain} instance for ${each.value.host}.

Repo: https://code.tjo.space/tjo-cloud/infrastructure/postgresql.tjo.cloud
  EOT

  tags = [each.value.domain]

  stop_on_destroy     = true
  timeout_start_vm    = 60
  timeout_stop_vm     = 60
  timeout_shutdown_vm = 60
  timeout_reboot      = 60
  timeout_create      = 60

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
    file_id      = proxmox_virtual_environment_download_file.ubuntu[each.key].id
    interface    = "virtio0"
    datastore_id = each.value.boot_storage
    size         = each.value.boot_size
    backup       = true
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

  initialization {
    interface         = "scsi0"
    datastore_id      = each.value.boot_storage
    user_data_file_id = proxmox_virtual_environment_file.userdata[each.key].id

    ip_config {
      ipv4 {
        address = "dhcp"
      }
      ipv6 {
        address = "dhcp"
      }
    }
  }
}
