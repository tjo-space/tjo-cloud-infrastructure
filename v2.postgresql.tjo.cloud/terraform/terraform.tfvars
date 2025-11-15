nodes = {
  pink = {
    host           = "nevaroo"
    boot_storage   = "local-nvme-lvm"
    data_storage   = "local-nvme-lvm"
    kind = "server"

    ipv4 = "10.1.10.1/10"
    ipv6 = "fd74:6a6f:1:1001::/64"
  }

  purple = {
    host           = "endor"
    boot_storage   = "local-nvme"
    data_storage   = "local-nvme"
    kind = "server"

    ipv4 = "10.1.10.2/10"
    ipv6 = "fd74:6a6f:1:1002::/64"
  }

  yellow = {
    host           = "mustafar"
    boot_storage   = "local"
    data_storage   = "local"
    kind = "backup"

    ipv4 = "10.1.10.3/10"
    ipv6 = "fd74:6a6f:1:1003::/64"
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
