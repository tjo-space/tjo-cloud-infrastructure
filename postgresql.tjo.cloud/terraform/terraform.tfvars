ssh_keys = [
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICXAlzwziqfUUb2qmFwNF/nrBYc5MNT1MMOx81ohBmB+ tine+pc@tjo.space",
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAdPg/nG/Qzk110SBukHHEDqH6/3IJHsIKKHWTrqjaOh tine+mobile@tjo.space",
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHrX2u82zWpVhjWng1cR4Kj76SajLJQ/Nmwd2GPaJpt1 tine+ipad@tjo.space",
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAdKdeca1pqJfT5SbvbOVxjvGXdIny29gqRrQbrNht3m tine+mac@tjo.space",
]

nodes = {
  pink = {
    host           = "nevaroo"
    boot_storage   = "local-nvme-lvm"
    data_storage   = "local-nvme-lvm"
    backup_storage = "local-nvme-lvm"

    ipv4 = "10.1.10.1/16"
    ipv6 = "fd74:6a6f:1:1001::/64"
  }

  purple = {
    host           = "endor"
    boot_storage   = "local-nvme"
    data_storage   = "local-nvme"
    backup_storage = "local-nvme"

    ipv4 = "10.1.10.2/16"
    ipv6 = "fd74:6a6f:1:1002::/64"
  }
}

users = {
  //chat_tjo_space_pink = {
  //  node = "pink"
  //  name = "chat.tjo.space_test"
  //}
}

databases = {
  //chat_tjo_space_mas_pink = {
  //  node = "pink"
  //  name = "chat.tjo.space_mas_test"
  //  owner = "chat.tjo.space_test"
  //}
  //chat_tjo_space_matrix_pink = {
  //  node = "pink"
  //  name = "chat.tjo.space_matrix_test"
  //  owner = "chat.tjo.space_test"
  //}
}
