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
    boot_image   = optional(string, "ubuntu_2404_server_cloudimg_amd64.img")
    ipv4         = optional(string, "dhcp")
    ipv6         = optional(string, "dhcp")
    userdata     = optional(any, {})
    disks = optional(list(object({
      storage = string
      size    = number
    })), [])
    tags = optional(set(string), [])
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
  default     = []
  description = "Tags to be added on instances."
}

variable "provision_sh" {
  type        = string
  description = "Provision Script to be executed."
}

variable "ssh_keys" {
  type = map(string)
}
