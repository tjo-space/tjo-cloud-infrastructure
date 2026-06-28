variable "id_hcloud_token" {
  sensitive = true
  type      = string
}

variable "nodes" {
  type = list(string)
}

variable "nodes_proxmox" {
  type = map(object({
    host         = string
    cores        = number
    memory       = number
    boot_storage = string
    boot_size    = number
  }))
}

variable "domain" {
  type    = string
  default = "id.tjo.cloud"
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
