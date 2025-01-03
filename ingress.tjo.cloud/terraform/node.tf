locals {
  domain = "ingress.tjo.cloud"

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
        tailscale = {
          auth_key = tailscale_tailnet_key.key.key
        }
        dnsimple = {
          token      = var.dnsimple_token
        }
      }
    })
  }
}

resource "tailscale_tailnet_key" "key" {
  reusable      = true
  ephemeral     = false
  preauthorized = true
  description   = "ingress-tjo-cloud terraform key"
  tags          = ["tag:ingress-tjo-cloud"]
}

resource "proxmox_virtual_environment_download_file" "ubuntu" {
  for_each = local.nodes

  content_type = "iso"
  datastore_id = each.value.iso_storage
  node_name    = each.value.host
  url          = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
  overwrite    = false
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
    ssh_authorized_keys: ${jsonencode(var.ssh_keys)}
    packages:
      - qemu-guest-agent
    power_state:
      mode: reboot
    runcmd:
      - git clone --depth 1 --no-checkout --filter=tree:0 https://github.com/tjo-space/tjo-cloud-infrastructure.git /srv
      - cd /srv && git sparse-checkout set --no-cone /ingress.tjo.cloud && git checkout
      - /srv/ingress.tjo.cloud/install.sh
    EOF
    file_name = "${each.value.host}.ingress.tjo.cloud.userconfig.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "nodes" {
  for_each = local.nodes

  vm_id     = each.value.id
  name      = "${each.value.host}.${each.value.domain}"
  node_name = each.value.host

  description = <<EOT
An ingress.tjo.cloud instance for ${each.value.host}.

Repo: https://code.tjo.space/tjo-cloud/ingress
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

  initialization {
    interface         = "scsi0"
    datastore_id      = each.value.boot_storage
    user_data_file_id = proxmox_virtual_environment_file.userdata[each.key].id

    ip_config {
      ipv4 {
        address = each.value.ipv4_address
        gateway = each.value.ipv4_gateway
      }
      ipv6 {
        address = each.value.ipv6_address
        gateway = each.value.ipv6_gateway
      }
    }
  }
}
