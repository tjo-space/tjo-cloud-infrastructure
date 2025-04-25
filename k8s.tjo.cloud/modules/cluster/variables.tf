variable "nodes" {
  type = map(object({
    id   = number
    type = string
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
    version    = optional(string, "v1.9.0")
    kubernetes = optional(string, "v1.32.0")
  })
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
        port      = optional(number, 6443)
      }), {})
    }), {})
    oidc = object({
      client_id  = string
      issuer_url = string
    })
    pod_cidr = object({
      ipv4 = string
      ipv6 = string
    })
    service_cidr = object({
      ipv4 = string
      ipv6 = string
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
