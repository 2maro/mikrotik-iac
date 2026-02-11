locals {
  # Network Configuration
  mikrotik_ip        = "192.168.1.2/24"
  network_cidr       = "192.168.1.0"
  gateway_ip         = "192.168.1.1"
  bridge_name        = "bridge1"
  home_lan_list_name = "home-lan"

  # Interface assignments - ALL interfaces go directly to bridge
  direct_bridge_members = toset([
    "ether1", "ether2", "ether3", "ether4", "ether5", "ether6", "ether7", "ether8",
    "sfp9", "sfp10", "sfp11", "sfp12",
  ])

  # DNS Configuration
  upstream_dns = ["8.8.8.8"]

  # Static DNS Records
  static_dns = {
    "mikrotik.home.lab"   = { address = "192.168.1.2", type = "A", comment = "RouterOS CRS112", tls_enabled = true },
    "proxmox.home.lab"    = { address = "192.168.1.3", type = "A", comment = "Proxmox Host", tls_enabled = true },
    "leith.home.lab"      = { address = "192.168.1.21", type = "A", comment = "Proxmox Host", tls_enabled = false },
    "builder.home.lab"    = { address = "192.168.1.22", type = "A", comment = "Proxmox Host", tls_enabled = false },
    "vault.home.lab"      = { address = "192.168.1.48", type = "A", comment = "Vault Server", tls_enabled = true },
    "storage.home.lab"    = { address = "192.168.1.118", type = "A", comment = "Storage Server", tls_enabled = false },
    "cicd.home.lab"       = { address = "192.168.1.121", type = "A", comment = "CI/CD Runner", tls_enabled = true },
    "netforge.home.lab"   = { address = "192.168.1.119", type = "A", comment = "Traefik Proxy", tls_enabled = true },
    "monitoring.home.lab" = { address = "192.168.1.116", type = "A", comment = "Grafana / Prometheus", tls_enabled = true },
    "master-1.home.lab"   = { address = "192.168.1.113", type = "A", comment = "K8s Master Node", tls_enabled = false },
    "worker-1.home.lab"   = { address = "192.168.1.117", type = "A", comment = "K8s Worker Node 1", tls_enabled = false },
    "worker-2.home.lab"   = { address = "192.168.1.112", type = "A", comment = "K8s Worker Node 2", tls_enabled = false }
  }

  valaria_ip = "192.168.1.21"

  # VLAN Configuration (for future expansion)
  vlans = {
    "Normal" = {
      name          = "Normal"
      vlan_id       = null
      network       = "192.168.1.0"
      cidr_suffix   = "24"
      gateway       = "192.168.1.1"
      dhcp_pool     = []
      dns_servers   = ["192.168.1.1"]
      domain        = "home.lab"
      static_leases = {}
    }
    "Guest" = {
      name          = "Guest"
      vlan_id       = 10
      network       = "172.16.10.0"
      cidr_suffix   = "24"
      gateway       = "172.16.10.1"
      dhcp_pool     = ["172.16.10.100-172.16.10.199"]
      dns_servers   = ["1.1.1.1", "8.8.8.8"]
      domain        = "guest.home.lab"
      static_leases = {}
    }
  }
}
