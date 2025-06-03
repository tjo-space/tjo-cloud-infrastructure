variable "nodes" {
  type = map(object({
    host = string

    cores  = optional(number, 6)
    memory = optional(number, 8192)

    ipv4 = string
    ipv6 = string

    boot_storage = string
    boot_size    = optional(number, 8)

    data_storage = string
    data_size    = optional(number, 16)

    backup_storage = string
    backup_size    = optional(number, 64)
  }))
}

variable "domain" {
  type    = string
  default = "v2.postgresql.tjo.cloud"
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
