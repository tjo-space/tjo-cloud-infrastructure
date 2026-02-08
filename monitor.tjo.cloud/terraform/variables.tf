variable "nodes" {
  type = map(object({
    host = string

    cores  = number
    memory = number

    boot_storage = string
    boot_size    = optional(number, 16)

    data_storage = string
    data_size    = number
  }))
}

variable "domain" {
  type    = string
  default = "monitor.tjo.cloud"
}

variable "proxmox_token" {
  type      = string
  sensitive = true
}

variable "authentik_token" {
  type      = string
  sensitive = true
}

variable "dns_tjo_cloud_token" {
  type      = string
  sensitive = true
}
