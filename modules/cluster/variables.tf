variable "nodes" {
  type = map(object({
    public = bool
    type   = string
    host   = string

    cores  = optional(number, 4)
    memory = optional(string, 4096)

    boot_pool = string
    boot_size = optional(string, "32G")
  }))
}

variable "versions" {
  type = object({
    talos      = optional(string, "v1.7.5")
    kubernetes = optional(string, "v1.30.0")
  })
}

variable "iso" {
  type        = string
  description = "Downloaded from factory.talos.dev, select quemu agent and tailscale extensions."
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
