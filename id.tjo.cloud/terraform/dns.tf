resource "technitium_record" "for_node" {
  for_each   = local.nodes_deployed
  zone       = "cloud.internal"
  domain     = "${each.value.name}.id.cloud.internal"
  ttl        = 60
  type       = "AAAA"
  ip_address = each.value.private_ipv6
}
resource "technitium_record" "all_cloud" {
  for_each   = local.nodes_deployed
  zone       = "cloud.internal"
  domain     = "id.cloud.internal"
  ttl        = 60
  type       = "AAAA"
  ip_address = each.value.private_ipv6
}
