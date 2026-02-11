terraform {
  required_version = ">= 1.0"

  required_providers {
    routeros = {
      source  = "terraform-routeros/routeros"
      version = "1.86.0"
    }
  }
}

provider "routeros" {
  hosturl  = var.mikrotik_host
  username = var.mikrotik_user
  password = var.mikrotik_password
  insecure = true
}
