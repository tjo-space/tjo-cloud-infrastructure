data "dnsimple_zone" "tjo_cloud" {
  name = "tjo.cloud"
}

resource "dnsimple_zone_record" "management" {
  zone_name = dnsimple_zone.tjo_cloud.name
  name      = "postgresql"
  value     = "any.ingress.tjo.cloud"
  type      = "ALIAS"
  ttl       = 300
}

resource "dnsimple_zone_record" "nodes_a" {
  for_each = proxmox_virtual_environment_vm.nodes

  zone_name = dnsimple_zone.tjo_cloud.name
  name      = "any"
  value     = each.value.
  type      = "A"
  ttl       = 300
}
