# Base SNMP Configuration
resource "routeros_snmp" "monitoring_snmp" {
  enabled  = true
  contact  = "Homelab Admin (Terraform)"
  location = "Home (Terraform)"
}

# SNMP Community for secure monitoring (SNMPv3 User)
resource "routeros_snmp_community" "prometheus_v3_user" {
  name                    = "prometheus" # Username for SNMPv3
  security                = "private"    # AuthPriv
  authentication_protocol = "SHA1"       # SHA1 or MD5
  encryption_protocol     = "AES"        # AES or DES
  authentication_password = var.snmp_auth_password
  encryption_password     = var.snmp_priv_password
  addresses               = ["192.168.1.45"]
  comment                 = "SNMPv3 User for Prometheus (Managed by Terraform)"
}

