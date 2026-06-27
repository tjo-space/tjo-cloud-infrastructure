nodes_hetzner_cloud = {
  "pink" = {
    datacenter  = "fsn1-dc14" // falkenstein
    use         = false
    server_type = "cx23" // intel, 2core 4gb, 4.26/m
    image       = "debian-13"
  }
  "blue" = {
    datacenter  = "nbg1-dc3" // nuremberg
    use         = true
    server_type = "cx23" // intel, 2core 4gb, 4.26/m
    image       = "debian-13"
  }
}
