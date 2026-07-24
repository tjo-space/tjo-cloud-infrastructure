locals {
  global = yamldecode(file("../../${path.module}/global.yaml"))

  nodes_with_name = {
    for k, v in var.nodes : k => merge(v, {
      name = k
      hash = sha1(k)
      fqdn = "${k}.network.cloud.internal"
    })
  }

  nodes_with_meta = {
    for k, v in local.nodes_with_name : k => merge(v, {
      meta = {
        cloud_region   = v.host
        cloud_provider = "proxmox"
        service_name   = "network.tjo.cloud"
        service_account = {
          username = authentik_user.service_account[k].username
          password = authentik_token.service_account[k].key
        }
        tailscale = {
          key = tailscale_tailnet_key.this.key
        }
      }
    })
  }

  nodes_deployed = {
    for k, v in local.nodes_with_meta : k => merge(v, {
      tailscale_ipv6 = try(module.proxmox_node[k].address.per_interface_ipv6["tailscale0"][0], "")
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
network.tjo.cloud node ${each.value.name}

Repo: https://code.tjo.space/tjo-cloud/infrastructuren/network.tjo.cloud
EOF
  host        = each.value.host

  cores  = each.value.cores
  memory = each.value.memory

  boot = {
    storage = each.value.boot_storage
    size    = each.value.boot_size
    image   = "debian_13_server_cloudimg_amd64.img"
  }

  network = {
    devices = [
      {
        bridge      = "vmbr0"
        mac_address = each.value.wan.mac_address != null ? each.value.wan.mac_address : "AA:BB:00:00:${format("%v:%v", substr(each.value.hash, 0, 2), substr(each.value.hash, 2, 2))}"
        ipv4        = { address = each.value.wan.ipv4.address, gateway = each.value.wan.ipv4.gateway }
        ipv6        = { address = each.value.wan.ipv6.address, gateway = each.value.wan.ipv6.gateway }
      },
      {
        bridge      = "vmbr3"
        mac_address = "AA:BB:00:22:${format("%v:%v", substr(each.value.hash, 0, 2), substr(each.value.hash, 2, 2))}"
      },
    ]
    dns = {
      servers = [
        "91.239.100.100", "2001:67c:28a4::", # anycast.uncensoreddns.org
        "89.233.43.71", "2a01:3a0:53:53::",  # unicast.uncensoreddns.org
      ]
    }
  }

  metadata = each.value.meta

  provision_sh = <<EOT
  mkdir -p --mode=0755 /usr/share/keyrings
  curl -fsSL https://pkgs.tailscale.com/stable/debian/trixie.noarmor.gpg > /usr/share/keyrings/tailscale-archive-keyring.gpg
  curl -fsSL https://pkgs.tailscale.com/stable/debian/trixie.tailscale-keyring.list > /etc/apt/sources.list.d/tailscale.list
  apt update && apt install -yyq tailscale
  tailscale up \
    --reset \
    --accept-dns=false \
    --ssh=true \
    --accept-routes=false \
    --advertise-tags="tag:network-tjo-cloud" \
    --hostname "${each.value.name}-network-cloud-internal" \
    --auth-key "${tailscale_tailnet_key.this.key}"
  EOT

  ssh_keys = local.global.tjo_cloud_admin_ssh_keys
  tags     = ["network.tjo.cloud", each.value.kind]
}

resource "local_file" "ansible_inventory" {
  content = yamlencode({
    router = {
      hosts = {
        for k, v in local.nodes_deployed : k => {
          ansible_host   = v.tailscale_ipv6
          ansible_port   = 2222
          ansible_user   = "bine"
          ansible_become = true
        } if v.kind == "router"
      }
    }
    gateway = {
      hosts = {
        for k, v in local.nodes_deployed : k => {
          ansible_host   = v.tailscale_ipv6
          ansible_port   = 2222
          ansible_user   = "bine"
          ansible_become = true
        } if v.kind == "gateway"
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
