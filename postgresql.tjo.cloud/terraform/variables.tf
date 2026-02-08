variable "nodes" {
  type = map(object({
    host = string

    cores  = number
    memory = number

    boot_storage = string
    boot_size    = optional(number, 16)

    data_storage = string
    data_size    = number

    kind = string // postgresql, barman

    postgresql_version = string
  }))
}

variable "users" {
  type = list(object({
    node             = string
    name             = string
    connection_limit = optional(number, 20)
    databases = list(object({
      name     = string
      encoding = optional(string, "UTF8")
      # Collation
      lc_collate = optional(string, "en_US.UTF-8")
      # Character Type
      lc_ctype         = optional(string, "en_US.UTF-8")
      connection_limit = optional(number, 20)
    }))
  }))
}

variable "administrators" {
  type        = set(string)
  description = "Administrator users to be created on all nodes."
}

variable "pgadmin_client_id" {
  type      = string
  sensitive = true
}

variable "pgadmin_client_secret" {
  type      = string
  sensitive = true
}

variable "proxmox_token" {
  type      = string
  sensitive = true
}

variable "authentik_token" {
  type      = string
  sensitive = true
}

variable "dns_tjo_cloud_token" {
  type      = string
  sensitive = true
}
