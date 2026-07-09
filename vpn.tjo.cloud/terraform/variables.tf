variable "nodes_hetzner_cloud" {
  type = map(object({
    location    = string
    image       = string
    server_type = string
    use         = bool
  }))
}

variable "domain" {
  type    = string
  default = "vpn.tjo.cloud"
}

variable "vpn_hcloud_token" {
  sensitive = true
  type      = string
}

variable "authentik_token" {
  type      = string
  sensitive = true
}

variable "desec_token" {
  type      = string
  sensitive = true
}
