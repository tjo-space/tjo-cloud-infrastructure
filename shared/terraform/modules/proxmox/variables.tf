variable "username" {
  type        = string
  default     = "bine"
  description = "Linux Username"
}

variable "network_bridge" {
  type        = string
  default     = "vmbr2"
  description = "Bridge to be used for network interface."
}

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
    index   = optional(number, null)
  }))
  default     = []
  description = "Disks to be attached to vm"
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
  default     = ""
  description = "Provision Script to be executed."
}

variable "ssh_keys" {
  type = map(string)
}

variable "hostpci" {
  default = []
  type = list(object({
    device  = string
    mapping = string
    pcie    = bool
    rombar  = bool
    xvga    = bool
  }))
  description = <<EOF
  See: https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm#hostpci-1
  EOF
}
