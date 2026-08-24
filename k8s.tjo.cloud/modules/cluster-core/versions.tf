terraform {
  required_version = ">= 1.0"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">=2.17.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">=3.2.1"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">=1.19.0"
    }
  }
}
