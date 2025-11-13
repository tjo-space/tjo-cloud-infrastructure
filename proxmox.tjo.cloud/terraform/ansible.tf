resource "local_file" "ansible_inventory" {
  content = yamlencode({
    all = {
      hosts = {
        for k, v in local.nodes : k => {
          ansible_host   = v.tailscale.ipv6
          ansible_port   = 22
          ansible_user   = "root"
          cloud_region   = v.cloud_region
          cloud_provider = v.cloud_provider
        }
      }
    }
  })
  filename = "${path.module}/../ansible/inventory.yaml"
}

resource "local_file" "ansible_secrets" {
  content = yamlencode({
    tailscale_auth_key = tailscale_tailnet_key.main.key
    prometheus_pve_exporter = {
      user        = proxmox_virtual_environment_user.prometheus-pve-exporter.user_id
      token_name  = trimprefix(proxmox_virtual_environment_user_token.prometheus-pve-exporter.id, "${proxmox_virtual_environment_user_token.prometheus-pve-exporter.user_id}!")
      token_value = trimprefix(proxmox_virtual_environment_user_token.prometheus-pve-exporter.value, "${proxmox_virtual_environment_user_token.prometheus-pve-exporter.id}=")
    }
    zerotier = {
      network = var.zerotier_network
      credentials = {
        for k, v in local.nodes : k => {
          public_key  = zerotier_identity.main[k].public_key
          private_key = zerotier_identity.main[k].private_key
        }
      }
    }
    tjo_cloud = {
      credentials = {
        for k, v in local.nodes : k => {
          username = authentik_user.service_account[k].username
          password = authentik_token.service_account[k].key
        }
      }
    }

  })
  filename = "${path.module}/../ansible/vars.terraform.secrets.yaml"
}

resource "local_file" "ansible_variables" {
  content = yamlencode({
    network = {
      nodes = {
        for k, node in local.nodes : k => {
          vmbr1 = node.vmbr1
        }
      }
    }
    ssh_keys = local.ssh_keys
  })
  filename = "${path.module}/../ansible/vars.terraform.yaml"
}
