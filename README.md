# MikroTik Homelab - Infrastructure as Code

Terraform configuration for managing a MikroTik CRS series switch/router in a homelab environment. Uses the [`terraform-routeros/routeros`](https://registry.terraform.io/providers/terraform-routeros/routeros/latest) provider to configure bridging, DNS, networking, QoS, and monitoring via the RouterOS API.

## Network Overview

```
Internet
   │
   ▼
┌──────────┐
│ Gateway  │  192.168.1.1
└────┬─────┘
     │
┌────┴─────────────────────────────────────────────────┐
│  MikroTik CRS (bridge1)           192.168.1.2        │
│  ether1-ether8, sfp9-sfp12                           │
│  Flat L2 domain, no VLAN filtering                   │
└──┬─────────┬──────────┬──────────┬───────────────────┘
   │         │          │          │
   ▼         ▼          ▼          ▼
 Proxmox   K8s       Storage    Other
 Hosts     Cluster   Server     Devices
```

### Services Behind Reverse Proxy (192.168.1.119)

Several services share the IP `192.168.1.119` and are routed through a **Traefik reverse proxy** that directs traffic based on the hostname. TLS termination is handled at the proxy.

| DNS Name | Service |
|---|---|
| `mikrotik.home.lab` | RouterOS CRS112 |
| `proxmox.home.lab` | Proxmox Host |
| `vault.home.lab` | Vault Server |
| `cicd.home.lab` | CI/CD Runner |
| `netforge.home.lab` | Traefik Proxy |
| `monitoring.home.lab` | Grafana / Prometheus |

### Direct Hosts

| DNS Name | IP | Service |
|---|---|---|
| `leith.home.lab` | 192.168.1.21 | Proxmox Host |
| `builder.home.lab` | 192.168.1.22 | Proxmox Host |
| `storage.home.lab` | 192.168.1.118 | Storage Server |
| `master-1.home.lab` | 192.168.1.113 | K8s Master Node |
| `worker-1.home.lab` | 192.168.1.117 | K8s Worker Node 1 |
| `worker-2.home.lab` | 192.168.1.112 | K8s Worker Node 2 |

## What's Managed

### Bridging (`bridge.tf`)
- Layer 2 bridge (`bridge1`) spanning all 12 physical ports (ether1-8, sfp9-12)
- Flat network with no VLAN filtering
- Hardware offloading enabled on bridge ports

### Networking (`networking.tf`)
- Static IP `192.168.1.2/24` on the bridge interface
- Default route via `192.168.1.1`
- IP forwarding enabled, fast path enabled
- Security hardening: source routing and redirects disabled
- Interface list (`home-lan`) grouping the bridge
- QoS simple queue giving `192.168.1.21` highest priority (100M/100M cap)

### DNS (`dns.tf`)
- Upstream resolver: Google DNS (`8.8.8.8`)
- Local caching enabled (4096 entries, 1 week max TTL)
- Remote requests allowed (serves as LAN DNS server)
- 12 static A records for internal services

### Monitoring (`monitoring.tf`)
- SNMPv3 with AuthPriv (SHA1 auth, AES encryption)
- Read-only `prometheus` user locked to the monitoring server IP
- Remote syslog (UDP/1514) forwarding all non-debug logs to Grafana Alloy
- ISO 8601 timestamp format, `routeros` log prefix

## Project Structure

```
.
├── main.tf                  # Module instantiation
├── provider.tf              # Provider config (routeros v1.86.0)
├── variable.tf              # Root variables
├── output.tf                # Exposes TLS/non-TLS host maps
├── terraform.tfvars         # Secrets (not committed)
└── modules/
    └── router1/
        ├── local.tf         # All configuration values and DNS records
        ├── bridge.tf        # Bridge and port membership
        ├── networking.tf    # IP, routing, QoS, system identity
        ├── dns.tf           # DNS server and static records
        ├── monitoring.tf    # SNMPv3 and syslog
        ├── variable.tf      # Module input variables
        ├── output.tf        # Filtered DNS outputs
        └── provider.tf      # Provider version constraint
```

## Prerequisites

- Terraform >= 1.0
- A MikroTik RouterOS device accessible via API (port 8728)
- Network access from the Terraform host to the router

## Setup

1. Clone the repo and initialize:
   ```bash
   git clone https://github.com/2maro/mikroTik-iac.git
   cd mikroTik-iac
   terraform init
   ```

2. Create `terraform.tfvars` (do **not** commit this file):
   ```hcl
   mikrotik_host      = "api://192.168.1.2:8728"
   mikrotik_user      = "admin"
   mikrotik_password   = ""
   snmp_auth_password  = ""
   snmp_priv_password  = ""
   valaria_mac_address = "AA:BB:CC:DD:EE:01"
   nox_mac_address     = "AA:BB:CC:DD:EE:02"
   ```

3. Review and apply:
   ```bash
   terraform plan
   terraform apply
   ```

## Outputs

| Output | Description |
|---|---|
| `tls_enabled_hosts` | Map of DNS records where TLS is enabled (proxy-fronted services) |
| `non_tls_hosts` | Map of DNS records accessed directly without TLS termination |

## Planned / Not Yet Implemented

The following are defined in locals but not yet wired up as resources:

- **VLAN segmentation** - Guest network (`172.16.10.0/24`, VLAN 10) is defined but no VLAN interfaces or filtering are configured
- **DHCP server** - No DHCP configuration exists yet
- **Firewall rules** - No filter or NAT rules are managed

## Notes

- The router uses `insecure = true` for the API connection (self-signed cert). If you set up proper TLS on the API, update `provider.tf`.
- State is stored locally (`terraform.tfstate`). For shared or production use, configure a remote backend.
- Always review `terraform plan` before applying -- bridge and routing changes can cause connectivity loss.
