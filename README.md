# My MikroTik Homelab Setup - Managed by Terraform & Vault

This repository contains the Terraform configuration I use to manage the core network settings on my MikroTik router (likely a CRS3xx series device acting as my main switch/router) within my homelab. The goal is to automate the setup and keep things consistent, especially for bridging, DHCP, DNS, basic firewalling, and TLS certificate management.

It leverages the `terraform-routeros/routeros` provider for interacting with the MikroTik API and the `hashicorp/vault` provider for handling PKI / TLS certificates.

## What This Configuration Does:

*   **Bridging:** Creates a main network bridge (`bridge1`) to act as the primary L2 domain.
    *   Adds most physical Ethernet and SFP+ ports directly to the bridge.
    *   Sets up an LACP bond (`proxmox-bond` using `ether2` and `ether3`) for my Proxmox server and adds it to the bridge.
    *   *Note:* VLAN filtering is currently **disabled** on the bridge for a simpler flat network setup.
*   **IP Addressing:** Assigns a static IP (`192.168.1.2/24`) to the bridge interface for management and services. Configures the default route via my main internet gateway (`192.168.1.1`).
*   **DHCP Server:** Runs a DHCP server on the bridge (`bridge1`):
    *   Provides dynamic IPs from the `192.168.1.100-192.168.1.200` range.
    *   Assigns static leases for specific devices (`Valaria` and `Nox`) based on their MAC addresses.
    *   Hands out the MikroTik itself (`192.168.1.2`) as the DNS server.
*   **DNS:**
    *   Configures the MikroTik to use external DNS servers (Cloudflare/Google) for lookups it can't resolve locally.
    *   Enables the MikroTik's DNS cache and allows requests from the LAN.
    *   Manages static DNS A records for internal services based on the `main.yaml` file.
*   **Firewall:** Implements a basic stateful firewall:
    *   Drops invalid connections.
    *   Allows established/related traffic.
    *   Allows traffic *from* the LAN (`bridge1`) *to* the router itself (for management, DNS, DHCP).
    *   Blocks DNS requests from *outside* the main bridge trying to reach internal clients (prevents DNS hijacking attempts).
    *   Uses an address list (`lan_subnet`) for the local network range.
*   **Vault PKI Integration:**
    *   Connects to a HashiCorp Vault instance (`http://192.168.1.50:8200`).
    *   Generates TLS certificates automatically using Vault's PKI engine (`pki_int` backend, `homelab` role) for services listed in `main.yaml` marked with `tls_enabled: true`.
    *   Specifically generates, downloads, and imports a certificate for the MikroTik's WebFig/API (`mikrotik.home.lab`) into the RouterOS certificate store.
    *   Enables the `www-ssl` (HTTPS) and `api-ssl` services on the MikroTik, assigning the imported Vault certificate.
    *   Deploys certificates (public cert, private key, full chain) via SSH to other specified Linux hosts (like Proxmox, Vault server itself, etc.) for use by their services (e.g., web UIs).
*   **SNMP:** Configures SNMPv3 (AuthPriv SHA1/AES) for secure monitoring, specifically allowing access for my Prometheus server (`192.168.1.45`).
*   **Quality of Service (QoS):** Creates a basic Simple Queue to give `Valaria`'s machine (`192.168.1.22`) higher network priority.
*   **System:** Sets the router's identity name (`HomeLab-mikrotik`).

## Prerequisites

Before you can run this, you'll need:

1.  **Terraform:** Version `1.0.0` or newer installed.
2.  **MikroTik Device:** A RouterOS device accessible on the network. Tested loosely with RouterOS v6/v7 but compatibility depends heavily on the provider version.
3.  **Vault Instance:** A running HashiCorp Vault server accessible at `http://192.168.1.50:8200`.
    *   The PKI secrets engine must be enabled at the path `pki_int`.
    *   A PKI role named `homelab` must exist within the `pki_int` backend, configured to issue certificates for your `home.lab` domain(s).
