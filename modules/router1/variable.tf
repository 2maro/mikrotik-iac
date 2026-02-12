variable "mikrotik_host" {
  description = "MikroTik Router API endpoint"
  type        = string
  default     = "api://192.168.1.2:8728"
}

variable "mikrotik_user" {
  description = "MikroTik admin username"
  type        = string
}

variable "mikrotik_password" {
  description = "MikroTik admin password"
  type        = string
  sensitive   = true
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

variable "valaria_mac_address" {
  description = "MAC address of Valaria PC"
  type        = string
}

variable "nox_mac_address" {
  description = "MAC address of NOX PC"
  type        = string
}

variable "k8s_domain" {
  description = "Domain for Kubernetes services (future external-dns use)"
  type        = string
  default     = "k8s.home.lab"
}
