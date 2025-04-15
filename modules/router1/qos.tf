# Create a simple queue for Valaria to ensure priority
resource "routeros_queue_simple" "valaria_priority" {
  name      = "valaria-priority"
  target    = ["192.168.1.22"]
  max_limit = "100M/100M" # 100Mbps up/down
  priority  = "1/1"       # High priority (1 is highest, 8 is lowest)
  comment   = "Priority bandwidth for Valaria"
}
