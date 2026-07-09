output "nodes" {
  value = [
    for key, node in local.nodes_deployed : {
      name = node.name
      fqdn = node.fqdn
      ipv4 = node.ipv4
      ipv6 = node.ipv6
    }
  ]
}
