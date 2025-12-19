resource "desec_rrset" "any" {
  for_each = {
    A    = [for k, v in local.nodes_deployed : v.ipv4 if v.use == true]
    AAAA = [for k, v in local.nodes_deployed : v.ipv6 if v.use == true]
  }
  domain  = "tjo.cloud"
  subname = "any.ingress"
  type    = each.key
  records = each.value
  ttl     = 3600
}
resource "desec_rrset" "node_a" {
  for_each = local.nodes_deployed
  domain   = "tjo.cloud"
  subname  = trimsuffix(each.value.fqdn, ".tjo.cloud")
  type     = "A"
  records  = [each.value.ipv4]
  ttl      = 3600
}
resource "desec_rrset" "node_aaaa" {
  for_each = local.nodes_deployed
  domain   = "tjo.cloud"
  subname  = trimsuffix(each.value.fqdn, ".tjo.cloud")
  type     = "AAAA"
  records  = [each.value.ipv6]
  ttl      = 3600
}
