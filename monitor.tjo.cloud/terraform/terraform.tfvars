nodes = {
  nevaroo-yellow = {
    host         = "nevaroo"
    boot_storage = "local-nvme-lvm"

    data_storage = "local-nvme-lvm"
    data_size    = 128

    cores  = 2
    memory = 8192
  }
}
