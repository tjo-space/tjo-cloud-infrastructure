resource "desec_rrset" "main" {
  for_each = {
    A    = [for k, v in local.nodes_with_address : v.ipv4]
    AAAA = [for k, v in local.nodes_with_address : v.ipv6]
  }
  domain  = "tjo.cloud"
  subname = "mail"
  type    = each.key
  records = each.value
  ttl     = 3600
}
resource "desec_rrset" "node_a" {
  for_each = local.nodes_with_address
  domain   = "tjo.cloud"
  subname  = "${each.value.name}.${trimsuffix(var.domain, ".tjo.cloud")}"
  type     = "A"
  records  = [each.value.ipv4]
  ttl      = 3600
}
resource "desec_rrset" "node_aaaa" {
  for_each = local.nodes_with_address
  domain   = "tjo.cloud"
  subname  = trimsuffix(each.value.fqdn, ".tjo.cloud")
  type     = "AAAA"
  records  = [each.value.ipv6]
  ttl      = 3600
}
