nodes_hetzner_cloud = {
  purple = {
    location    = "fsn1"
    use         = true
    server_type = "cx23" // intel, 2core 4gb, 4.26/m
    image       = "debian-13"

    wireguard = {
      id      = 22
      address = "fd74:6a6f:3030:70::22/128"
    }
  }
}
