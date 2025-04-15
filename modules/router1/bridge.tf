# Define the main bridge interface
resource "routeros_bridge" "main_bridge" {
  name              = local.bridge_name # Use local variable "bridge1"
  protocol_mode     = "none"            # Good for switching
  auto_mac          = true
  fast_forward      = true  # Enable hardware offloading where possible
  vlan_filtering    = false # Explicitly disable VLAN filtering as requested
  ingress_filtering = false # Usually false if vlan_filtering is false
  comment           = "Main Homelab Bridge"
}

# Define the LACP bond for Proxmox
resource "routeros_interface_bonding" "proxmox_bond" {
  name                 = "proxmox-bond"
  mode                 = "802.3ad"
  slaves               = ["ether2", "ether3"] # Ports dedicated to the bond
  transmit_hash_policy = "layer-2-and-3"
  link_monitoring      = "mii" # Standard link monitoring
  comment              = "LACP Bond for Proxmox Homelab"
}

# Add the physical interfaces directly to the bridge
resource "routeros_interface_bridge_port" "direct_ports_to_bridge" {
  for_each  = local.direct_bridge_members
  bridge    = routeros_bridge.main_bridge.name
  interface = each.value
  comment   = "Added by Terraform"
  # add vlans in the future deployment
}

# Add the bond interface to the bridge
resource "routeros_interface_bridge_port" "proxmox_bond_to_bridge" {
  bridge    = routeros_bridge.main_bridge.name
  interface = routeros_interface_bonding.proxmox_bond.name
  comment   = "Added by Terraform"
  # pvid = 1 # Not needed if vlan_filtering=false
  depends_on = [
    routeros_interface_bonding.proxmox_bond # Ensure bond exists first
  ]
}

# Define the LAN interface list (used by firewall rule)
resource "routeros_interface_list" "lan" {
  name    = "LAN"
  comment = "Managed by Terraform - Contains main bridge"
}

# Add the bridge interface to the LAN list
resource "routeros_interface_list_member" "lan_bridge" {
  interface = routeros_bridge.main_bridge.name
  list      = routeros_interface_list.lan.name
}