4.  **Vault Token:** A Vault token with permissions to issue certificates from the `pki_int/roles/homelab` path.
5.  **SSH Access:** SSH key-based access (without password prompt) from the machine running Terraform *to* the hosts listed in `main.yaml` that require certificate deployment (`tls_enabled: true`). The default setup assumes:
    *   SSH user: `root`
    *   SSH private key path: `~/.ssh/id_rsa` (configurable via variables).
6.  **Network Connectivity:** The machine running Terraform needs network access to the MikroTik API (port 8728 or 8729 for SSL) and the Vault API (port 8200).

## Configuration

1.  **Clone the Repository:**
    ```bash
    git clone <your-repo-url>
    cd <your-repo-directory>
    ```
2.  **Create `terraform.tfvars`:** This file holds your secrets. **Do not commit this file to Git!** Create a `terraform.tfvars` file in the root directory with the following content:
    ```hcl
    mikrotik_host       = "192.168.1.2" # Or your MikroTik's IP/hostname
    mikrotik_user       = "admin"       # Your MikroTik admin username
    mikrotik_password   = "YOUR_MIKROTIK_PASSWORD"
    vault_token         = "YOUR_VAULT_TOKEN"
    valaria_mac_address = "AA:BB:CC:DD:EE:01" # MAC for Valaria PC
    nox_mac_address     = "AA:BB:CC:DD:EE:02" # MAC for Nox PC

    # Optional: Override defaults if needed
    # snmp_auth_password = "your_secure_snmp_auth_password"
    # snmp_priv_password = "your_secure_snmp_priv_password"
    # ssh_user           = "your_ssh_user"
    # ssh_key_path       = "~/.ssh/your_private_key"
    ```
3.  **Create/Edit `main.yaml`:** This file defines the DNS records and which services need TLS certificates managed by Vault. Place it in the same directory as your `main.tf`.
    ```yaml
    ---
    dns_records:
      - name: mikrotik.home.lab # Used for the router itself
        address: 192.168.1.2
        tls_enabled: true       # Gets a cert imported to RouterOS
      - name: vault.home.lab
        address: 192.168.1.50
        tls_enabled: true       # Gets a cert deployed via SSH
      - name: nas.home.lab
        address: 192.168.1.5
        tls_enabled: false      # Just a DNS record, no cert needed
      - name: proxmox.home.lab
        address: 192.168.1.3
        tls_enabled: true       # Gets a cert deployed via SSH
      - name: monitoring.home.lab # Prometheus/Grafana
        address: 192.168.1.45
        tls_enabled: true       # Gets a cert deployed via SSH
    ```

## Usage

Standard Terraform workflow applies:

1.  **Initialize:** Download the necessary providers.
    ```bash
    terraform init
    ```
2.  **Plan:** Review the changes Terraform intends to make.
    ```bash
    terraform plan
    ```
3.  **Apply:** Apply the changes to your MikroTik router and deploy certificates.
    ```bash
    terraform apply
    ```

## Important Notes & Caveats

*   **Network Addresses:** This configuration assumes a `192.168.1.0/24` network with the MikroTik at `.2` and the gateway at `.1`. Adjust the `locals` block and relevant resources if your network differs.
*   **Firewall:** The firewall rules are **basic**. This is not a comprehensive security setup. Review and enhance it based on your specific security needs.
*   **Vault PKI:** Ensure your Vault PKI backend and role are correctly configured *before* running Terraform. Incorrect Vault setup will cause errors during the `apply` phase.
*   **SSH Deployment:** Certificate deployment relies on direct SSH access and specific file paths (`/etc/ssl/certs/`, `/etc/ssl/private/`) on the target Linux hosts. Ensure the specified `ssh_user` has permissions to write to these locations and execute basic commands (`mkdir`, `chmod`, `update-ca-trust`/`update-ca-certificates`).
*   **Temporary Files:** When importing the MikroTik certificate, temporary `.crt` and `.key` files are created locally in the Terraform directory and then cleaned up.
*   **Idempotency:** The configuration aims to be idempotent, meaning running `terraform apply` multiple times should result in the same state without unnecessary changes (though certificate renewals *will* trigger updates).
*   **Use with Caution:** Applying network changes, especially firewall rules or bridge configurations, can potentially disrupt connectivity. Always review the `terraform plan` carefully.
