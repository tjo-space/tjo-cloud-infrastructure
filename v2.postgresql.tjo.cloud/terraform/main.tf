locals {
  users = { for user in var.users : "${user.name}@${user.node}" => user }

  databases = {
    for database in flatten([
      for user in local.users : [
        for database in user.databases : merge(database, { owner : user.name, node : user.node })
      ]
    ]) : "${database.name}@${database.node}" => database
  }

  clusters = [for cluster in toset([for k, v in var.nodes : v.postgresql.cluster_name if v.kind == "postgresql"]) : {
    name = cluster
    fqdn = "${cluster}.${var.domain}"
  }]

  global = yamldecode(file("../../${path.module}/global.yaml"))
}

resource "random_password" "postgres" {
  length  = 16
  special = false
}

resource "random_password" "barman" {
  length  = 16
  special = false
}

moved {
  from = random_password.this
  to   = random_password.user
}

resource "random_password" "user" {
  for_each = local.users
  length   = 22
  special  = false
  lower    = true
  upper    = false
  numeric  = false
}

resource "postgresql_role" "this" {
  for_each = local.users
  provider = postgresql.for_node[each.value.node]

  name             = each.value.name
  password         = random_password.user[each.key].result
  connection_limit = each.value.connection_limit
  login            = true
}

resource "postgresql_database" "this" {
  for_each = local.databases
  provider = postgresql.for_node[each.value.node]

  depends_on = [postgresql_role.this]

  name                   = each.value.name
  owner                  = each.value.owner
  template               = "template0"
  encoding               = each.value.encoding
  lc_collate             = each.value.lc_collate
  lc_ctype               = each.value.lc_ctype
  connection_limit       = each.value.connection_limit
  allow_connections      = true
  alter_object_ownership = true
}
