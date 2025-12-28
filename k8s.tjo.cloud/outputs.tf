output "nodes" {
  value = [for key, value in module.cluster.nodes : value]
}

output "talos" {
  value = module.cluster.talos
}
