variable "nodes" {
  type = map(object({
    public = bool
    type   = string
    host   = string

    cores  = optional(number, 4)
    memory = optional(number, 4096)

    storage   = string
    boot_size = optional(number, 32)
  }))
}

variable "talos" {
  type = object({
    version    = optional(string, "v1.7.5")
    kubernetes = optional(string, "v1.30.0")

    # Default is:
    # customization:
    #   systemExtensions:
    #     officialExtensions:
    #         - siderolabs/kata-containers
    #         - siderolabs/qemu-guest-agent
    #         - siderolabs/tailscale
    #         - siderolabs/wasmedge
    schematic_id = optional(string, "a125b6d6becb63df5543edfae1231e351723dd6e4d551ba73e0f30229ad6ff59")
  })
}


variable "allow_scheduling_on_control_planes" {
  default     = false
  type        = bool
  description = "Allow scheduling on control plane nodes"
}

variable "cluster" {
  type = object({
    name   = string
    domain = string
    api = optional(object({
      subdomain = optional(string, "api")
      port      = optional(number, 6443)
    }), {})
    oidc = object({
      client_id  = string
      issuer_url = string
    })
  })
}

variable "tailscale_authkey" {
  type      = string
  sensitive = true
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
