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

resource "desec_rrset" "cluster_a" {
  for_each = { for k, v in local.nodes_deployed : k => v if v.kind == "postgresql" && v.postgresql.role == "primary" }
  domain   = "tjo.cloud"
  subname  = "${each.value.postgresql.cluster_name}.${trimsuffix(var.domain, ".tjo.cloud")}"
  type     = "A"
  records  = [each.value.private_ipv4]
  ttl      = 3600
}

resource "desec_rrset" "cluster_aaaa" {
  for_each = { for k, v in local.nodes_deployed : k => v if v.kind == "postgresql" && v.postgresql.role == "primary" }
  domain   = "tjo.cloud"
  subname  = "${each.value.postgresql.cluster_name}.${trimsuffix(var.domain, ".tjo.cloud")}"
  type     = "AAAA"
  records  = [each.value.private_ipv6]
  ttl      = 3600
}
