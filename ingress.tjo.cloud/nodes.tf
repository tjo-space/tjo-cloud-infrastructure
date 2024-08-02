
locals {
  nodes = {
    hetzner = {
      ipv4 = "46.4.88.62"
      ipv6 = "2a01:4f8:202:2395::"
    }
    odroid = {
      ipv4 = "93.103.125.118"
      ipv6 = "2a01:261:455:6c00:21e:6ff:fe45:c34"
    }
  }
}

data "digitalocean_domain" "ingress" {
  name = "ingress.tjo.cloud"
}

resource "digitalocean_record" "nodes-a" {
  for_each = local.nodes

  domain = data.digitalocean_domain.ingress.id
  type   = "A"
  name   = each.key
  value  = each.value.ipv4
}

resource "digitalocean_record" "nodes-aaaa" {
  for_each = local.nodes

  domain = data.digitalocean_domain.ingress.id
  type   = "AAAA"
  name   = each.key
  value  = each.value.ipv6

  ttl = 60
}
