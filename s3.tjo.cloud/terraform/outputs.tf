output "nodes" {
  value = [
    for key, node in local.nodes_with_address : {
      name     = node.name
      fqdn     = node.fqdn
      ipv4     = node.ipv4
      ipv6     = node.ipv6
      provider = node.provider
    }
  ]
}
