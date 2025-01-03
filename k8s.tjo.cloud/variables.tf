variable "oidc_username" {
  type = string
}
variable "oidc_password" {
  type      = string
  sensitive = true
}
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

variable "proxmox_token" {
  type      = string
  sensitive = true
}
