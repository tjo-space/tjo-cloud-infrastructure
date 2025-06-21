resource "zerotier_identity" "main" {
  for_each = local.nodes_with_name
}

resource "zerotier_member" "main" {
  for_each = local.nodes_with_name

  name                    = each.value.fqdn
  member_id               = zerotier_identity.main[each.key].id
  network_id              = "b6079f73c6379990"
}
