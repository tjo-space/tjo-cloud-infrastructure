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
  default = "ingress.tjo.cloud"
}

variable "zerotier_token" {
  sensitive = true
  type      = string
}

variable "ingress_hcloud_token" {
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

variable "proxmox_token" {
  type      = string
  sensitive = true
}
