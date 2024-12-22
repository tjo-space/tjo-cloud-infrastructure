variable "nodes" {
  type = map(object({
    id   = number
    host = string

    cores  = optional(number, 1)
    memory = optional(number, 512)

    mac_address  = optional(string)
    bridge_ports = list(string)
    gateway      = string
    address      = string

    iso_storage  = string
    boot_storage = string
  }))
}

variable "proxmox_token" {
  type      = string
  sensitive = true
}
