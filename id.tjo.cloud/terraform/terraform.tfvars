nodes = [
  "01",
]

nodes_proxmox = {
  "nevaroo-purple" = {
    host         = "nevaroo"
    cores        = 1
    memory       = 2048
    boot_storage = "local-nvme-lvm"
    boot_size    = 16
  }
}
