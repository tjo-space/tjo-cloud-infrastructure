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

variable "digitalocean_token" {
  type      = string
  sensitive = true
}

variable "proxmox_csi_username" {
  type = string
}
variable "proxmox_csi_token" {
  type      = string
  sensitive = true
}

variable "proxmox_ccm_username" {
  type = string
}
variable "proxmox_ccm_token" {
  type      = string
  sensitive = true
}
