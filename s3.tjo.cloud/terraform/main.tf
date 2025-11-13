locals {
  nodes_with_provider = merge(
    {
      for k, v in var.nodes_hetzner_cloud : k => merge(v, {
        provider = "hetzner-cloud"
      })
    },
    {
      for k, v in var.nodes_proxmox : k => merge(v, {
        provider = "proxmox"
      })
    }
  )

  nodes_with_name = {
    for k, v in local.nodes_with_provider : k => merge(v, {
      name = "${k}-${v.provider}"
      fqdn = "${k}-${v.provider}.${var.domain}"
    })
  }

  nodes_with_meta = {
    for k, v in local.nodes_with_name : k => merge(v, {
      meta = {
        garage = {
          kind = v.garage_kind
          zone = v.garage_zone
          size = "${lookup(v, "garage_size", 0)}G"
        }
        cloud_provider = v.provider
        service_name   = var.domain
        service_account = {
          username = authentik_user.service_account[k].username
          password = authentik_token.service_account[k].key
        }
        zerotier = v.provider == "proxmox" ? { public_key = "", private_key = "" } : {
          public_key  = zerotier_identity.main[k].public_key
          private_key = zerotier_identity.main[k].private_key
        }
      }
    })
  }

  nodes_deployed = {
    for k, v in local.nodes_with_meta : k => merge(v, {
      private_ipv4 = v.provider == "hetzner-cloud" ? v.private_ipv4 : module.proxmox_node[k].address.ipv4
      private_ipv6 = v.provider == "hetzner-cloud" ? v.private_ipv6 : module.proxmox_node[k].address.ipv6

      public_ipv4 = v.provider == "hetzner-cloud" ? module.hetzner-cloud[k].address.ipv4 : ""
      public_ipv6 = v.provider == "hetzner-cloud" ? module.hetzner-cloud[k].address.ipv6 : ""
    })
  }

  ssh_keys = yamldecode(file("../../${path.module}/global.yaml")).ssh_keys
}

module "hetzner-cloud" {
  source = "../../shared/terraform/modules/hetzner-cloud"

  for_each = {
    for k, v in local.nodes_with_meta : k => v if v.provider == "hetzner-cloud"
  }

  name       = each.value.name
  fqdn       = each.value.fqdn
  datacenter = each.value.datacenter
  metadata   = each.value.meta

  ssh_keys = local.ssh_keys
  domain   = var.domain
}

module "proxmox_node" {
  source = "../../shared/terraform/modules/proxmox"

  for_each = {
    for k, v in local.nodes_with_meta : k => v if v.provider == "proxmox"
  }

  name        = each.value.name
  fqdn        = each.value.fqdn
  description = "s3.tjo.cloud node ${each.value.name}"
  host        = each.value.host

  cores  = each.value.cores
  memory = each.value.memory

  boot = {
    storage = each.value.boot_storage
    size    = each.value.boot_size
    image   = "ubuntu_2404_server_cloudimg_amd64.img"
  }

  disks = [{
    storage = each.value.garage_storage
    size    = each.value.garage_size
  }]

  userdata = {
    disk_setup = { "/dev/vdb" = {
      table_type = "gpt"
      layout     = [100]
    } }
    fs_setup = [{
      label      = "garage"
      filesystem = "xfs"
      device     = "/dev/vdb"
    }]
    mounts = [["/dev/vdb1", "/srv/garage"]]
  }
  metadata = each.value.meta

  ssh_keys = local.ssh_keys
  tags     = ["s3.tjo.cloud"]
}

resource "local_file" "ansible_inventory" {
  content = yamlencode({
    all = {
      hosts = {
        for k, v in local.nodes_deployed : v.fqdn => {
          ansible_host   = v.private_ipv4 != "" ? v.private_ipv4 : v.public_ipv4
          ansible_port   = 2222
          ansible_user   = "bine"
          ansible_become = true
          garage_size    = v.meta.garage.size
          garage_kind    = v.meta.garage.kind
          garage_zone    = v.meta.garage.zone
          provider       = v.provider
        }
      }
    }
  })
  filename = "${path.module}/../ansible/inventory.yaml"
}

resource "local_file" "ansible_vars" {
  content = yamlencode({
    ssh_keys = local.ssh_keys
  })
  filename = "${path.module}/../ansible/vars.terraform.yaml"
}
