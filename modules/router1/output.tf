output "tls_enabled_hosts" {
  description = "Hosts with TLS enabled"
  value = {
    for name, record in local.static_dns : name => record.address
    if record.tls_enabled == true
  }
}

output "non_tls_hosts" {
  description = "Hosts without TLS enabled"
  value = {
    for name, record in local.static_dns : name => record.address
    if record.tls_enabled == false
  }
}
