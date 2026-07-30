nodes_hetzner_cloud = {
  "blue" = {
    location  = "nbg1" // nuremberg
    use         = true
    server_type = "cx23" // intel, 2core 4gb, 4.26/m
    image       = "debian-13"

    wireguard = {
      id = 21
      address = "fd74:6a6f:70::21/128"
    }
  }
}
