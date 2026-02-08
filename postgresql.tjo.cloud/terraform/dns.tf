resource "technitium_record" "for_node" {
  for_each   = local.nodes_deployed
  zone       = "cloud.internal"
  domain     = "${each.value.name}.postgresql.cloud.internal"
  ttl        = 60
  type       = "AAAA"
  ip_address = each.value.private_ipv6
}
