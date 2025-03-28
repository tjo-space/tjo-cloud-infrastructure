terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.73.2"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.7.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "1.4.0"
    }
    dnsimple = {
      source  = "dnsimple/dnsimple"
      version = "1.8.0"
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
      version = "2.36.0"
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

    node {
      name    = "batuu"
      address = "batuu.system.tjo.cloud"
      port    = 22
    }

    node {
      name    = "jakku"
      address = "jakku.system.tjo.cloud"
      port    = 22
    }

    node {
      name    = "nevaroo"
      address = "nevaroo.system.tjo.cloud"
      port    = 22
    }

    node {
      name    = "mustafar"
      address = "mustafar.system.tjo.cloud"
      port    = 22
    }

    node {
      name    = "endor"
      address = "endor.system.tjo.cloud"
      port    = 22
    }
  }
}

provider "dnsimple" {
  token   = var.dnsimple_token
  account = var.dnsimple_account_id
}

provider "helm" {
  alias = "template"
}

provider "helm" {
  kubernetes {
    host                   = module.cluster.api.internal.endpoint
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
  host                   = module.cluster.api.internal.endpoint
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
