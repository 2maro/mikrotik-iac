module "router1" {
  source = "./modules/router1"

  # Connection details
  mikrotik_host     = var.mikrotik_host
  mikrotik_user     = var.mikrotik_user
  mikrotik_password = var.mikrotik_password

  # SNMP monitoring
  snmp_auth_password = var.snmp_auth_password
  snmp_priv_password = var.snmp_priv_password

  # Device MAC addresses
  valaria_mac_address = var.valaria_mac_address
  nox_mac_address     = var.nox_mac_address

  # Kubernetes domain for external-dns
  k8s_domain = var.k8s_domain
}
