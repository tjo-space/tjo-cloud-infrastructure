resource "random_password" "this" {
  for_each = var.users
  length   = 16
  special  = false
  lower    = true
  upper    = false
  numeric  = false
}

resource "postgresql_role" "this" {
  for_each = var.users
  provider = postgresql.for_node[each.value.node]

  name             = each.value.name
  password         = random_password.this[each.key].result
  connection_limit = each.value.connection_limit
  login            = true
}

resource "postgresql_database" "this" {
  for_each = var.databases
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
