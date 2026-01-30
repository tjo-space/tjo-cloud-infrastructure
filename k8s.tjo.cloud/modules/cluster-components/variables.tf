variable "oidc_client_id" {
  type = string
}
variable "oidc_issuer_url" {
  type = string
}

variable "backup" {
  type = object({
    password             = string
    s3_bucket            = string
    s3_endpoint          = string
    s3_access_key_id     = string
    s3_secret_access_key = string
  })
  sensitive   = true
  description = "Backup Configuration"
}
