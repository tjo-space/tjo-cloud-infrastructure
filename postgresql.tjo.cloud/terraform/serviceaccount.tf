data "authentik_group" "monitoring_publisher" {
  name          = "monitor.tjo.cloud publisher"
  include_users = false
}

resource "authentik_user" "service_account" {
  for_each = var.nodes

  username = "${each.value.host}.${local.domain}"
  name     = "${each.value.host}.${local.domain}"

  type = "service_account"
  path = "postgresql.tjo.cloud"

  groups = [
    data.authentik_group.monitoring_publisher.id,
  ]
}

resource "authentik_token" "service_account" {
  for_each = var.nodes

  identifier   = replace("service-account-${each.value.host}-${local.domain}", ".", "-")
  user         = authentik_user.service_account[each.key].id
  description  = "Service account for ${each.value.host}.${local.domain} node."
  expiring     = false
  intent       = "app_password"
  retrieve_key = true
}
