variable "nodes" {
  type = map(object({
    host = string

    cores  = optional(number, 6)
    memory = optional(number, 12288)

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

variable "pgadmin_client_id" {
  type      = string
  sensitive = true
}

variable "pgadmin_client_secret" {
  type      = string
  sensitive = true
}

variable "domain" {
  type    = string
  default = "postgresql.tjo.cloud"
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

variable "dnsimple_token" {
  type      = string
  sensitive = true
}

variable "dnsimple_account_id" {
  type = string
}
