variable "nodes" {
  type = map(object({
    id   = number
    host = string

    cores  = optional(number, 1)
    memory = optional(number, 512)

    vmbr0 = object({
      gateway      = string
      address      = string
      gateway6     = optional(string)
      address6     = optional(string)
      mac_address  = optional(string)
      bridge_ports = list(string)
    })

    vmbr1 = optional(object({
      gateway  = optional(string)
      address  = optional(string)
      gateway6 = optional(string)
      address6 = optional(string)
      }), {
      gateway  = null
      address  = null
      gateway6 = null
      address6 = null
    })

    iso_storage  = string
    boot_storage = string
  }))
}

variable "proxmox_token" {
  type      = string
  sensitive = true
}
