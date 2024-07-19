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
    #  customization:
    #    systemExtensions:
    #      officialExtensions:
    #          - siderolabs/kata-containers
    #          - siderolabs/qemu-guest-agent
    #          - siderolabs/tailscale
    schematic_id = optional(string, "a3f29a65dfd32b73c76f14eef96ef7588cf08c7d737d24fae9b8216d1ffa5c3d")
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
