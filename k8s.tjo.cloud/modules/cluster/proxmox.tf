locals {
  nodes_with_names = {
    for k, v in var.nodes : k => merge(v, {
      id   = 6000 + index(keys(var.nodes), k)
      name = replace("${k}.${v.type}.${var.cluster.name}", ".", "-")
    })
  }
  hashes = {
    for k, v in local.nodes_with_names : k => sha1("${v.name}:${var.cluster.name}")
  }
  nodes = {
    for k, v in local.nodes_with_names : k => merge(v, {
      mac_address = "AA:BB:CC:DD:${format("%v:%v", substr(local.hashes[k], 0, 2), substr(local.hashes[k], 2, 2))}"
    })
  }


  first_controlplane_node = values({ for k, v in local.nodes_with_address : k => v if v.type == "controlplane" })[0]

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

resource "proxmox_virtual_environment_download_file" "talos" {
  content_type = "iso"
  datastore_id = var.proxmox.common_storage
  node_name    = values(var.nodes)[0].host
  file_name    = "talos-${var.talos.schematic_id}-${var.talos.version}-amd64.iso"
  url          = "https://factory.talos.dev/image/${var.talos.schematic_id}/${var.talos.version}/nocloud-amd64.iso"
}

resource "proxmox_virtual_environment_file" "metadata" {
  for_each = local.nodes

  node_name    = each.value.host
  content_type = "snippets"
  datastore_id = var.proxmox.common_storage

  source_raw {
    data      = <<-EOF
      hostname: ${each.value.name}
      id: ${each.value.id}
      providerID: proxmox://${var.proxmox.name}/${each.value.id}
      type: ${each.value.cores}VCPU-${floor(each.value.memory / 1024)}GB
      zone: ${each.value.host}
      region: ${var.proxmox.name}
    EOF
    file_name = "cluster-${var.cluster.name}-${each.value.name}.metadata.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "nodes" {
  for_each = local.nodes

  vm_id     = each.value.id
  name      = each.value.name
  node_name = each.value.host

  description = "Node ${each.value.name} for cluster ${var.cluster.name}."
  tags        = ["kubernetes.tjo.cloud", each.value.type]

  stop_on_destroy     = true
  timeout_start_vm    = 60
  timeout_stop_vm     = 60
  timeout_shutdown_vm = 60
  timeout_reboot      = 60
  timeout_create      = 120

  cpu {
    cores = each.value.cores
    type  = "host"
  }
  memory {
    dedicated = each.value.memory
  }

  operating_system {
    type = "l26"
  }

  agent {
    enabled = true
    timeout = "1m"
  }

  network_device {
    bridge      = "vmbr1"
    mac_address = each.value.mac_address
  }

  cdrom {
    enabled = true
    file_id = proxmox_virtual_environment_download_file.talos.id
  }

  scsi_hardware = "virtio-scsi-single"
  disk {
    file_format  = "raw"
    interface    = "virtio0"
    datastore_id = each.value.storage
    size         = each.value.boot_size
    backup       = true
    cache        = "none"
    iothread     = true
  }

  initialization {
    datastore_id      = each.value.storage
    meta_data_file_id = proxmox_virtual_environment_file.metadata[each.key].id
  }
}

resource "proxmox_virtual_environment_role" "csi" {
  role_id = "kubernetes-csi"

  privileges = [
    "VM.Audit",
    "VM.Config.Disk",
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
