variable "bastion_name" {
  default = "bastion"
}

resource "triton_machine" "bastion" {
  name    = "${var.bastion_name}"
  package = "g4-general-8G"
  image   = "8879c758-c0da-11e6-9e4b-93e32a67e805"

  firewall_enabled = true
}

resource "triton_firewall_rule" "ssh" {
  rule    = "FROM any TO vm ${triton_machine.bastion.id} ALLOW tcp PORT 22"
  enabled = true
}

output "bastion_ip" {
  value = "${triton_machine.bastion.primaryip}"
}
