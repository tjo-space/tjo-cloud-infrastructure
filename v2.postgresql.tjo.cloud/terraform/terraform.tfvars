nodes = {
  nevaroo-one = {
    kind = "postgresql"
    postgresql = {
      cluster_name = "nevaroo"
      role    = "primary"
      version = "18"
    }

    host         = "nevaroo"
    boot_storage = "local-nvme-lvm"

    data_storage = "local-nvme-lvm"
    data_size    = 64

    cores  = 2
    memory = 8192
  }

  endor-one = {
    kind = "postgresql"
    postgresql = {
      cluster_name = "endor"
      role    = "primary"
      version = "18"
    }

    host         = "endor"
    boot_storage = "local-nvme"

    data_storage = "local-nvme"
    data_size    = 64

    cores  = 2
    memory = 8192
  }

  barman = {
    kind = "barman"

    host         = "mustafar"
    boot_storage = "local"

    data_storage = "local"
    data_size    = 128

    cores  = 2
    memory = 2048
  }
}

users = [

]
