variable "cluster" {
  type = object({
    name = string
    load_balancer_cidr = object({
      ipv4 = string
      ipv6 = string
    })
  })
}

variable "proxmox" {
  type = object({
    name     = string
    url      = string
    insecure = optional(bool, false)
    token = object({
      id     = string
      secret = string
    })
  })
  sensitive = true
}

variable "hosts" {
  type = map(object({
    asn     = number
    storage = string
  }))
}
