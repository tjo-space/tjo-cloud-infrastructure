locals {
  domain = "network.tjo.cloud"

  nodes = {
    for k, v in var.nodes : k => merge(v, {
      hash = sha1(k)
    })
  }

  nodes_deployed = {
    for k, v in local.nodes : k => merge(v, {
      wan_ipv4       = module.proxmox_node[k].address.wan_ipv4
      wan_ipv6       = module.proxmox_node[k].address.wan_ipv6
      tailscale_ipv6 = module.proxmox_node[k].address.tailscale_ipv6
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

module "proxmox_node" {
  source = "${path.module}/node"

  for_each = local.nodes

  host = each.value.host
  name = "${each.key}.${local.domain}"
  tags = [each.value.role, local.domain]

  memory = each.value.memory
  cores  = each.value.cores

  wan = {
    bridge      = "vmbr0"
    mac_address = each.value.internet_mac_address != null ? each.value.internet_mac_address : "AA:BB:00:00:${format("%v:%v", substr(each.value.hash, 0, 2), substr(each.value.hash, 2, 2))}"
  }
  lan = {
    bridge      = "vmbr3"
    mac_address = "AA:BB:00:22:${format("%v:%v", substr(each.value.hash, 0, 2), substr(each.value.hash, 2, 2))}"
  }

  boot = {
    file_id = proxmox_virtual_environment_file.iso[each.value.host].id
    storage = each.value.boot_storage
  }
}

resource "local_file" "ansible_inventory" {
  content = yamlencode({
    router = {
      hosts = {
        for k, v in local.nodes_deployed : k => {
          ansible_host = v.tailscale_ipv6
          ansible_port = 22
          ansible_user = "root"
        } if v.role == "router"
      }
    }
    gateway = {
      hosts = {
        for k, v in local.nodes_deployed : k => {
          ansible_host = v.tailscale_ipv6
          ansible_port = 22
          ansible_user = "root"
        } if v.role == "gateway"
      }
    }
  })
  filename = "${path.module}/../ansible/inventory.yaml"
}

resource "local_file" "ansible_vars" {
  content  = yamlencode({})
  filename = "${path.module}/../ansible/vars.terraform.yaml"
}

resource "local_file" "ansible_secrets" {
  content  = yamlencode({})
  filename = "${path.module}/../ansible/vars.terraform.secrets.yaml"
}
