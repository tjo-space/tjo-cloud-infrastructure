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

# TODO: For each node or some VIP + BGP thing?
resource "dnsimple_zone_record" "nodes" {
  zone_name = dnsimple_zone.tjo_cloud.name
  name      = "postgresql"
  value     = "any.ingress.tjo.cloud"
  type      = "ALIAS"
  ttl       = 300
}
