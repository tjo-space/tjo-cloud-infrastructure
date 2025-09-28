resource "desec_rrset" "api" {
  for_each = {
    A    = [for k, v in local.nodes_with_address : v.ipv4 if v.garage_kind == "gateway"]
    AAAA = [for k, v in local.nodes_with_address : v.ipv6 if v.garage_kind == "gateway"]
  }
  domain  = "tjo.cloud"
  subname = "api.s3"
  type    = each.key
  records = each.value
  ttl     = 3600
}
resource "desec_rrset" "admin" {
  for_each = {
    A    = [for k, v in local.nodes_with_address : v.ipv4 if v.garage_kind == "gateway"]
    AAAA = [for k, v in local.nodes_with_address : v.ipv6 if v.garage_kind == "gateway"]
  }
  domain  = "tjo.cloud"
  subname = "admin.s3"
  type    = each.key
  records = each.value
  ttl     = 3600
}
resource "desec_rrset" "web" {
  for_each = {
    A    = [for k, v in local.nodes_with_address : v.ipv4 if v.garage_kind == "gateway"]
    AAAA = [for k, v in local.nodes_with_address : v.ipv6 if v.garage_kind == "gateway"]
  }
  domain  = "tjo.cloud"
  subname = "web.s3.tjo.cloud"
  type    = each.key
  records = each.value
  ttl     = 3600
}
resource "desec_rrset" "anyweb" {
  for_each = {
    A    = [for k, v in local.nodes_with_address : v.ipv4 if v.garage_kind == "gateway"]
    AAAA = [for k, v in local.nodes_with_address : v.ipv6 if v.garage_kind == "gateway"]
  }
  domain  = "tjo.cloud"
  subname = "*.web.s3.tjo.cloud"
  type    = each.key
  records = each.value
  ttl     = 3600
}

resource "desec_rrset" "any" {
  for_each = {
    A    = [for k, v in local.nodes_with_address : v.ipv4 if v.garage_kind != "gateway"]
    AAAA = [for k, v in local.nodes_with_address : v.ipv6 if v.garage_kind != "gateway"]
  }
  domain  = "tjo.cloud"
  subname = "any.s3"
  type    = each.key
  records = each.value
  ttl     = 3600
}
resource "desec_rrset" "node_a" {
  for_each = { for k, v in local.nodes_with_address : k => v }
  domain   = "tjo.cloud"
  subname  = trimsuffix(each.value.fqdn, ".tjo.cloud")
  type     = "A"
  records  = [each.value.ipv4]
  ttl      = 3600
}
resource "desec_rrset" "node_aaaa" {
  for_each = { for k, v in local.nodes_with_address : k => v }
  domain   = "tjo.cloud"
  subname  = trimsuffix(each.value.fqdn, ".tjo.cloud")
  type     = "AAAA"
  records  = [each.value.ipv6]
  ttl      = 3600
}
