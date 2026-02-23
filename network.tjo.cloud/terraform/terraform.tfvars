nodes = {
  nevaroo = {
    id           = 702
    host         = "nevaroo"
    boot_storage = "local"
    iso_storage  = "local"

    role = "gateway"
    internet_mac_address = "00:50:56:00:97:FD"
  }

  mustafar = {
    host         = "mustafar"
    boot_storage = "local"
    iso_storage  = "local"
    role = "switch"
  }

  batuu = {
    host         = "batuu"
    boot_storage = "local-nvme"
    iso_storage  = "local"
    role = "switch"
  }
  endor = {
    host         = "endor"
    boot_storage = "local-nvme"
    iso_storage  = "local"
    role = "switch"
  }
  jakku = {
    host         = "jakku"
    boot_storage = "local-nvme"
    iso_storage  = "local"
    role = "switch"
  }
}
