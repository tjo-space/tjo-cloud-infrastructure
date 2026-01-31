variable "nodes" {
  type = map(object({
    id   = number
    type = string # controlplane, worker
    host = string

    cores  = optional(number, 4)
    memory = optional(number, 4096)

    storage   = string
    boot_size = optional(number, 32)

    bootstrap = optional(bool, false)
  }))
}

variable "talos" {
  type = object({
    version    = string
    kubernetes = string
  })
}

variable "cluster" {
  type = object({
    name = string
    api = optional(object({
      internal = optional(object({
        domain    = optional(string, "tjo.cloud")
        subdomain = optional(string, "api.internal.k8s")
        port      = optional(number, 6443)
      }), {})
      public = optional(object({
        domain    = optional(string, "tjo.cloud")
        subdomain = optional(string, "api.k8s")
        port      = optional(number, 443)
      }), {})
    }), {})
    oidc = object({
      client_id  = string
      issuer_url = string
    })
    pod_cidr = object({
      ipv6 = string
    })
    service_cidr = object({
      ipv6 = string
    })
  })
}

variable "proxmox" {
  type = object({
    name     = string
    url      = string
    insecure = optional(bool, false)
  })
  sensitive = true
}
