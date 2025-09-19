variable "id_hcloud_token" {
  sensitive = true
  type      = string
}

variable "dnsimple_token" {
  sensitive = true
  type      = string
}

variable "dnsimple_account_id" {
  type = string
}

variable "ssh_keys" {
  type = map(string)
}

variable "nodes" {
  type = list(string)
}

variable "domain" {
  type = object({
    name = string
    zone = string
  })
}

variable "additional_domains" {
  type = list(object({
    name = string
    zone = string
  }))
}

variable "desec_token" {
  type      = string
  sensitive = true
}
