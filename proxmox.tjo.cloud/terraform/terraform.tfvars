nodes = {
  endor = {
    cloud_provider = "onprem"
    cloud_region   = "tine"
    tailscale = {
      ipv4 = "100.103.129.84"
      ipv6 = "fd7a:115c:a1e0::3b01:8154"
    }
    vmbr0 = {
      interfaces = ["enp1s0", "enp2s0"]
      ipv4 = {
        gateway = "192.168.1.1"
        address = "192.168.1.103/24"
      }
    }
    vmbr2 = {
      ipv6 = { address = "fd74:6a6f:3030:11::10/64" }
    }
    features = {
      nut = {
        enabled = true
        host    = "fe80::bf1e:8ac5:67c1:db1%vmbr0"
      }
    }
  }
  batuu = {
    cloud_provider = "onprem"
    cloud_region   = "tine"
    tailscale = {
      ipv4 = "100.110.88.100"
      ipv6 = "fd7a:115c:a1e0::1901:5864"
    }
    vmbr0 = {
      interfaces = ["enp1s0", "enp2s0"]
      ipv4 = {
        gateway = "192.168.1.1"
        address = "192.168.1.161/24"
      }
    }
    vmbr2 = {
      ipv6 = { address = "fd74:6a6f:3030:12::10/64" }
    }
    features = {
      nut = {
        enabled = true
        host    = "fe80::bf1e:8ac5:67c1:db1%vmbr0"
      }
    }
  }
  jakku = {
    cloud_provider = "onprem"
    cloud_region   = "tine"
    tailscale = {
      ipv4 = "100.67.200.27"
      ipv6 = "fd7a:115c:a1e0::301:c81b"
    }
    vmbr0 = {
      interfaces = ["enp1s0", "enp2s0"]
      ipv4 = {
        gateway = "192.168.1.1"
        address = "192.168.1.187/24"
      }
    }
    vmbr2 = {
      ipv6 = { address = "fd74:6a6f:3030:13::10/64" }
    }
    features = {
      disable_network_offloading = {
        enabled    = true
        interfaces = ["enp1s0", "enp2s0"]
      }
      nut = {
        enabled = true
        host    = "fe80::bf1e:8ac5:67c1:db1%vmbr0"
      }
    }
  }
  nevaroo = {
    cloud_provider = "hetzner"
    cloud_region   = "germany"
    tailscale = {
      ipv4 = "100.82.48.119"
      ipv6 = "fd7a:115c:a1e0::b301:3077"
    }
    vmbr0 = {
      interfaces = ["eno1"]
      ipv4 = {
        gateway = "178.63.49.193"
        address = "178.63.49.225/26"
      }
      ipv6 = {
        gateway = "fe80::1"
        address = "2a01:4f8:120:70b5::/64"
      }
    }
    vmbr2 = {
      ipv6 = { address = "fd74:6a6f:3030:10::10/64" }
    }
    features = {
      disable_network_offloading = {
        enabled    = true
        interfaces = ["eno1"]
      }
    }
  }
}
