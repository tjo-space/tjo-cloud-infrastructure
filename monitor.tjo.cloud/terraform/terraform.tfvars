nodes = {
  batuu-pink = {
    host         = "batuu"
    boot_storage = "local-nvme"

    data_storage = "local-nvme"
    data_size    = 128

    cores  = 2
    memory = 6144

    image = "debian_13_server_cloudimg_amd64.img"
    use = true
  }
}
