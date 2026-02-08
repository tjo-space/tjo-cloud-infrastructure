resource "technitium_record" "for_node" {
  for_each   = local.nodes_deployed
  zone       = "cloud.internal"
  domain     = "${each.value.name}.monitor.cloud.internal"
  ttl        = 60
  type       = "AAAA"
  ip_address = each.value.private_ipv6
}
resource "technitium_record" "all" {
  for_each = { for pair in setproduct(keys(local.nodes_deployed), [
    "",
    "prometheus.",
    "loki.",
    "grpc.otel.",
    "http.otel.",
  ]) : "${pair[0]}-${pair[1]}" => { node = pair[0], domain = pair[1] } }

  zone       = "cloud.internal"
  domain     = "${each.value.domain}monitor.cloud.internal"
  ttl        = 60
  type       = "AAAA"
  ip_address = local.nodes_deployed[each.value.node].private_ipv6
}
