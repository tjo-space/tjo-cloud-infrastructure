nodes_hetzner_cloud = {
  "pink" = {
    garage_zone  = "germany"
    garage_kind  = "gateway"
    datacenter   = "fsn1-dc14"
    private_ipv4 = "10.1.230.194" # manually configured once known
    private_ipv6 = "fd74:6a6f::9055:afff:fe6e:c6ef"
  }
}

nodes_proxmox = {
  "mustafar-purple" = {
    garage_zone    = "mustafar"
    garage_kind    = "store"
    garage_storage = "local"
    garage_size    = 400

    host         = "mustafar"
    boot_storage = "local"
  }
  "batuu-yellow" = {
    garage_zone    = "batuu"
    garage_kind    = "store"
    garage_storage = "local-nvme"
    garage_size    = 400

    host         = "batuu"
    boot_storage = "local-nvme"
  }
  "endor-yellow" = {
    garage_zone    = "endor"
    garage_kind    = "store"
    garage_storage = "local-nvme"
    garage_size    = 400

    host         = "endor"
    boot_storage = "local-nvme"
  }
  "jakku-yellow" = {
    garage_zone    = "jakku"
    garage_kind    = "store"
    garage_storage = "local-nvme"
    garage_size    = 400

    host         = "jakku"
    boot_storage = "local-nvme"
  }
}
