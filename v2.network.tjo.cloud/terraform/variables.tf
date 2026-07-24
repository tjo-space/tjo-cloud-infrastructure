variable "nodes" {
  type = map(object({
    host = string

    cores  = optional(number, 1)
    memory = optional(number, 1024)

    kind = string # router or gateway

    boot_storage = string
    boot_size    = optional(number, 16)

    wan = object({
      mac_address = optional(string)
      ipv4 = optional(
        object({
          address = optional(string, "dhcp")
          gateway = optional(string)
        }),
        {}
      )
      ipv6 = optional(
        object({
          address = optional(string, "auto")
          gateway = optional(string)
        }),
        {}
      )
    })
  }))
}

variable "proxmox_token" {
  type      = string
  sensitive = true
}

variable "authentik_token" {
  type      = string
  sensitive = true
}

variable "tailscale_token" {
  sensitive = true
  type      = string
}
