variable "nodes" {
  type = map(object({
    host = string

    cores  = optional(number, 1)
    memory = optional(number, 512)

    ipv4 = string
    ipv6 = string

    boot_storage = string
    boot_size    = optional(number, 8)
  }))
}

variable "postgresql_password" {
  type      = string
  sensitive = true
}

variable "domain" {
  type    = string
  default = "mail.tjo.cloud"
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
