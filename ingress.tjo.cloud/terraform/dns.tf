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