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
