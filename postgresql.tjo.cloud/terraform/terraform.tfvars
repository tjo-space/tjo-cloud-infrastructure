nodes = {
  pink = {
    host         = "nevaroo"
    boot_storage = "local-nvme-lvm"
    data_storage = "local-nvme-lvm"
    backup_storage = "local-nvme-lvm"

    ipv4         = "10.1.10.1/16"
    ipv6         = "fd74:6a6f:1:1001::/64"
  }
}

ssh_keys = [
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICXAlzwziqfUUb2qmFwNF/nrBYc5MNT1MMOx81ohBmB+ tine+pc@tjo.space",
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAdPg/nG/Qzk110SBukHHEDqH6/3IJHsIKKHWTrqjaOh tine+mobile@tjo.space",
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHrX2u82zWpVhjWng1cR4Kj76SajLJQ/Nmwd2GPaJpt1 tine+ipad@tjo.space",
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAdKdeca1pqJfT5SbvbOVxjvGXdIny29gqRrQbrNht3m tine+mac@tjo.space",
]
