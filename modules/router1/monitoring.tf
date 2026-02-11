# SNMP service configuration
resource "routeros_snmp" "monitoring_snmp" {
  enabled  = true
  contact  = "Homelab Admin (Terraform)"
  location = "Home (Terraform)"
}
# SNMP v3 user for Prometheus monitoring
resource "routeros_snmp_community" "prometheus_v3_user" {
  name                    = "prometheus"
  security                = "private"
  authentication_protocol = "SHA1"
  encryption_protocol     = "AES"
  authentication_password = var.snmp_auth_password
  encryption_password     = var.snmp_priv_password
  addresses               = [local.static_dns["monitoring.home.lab"].address]
  read_access             = true
  write_access            = false
  comment                 = "SNMPv3 User for Prometheus (Managed by Terraform)"
  depends_on              = [routeros_snmp.monitoring_snmp]
}
resource "routeros_system_logging_action" "alloy_syslog" {
  name               = "alloycollector"
  target             = "remote"
  remote             = local.static_dns["monitoring.home.lab"].address
  remote_port        = 1514
  remote_protocol    = "udp"
  remote_log_format  = "syslog"
  syslog_time_format = "iso8601"
}
resource "routeros_system_logging" "all_to_alloy" {
  topics     = ["!debug"] # Everything except debug logs
  action     = routeros_system_logging_action.alloy_syslog.name
  prefix     = "routeros"
  depends_on = [routeros_system_logging_action.alloy_syslog]
}
