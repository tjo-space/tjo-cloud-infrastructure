terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.61.1"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "1.4.0"
    }
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.2"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.14.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.31.0"
    }
    tailscale = {
      source  = "tailscale/tailscale"
      version = "0.16.1"
    }
  }

  required_version = "~> 1.7.3"
}

provider "proxmox" {
  # FIXME: Traefik/NGINX breaks this! 500 ERROR
  endpoint  = "https://178.63.49.225:8006/api2/json"
  insecure  = true
  api_token = var.proxmox_token
  ssh {
    agent    = true
    username = "root"
  }
}

provider "digitalocean" {
  token = var.digitalocean_token
}

provider "tailscale" {
  api_key = var.tailscale_apikey
}

provider "helm" {
  alias = "template"
}

provider "helm" {
  kubernetes {
    host                   = module.cluster.api.endpoint
    cluster_ca_certificate = base64decode(module.cluster.api.ca)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "kubectl"
      args = [
        "oidc-login",
        "get-token",
        "--oidc-issuer-url", var.oidc_issuer_url,
        "--oidc-client-id", var.oidc_client_id,
        "--oidc-extra-scope", "profile",
        "--grant-type", "password",
        "--username", var.oidc_username,
        "--password", var.oidc_password,
      ]
    }
  }
}

provider "kubernetes" {
  host                   = module.cluster.api.endpoint
  cluster_ca_certificate = base64decode(module.cluster.api.ca)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "kubectl"
    args = [
      "oidc-login",
      "get-token",
      "--oidc-issuer-url", var.oidc_issuer_url,
      "--oidc-client-id", var.oidc_client_id,
      "--oidc-extra-scope", "profile",
      "--grant-type", "password",
      "--username", var.oidc_username,
      "--password", var.oidc_password,
    ]
  }
}
