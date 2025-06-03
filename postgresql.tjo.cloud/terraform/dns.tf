resource "dnsimple_zone" "tjo_cloud" {
  name = "tjo.cloud"
}

resource "dnsimple_zone_record" "management" {
  zone_name = dnsimple_zone.tjo_cloud.name
  name      = trimsuffix(var.domain, ".tjo.cloud")
  value     = "any.ingress.tjo.cloud"
  type      = "ALIAS"
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
