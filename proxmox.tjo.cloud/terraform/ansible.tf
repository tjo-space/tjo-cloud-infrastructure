resource "local_file" "ansible_inventory" {
  content = yamlencode({
    all = {
      hosts = {
        for k, v in local.nodes : k => {
          ansible_host   = v.tailscale.ipv6
          ansible_port   = 22
          ansible_user   = "root"
          cloud_region   = v.cloud_region
          cloud_provider = v.cloud_provider
        }
      }
    }
  })
  filename = "${path.module}/../ansible/inventory.yaml"
}
