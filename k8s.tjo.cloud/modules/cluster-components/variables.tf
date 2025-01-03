variable "cluster_name" {
  description = "Name of the cluster."
  type        = string
}

variable "cluster_domain" {
  description = "Domain of the cluster."
  type        = string
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

variable "dnsimple_account_id" {
  type      = string
}
