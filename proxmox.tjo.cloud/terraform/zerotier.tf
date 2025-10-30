
resource "zerotier_identity" "main" {
  for_each = local.nodes
}

resource "zerotier_member" "main" {
  for_each = local.nodes

  name                    = each.value.fqdn
  member_id               = zerotier_identity.main[each.key].id
  network_id              = var.zerotier_network
  allow_ethernet_bridging = true
  no_auto_assign_ips      = true
}

resource "local_file" "ansible_zerotier_variables" {
  content = yamlencode({
    zerotier = {
      network = var.zerotier_network
      credentials = {
        for k, v in local.nodes : k => {
          public_key  = zerotier_identity.main[k].public_key
          private_key = zerotier_identity.main[k].private_key
        }
      }
    }
  })
  filename = "${path.module}/../ansible/vars.zerotier.secrets.yaml"
}
