output "nodes" {
  value = [
    for key, node in local.nodes_deployed : {
      name = node.name
      fqdn = node.fqdn
      ipv4 = node.private_ipv4
      ipv6 = node.private_ipv6
    }
  ]
}

output "users" {
  sensitive = true
  value = {
    for k, user in local.users : k => merge(user, {
      password = random_password.user[k].result
    })
  }
}

output "databases" {
  value = local.databases
}
