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
  {
    node      = "endor-one"
    name      = "code.tjo.space"
    databases = [{ name = "code.tjo.space" }]
  },
  {
    node      = "endor-one"
    name      = "cloud.tjo.space"
    databases = [{ name = "cloud.tjo.space" }]
  },
  {
    node      = "endor-one"
    name      = "paperless.tjo.space"
    databases = [{ name = "paperless.tjo.space" }]
  },
  {
    node      = "endor-one"
    name      = "penpot.tjo.space"
    databases = [{ name = "penpot.tjo.space" }]
  },
]

administrators = [
  "tine.jozelj",
  "jakob.jozelj",
]
