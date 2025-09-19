resource "dnsimple_zone" "ingress_tjo_cloud" {
  name = "ingress.tjo.cloud"
}

resource "desec_rrset" "any" {
  for_each = {
    A    = [for k, v in local.nodes_with_address : v.ipv4]
    AAAA = [for k, v in local.nodes_with_address : v.ipv6]
  }
  domain  = "tjo.cloud"
  subname = "any.ingress"
  type    = each.key
  records = each.value
  ttl     = 3600
}
resource "desec_rrset" "node_a" {
  for_each = local.nodes_with_address
  domain   = "tjo.cloud"
  subname  = trimsuffix(each.value.fqdn, ".tjo.cloud")
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

resource "dnsimple_zone_record" "any_a" {
  for_each = local.nodes_with_address

  zone_name = dnsimple_zone.ingress_tjo_cloud.name
  name      = "any"
  value     = each.value.ipv4
  type      = "A"
  ttl       = 300
}
resource "dnsimple_zone_record" "any_aaaa" {
  for_each = local.nodes_with_address

  zone_name = dnsimple_zone.ingress_tjo_cloud.name
  name      = "any"
  value     = each.value.ipv6
  type      = "AAAA"
  ttl       = 300
}
resource "dnsimple_zone_record" "nodes_a" {
  for_each = local.nodes_with_address

  zone_name = dnsimple_zone.ingress_tjo_cloud.name
  name      = trimsuffix(each.value.fqdn, ".ingress.tjo.cloud")
  value     = each.value.ipv4
  type      = "A"
  ttl       = 300
}
resource "dnsimple_zone_record" "nodes_aaaa" {
  for_each = local.nodes_with_address

  zone_name = dnsimple_zone.ingress_tjo_cloud.name
  name      = trimsuffix(each.value.fqdn, ".ingress.tjo.cloud")
  value     = each.value.ipv6
  type      = "AAAA"
  ttl       = 300
}

resource "dnsimple_zone" "all" {
  for_each = var.zones
  name     = each.key
}
locals {
  records_with_zones = { for key, value in var.records : key => merge(
    value,
    { zone = one([for zone in var.zones : zone if endswith(key, zone)]) }
  ) }
}
resource "dnsimple_zone_record" "all" {
  for_each = local.records_with_zones

  zone_name = dnsimple_zone.all[each.value.zone].name
  name      = trimsuffix(each.key, ".${each.value.zone}")
  value     = each.value.to
  type      = each.value.type
  ttl       = each.value.ttl
}
