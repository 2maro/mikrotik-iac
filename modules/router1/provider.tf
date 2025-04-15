terraform {
  required_providers {
    routeros = {
      source  = "terraform-routeros/routeros"
      version = "1.76.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.18.0"
    }
  }
}

