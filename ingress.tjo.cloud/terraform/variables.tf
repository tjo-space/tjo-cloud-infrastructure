variable "nodes" {
  type = map(object({
    host = string

    cores  = optional(number, 1)
    memory = optional(number, 512)

    iso_storage = string

    ipv4 = string
    ipv6 = string

    boot_storage = string
    boot_size    = optional(number, 8)
  }))
}

variable "zones" {
  type = set(string)
}

variable "records" {
  type = map(object({
    to   = string
    ttl  = optional(number, 600)
    type = optional(string, "ALIAS")
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

variable "dnsimple_token" {
  type      = string
  sensitive = true
}

variable "dnsimple_account_id" {
  type = string
}
