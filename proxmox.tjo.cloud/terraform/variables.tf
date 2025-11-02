variable "proxmox_token" {
  type      = string
  sensitive = true
}

variable "zerotier_token" {
  sensitive = true
  type      = string
}

variable "zerotier_network" {
  type    = string
  default = "b6079f73c6379990"
}

variable "authentik_token" {
  type      = string
  sensitive = true
}

variable "desec_token" {
  type      = string
  sensitive = true
}

variable "domain" {
  type    = string
  default = "proxmox.tjo.cloud"
}

variable "nodes" {
  type = map(object({
    tailscale = object({
      ipv4 = string
      ipv6 = string
    })
    bridges = object({
      vmbr0 = object({
        ipv4 = object({
          address = string
          gateway = string
        })
        ipv6 = optional(object({
          address = optional(string, null)
          gateway = optional(string, null)
        }), { address = null, gateway = null })
        interfaces = list(string)
      })
    })
    iso_storage = optional(string, "local")
  }))
  description = "List of proxmox nodes"
}
