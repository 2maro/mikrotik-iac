terraform {
  required_version = ">= 1.0.0"
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
provider "routeros" {
  hosturl = var.mikrotik_host # MikroTik Router IP
  #hosturl  = 192.168.1.2 # MikroTik Router IP
  username = var.mikrotik_user # MikroTik username
  password = var.mikrotik_password
  insecure = true
}

provider "vault" {
  address = "http://192.168.1.50:8200"
  token   = var.vault_token
}
