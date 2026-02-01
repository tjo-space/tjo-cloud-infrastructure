variable "nodes_proxmox" {
  type = map(object({
    host         = string
    cores        = number
    memory       = number
    boot_storage = string
    boot_size    = number
    data_storage = string
    data_size    = number
  }))
}

variable "domain" {
  type    = string
  default = "ca.tjo.cloud"
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
