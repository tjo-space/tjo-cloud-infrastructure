
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
