resource "dnsimple_zone" "tjo_cloud" {
  name = "tjo.cloud"
}

resource "dnsimple_zone_record" "main" {
  zone_name = dnsimple_zone.tjo_cloud.name
  name      = trimsuffix(var.domain, ".tjo.cloud")
  value     = "any.mail.tjo.cloud"
  type      = "ALIAS"
  ttl       = 300
}

resource "dnsimple_zone_record" "any_a" {
  for_each = local.nodes_with_address

  zone_name = dnsimple_zone.tjo_cloud.name
  name      = "any.${trimsuffix(var.domain, ".tjo.cloud")}"
  value     = each.value.ipv4
  type      = "A"
  ttl       = 300
}

resource "dnsimple_zone_record" "any_aaaa" {
  for_each = local.nodes_with_address

  zone_name = dnsimple_zone.tjo_cloud.name
  name      = "any.${trimsuffix(var.domain, ".tjo.cloud")}"
  value     = each.value.ipv6
  type      = "AAAA"
  ttl       = 300
}

resource "dnsimple_zone_record" "nodes_a" {
  for_each = local.nodes_with_address

  zone_name = dnsimple_zone.tjo_cloud.name
  name      = "${each.value.name}.${trimsuffix(var.domain, ".tjo.cloud")}"
  value     = each.value.ipv4
  type      = "A"
  ttl       = 300
}
resource "dnsimple_zone_record" "nodes_aaaa" {
  for_each = local.nodes_with_address

  zone_name = dnsimple_zone.tjo_cloud.name
  name      = "${each.value.name}.${trimsuffix(var.domain, ".tjo.cloud")}"
  value     = each.value.ipv6
  type      = "AAAA"
  ttl       = 300
}

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
