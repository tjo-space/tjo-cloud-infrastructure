variable "nodes_hetzner_cloud" {
  type = map(object({
    garage_zone  = string
    garage_kind  = string
    datacenter   = string
    image        = optional(string, "ubuntu-24.04")
    server_type  = optional(string, "cax11")
    private_ipv4 = optional(string, "")
    private_ipv6 = optional(string, "")
  }))
}

variable "nodes_proxmox" {
  type = map(object({
    garage_zone    = string
    garage_kind    = string
    garage_storage = string
    garage_size    = number
    host           = string
    cores          = optional(number, 2)
    memory         = optional(number, 4096)
    boot_storage   = string
    boot_size      = optional(number, 8)
  }))
}

variable "domain" {
  type    = string
  default = "s3.tjo.cloud"
}

variable "zerotier_token" {
  sensitive = true
  type      = string
}

variable "s3_hcloud_token" {
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

variable "dns_tjo_cloud_token" {
  type      = string
  sensitive = true
}
