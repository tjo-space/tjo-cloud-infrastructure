resource "local_file" "ansible_inventory" {
  content = yamlencode({
    all = {
      hosts = {
        for k, v in local.nodes : k => {
          ansible_host = v.tailscale.ipv6
          ansible_port = 22
          ansible_user = "root"
        }
      }
    }
  })
  filename = "${path.module}/../ansible/inventory.yaml"
}
