locals {
  # Temporary file paths
  temp_mikrotik_cert_path = "${path.module}/temp_mikrotik_${local.mikrotik_common_name}.crt"
  temp_mikrotik_key_path  = "${path.module}/temp_mikrotik_${local.mikrotik_common_name}.key"

  tls_service = { "api-ssl" = 8729, "www-ssl" = 443 }

}

# Generate certificates for TLS-enabled services (excluding MikroTik itself here)
resource "vault_pki_secret_backend_cert" "tls_certs" {
  for_each    = { for k, v in local.tls_enabled_records : k => v if k != local.mikrotik_common_name }
  backend     = "pki_int" # Ensure this path exists in Vault
  name        = "homelab" # Ensure this role exists in Vault
  common_name = each.key
  ttl         = "720h" # 30 days
  auto_renew  = true
  # alt_names = [each.key] # Consider adding alt_names if needed
}

# Generate a specific certificate for the MikroTik router UI
resource "vault_pki_secret_backend_cert" "mikrotik_cert" {
  backend     = "pki_int"                  # Ensure this path exists in Vault
  name        = "homelab"                  # Ensure this role exists in Vault
  common_name = local.mikrotik_common_name # mikrotik.home.lab
  ttl         = "720h"                     # 30 days
  alt_names   = [local.mikrotik_common_name]
  ip_sans     = [local.mikrotik_mgmt_ip] # Add IP SAN for accessing via IP
  auto_renew  = true
}

# Create temporary files for the MikroTik certificate
resource "local_file" "temp_mikrotik_cert" {
  content  = vault_pki_secret_backend_cert.mikrotik_cert.certificate
  filename = local.temp_mikrotik_cert_path
}

resource "local_file" "temp_mikrotik_key" {
  content         = vault_pki_secret_backend_cert.mikrotik_cert.private_key
  filename        = local.temp_mikrotik_key_path
  file_permission = "0600" # Restrict permissions
}

# Import certificate into RouterOS certificate store
resource "routeros_system_certificate" "imported_mikrotik_cert" {
  name        = local.mikrotik_common_name # Name in RouterOS cert store
  common_name = vault_pki_secret_backend_cert.mikrotik_cert.common_name
  # The import block handles uploading from the temp files
  import {
    cert_file_name = local_file.temp_mikrotik_cert.filename
    key_file_name  = local_file.temp_mikrotik_key.filename
    # passphrase = "" # Add if your key has a passphrase
  }

  # Ensure temp files are created before attempting import
  depends_on = [local_file.temp_mikrotik_cert, local_file.temp_mikrotik_key]
}

# Clean up temporary MikroTik certificate files after import
resource "null_resource" "cleanup_temp_mikrotik_files" {
  # Trigger after the certificate resource is successfully applied
  triggers = {
    cert_id   = routeros_system_certificate.imported_mikrotik_cert.id
    cert_path = local.temp_mikrotik_cert_path
    key_path  = local.temp_mikrotik_key_path
  }

  provisioner "local-exec" {
    command = "rm -f ${local.temp_mikrotik_cert_path} ${local.temp_mikrotik_key_path}"
  }
  provisioner "local-exec" {
    command = "rm -f ${self.triggers.cert_path} ${self.triggers.key_path}"
  }
}



# Configure the HTTPS service (www-ssl) to use the imported certificate
resource "routeros_ip_service" "tls_services" {
  for_each = local.tls_service
  numbers  = each.key
  # address     = "0.0.0.0/0" # Default is usually fine
  port        = each.value                                              # Default is fine
  disabled    = false                                                   # Ensure it's enabled
  certificate = routeros_system_certificate.imported_mikrotik_cert.name # Use the name given in RouterOS
  depends_on  = [routeros_system_certificate.imported_mikrotik_cert]
}

# Deploy certificates to other hosts via SSH (Keep as is, review logic)
resource "null_resource" "direct_certificate_deployment" {
  for_each = { for k, v in local.tls_enabled_records : k => v if k != local.mikrotik_common_name }

  triggers = {
    certificate = vault_pki_secret_backend_cert.tls_certs[each.key].certificate
    private_key = vault_pki_secret_backend_cert.tls_certs[each.key].private_key
    host_ip     = each.value.address # Trigger if host IP changes in YAML
  }

  connection {
    type        = "ssh"
    host        = each.value.address # Assumes DNS is working or use IP
    user        = var.ssh_user
    private_key = file(pathexpand(var.ssh_key_path)) # Use pathexpand for ~
    timeout     = "5m"
  }

  # Create directories and set permissions (Idempotent)
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /etc/ssl/private /etc/ssl/certs",
      "chmod 755 /etc/ssl/certs",
      "chmod 700 /etc/ssl/private",
    ]
  }

  # Write certificate files to remote host
  provisioner "file" {
    content     = self.triggers.certificate # Use trigger value
    destination = "/etc/ssl/certs/${each.key}.crt"
  }
  provisioner "file" {
    content     = self.triggers.private_key # Use trigger value
    destination = "/etc/ssl/private/${each.key}.key"
  }
  provisioner "file" {
    # Include intermediate CA cert if provided by Vault resource
    content     = "${self.triggers.certificate}\n${vault_pki_secret_backend_cert.tls_certs[each.key].issuing_ca}"
    destination = "/etc/ssl/certs/${each.key}_fullchain.crt"
  }

  # Set permissions on deployed files
  provisioner "remote-exec" {
    inline = [
      "chmod 644 /etc/ssl/certs/${each.key}.crt /etc/ssl/certs/${each.key}_fullchain.crt",
      "chmod 600 /etc/ssl/private/${each.key}.key",
      "if command -v update-ca-trust >/dev/null; then update-ca-trust extract; elif command -v update-ca-certificates >/dev/null; then update-ca-certificates; fi",

    ]
  }
}
