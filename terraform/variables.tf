variable "nodes" {
  type = map(object({
    public = bool
    type   = string
    host   = string
  }))
}

variable "cluster_name" {
  type = string
}

variable "domain" {
  type = string
}

variable "tailscale_authkey" {
  type      = string
  sensitive = true
}
