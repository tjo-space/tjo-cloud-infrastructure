resource "tailscale_tailnet_key" "main" {
  reusable      = true
  ephemeral     = false
  preauthorized = true
  description   = "proxmox tjo cloud key"
  tags = [
    "tag:system-tjo-cloud"
  ]
}
