locals {
  nodes = {
    "nevaroo" : "local",
    "jakku" : "local",
    "batuu" : "local",
    "mustafar" : "local",
    "endor" : "local"
  }

  images = {
    "ubuntu_2404_server_cloudimg_amd64.img" = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
    "debian_13_server_cloudimg_amd64.img"   = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-generic-amd64.qcow2"
  }
}

resource "proxmox_virtual_environment_download_file" "images" {
  for_each = { for pair in setproduct(toset(keys(local.nodes)), toset(keys(local.images))) :
    "${pair[0]}-${pair[1]}" => {
      node : pair[0],
      datastore_id : local.nodes[pair[0]],
      image : pair[1],
      url : local.images[pair[1]]
    }
  }

  content_type = "iso"
  datastore_id = each.value.datastore_id
  node_name    = each.value.node
  file_name    = each.value.image
  url          = each.value.url
  overwrite    = false
}
