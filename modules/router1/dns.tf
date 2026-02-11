# DNS server settings
resource "routeros_ip_dns" "dns_settings" {
  servers               = local.upstream_dns
  allow_remote_requests = true
  cache_size            = 4096
  cache_max_ttl         = "1w"
}

# Static DNS records for infrastructure
resource "routeros_ip_dns_record" "static_records" {
  for_each = local.static_dns

  name    = each.key
  address = each.value.address
  type    = each.value.type
  comment = "${each.value.comment} (Managed by Terraform)"

}
