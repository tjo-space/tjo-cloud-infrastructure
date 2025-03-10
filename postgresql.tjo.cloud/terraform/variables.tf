variable "nodes" {
  type = map(object({
    host = string

    cores  = optional(number, 1)
    memory = optional(number, 512)

    iso_storage = string

    boot_storage = string
    boot_size    = optional(number, 8)

    data_storage = string
    data_size    = optional(number, 64)
  }))
}

variable "ssh_keys" {
  type = map(string)
}

variable "proxmox_token" {
  type      = string
  sensitive = true
}

variable "authentik_token" {
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
