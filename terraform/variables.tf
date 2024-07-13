variable "nodes" {
  type = map(object({
    public = bool
    type   = string
    host   = string
  }))
}

variable "talos_version" {
  type    = string
  default = "v1.7.5"
}

variable "kubernetes_version" {
  type    = string
  default = "v1.30.0"
}

variable "cluster_name" {
  type = string
}

variable "domain" {
  type = string
}

variable "tailscale_authkey" {
  type      = string
  sensitive = true
}

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
