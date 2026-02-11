# System identity
resource "routeros_system_identity" "identity" {
  name = "HomeLab-mikrotik"
}

# Interface lists
resource "routeros_interface_list" "home_lan" {
  name    = local.home_lan_list_name
  comment = "Managed by Terraform - Contains main bridge"
}

# Add the main bridge interface to the LAN list
resource "routeros_interface_list_member" "lan_bridge" {
  interface = routeros_bridge.main_bridge.name
  list      = routeros_interface_list.home_lan.name

  depends_on = [
    routeros_interface_list.home_lan,
    routeros_bridge.main_bridge,
  ]
}

# Bridge IP configuration
resource "routeros_ip_address" "bridge_ip" {
  address   = local.mikrotik_ip
  interface = routeros_bridge.main_bridge.name
  network   = local.network_cidr
  comment   = "Routing/Management IP for Bridge (Managed by Terraform)"

  depends_on = [routeros_bridge.main_bridge]
}

# Default route
resource "routeros_ip_route" "default_gw" {
  dst_address  = "0.0.0.0/0"
  gateway      = local.gateway_ip
  distance     = 1
  scope        = 30
  target_scope = 10

  lifecycle {
    ignore_changes = [routing_table]
  }
}

# IP settings
resource "routeros_ip_settings" "ip_settings" {
  ip_forward          = true
  send_redirects      = true
  accept_redirects    = false
  accept_source_route = false
  allow_fast_path     = true
  arp_timeout         = "30s"
  icmp_rate_limit     = 10
  tcp_syncookies      = false
}

# Quality of Service - Valaria Priority
resource "routeros_queue_simple" "valaria_priority" {
  name      = "valaria-priority"
  target    = [local.valaria_ip]
  max_limit = "100M/100M"
  priority  = "1/1"
  comment   = "Priority bandwidth for Valaria (Managed by Terraform)"
}
