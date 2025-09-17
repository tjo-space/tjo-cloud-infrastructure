variable "oidc_client_id" {
  type = string
}
variable "oidc_issuer_url" {
  type = string
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

variable "proxmox_token" {
  type      = string
  sensitive = true
}
