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
    cloud_provider = string
    cloud_region   = string
    tailscale = object({
      ipv4 = string
      ipv6 = string
    })
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
    vmbr1 = object({
      ipv4 = object({
        address = string
        subnet  = optional(string, "10.0.0.0/10")
      })
      ipv6 = object({
        address = string
        subnet  = optional(string, "fd74:6a6f::/48")
      })
    })
    iso_storage = optional(string, "local")
  }))
  description = "List of proxmox nodes"
}
