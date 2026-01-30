variable "oidc_client_id" {
  type = string
}
variable "oidc_issuer_url" {
  type = string
}

variable "desec_token" {
  type      = string
  sensitive = true
}

variable "proxmox_token" {
  type      = string
  sensitive = true
}

variable "backup" {
  type = object({
    password             = string
    s3_access_key_id     = string
    s3_secret_access_key = string
  })
  sensitive = true
}
