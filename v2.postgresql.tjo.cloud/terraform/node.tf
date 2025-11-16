locals {
  nodes_with_name = {
    for k, v in var.nodes : k => merge(v, {
      name = k
      fqdn = "${k}.${var.domain}"
    })
  }

  nodes_with_meta = {
    for k, v in local.nodes_with_name : k => merge(v, {
      meta = {
        cloud_region   = v.host
        cloud_provider = "proxmox"
        service_name   = var.domain
        service_account = {
          username = authentik_user.service_account[k].username
          password = authentik_token.service_account[k].key
        }
      }
    })
  }

  nodes_deployed = {
    for k, v in local.nodes_with_meta : k => merge(v, {
      private_ipv4 = module.proxmox_node[k].address.ipv4
      private_ipv6 = module.proxmox_node[k].address.ipv6
    })
  }
}

module "proxmox_node" {
  source = "../../shared/terraform/modules/proxmox"

  for_each = {
    for k, v in local.nodes_with_meta : k => v
  }

  name        = each.value.name
  fqdn        = each.value.fqdn
  description = <<EOF
postgresql.tjo.cloud node ${each.value.name}

Repo: https://code.tjo.space/tjo-cloud/infrastructure/postgresql.tjo.cloud
EOF
  host        = each.value.host

  cores  = each.value.cores
  memory = each.value.memory

  boot = {
    storage = each.value.boot_storage
    size    = each.value.boot_size
    image   = "ubuntu_2404_server_cloudimg_amd64.img"
  }

  disks = [{
    storage = each.value.data_storage
    size    = each.value.data_size
  }]

  userdata = {
    disk_setup = { "/dev/vdb" = {
      table_type = "gpt"
      layout     = [100]
    } }
    fs_setup = [{
      label      = "data"
      filesystem = "xfs"
      device     = "/dev/vdb"
    }]
    mounts = [["/dev/vdb1", "/srv/data"]]
  }
  metadata = each.value.meta

  ssh_keys = local.global.tjo_cloud_admin_ssh_keys
  tags     = ["postgresql.tjo.cloud", each.value.kind]
}

resource "local_file" "ansible_inventory" {
  content = yamlencode({
    postgresql = {
      hosts = {
        for k, v in local.nodes_deployed : v.fqdn => {
          ansible_host   = v.private_ipv4
          ansible_port   = 2222
          ansible_user   = "bine"
          ansible_become = true
        } if v.kind == "postgresql"
      }
    }
    barman = {
      hosts = {
        for k, v in local.nodes_deployed : v.fqdn => {
          ansible_host   = v.private_ipv4
          ansible_port   = 2222
          ansible_user   = "bine"
          ansible_become = true
        } if v.kind == "barman"
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
  content = yamlencode({
    postgres_password = random_password.postgres.result
    barman_password   = random_password.barman.result
    desec_token       = var.desec_token
  })
  filename = "${path.module}/../ansible/vars.terraform.secrets.yaml"
}
