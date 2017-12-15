data "triton_image" "ubuntu" {
  name        = "ubuntu-16.04"
  type        = "lx-dataset"
  most_recent = true
}

data "triton_network" "public" {
  name = "Joyent-SDC-Public"
}

data "triton_network" "private" {
  name = "My-Fabric-Network"
}

variable "bastion_name" {
  default = "bastion"
}

resource "triton_machine" "bastion" {
  name    = "${var.bastion_name}"
  package = "g4-general-4G"
  image   = "${data.triton_image.ubuntu.id}"

  firewall_enabled = true

  networks = [
    "${data.triton_network.public.id}",
    "${data.triton_network.private.id}",
  ]

  tags {
    role = "${var.bastion_name}"
  }

  cns {
    services = ["${var.bastion_name}"]
  }
}

resource "triton_firewall_rule" "ssh" {
  rule    = "FROM any TO vm ${triton_machine.bastion.id} ALLOW tcp PORT 22"
  enabled = true
}

output "bastion_ip" {
  value = "${triton_machine.bastion.primaryip}"
}
