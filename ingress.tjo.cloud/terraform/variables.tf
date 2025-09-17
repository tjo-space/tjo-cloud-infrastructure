variable "nodes_hetzner_cloud" {
  type = map(object({
    datacenter  = string
    image       = optional(string, "ubuntu-24.04")
    server_type = optional(string, "cax11")
  }))
}

variable "domain" {
  type    = string
  default = "ingress.tjo.cloud"
}

variable "ssh_keys" {
  type = map(string)
}

variable "zerotier_token" {
  sensitive = true
  type      = string
}

variable "ingress_hcloud_token" {
  sensitive = true
  type      = string
}

variable "authentik_token" {
  type      = string
  sensitive = true
}

variable "dnsimple_token" {
  type      = string
  sensitive = true
}

variable "desec_token" {
  type      = string
  sensitive = true
}

variable "dnsimple_account_id" {
  type = string
}

variable "zones" {
  type = set(string)
}

variable "records" {
  type = map(object({
    to   = string
    ttl  = optional(number, 600)
    type = optional(string, "ALIAS")
  }))
}

variable "proxmox_token" {
  type      = string
  sensitive = true
}
variable "tailscale_apikey" {
  type      = string
  sensitive = true
}
