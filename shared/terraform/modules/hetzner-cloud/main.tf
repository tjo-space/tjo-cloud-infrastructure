resource "hcloud_server" "main" {
  name = var.fqdn

  image       = var.image
  server_type = var.server_type
  datacenter  = var.datacenter
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
  backups = false

  user_data = <<EOF
#cloud-config
${yamlencode(merge(var.userdata, {
  hostname                  = var.name
  fqdn                      = var.fqdn
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
      content  = base64encode(jsonencode(merge(var.metadata, { cloud_region = var.datacenter, cloud_provider = "hetzner-cloud" })))
    },
    {
      path     = "/tmp/provision.sh"
      encoding = "base64"
      content  = base64encode(var.provision_sh)
    },
    {
      path    = "/etc/ssh/sshd_config.d/00-cloud-init-port-change.conf"
      content = "Port 2222"
    },
    {
      path    = "/etc/firewalld/services/ssh.xml"
      content = <<EOF
          <?xml version="1.0" encoding="utf-8"?>
          <service>
            <short>SSH</short>
            <port protocol="tcp" port="2222"/>
          </service>
        EOF
    }
  ]

  packages = [
    "ansible-core",
    "firewalld",
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
}))
}
EOF

lifecycle {
  ignore_changes = [user_data]
}
}

resource "hcloud_rdns" "ipv4" {
  server_id  = hcloud_server.main.id
  ip_address = hcloud_server.main.ipv4_address
  dns_ptr    = var.domain
}

resource "hcloud_rdns" "ipv6" {
  server_id  = hcloud_server.main.id
  ip_address = hcloud_server.main.ipv6_address
  dns_ptr    = var.domain
}
