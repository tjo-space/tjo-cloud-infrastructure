locals {
  nodes_with_name = {
    for node in var.nodes : node => {
      name = node
      fqdn = "${node}.${var.domain}"
    }
  }

  nodes = {
    for k, v in local.nodes_with_name : k => merge(v, {
      meta = {
        service_name = var.domain
        service_account = {
          username = authentik_user.service_account[k].username
          password = authentik_token.service_account[k].key
        }
        zerotier = {
          public_key  = zerotier_identity.main[k].public_key
          private_key = zerotier_identity.main[k].private_key
        }
      }
    })
  }

  nodes_with_address = {
    for k, v in local.nodes :
    k => merge(v, {
      ipv4 = hcloud_server.main[k].ipv4_address
      ipv6 = hcloud_server.main[k].ipv6_address
    })
  }
}

resource "hcloud_ssh_key" "main" {
  for_each = var.ssh_keys

  name       = each.key
  public_key = each.value
}

resource "hcloud_server" "main" {
  for_each = local.nodes

  name = each.value.fqdn

  image       = "ubuntu-24.04"
  server_type = "cax11"
  datacenter  = "hel1-dc2"
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
  backups  = false
  ssh_keys = [for key, value in var.ssh_keys : hcloud_ssh_key.main[key].id]

  user_data = <<-EOF
    #cloud-config
    hostname: "${each.value.name}"
    fqdn: "${each.value.fqdn}"
    prefer_fqdn_over_hostname: true

    write_files:
    - path: /etc/tjo.cloud/meta.json
      encoding: base64
      content: ${base64encode(jsonencode(each.value.meta))}
    - path: /tmp/provision.sh
      encoding: base64
      content: ${base64encode(file("${path.module}/../provision.sh"))}

    power_state:
      mode: reboot

    runcmd:
      - "chmod +x /tmp/provision.sh"
      - "/tmp/provision.sh"
      - "rm /tmp/provision.sh"
    EOF
}

resource "hcloud_rdns" "ipv4" {
  for_each = local.nodes

  server_id  = hcloud_server.main[each.key].id
  ip_address = hcloud_server.main[each.key].ipv4_address
  dns_ptr    = each.value.fqdn
}

resource "hcloud_rdns" "ipv6" {
  for_each = local.nodes

  server_id  = hcloud_server.main[each.key].id
  ip_address = hcloud_server.main[each.key].ipv6_address
  dns_ptr    = each.value.fqdn
}
