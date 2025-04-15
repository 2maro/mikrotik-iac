# These are simple firewall rules. Need to improve them for a more comprehensive setup.
# Address list for the entire LAN subnet
resource "routeros_ip_firewall_addr_list" "lan_addresses" {
  list    = "lan_subnet"       # Using a different name to avoid conflict with Interface List "LAN"
  address = local.network_cidr # 192.168.1.0/24
  comment = "Managed by Terraform"
}

# Address list specifically for Valaria (optional, could use IP directly in rules)
resource "routeros_ip_firewall_addr_list" "valaria" {
  list    = "VALARIA_IP"
  address = "192.168.1.22" # Match static lease
  comment = "Managed by Terraform"
}

# --- Basic Filter Rules ---

# Drop invalid connections (Good practice)
resource "routeros_ip_firewall_filter" "drop_invalid" {
  chain            = "input" # Protect the router itself
  action           = "drop"
  connection_state = "invalid"
  comment          = "Drop invalid input connections"
  place_before     = "*" # Place early
}

resource "routeros_ip_firewall_filter" "drop_invalid_forward" {
  chain            = "forward" # Protect traffic passing through
  action           = "drop"
  connection_state = "invalid"
  comment          = "Drop invalid forwarded connections"
  place_before     = "*" # Place early
}

# Allow established/related connections (Standard rule)
resource "routeros_ip_firewall_filter" "allow_established_related_input" {
  chain            = "input"
  action           = "accept"
  connection_state = "established,related"
  comment          = "Accept established/related input"
  place_before     = "*" # Place early, after drop invalid
}

resource "routeros_ip_firewall_filter" "allow_established_related_forward" {
  chain            = "forward"
  action           = "accept"
  connection_state = "established,related"
  comment          = "Accept established/related forward"
  place_before     = "*" # Place early, after drop invalid
}

# Allow access FROM the LAN bridge TO the router (input chain)
resource "routeros_ip_firewall_filter" "allow_lan_to_router" {
  chain        = "input"
  action       = "accept"
  in_interface = local.bridge_name # Accept from bridge1
  comment      = "Allow input from LAN bridge"
  # place_before = <rule number or *> # Adjust placement as needed
}


# Block External DNS Requests trying to bypass MikroTik DNS
# Block requests coming from OUTSIDE the bridge trying to reach port 53 INSIDE
resource "routeros_ip_firewall_filter" "block_external_dns_udp" {
  chain        = "forward"
  action       = "drop"
  protocol     = "udp"
  dst_port     = 53
  in_interface = "!${local.bridge_name}" # If NOT coming from bridge1
  comment      = "Block non-LAN DNS queries (UDP)"
}

resource "routeros_ip_firewall_filter" "block_external_dns_tcp" {
  chain        = "forward"
  action       = "drop"
  protocol     = "tcp"
  dst_port     = 53
  in_interface = "!${local.bridge_name}" # If NOT coming from bridge1
  comment      = "Block non-LAN DNS queries (TCP)"
}

