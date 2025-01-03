nodes = {
  batuu = {
    id           = 800
    host         = "batuu"
    iso_storage  = "local"
    boot_storage = "local-nvme"

    ipv4_address = "10.0.16.10/20"
    ipv4_gateway = "10.0.16.1"
    ipv6_address = "fd74:6a6f:0:1010::1/64"
    ipv6_gateway = "fd74:6a6f:0:1000::1"
  }
  jakku = {
    id           = 801
    host         = "jakku"
    iso_storage  = "local"
    boot_storage = "local-nvme"

    ipv4_address = "10.0.32.10/20"
    ipv4_gateway = "10.0.32.1"
    ipv6_address = "fd74:6a6f:0:2010::1/64"
    ipv6_gateway = "fd74:6a6f:0:2000::1"
  }
  nevaroo = {
    id           = 802
    host         = "nevaroo"
    iso_storage  = "local"
    boot_storage = "local"

    ipv4_address = "10.0.48.10/20"
    ipv4_gateway = "10.0.48.1"
    ipv6_address = "fd74:6a6f:0:3010::1/64"
    ipv6_gateway = "fd74:6a6f:0:3000::1"
  }
  mustafar = {
    id           = 803
    host         = "mustafar"
    iso_storage  = "local"
    boot_storage = "local"

    ipv4_address = "10.0.64.10/20"
    ipv4_gateway = "10.0.64.1"
    ipv6_address = "fd74:6a6f:0:4010::1/64"
    ipv6_gateway = "fd74:6a6f:0:4000::1"
  }
}

ssh_keys = [
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICXAlzwziqfUUb2qmFwNF/nrBYc5MNT1MMOx81ohBmB+ tine@little.sys.tjo.space"
]