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
    vmbr1 = {
      ipv4 = { address = "10.0.0.61/10" }
      ipv6 = { address = "fd74:6a6f::61/64" }
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
    vmbr1 = {
      ipv4 = { address = "10.0.0.62/10" }
      ipv6 = { address = "fd74:6a6f::62/64" }
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
    vmbr1 = {
      ipv4 = { address = "10.0.0.63/10" }
      ipv6 = { address = "fd74:6a6f::63/64" }
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
    vmbr1 = {
      ipv4 = { address = "10.0.0.64/10" }
      ipv6 = { address = "fd74:6a6f::64/64" }
    }
  }
  mustafar = {
    cloud_provider = "onprem"
    cloud_region   = "jakob"
    tailscale = {
      ipv4 = "100.99.13.61"
      ipv6 = "fd7a:115c:a1e0::2601:d3d"
    }
    vmbr0 = {
      interfaces = ["enp3s0", "enp5s0"]
      ipv4 = {
        gateway = "192.168.64.1"
        address = "192.168.64.107/24"
      }
    }
    vmbr1 = {
      ipv4 = { address = "10.0.0.65/10" }
      ipv6 = { address = "fd74:6a6f::65/64" }
    }
  }
}
