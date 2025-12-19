locals {
  ipv4_addresses = {
    for k, v in proxmox_virtual_environment_vm.node.ipv4_addresses :
    proxmox_virtual_environment_vm.node.network_interface_names[k] => v
  }
  ipv6_addresses = {
    for k, v in proxmox_virtual_environment_vm.node.ipv6_addresses :
    proxmox_virtual_environment_vm.node.network_interface_names[k] => v
  }

  local_interfaces_ipv4_address = flatten([for iface, ips in local.ipv4_addresses : ips if iface == "ens18" || iface == "eth0"])
  local_interfaces_ipv6_address = flatten([for iface, ips in local.ipv6_addresses : ips if iface == "ens18" || iface == "eth0"])
}

output "address" {
  value = {
    ipv4 = local.local_interfaces_ipv4_address[0]

    // We filter ip addresses to only find internal ones.
    ipv6 = try([for ipv6 in local.local_interfaces_ipv6_address : ipv6 if startswith(ipv6, "fd74:6a6f:")][0], "")
  }
}
