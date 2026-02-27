nodes = {
  nevaroo = {
    id           = 702
    host         = "nevaroo"
    boot_storage = "local"
    iso_storage  = "local"
    role = "gateway"
    internet_mac_address = "00:50:56:00:97:FD"
  }

  nevaroo-router = {
    host         = "nevaroo"
    boot_storage = "local"
    iso_storage  = "local"
    role = "router"
  }
  mustafar-router = {
    host         = "mustafar"
    boot_storage = "local"
    iso_storage  = "local"
    role = "router"
  }
  batuu-router = {
    host         = "batuu"
    boot_storage = "local-nvme"
    iso_storage  = "local"
    role = "router"
  }
  endor-router = {
    host         = "endor"
    boot_storage = "local-nvme"
    iso_storage  = "local"
    role = "router"
  }
  jakku-router = {
    host         = "jakku"
    boot_storage = "local-nvme"
    iso_storage  = "local"
    role = "router"
  }
}
