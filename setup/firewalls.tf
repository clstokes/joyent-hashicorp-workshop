resource "triton_firewall_rule" "ssh" {
  rule        = "FROM any TO all vms ALLOW tcp PORT 22"
  enabled     = true
  description = "${var.environment} - Allow access from any TO all PORT 22."
}
