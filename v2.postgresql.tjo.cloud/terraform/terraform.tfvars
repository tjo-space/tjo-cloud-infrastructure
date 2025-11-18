nodes = {
  nevaroo-one = {
    kind = "postgresql"

    host         = "nevaroo"
    boot_storage = "local-nvme-lvm"

    data_storage = "local-nvme-lvm"
    data_size    = 64

    cores  = 2
    memory = 8192

    postgresql_version = "16"
  }

  endor-one = {
    kind = "postgresql"

    host         = "endor"
    boot_storage = "local-nvme"

    data_storage = "local-nvme"
    data_size    = 64

    cores  = 2
    memory = 8192

    postgresql_version = "16"
  }

  barman = {
    kind = "barman"

    host         = "mustafar"
    boot_storage = "local"

    data_storage = "local"
    data_size    = 128

    cores  = 2
    memory = 2048

    postgresql_version = "18"
  }
}

users = [

]
