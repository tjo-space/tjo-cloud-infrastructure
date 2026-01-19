locals {
  nodes_with_names = {
    for k, v in var.nodes : k => merge(v, {
      name = replace("${k}.${var.cluster.name}", ".", "-")
    })
  }
  hashes = {
    for k, v in local.nodes_with_names : k => sha1(v.name)
  }
  nodes = {
    for k, v in local.nodes_with_names : k => merge(v, {
      mac_address = "AA:BB:CC:DD:${format("%v:%v", substr(local.hashes[k], 0, 2), substr(local.hashes[k], 2, 2))}"
    })
  }

  bootstrap_node = try(values({ for k, v in local.nodes_with_address : k => v if v.bootstrap })[0], null)

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
      ipv6 = try([
        for ipv6 in try(local.ipv6_addresses[k]["ens18"], try(local.ipv6_addresses[k]["eth0"], [])) : ipv6 if startswith(ipv6, "fd74:6a6f:")
      ][0], "")
    })
  }
}

resource "proxmox_virtual_environment_download_file" "talos" {
  for_each = toset([for node in local.nodes : node.host])

  content_type = "iso"
  datastore_id = "local"
  node_name    = each.key
  file_name    = "${var.cluster.name}-talos-${talos_image_factory_schematic.this.id}-${var.talos.version}-amd64.iso"
  url          = "https://factory.talos.dev/image/${talos_image_factory_schematic.this.id}/${var.talos.version}/nocloud-amd64.iso"
}

resource "proxmox_virtual_environment_file" "metadata" {
  for_each = local.nodes

  node_name    = each.value.host
  content_type = "snippets"
  datastore_id = "local"

  source_raw {
    data      = <<-EOF
      hostname: ${each.value.name}
      instance-id: ${each.value.id}
      instance-type: ${each.value.cores}VCPU-${floor(each.value.memory / 1024)}GB
      provider-id: proxmox://${var.proxmox.name}/${each.value.id}
      region: ${var.proxmox.name}
      zone: ${each.value.host}
    EOF
    file_name = "${each.value.name}.metadata.yaml"
  }

  timeout_upload = 30
}

resource "proxmox_virtual_environment_vm" "nodes" {
  for_each = local.nodes

  vm_id     = each.value.id
  name      = each.value.name
  node_name = each.value.host

  description = "Node ${each.value.name} for cluster ${var.cluster.name}."
  tags        = ["k8s.tjo.cloud", each.value.type]

  stop_on_destroy     = true
  timeout_start_vm    = 60
  timeout_stop_vm     = 60
  timeout_shutdown_vm = 60
  timeout_reboot      = 60
  timeout_create      = 120

  boot_order = ["virtio0", "ide3"]

  cpu {
    cores = each.value.cores
    type  = "host"
  }
  memory {
    dedicated = each.value.memory
  }

  machine = "q35"
  bios    = "ovmf"
  efi_disk {
    datastore_id = each.value.storage
  }

  operating_system {
    type = "l26"
  }

  agent {
    enabled = true
    timeout = "5m"
  }

  network_device {
    bridge      = "vmbr1"
    mac_address = each.value.mac_address
  }

  cdrom {
    file_id = proxmox_virtual_environment_download_file.talos[each.value.host].id
  }

  scsi_hardware = "virtio-scsi-single"
  disk {
    file_format  = "raw"
    interface    = "virtio0"
    datastore_id = each.value.storage
    size         = each.value.boot_size
    backup       = true
    cache        = "none"
    discard      = "on"
    iothread     = true
  }

  initialization {
    interface         = "scsi0"
    datastore_id      = each.value.storage
    meta_data_file_id = proxmox_virtual_environment_file.metadata[each.key].id
  }

  lifecycle {
    // We preform upgrades via talosctl
    ignore_changes = [cdrom, boot_order, initialization[0].meta_data_file_id]
  }
}

resource "proxmox_virtual_environment_role" "csi" {
  role_id = "kubernetes-csi"

  privileges = [
    "Sys.Audit",
    "VM.Audit",
    "VM.Allocate",
    "VM.Clone",
    "VM.Config.Disk",
    "VM.Config.CPU",
    "VM.Config.Disk",
    "VM.Config.HWType",
    "VM.Config.Memory",
    "VM.Config.Options",
    "VM.Migrate",
    "VM.PowerMgmt",
    "Datastore.Allocate",
    "Datastore.AllocateSpace",
    "Datastore.Audit",
  ]
}
resource "proxmox_virtual_environment_user" "csi" {
  comment = "Managed by Terraform"
  user_id = "kubernetes-csi@pve"
  enabled = true
  acl {
    path      = "/"
    propagate = true
    role_id   = proxmox_virtual_environment_role.csi.role_id
  }
}
resource "proxmox_virtual_environment_user_token" "csi" {
  comment    = "Managed by Terraform"
  token_name = "terraform"
  user_id    = proxmox_virtual_environment_user.csi.user_id
}
resource "proxmox_virtual_environment_acl" "csi" {
  token_id = proxmox_virtual_environment_user_token.csi.id
  role_id  = proxmox_virtual_environment_role.csi.role_id

  path      = "/"
  propagate = true
}

resource "proxmox_virtual_environment_role" "ccm" {
  role_id = "kubernetes-ccm"

  privileges = [
    "VM.Audit",
  ]
}
resource "proxmox_virtual_environment_user" "ccm" {
  comment = "Managed by Terraform"
  user_id = "kubernetes-ccm@pve"
  enabled = true
  acl {
    path      = "/"
    propagate = true
    role_id   = proxmox_virtual_environment_role.ccm.role_id
  }
}
resource "proxmox_virtual_environment_user_token" "ccm" {
  comment    = "Managed by Terraform"
  token_name = "terraform"
  user_id    = proxmox_virtual_environment_user.ccm.user_id
}
resource "proxmox_virtual_environment_acl" "ccm" {
  token_id = proxmox_virtual_environment_user_token.ccm.id
  role_id  = proxmox_virtual_environment_role.ccm.role_id

  path      = "/"
  propagate = true
}
