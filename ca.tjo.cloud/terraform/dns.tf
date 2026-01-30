resource "desec_rrset" "node" {
  for_each = local.nodes_deployed
  domain   = "tjo.cloud"
  subname  = trimsuffix(each.value.fqdn, ".tjo.cloud")
  type     = "AAAA"
  records  = [each.value.private_ipv6]
  ttl      = 3600
}
