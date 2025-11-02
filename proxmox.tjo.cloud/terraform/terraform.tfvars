nodes = {
  batuu = {
    tailscale = {
      ipv4 = "100.110.88.100"
      ipv6 = "fd7a:115c:a1e0::1901:5864"
    }
    bridges = {
      vmbr0 = {
        interfaces = ["enp1s0", "enp2s0"]
        ipv4 = {
          gateway = "192.168.1.1"
          address = "192.168.1.161/24"
        }
      }
    }
  }
  endor = {
    tailscale = {
      ipv4 = "100.103.129.84"
      ipv6 = "fd7a:115c:a1e0::3b01:8154"
    }
    bridges = {
      vmbr0 = {
        interfaces = ["enp1s0", "enp2s0"]
        ipv4 = {
          gateway = "192.168.1.1"
          address = "192.168.1.103/24"
        }
      }
    }
  }
  jakku = {
    tailscale = {
      ipv4 = "100.67.200.27"
      ipv6 = "fd7a:115c:a1e0::301:c81b"
    }
    bridges = {
      vmbr0 = {
        interfaces = ["enp1s0", "enp2s0"]
        ipv4 = {
          gateway = "192.168.1.1"
          address = "192.168.1.187/24"
        }
      }
    }
  }
  nevaroo = {
    tailscale = {
      ipv4 = "100.82.48.119"
      ipv6 = "fd7a:115c:a1e0::b301:3077"
    }
    bridges = {
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
    }
  }
  mustafar = {
    tailscale = {
      ipv4 = "100.99.13.61"
      ipv6 = "fd7a:115c:a1e0::2601:d3d"
    }
    bridges = {
      vmbr0 = {
        interfaces = ["enp3s0", "enp5s0"]
        ipv4 = {
          gateway = "192.168.64.1"
          address = "192.168.64.107/24"
        }
      }
    }
  }
}
