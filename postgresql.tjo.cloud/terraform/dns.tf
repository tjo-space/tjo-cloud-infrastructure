resource "dnsimple_zone" "tjo_cloud" {
  name = "tjo.cloud"
}

resource "dnsimple_zone_record" "management" {
  zone_name = dnsimple_zone.tjo_cloud.name
  name      = "postgresql"
  value     = "any.ingress.tjo.cloud"
  type      = "ALIAS"
  ttl       = 300
}
