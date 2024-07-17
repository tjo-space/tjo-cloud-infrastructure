locals {
  nodes = { for k, v in var.nodes : k => merge(v, { name = replace("${k}.${v.type}.${var.cluster.domain}", ".", "-") }) }



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
      ipv4 = try(local.ipv4_addresses[k]["eth0"][0], null)
      ipv6 = try(local.ipv6_addresses[k]["eth0"][0], null)
    })
  }
}

resource "proxmox_virtual_environment_download_file" "talos" {
  content_type = "iso"
  datastore_id = var.proxmox.iso_storage_id
  node_name    = values(var.nodes)[0].host
  file_name    = "talos-${var.talos.version}-amd64.iso"
  url          = "https://factory.talos.dev/image/${var.talos.schematic_id}/${var.talos.version}/nocloud-amd64.iso"
}

resource "proxmox_virtual_environment_file" "controlplane" {
  for_each     = { for k, v in local.nodes_with_address : k => v if v.type == "controlplane" }
  node_name    = each.value.host
  content_type = "snippets"
  datastore_id = each.value.boot_pool

  source_raw {
    data      = <<-EOF
      hostname: ${each.value.name}
      instance-id: 1000
      instance-type: ${each.value.cpu}VCPU-${floor(each.value.memory / 1024)}GB
      provider-id: "proxmox://${var.proxmox.name}/1000"
      region: ${var.proxmox.name}
      zone: ${each.value.host}
    EOF
    file_name = "${each.value.name}.metadata.yaml"
  }
}

resource "macaddress" "private" {
  for_each = local.nodes
}
resource "macaddress" "public" {
  for_each = local.nodes
}

resource "proxmox_virtual_environment_vm" "nodes" {
  for_each = local.nodes

  name      = each.value.name
  node_name = each.value.host

  description = "Node ${each.value.name} for cluster ${var.cluster.name}."
  tags = concat(
    ["kubernetes", "terraform"],
    each.value.public ? ["public"] : ["private"],
    [each.value.type]
  )

  stop_on_destroy     = true
  timeout_stop_vm     = 60
  timeout_shutdown_vm = 60

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
    bridge      = each.value.public ? "vmpublic0" : "vmprivate0"
    mac_address = macaddress.private[each.key].address
  }

  disk {
    file_format  = "raw"
    interface    = "scsi0"
    datastore_id = each.value.boot_pool
    file_id      = proxmox_virtual_environment_download_file.talos.id
    backup       = false
  }

  disk {
    file_format  = "raw"
    interface    = "virtio0"
    datastore_id = each.value.boot_pool
    size         = each.value.boot_size
    backup       = true
  }

  initialization {
    meta_data_file_id = proxmox_virtual_environment_file.controlplane[each.key].id
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
}
resource "proxmox_virtual_environment_user_token" "csi" {
  comment    = "Managed by Terraform"
  token_name = "terraform"
  user_id    = proxmox_virtual_environment_user.csi.user_id
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
}
resource "proxmox_virtual_environment_user_token" "ccm" {
  comment    = "Managed by Terraform"
  token_name = "terraform"
  user_id    = proxmox_virtual_environment_user.ccm.user_id
}
