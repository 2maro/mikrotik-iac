
variable "mikrotik_host" {
  description = "MikroTik Router IP"
  type        = string
}

variable "mikrotik_user" {
  description = "MikroTik username"
  type        = string
}

variable "mikrotik_password" {
  description = "MikroTik password"
  type        = string
  sensitive   = true
}

variable "vault_token" {
  description = "Vault token"
  type        = string
  sensitive   = true
}
variable "nox_mac_address" {
  description = "MAC address of builder PC"
  type        = string
}

variable "valaria_mac_address" {
  description = "MAC address of Valaria PC"
  type        = string
}

variable "snmp_auth_password" {
  description = "SNMP authentication password"
  type        = string
  sensitive   = true
}

variable "snmp_priv_password" {
  description = "SNMP privacy password"
  type        = string
  sensitive   = true
}

variable "ssh_user" {
  description = " Username for ssh connection"
  type        = string
  default     = "root"
}

variable "ssh_key_path" {
  description = "Path for ssh key"
  type        = string
  default     = "~/.ssh/id_rsa"
}
locals {
  # Define MikroTik Management IP here for consistency
  mikrotik_mgmt_ip = "192.168.1.2"
  network_cidr     = "192.168.1.0/24"
  gateway_ip       = "192.168.1.1" # Main Router IP
  bridge_name      = "bridge1"

  # Interfaces to add directly to the bridge
  direct_bridge_members = toset([
    "ether1", "ether4", "ether5", "ether6", "ether7", "ether8",
    "sfp9", "sfp10", "sfp11", "sfp12",
  ])

  # YAML data loading
  yaml_data           = yamldecode(file("${path.module}/main.yaml"))
  dns_records         = { for record in local.yaml_data.dns_records : record.name => record }
  tls_enabled_records = { for k, v in local.dns_records : k => v if lookup(v, "tls_enabled", false) == true }

  mikrotik_common_name = "mikrotik.home.lab"
}
