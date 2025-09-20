variable "nodes_hetzner_cloud" {
  type = map(object({
    datacenter  = string
    image       = optional(string, "ubuntu-24.04")
    server_type = optional(string, "cax11")
  }))
}

variable "domain" {
  type    = string
  default = "mail.tjo.cloud"
}

variable "ssh_keys" {
  type = map(string)
}

variable "proxmox_token" {
  type      = string
  sensitive = true
}

variable "zerotier_token" {
  sensitive = true
  type      = string
}

variable "mail_hcloud_token" {
  sensitive = true
  type      = string
}

variable "authentik_token" {
  type      = string
  sensitive = true
}

variable "desec_token" {
  type      = string
  sensitive = true
}
