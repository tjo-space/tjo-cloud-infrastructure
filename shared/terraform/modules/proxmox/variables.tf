variable "name" {
  type = string
}

variable "description" {
  type = string
}

variable "fqdn" {
  type = string
}

variable "host" {
  type = string
}

variable "memory" {
  type = number
}

variable "cores" {
  type = number
}

variable "boot" {
  type = object({
    storage = string
    size    = number
    image   = optional(string, "ubuntu_2404_server_cloudimg_amd64.img")
  })
}

variable "network" {
  type = object({
    ipv4 = optional(string, "dhcp")
    ipv6 = optional(string, "dhcp")
  })
  default = {
    ipv4 = "dhcp"
    ipv6 = "dhcp"
  }
}

variable "disks" {
  type = list(object({
    storage = string
    size    = number
  }))
  default = []
}

variable "userdata" {
  type        = any
  default     = {}
  description = "VM Userdata"
}

variable "metadata" {
  type = object({
    cloud_provider = string
    service_name   = string
    service_account = object({
      username = string
      password = string
    })
  })
  description = "VM Metadata"
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
