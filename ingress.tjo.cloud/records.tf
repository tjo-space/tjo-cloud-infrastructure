locals {
  listeners = [
    {
      domain = "k8s.tjo.cloud"
      name   = "api"
      nodes  = ["hetzner", "odroid"]
    }
  ]
}

resource "digitalocean_record" "listeners" {
  for_each = merge([
    for listener in local.listeners : merge(
      {
        for node in listener.nodes : "ipv4 ${listener.name}.${listener.domain} at ${node}" => {
          ip     = local.nodes[node].ipv4
          domain = listener.domain
          name   = listener.name
          type   = "A"
        }
      },
      {
        for node in listener.nodes : "ipv6 ${listener.name}.${listener.domain} at ${node}" => {
          ip     = local.nodes[node].ipv6
          domain = listener.domain
          name   = listener.name
          type   = "AAAA"
        }
      }
    )
  ]...)

  domain = each.value.domain
  type   = each.value.type
  name   = each.value.name
  value  = each.value.ip

  ttl = 60
}
