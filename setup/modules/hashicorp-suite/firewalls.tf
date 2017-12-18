# TODO(clstokes): lock all this down.
resource "triton_firewall_rule" "ssh" {
  rule        = "FROM tag \"role\" = \"${var.bastion_role_tag}\" TO tag \"role\" = \"${var.consul_role_tag}\" ALLOW tcp PORT 22"
  enabled     = true
  description = "${var.hashicorp_environment} - Allow access from bastion hosts to Consul servers."
}

resource "triton_firewall_rule" "all_tcp" {
  rule        = "FROM all vms TO all vms ALLOW tcp PORT all"
  enabled     = true
  description = "${var.hashicorp_environment} - Allow ALL TCP internal access."
}

resource "triton_firewall_rule" "all_udp" {
  rule        = "FROM all vms TO all vms ALLOW udp PORT all"
  enabled     = true
  description = "${var.hashicorp_environment} - Allow ALL UDP internal access."
}
