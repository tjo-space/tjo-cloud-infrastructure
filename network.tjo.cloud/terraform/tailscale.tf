resource "tailscale_tailnet_key" "this" {
  reusable      = true
  ephemeral     = false
  preauthorized = true
  description   = "network tjo cloud key"
  tags = [
    "tag:network-tjo-cloud"
  ]
}
