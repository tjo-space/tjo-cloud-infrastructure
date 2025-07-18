variable "nodes" {
  type = map(object({
    name         = string
    description  = optional(string, "")
    fqdn         = string
    host         = string
    memory       = number
    cores        = number
    boot_storage = string
    boot_size    = number
    userdata     = optional(any, {})
    disks = optional(list(object({
      storage = string
      size    = number
    })), [])
    meta = object({
      cloud_provider = string
      service_name   = string
      service_account = object({
        username = string
        password = string
      })
    })
  }))
}

variable "tags" {
  type        = set(string)
  description = "Tags to be added on instances."
}

variable "provision_sh" {
  type        = string
  description = "Provision Script to be executed."
}

variable "domain" {
  type = string
}

variable "ssh_keys" {
  type = map(string)
}
