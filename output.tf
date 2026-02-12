output "tls_enabled_hosts" {
  description = "Hosts with TLS enabled"
  value       = module.router1.tls_enabled_hosts
}

output "non_tls_hosts" {
  description = "Hosts without TLS enabled"
  value       = module.router1.non_tls_hosts
}
