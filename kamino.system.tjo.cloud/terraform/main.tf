data "authentik_group" "monitoring_publisher" {
  name          = "cloud.tjo.monitor/publisher"
  include_users = false
}

resource "authentik_user" "service_account" {
  username = "kamino.system.tjo.cloud"
  name     = "kamino.system.tjo.cloud"

  type = "service_account"
  path = "system.tjo.cloud"

  groups = [
    data.authentik_group.monitoring_publisher.id,
  ]
}

resource "authentik_token" "service_account" {
  identifier   = "service-account-kamino-system-tjo-cloud"
  user         = authentik_user.service_account.id
  description  = "Service account for kamino.system.tjo.cloud node."
  expiring     = false
  intent       = "app_password"
  retrieve_key = true
}

resource "local_file" "ansible_secrets" {
  content = yamlencode({
    tjo_cloud = {
      credentials = {
        username = authentik_user.service_account.username
        password = authentik_token.service_account.key
      }
    }
  })
  filename = "${path.module}/../ansible/vars.terraform.secrets.yaml"
}
