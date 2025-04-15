variable "mikrotik_host" {
  type = string
}

variable "mikrotik_user" {
  type    = string
  default = "admin"
}

variable "mikrotik_password" {
  type      = string
  sensitive = true
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
  default     = "snmp-auth-password"
}

variable "snmp_priv_password" {
  description = "SNMP privacy password"
  type        = string
  sensitive   = true
  default     = "snmp-priv-password"
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
