resource "desec_rrset" "api" {
  for_each = {
    A    = [for k, v in local.nodes_deployed : v.public_ipv4 if v.garage_kind == "gateway"]
    AAAA = [for k, v in local.nodes_deployed : v.public_ipv6 if v.garage_kind == "gateway"]
  }
  domain  = "tjo.cloud"
  subname = "api.s3"
  type    = each.key
  records = each.value
  ttl     = 3600
}
resource "desec_rrset" "api_https" {
  domain  = "tjo.cloud"
  subname = "api.s3"
  type    = "HTTPS"
  records = ["1 . alpn=h2"]
  ttl     = 3600
}

resource "desec_rrset" "admin" {
  for_each = {
    A    = [for k, v in local.nodes_deployed : v.public_ipv4 if v.garage_kind == "gateway"]
    AAAA = [for k, v in local.nodes_deployed : v.public_ipv6 if v.garage_kind == "gateway"]
  }
  domain  = "tjo.cloud"
  subname = "admin.s3"
  type    = each.key
  records = each.value
  ttl     = 3600
}
resource "desec_rrset" "admin_https" {
  domain  = "tjo.cloud"
  subname = "admin.s3"
  type    = "HTTPS"
  records = ["1 . alpn=h2"]
  ttl     = 3600
}

resource "desec_rrset" "web" {
  for_each = {
    A    = [for k, v in local.nodes_deployed : v.public_ipv4 if v.garage_kind == "gateway"]
    AAAA = [for k, v in local.nodes_deployed : v.public_ipv6 if v.garage_kind == "gateway"]
  }
  domain  = "tjo.cloud"
  subname = "*.web.s3"
  type    = each.key
  records = each.value
  ttl     = 3600
}
resource "desec_rrset" "web_https" {
  domain  = "tjo.cloud"
  subname = "*.web.s3"
  type    = "HTTPS"
  records = ["1 . alpn=h2"]
  ttl     = 3600
}

resource "desec_rrset" "node_aaaa" {
  for_each = local.nodes_deployed
  domain   = "tjo.cloud"
  subname  = trimsuffix(each.value.fqdn, ".tjo.cloud")
  type     = "AAAA"
  records  = [each.value.private_ipv6]
  ttl      = 3600
}
resource "technitium_record" "any" {
  for_each   = local.nodes_deployed
  zone       = "cloud.internal"
  domain     = "any.s3.cloud.internal"
  ttl        = 60
  type       = "AAAA"
  ip_address = each.value.private_ipv6
}
resource "technitium_record" "for_node" {
  for_each   = local.nodes_deployed
  zone       = "cloud.internal"
  domain     = "${each.value.name}.s3.cloud.internal"
  ttl        = 60
  type       = "AAAA"
  ip_address = each.value.private_ipv6
}
