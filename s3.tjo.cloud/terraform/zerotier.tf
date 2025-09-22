resource "zerotier_identity" "main" {
  for_each = { for k, v in local.nodes_with_name : k => v if v.provider == "hetzner-cloud" }
}

resource "zerotier_member" "main" {
  for_each = { for k, v in local.nodes_with_name : k => v if v.provider == "hetzner-cloud" }

  name       = each.value.fqdn
  member_id  = zerotier_identity.main[each.key].id
  network_id = "b6079f73c6379990"
}
