data "authentik_group" "monitoring_publisher" {
  name          = "monitor.tjo.cloud publisher"
  include_users = false
}

resource "authentik_user" "service_account" {
  for_each = local.nodes

  username = each.value.fqdn
  name     = each.value.fqdn

  type = "service_account"
  path = var.domain

  groups = [
    data.authentik_group.monitoring_publisher.id,
  ]
}

resource "authentik_token" "service_account" {
  for_each = local.nodes

  identifier   = replace("service-account-${each.value.fqdn}", ".", "-")
  user         = authentik_user.service_account[each.key].id
  description  = "Service account for ${each.value.fqdn} node."
  expiring     = false
  intent       = "app_password"
  retrieve_key = true
}

resource "local_file" "ansible_tjo_cloud_variables" {
  content = yamlencode({
    tjo_cloud = {
      credentials = {
        for k, v in local.nodes : k => {
          username = authentik_user.service_account[k].username
          password = authentik_token.service_account[k].key
        }
      }
    }
  })
  filename = "${path.module}/../ansible/vars.tjo_cloud.secrets.yaml"
}
