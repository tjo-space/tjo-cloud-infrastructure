data "authentik_group" "monitoring_publisher" {
  name          = "cloud.tjo.monitor/publisher"
  include_users = false
}

resource "authentik_user" "service_account" {
  for_each = local.nodes_with_name

  username = each.value.fqdn
  name     = each.value.fqdn

  type = "service_account"
  path = var.domain

  groups = [
    data.authentik_group.monitoring_publisher.id,
  ]
}

data "authentik_flow" "ldap-authentication-flow" {
  slug = "ldap-authentication-flow"
}

data "authentik_flow" "default-invalidation-flow" {
  slug = "default-invalidation-flow"
}

resource "authentik_provider_ldap" "mail" {
  name        = "mail.tjo.cloud"
  base_dn     = "dc=mail,dc=tjo,dc=cloud"
  bind_flow   = data.authentik_flow.ldap-authentication-flow.id
  unbind_flow = data.authentik_flow.default-invalidation-flow.id
  bind_mode   = "direct"
  search_mode = "direct"
}

resource "authentik_outpost" "mail" {
  name = "mail.tjo.cloud"
  type = "ldap"
  protocol_providers = [
    authentik_provider_ldap.mail.id
  ]
}

resource "authentik_application" "mail" {
  name              = "mail.tjo.cloud"
  slug              = "mailtjocloud"
  protocol_provider = authentik_provider_ldap.mail.id
}

resource "authentik_rbac_permission_user" "ldap" {
  for_each = local.nodes_with_name

  user       = authentik_user.service_account[each.key].id
  model      = "authentik_providers_ldap.ldapprovider"
  permission = "search_full_directory"
  object_id  = authentik_provider_ldap.mail.id
}

resource "authentik_token" "service_account" {
  for_each = local.nodes_with_name

  identifier   = replace("service-account-${each.value.fqdn}", ".", "-")
  user         = authentik_user.service_account[each.key].id
  description  = "Service account for ${each.value.fqdn} node."
  expiring     = false
  intent       = "app_password"
  retrieve_key = true
}
