output "nodes" {
  value = [
    for key, node in local.nodes : replace(node.fqdn, ".", "-")
  ]
}
