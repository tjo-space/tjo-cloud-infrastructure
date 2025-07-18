output "nodes" {
  value = {
    for k, v in var.nodes :
    k => merge(v, {
      ipv4 = hcloud_server.main[k].ipv4_address
      ipv6 = hcloud_server.main[k].ipv6_address
    })
  }
}
