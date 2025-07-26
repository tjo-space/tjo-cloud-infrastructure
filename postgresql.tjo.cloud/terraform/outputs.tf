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
    for k, user in local.users : k => merge(user, {
      password = random_password.this[k].result
    })
  }
}

output "databases" {
  value = local.databases
}
