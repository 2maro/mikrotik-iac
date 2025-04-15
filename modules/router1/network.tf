# Assign IP address to the Bridge interface for management, DHCP, DNS
resource "routeros_ip_address" "bridge_ip" {
  address   = "${local.mikrotik_mgmt_ip}/24"
  interface = routeros_bridge.main_bridge.name
  network   = cidrhost(local.network_cidr, 0)
  comment   = "Management IP for Bridge"
}

# Define the default route via the main router
resource "routeros_ip_route" "default_gw" {
  gateway     = local.gateway_ip
  dst_address = "0.0.0.0/0"
  comment     = "Default route via main router"
  # Optional: check_gateway = "ping"
}

# Configure DNS settings on the MikroTik
resource "routeros_ip_dns" "dns_settings" {
  servers               = ["1.1.1.1", "8.8.8.8"]
  allow_remote_requests = true
  cache_size            = 4096
  cache_max_ttl         = "1w"
}

# Create DNS entries for all records from YAML
resource "routeros_ip_dns_record" "dns_entries" {
  for_each = local.dns_records
  name     = each.key
  address  = each.value.address
  type     = "A"
  ttl      = "1h"
  comment  = "Managed by Terraform from YAML"
}
