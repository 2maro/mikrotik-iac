module "router1" {
  source              = "./modules/router1"
  mikrotik_host       = var.mikrotik_host
  mikrotik_user       = var.mikrotik_user
  mikrotik_password   = var.mikrotik_password
  vault_token         = var.vault_token
  snmp_auth_password  = var.snmp_auth_password
  snmp_priv_password  = var.snmp_priv_password
  ssh_user            = var.ssh_user
  ssh_key_path        = var.ssh_key_path
  valaria_mac_address = var.valaria_mac_address
  nox_mac_address     = var.nox_mac_address

}
