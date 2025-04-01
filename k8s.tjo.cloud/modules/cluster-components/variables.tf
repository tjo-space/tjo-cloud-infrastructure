variable "oidc_client_id" {
  type = string
}
variable "oidc_issuer_url" {
  type = string
}

variable "dnsimple" {
  type = object({
    token      = string
    account_id = string
  })
}

variable "domains" {
  type = map(object({
    zone   = string
    domain = string
  }))
  description = "Domains to be managed via cert-manager and external-dns."
}
