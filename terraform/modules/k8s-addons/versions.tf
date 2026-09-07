terraform {
  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
    }
    http = {
      source = "hashicorp/http"
    }
    helm = {
      source = "hashicorp/helm"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}
