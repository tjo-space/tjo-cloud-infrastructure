nodes = {
  batuu = {
    id           = 700
    host         = "batuu"
    boot_storage = "local-nvme"
    iso_storage  = "local"

    bridge_ports = ["enp1s0", "enp2s0"]
    gateway      = "192.168.1.1"
    address      = "192.168.1.161/24"
  }
  jakku = {
    id           = 701
    host         = "jakku"
    boot_storage = "local-nvme"
    iso_storage  = "local"

    bridge_ports = ["enp1s0", "enp2s0"]
    gateway      = "192.168.1.1"
    address      = "192.168.1.187/24"
  }
  nevaroo = {
    id           = 702
    host         = "nevaroo"
    boot_storage = "local"
    iso_storage  = "local"

    mac_address  = "00:50:56:00:97:FD"
    bridge_ports = ["eno1"]
    gateway      = "178.63.49.193"
    address      = "178.63.49.225/26"
  }
  mustafar = {
    id           = 703
    host         = "mustafar"
    boot_storage = "local"
    iso_storage  = "local"

    bridge_ports = ["enp3s0", "enp5s0"]
    gateway      = "192.168.64.1"
    address      = "192.168.64.107/24"
  }
  endor = {
    id           = 704
    host         = "endor"
    boot_storage = "local-nvme"
    iso_storage  = "local"

    bridge_ports = ["enp1s0", "enp2s0"]
    gateway      = "192.168.1.1"
    address      = "192.168.1.103/24"
  }
}
