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
  type = string
}

variable "domains" {
  type = object({
    privileged  = string
    usercontent = string
  })
  default = {
    privileged  = "k8s.tjo.cloud"
    usercontent = "usercontent.k8s.tjo.cloud"
  }
  description = "Domains to be managed via cert-manager and external-dns."
}
