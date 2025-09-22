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

  nodes_with_address = {
    for k, v in local.nodes_with_meta : k => merge(v, {
      ipv4 = v.provider == "hetzner-cloud" ? module.hetzner-cloud.nodes[k].ipv4 : module.proxmox.nodes[k].ipv4
      ipv6 = v.provider == "hetzner-cloud" ? module.hetzner-cloud.nodes[k].ipv6 : module.proxmox.nodes[k].ipv6
    })
  }
}

module "hetzner-cloud" {
  source = "../../shared/terraform/modules/hetzner-cloud"

  nodes = {
    for k, v in local.nodes_with_meta : k => v if v.provider == "hetzner-cloud"
  }
  ssh_keys = var.ssh_keys
  domain   = var.domain

  provision_sh = file("${path.module}/../provision.sh")
}

module "proxmox" {
  source = "../../shared/terraform/modules/proxmox"

  nodes = {
    for k, v in local.nodes_with_meta : k => merge(v, {
      tags = []
      disks = [{
        storage = v.garage_storage
        size    = v.garage_size
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
          cmd        = "mkfs -t %(filesystem)s -L %(label)s %(device)s"
        }]
        mounts = [["/dev/vdb1", "/srv/garage"]]
      }
    }) if v.provider == "proxmox"
  }
  ssh_keys = var.ssh_keys
  domain   = var.domain
  tags     = ["s3.tjo.cloud"]

  provision_sh = file("${path.module}/../provision.sh")
}
