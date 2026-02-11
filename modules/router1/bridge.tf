# Main bridge configuration
resource "routeros_bridge" "main_bridge" {
  name          = local.bridge_name
  auto_mac      = true
  protocol_mode = "none"
  fast_forward  = true
  igmp_snooping = false
  comment       = "Main Homelab Brige (Manage by Terraform)"
}
resource "routeros_interface_bridge_port" "direct_ports_to_bridge" {
  for_each = local.direct_bridge_members

  bridge    = routeros_bridge.main_bridge.name
  interface = each.value
  comment   = "Direct port to bridge (Managed by Terraform)"
  hw        = true

  depends_on = [routeros_bridge.main_bridge]

  lifecycle {
    ignore_changes = [
      # Ignore changes that might cause recreation
      bridge,
      interface,
      hw
    ]
  }
}
