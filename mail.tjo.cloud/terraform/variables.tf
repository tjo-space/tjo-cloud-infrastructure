variable "nodes" {
  type = set(string)
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

variable "dnsimple_token" {
  type      = string
  sensitive = true
}

variable "dnsimple_account_id" {
  type = string
}
