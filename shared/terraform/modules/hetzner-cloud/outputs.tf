output "address" {
  value = {
    ipv4 = hcloud_server.main.ipv4_address
    ipv6 = hcloud_server.main.ipv6_address
  }
}
