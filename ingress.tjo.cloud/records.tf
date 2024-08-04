locals {
  listeners = [
    {
      domain    = "k8s.tjo.cloud"
      name      = "api"
      locations = ["SI", "DE"]
    },
    {
      domain    = "k8s.tjo.cloud"
      name      = "dashboard"
      locations = ["SI", "DE"]
    }
  ]
}

resource "digitalocean_record" "listeners" {
  for_each = merge(flatten([
    for listener in local.listeners :
    [
      for location in listener.locations : {
        for ip in local.locations[location] : "${ip} for ${listener.name}.${listener.domain} at ${location}" => {
          ip     = ip
          domain = listener.domain
          name   = listener.name
        }
      }
    ]
  ])...)

  domain = each.value.domain
  type   = strcontains(each.value.ip, ":") ? "AAAA" : "A"
  name   = each.value.name
  value  = each.value.ip
  ttl    = 60
}
