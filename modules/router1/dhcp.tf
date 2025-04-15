# Define the DHCP IP Pool
resource "routeros_ip_pool" "main_pool" {
  name    = "main-dhcp-pool"                # Slightly more descriptive name
  ranges  = ["192.168.1.100-192.168.1.200"] # Main dynamic range
  comment = "Managed by Terraform"
}


# Configure the DHCP Server
resource "routeros_ip_dhcp_server" "main_dhcp" {
  name          = "main-dhcp-server"
  interface     = routeros_bridge.main_bridge.name
  address_pool  = routeros_ip_pool.main_pool.name
  lease_time    = "1d"
  authoritative = "yes"
  comment       = "Managed by Terraform"

  depends_on = [routeros_ip_address.bridge_ip] # Ensure bridge has IP first
}

resource "routeros_ip_dhcp_server_network" "main_network" {
  address    = local.network_cidr
  gateway    = local.gateway_ip
  dns_server = [local.mikrotik_mgmt_ip]
  comment    = "Managed by Terraform"
}


# Static Lease for Valaria
resource "routeros_ip_dhcp_server_lease" "valaria" {
  address     = "192.168.1.22"
  mac_address = var.valaria_mac_address
  comment     = "Valaria - Static IP (Managed by Terraform)"
  server      = routeros_ip_dhcp_server.main_dhcp.name
}

# Static Lease for Nox
resource "routeros_ip_dhcp_server_lease" "nox" {
  address     = "192.168.1.21"
  mac_address = var.nox_mac_address
  comment     = "Nox - Static IP (Managed by Terraform)"
  server      = routeros_ip_dhcp_server.main_dhcp.name
}
