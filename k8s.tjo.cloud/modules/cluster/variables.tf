variable "nodes" {
  type = map(object({
    id   = number
    type = string
    host = string

    cores  = optional(number, 4)
    memory = optional(number, 4096)

    storage   = string
    boot_size = optional(number, 32)
  }))
}

variable "talos" {
  type = object({
    version    = optional(string, "v1.8.3")
    kubernetes = optional(string, "v1.31.0")

    # Default is:
    # customization:
    #   systemExtensions:
    #     officialExtensions:
    #         - siderolabs/kata-containers
    #         - siderolabs/qemu-guest-agent
    #         - siderolabs/wasmedge
    schematic_id = optional(string, "392092063ce5c8be7dfeba0bd466add2bc0b55a20939cc2c0060058fcc25d784")
  })
}


variable "allow_scheduling_on_control_planes" {
  default     = false
  type        = bool
  description = "Allow scheduling on control plane nodes"
}

variable "cluster" {
  type = object({
    name = string
    api = optional(object({
      internal = optional(object({
        domain    = optional(string, "k8s.tjo.cloud")
        subdomain = optional(string, "api.internal")
        port      = optional(number, 6443)
      }), {})
      public = optional(object({
        domain    = optional(string, "k8s.tjo.cloud")
        subdomain = optional(string, "api")
        port      = optional(number, 443)
      }), {})
    }), {})
    oidc = object({
      client_id  = string
      issuer_url = string
    })
  })
}

variable "proxmox" {
  type = object({
    name           = string
    url            = string
    insecure       = optional(bool, false)
    common_storage = string
  })
  sensitive = true
}
