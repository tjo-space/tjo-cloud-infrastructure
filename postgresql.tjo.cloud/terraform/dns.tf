resource "desec_rrset" "admin" {
  domain  = "tjo.cloud"
  subname = trimsuffix(var.domain, ".tjo.cloud")
  type    = "CNAME"
  records = ["any.ingress.tjo.cloud."]
  ttl     = 3600
}

resource "desec_rrset" "node_a" {
  for_each = local.nodes_deployed
  domain   = "tjo.cloud"
  subname  = "${each.value.name}.${trimsuffix(var.domain, ".tjo.cloud")}"
  type     = "A"
  records  = [each.value.private_ipv4]
  ttl      = 3600
}
resource "desec_rrset" "node_aaaa" {
  for_each = local.nodes_deployed
  domain   = "tjo.cloud"
  subname  = "${each.value.name}.${trimsuffix(var.domain, ".tjo.cloud")}"
  type     = "AAAA"
  records  = [each.value.private_ipv6]
  ttl      = 3600
}
resource "technitium_record" "for_node" {
  for_each   = local.nodes_deployed
  zone       = "cloud.internal"
  domain     = "${each.value.name}.postgresql.cloud.internal"
  ttl        = 60
  type       = "AAAA"
  ip_address = each.value.private_ipv6
}
