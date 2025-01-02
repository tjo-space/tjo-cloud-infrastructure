variable "nodes" {
  type = map(object({
    id   = number
    host = string

    ipv4_address = string
    ipv4_gateway = string

    ipv6_address = string
    ipv6_gateway = string

    cores  = optional(number, 1)
    memory = optional(number, 512)

    iso_storage = string

    boot_storage = string
    boot_size    = optional(number, 8)
  }))
}

variable "ssh_keys" {
  type = list(string)
}

variable "proxmox_token" {
  type      = string
  sensitive = true
}

variable "authentik_token" {
  type      = string
  sensitive = true
}

variable "tailscale_apikey" {
  type      = string
  sensitive = true
}

variable "digitalocean_token" {
  type      = string
  sensitive = true
}