variable "username" {
  type        = string
  default     = "bine"
  description = "Linux Username"
}

variable "network" {
  type = object({
    devices = optional(
      list(object({
        bridge      = string
        mac_address = optional(string)
        ipv4 = optional(
          object({
            address = optional(string) // either ipv4 address or "dhcp"
            gateway = optional(string)
          }),
          { address = null }
        )
        ipv6 = optional(
          object({
            address = optional(string) // either ipv6 address or "dhcp" or "auto" for slaac
            gateway = optional(string)
          }),
          { address = "auto" }
        )
      })),
      [{ bridge = "vmbr2" }]
    )

    dns = optional(
      object({
        servers = set(string)
      }),
      { servers = ["fd74:6a6f:3030:53::53"] }
    )
  })
  description = "Network configuration."
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
    image   = string
  })
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
