
locals {
  locations = {
    DE = ["46.4.88.62", "2a01:4f8:202:2395::"]
    SI = ["93.103.125.118", "2a01:261:455:6c00:21e:6ff:fe45:c34"]
  }
}

data "digitalocean_domain" "ingress" {
  name = "ingress.tjo.cloud"
}

resource "digitalocean_record" "locations" {
  for_each = merge([
    for location, ips in local.locations : {
      for ip in ips : "${location} at ${ip}" => {
        location = location,
        ip       = ip,
      }
    }
  ]...)

  domain = data.digitalocean_domain.ingress.id
  type   = strcontains(each.value.ip, ":") ? "AAAA" : "A"
  name   = lower(each.value.location)
  value  = each.value.ip
  ttl    = 60
}
