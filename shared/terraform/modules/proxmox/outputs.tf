locals {
  ipv4_addresses = {
    for k, v in proxmox_virtual_environment_vm.node.ipv4_addresses :
    proxmox_virtual_environment_vm.node.network_interface_names[k] => v
  }
  ipv6_addresses = {
    for k, v in proxmox_virtual_environment_vm.node.ipv6_addresses :
    proxmox_virtual_environment_vm.node.network_interface_names[k] => v
  }
}

output "address" {
  value = {
    ipv4 = lookup(local.ipv4_addresses, "ens18", lookup(local.ipv4_addresses, "eth0", [""]))[0]
    ipv6 = lookup(local.ipv6_addresses, "ens18", lookup(local.ipv6_addresses, "eth0", [""]))[0]
  }
}
