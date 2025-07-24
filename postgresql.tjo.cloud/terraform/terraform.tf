terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.78.1"
    }
    authentik = {
      source  = "goauthentik/authentik"
      version = "2025.4.0"
    }
    dnsimple = {
      source  = "dnsimple/dnsimple"
      version = "1.8.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.37.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.1"
    }
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "1.25.0"
    }
    dotenv = {
      source  = "germanbrew/dotenv"
      version = "1.2.6"
    }
  }

  required_version = "~> 1.9.0"
}

provider "dnsimple" {
  token   = var.dnsimple_token
  account = var.dnsimple_account_id
}

provider "authentik" {
  url   = "https://id.tjo.space"
  token = var.authentik_token
}

provider "proxmox" {
  # FIXME: Traefik/NGINX breaks this! 500 ERROR
  endpoint  = "https://batuu.system.tjo.cloud:8006/api2/json"
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

provider "kubernetes" {
  config_path = "${path.module}/../../k8s.tjo.cloud/kubeconfig"
}

provider "postgresql" {
  alias    = "for_node"
  for_each = var.nodes

  host            = split("/", each.value.ipv4)[0]
  port            = 5432
  database        = "postgres"
  username        = "postgres"
  password        = provider::dotenv::get_by_key("POSTGRESQL_PASSWORD", "${path.module}/../secrets.env")
  sslmode         = "disable"
  connect_timeout = 15
}
