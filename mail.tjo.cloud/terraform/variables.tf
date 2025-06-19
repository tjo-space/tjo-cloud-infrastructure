variable "nodes" {
  type = set(string)
}

variable "domain" {
  type    = string
  default = "mail.tjo.cloud"
}

variable "ssh_keys" {
  type = list(string)
}

variable "hcloud_token" {
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
