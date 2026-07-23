nodes_hetzner_cloud = {
  "pink" = {
    garage_zone  = "germany"
    garage_kind  = "gateway"
    location  = "nbg1" // nuremberg
    use         = true
    server_type = "cx23" // intel, 2core 4gb, 4.26/m
    image       = "debian-13"
    private_ipv6 = "fd74:6a6f::90af:1eff:fe52:3884"
  }
}

nodes_proxmox = {
  "batuu-yellow" = {
    garage_zone    = "batuu"
    garage_kind    = "store"
    garage_storage = "local-ssd"
    garage_size    = 800

    host         = "batuu"
    boot_storage = "local-nvme"
  }
  "endor-yellow" = {
    garage_zone    = "endor"
    garage_kind    = "store"
    garage_storage = "local-nvme"
    garage_size    = 800

    host         = "endor"
    boot_storage = "local-nvme"
  }
  "jakku-yellow" = {
    garage_zone    = "jakku"
    garage_kind    = "store"
    garage_storage = "local-nvme"
    garage_size    = 800

    host         = "jakku"
    boot_storage = "local-nvme"
  }
}
