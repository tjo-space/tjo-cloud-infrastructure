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

  ca_certs = {
    remove_defaults = false
    trusted = [
      # ca.tjo.cloud
      <<EOF
-----BEGIN CERTIFICATE-----
MIIBfzCCASSgAwIBAgIQTwBj3msM0GPYkUSHuEsKEjAKBggqhkjOPQQDAjAeMRww
GgYDVQQDExNjYS50am8uY2xvdWQgLSBSb290MCAXDTI2MDIwNjIwNTc0MFoYDzIw
NTEwMzE0MTI1NzQwWjAeMRwwGgYDVQQDExNjYS50am8uY2xvdWQgLSBSb290MFkw
EwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAENghQfaCunCDzn0BmU8vI5X79OAqZ7Uob
8tM38BJmvUmafJMyxpvlIKNgotXJfnTw1GN5mR6u4eqvSRclhUcRtKNCMEAwDgYD
VR0PAQH/BAQDAgEGMA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFD0gfxAPGvuX
jmqfZ1CreFQT+WuQMAoGCCqGSM49BAMCA0kAMEYCIQCY0suGAsNGx7n2+F+Z786Q
dubTJY1VA3fqwc0ZpO+AtQIhAOmeM2O7iFarM2KILzS5189DsdNIn5pp9v5uLOSX
T8+p
-----END CERTIFICATE-----
EOF
    ]
  }

  users = [
    {
      name = "root"
      # As we provision instance without Hetzner ssh keys.
      # Hetzner thinks we want to use password authentication for ssh.
      # We do not. Additionally, hetzner will enforce that root needs
      # a password change. We do not care about that.
      # Set something random, we won't use it anyway.
      type = "RANDOM"
    },
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
      path    = "/etc/ssh/sshd_config.d/00-cloud-init-disable-password-auth.conf"
      content = "PasswordAuthentication no"
    },
    {
      path = "/etc/firewalld/services/ssh.xml"
      content = trimspace(<<EOF
<?xml version="1.0" encoding="utf-8"?>
<service>
  <short>SSH</short>
  <port protocol="tcp" port="2222"/>
</service>
EOF
      )
    }
  ]

  packages = [
    "ansible-core",
    "firewalld",
    "python3-firewall",
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
