variable "oidc_client_id" {
  type = string
}
variable "oidc_issuer_url" {
  type = string
}

variable "desec" {
  type = object({
    token = string
  })
}

variable "domains" {
  type = map(object({
    zone     = string
    domain   = string
    wildcard = optional(bool, true)
  }))
  description = "Domains to be managed via cert-manager and external-dns."
}
