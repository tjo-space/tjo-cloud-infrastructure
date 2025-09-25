nodes_hetzner_cloud = {
  "pink" = {
    garage_zone = "hetzner-germany"
    garage_kind = "gateway"
    datacenter  = "fsn1-dc14"
  }
}

nodes_proxmox = {
  "mustafar-purple" = {
    garage_zone    = "onprem-purple"
    garage_kind    = "store"
    garage_storage = "local"
    garage_size    = 400

    host         = "mustafar"
    boot_storage = "local"
  }
  "batuu-yellow" = {
    garage_zone    = "onprem-pink"
    garage_kind    = "store"
    garage_storage = "local-nvme"
    garage_size    = 400

    host         = "batuu"
    boot_storage = "local-nvme"
  }
  "endor-yellow" = {
    garage_zone    = "onprem-pink"
    garage_kind    = "store"
    garage_storage = "local-nvme"
    garage_size    = 400

    boot_storage = "local-nvme"
    host         = "endor"
  }
  "jakku-yellow" = {
    garage_zone    = "onprem-pink"
    garage_kind    = "store"
    garage_storage = "local-nvme"
    garage_size    = 400

    host         = "jakku"
    boot_storage = "local-nvme"
  }
}

ssh_keys = {
  "tine+pc"     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICXAlzwziqfUUb2qmFwNF/nrBYc5MNT1MMOx81ohBmB+ tine+pc@tjo.space"
  "tine+mobile" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAdPg/nG/Qzk110SBukHHEDqH6/3IJHsIKKHWTrqjaOh tine+mobile@tjo.space"
  "tine+ipad"   = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHrX2u82zWpVhjWng1cR4Kj76SajLJQ/Nmwd2GPaJpt1 tine+ipad@tjo.cloud"
  "tine+mac"    = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAdKdeca1pqJfT5SbvbOVxjvGXdIny29gqRrQbrNht3m tine+mac@tjo.space"
}
