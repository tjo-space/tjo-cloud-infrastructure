resource "hcloud_ssh_key" "main" {
  for_each = var.ssh_keys

  name       = each.key
  public_key = each.value
}

resource "hcloud_server" "main" {
  for_each = { for node in var.nodes : node => {} }

  name = "${each.key}.${var.domain.name}"

  image       = "ubuntu-24.04"
  server_type = "cax11"
  datacenter  = "hel1-dc2"
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
  backups  = true
  ssh_keys = [for key, value in var.ssh_keys : hcloud_ssh_key.main[key].id]

  user_data = <<-EOF
    #cloud-config
    hostname: "${each.key}"
    fqdn: "${each.key}.${var.domain.name}"
    prefer_fqdn_over_hostname: true
    write_files:
    - path: /tmp/provision.sh
      encoding: base64
      content: ${base64encode(file("${path.module}/../provision.sh"))}
    packages:
      - git
      - curl
    package_update: true
    package_upgrade: true
    power_state:
      mode: reboot
    swap:
      filename: /swapfile
      size: 512M
    runcmd:
      - "chmod +x /tmp/provision.sh"
      - "/tmp/provision.sh"
      - "rm /tmp/provision.sh"
    EOF

  lifecycle {
    ignore_changes = [ssh_keys]
  }
}

resource "desec_rrset" "main" {
  for_each = {
    A = [for k, v in hcloud_server.main : v.ipv4_address]
    #AAAA = [for k, v in hcloud_server.main : v.ipv6_address]
  }
  domain  = var.domain.zone
  subname = trimsuffix(var.domain.name, ".${var.domain.zone}")
  type    = each.key
  records = each.value
  ttl     = 3600
}
