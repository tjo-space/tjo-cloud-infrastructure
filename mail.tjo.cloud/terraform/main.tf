locals {
  nodes_with_provider = merge({
    for k, v in var.nodes_hetzner_cloud : k => merge(v, {
      provider = "hetzner-cloud"
    })
  })

  nodes_with_name = {
    for k, v in local.nodes_with_provider : k => merge(v, {
      name = "${k}-${v.provider}"
      fqdn = "${k}-${v.provider}.${var.domain}"
    })
  }

  nodes_with_meta = {
    for k, v in local.nodes_with_name : k => merge(v, {
      meta = {
        cloud_provider = v.provider
        service_name   = var.domain
        service_account = {
          username = authentik_user.service_account[k].username
          password = authentik_token.service_account[k].key
        }
        zerotier = {
          public_key  = zerotier_identity.main[k].public_key
          private_key = zerotier_identity.main[k].private_key
        }
      }
    })
  }

  nodes_with_address = {
    for k, v in local.nodes_with_meta : k => merge(v, {
      ipv4 = v.provider == "hetzner-cloud" ? module.hetzner-cloud.nodes[k].ipv4 : ""
      ipv6 = v.provider == "hetzner-cloud" ? module.hetzner-cloud.nodes[k].ipv6 : ""
    })
  }
}

module "hetzner-cloud" {
  source = "../../shared/terraform/modules/hetzner-cloud"

  nodes = {
    for k, v in local.nodes_with_meta : k => v if v.provider == "hetzner-cloud"
  }
  ssh_keys = var.ssh_keys
  domain   = var.domain

  provision_sh = file("${path.module}/../provision.sh")
}
