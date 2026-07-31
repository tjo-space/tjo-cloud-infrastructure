nodes = {
  nevaroo = {
    host         = "nevaroo"
    boot_storage = "local-nvme-lvm"
    kind         = "gateway"
    id           = 10
    wan = {
      bridge = "vmbr1"
    }
    wireguard = {
      address = "fd74:6a6f:3030:70::10/128"
    }
    lan = {
      bridge = "vmbr3"
      public = {
        prefix = "2a01:4f8:120:7710::/64"
      }
      internal = {
        prefix = "fd74:6a6f:3030:0:10::/64"
      }
    }
  }
  endor = {
    host         = "endor"
    boot_storage = "local-nvme"
    kind         = "router"
    id           = 11
    wan = {
      bridge = "vmbr0"
    }
    wireguard = {
      address = "fd74:6a6f:3030:70::11/128"
    }
    lan = {
      bridge = "vmbr3"
      public = {
        prefix = "2a01:4f8:120:7711::/64"
      }
      internal = {
        prefix = "fd74:6a6f:3030:0:11::/64"
      }
    }
  }
  batuu = {
    host         = "batuu"
    boot_storage = "local-nvme"
    kind         = "router"
    id           = 12
    wan = {
      bridge = "vmbr0"
    }
    wireguard = {
      address = "fd74:6a6f:3030:70::12/128"
    }
    lan = {
      bridge = "vmbr3"
      public = {
        prefix = "2a01:4f8:120:7712::/64"
      }
      internal = {
        prefix = "fd74:6a6f:3030:0:12::/64"
      }
    }
  }
  jakku = {
    host         = "jakku"
    boot_storage = "local-nvme"
    kind         = "router"
    id           = 13
    wan = {
      bridge = "vmbr0"
    }
    wireguard = {
      address = "fd74:6a6f:3030:70::13/128"
    }
    lan = {
      bridge = "vmbr3"
      public = {
        prefix = "2a01:4f8:120:7713::/64"
      }
      internal = {
        prefix = "fd74:6a6f:3030:0:13::/64"
      }
    }
  }
}
