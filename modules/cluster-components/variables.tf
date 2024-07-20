variable "loadbalancer_ips" {
  description = "Map of loadbalancer IPs."
  type        = map(object({ ipv4 = set(string), ipv6 = set(string) }))
}

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

variable "digitalocean_token" {
  type      = string
  sensitive = true
}
