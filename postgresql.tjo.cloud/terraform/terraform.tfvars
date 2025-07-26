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

    ipv4 = "10.1.10.1/10"
    ipv6 = "fd74:6a6f:1:1001::/64"
  }

  purple = {
    host           = "endor"
    boot_storage   = "local-nvme"
    data_storage   = "local-nvme"
    backup_storage = "local-nvme"

    ipv4 = "10.1.10.2/10"
    ipv6 = "fd74:6a6f:1:1002::/64"
  }
}

users = [
  {
    node      = "purple"
    name      = "code.tjo.space"
    databases = [{ name = "code.tjo.space" }]
  },
  {
    node      = "purple"
    name      = "cloud.tjo.space"
    databases = [{ name = "cloud.tjo.space" }]
  },
  {
    node      = "purple"
    name      = "paperless.tjo.space"
    databases = [{ name = "paperless.tjo.space" }]
  },
  {
    node      = "purple"
    name      = "penpot.tjo.space"
    databases = [{ name = "penpot.tjo.space" }]
  },
]
