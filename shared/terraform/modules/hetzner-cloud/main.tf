resource "hcloud_ssh_key" "main" {
  for_each = var.ssh_keys

  name       = each.key
  public_key = each.value
}

resource "hcloud_server" "main" {
  for_each = var.nodes

  name = each.value.fqdn

  image       = each.value.image
  server_type = each.value.server_type
  datacenter  = each.value.datacenter
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
  backups  = false
  ssh_keys = [for key, value in var.ssh_keys : hcloud_ssh_key.main[key].id]

  user_data = <<EOF
#cloud-config
${yamlencode({
  hostname                  = each.value.name
  fqdn                      = each.value.fqdn
  prefer_fqdn_over_hostname = true

  users = [
    {
      name                = var.username
      sudo                = "ALL=(ALL) NOPASSWD:ALL"
      ssh_authorized_keys = values(var.ssh_keys)
    }
  ]

  write_files = [
    {
      path     = "/etc/tjo.cloud/meta.json"
      encoding = "base64"
      content  = base64encode(jsonencode(merge(each.value.meta, { cloud_region = each.value.datacenter, cloud_provider = "hetzner-cloud" })))
    },
    {
      path     = "/tmp/provision.sh"
      encoding = "base64"
      content  = base64encode(var.provision_sh)
    },
    {
      path    = "/etc/ssh/sshd_config.d/00-cloud-init-port-change.conf"
      content = "Port 2222"
    }
  ]

  packages = [
    "ansible-core",
  ]
  package_update  = true
  package_upgrade = true

  power_state = {
    mode = "reboot"
  }

  # If provision script provided, run it.
  # Else we remove the empty file.
  runcmd = var.provision_sh != "" ? [
    "chmod +x /tmp/provision.sh",
    "/tmp/provision.sh",
    "rm /tmp/provision.sh",
    ] : [
    "rm /tmp/provision.sh",
  ]
})
}
EOF
}

resource "hcloud_rdns" "ipv4" {
  for_each = var.nodes

  server_id  = hcloud_server.main[each.key].id
  ip_address = hcloud_server.main[each.key].ipv4_address
  dns_ptr    = var.domain
}

resource "hcloud_rdns" "ipv6" {
  for_each = var.nodes

  server_id  = hcloud_server.main[each.key].id
  ip_address = hcloud_server.main[each.key].ipv6_address
  dns_ptr    = var.domain
}
