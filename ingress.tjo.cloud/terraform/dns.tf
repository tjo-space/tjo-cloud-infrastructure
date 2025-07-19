resource "dnsimple_zone" "ingress_tjo_cloud" {
  name = "ingress.tjo.cloud"
}

moved {
  from = dnsimple_zone.all["ingress.tjo.cloud"]
  to   = dnsimple_zone.ingress_tjo_cloud
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
