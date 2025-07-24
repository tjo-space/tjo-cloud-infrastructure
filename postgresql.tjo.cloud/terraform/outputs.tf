output "nodes" {
  value = [
    for key, node in local.nodes_with_address : {
      name = node.name
      fqdn = node.fqdn
      ipv4 = node.ipv4
      ipv6 = node.ipv6
    }
  ]
}

output "users" {
  sensitive = true
  value = {
    for k, v in var.users : k => merge(v, {
      password = random_password.this[k].result
    })
  }
}

output "databases" {
  value = var.databases
}
