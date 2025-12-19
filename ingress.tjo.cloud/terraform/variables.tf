variable "nodes_hetzner_cloud" {
  type = map(object({
    datacenter  = string
    image       = optional(string, "ubuntu-24.04")
    server_type = optional(string, "cax11")
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
