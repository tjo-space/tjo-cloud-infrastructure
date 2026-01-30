variable "nodes_proxmox" {
  type = map(object({
    host         = string
    cores        = optional(number, 1)
    memory       = optional(number, 1042)
    boot_storage = string
    boot_size    = optional(number, 8)
  }))
}

variable "domain" {
  type    = string
  default = "ca.tjo.cloud"
}

variable "zerotier_token" {
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
