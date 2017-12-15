variable "nginx_package" {
  default = "g4-general-8G"
}

variable "nginx_name" {
  default = "nginx"
}

data "triton_image" "nginx" {
  name        = "${var.nginx_name}"
  type        = "lx-dataset"
  most_recent = true
}

data "triton_network" "public" {
  name = "Joyent-SDC-Public"
}

data "triton_network" "private" {
  name = "My-Fabric-Network"
}

resource "triton_machine" "nginx" {
  name    = "${var.nginx_name}"
  package = "${var.nginx_package}"
  image   = "${data.triton_image.nginx.id}"

  firewall_enabled = true

  networks = [
    "${data.triton_network.public.id}",
    "${data.triton_network.private.id}",
  ]

  tags {
    role = "${var.nginx_name}"
  }

  cns {
    services = ["${var.nginx_name}"]
  }
}

resource "triton_firewall_rule" "ssh" {
  rule    = "FROM any TO vm ${triton_machine.nginx.id} ALLOW tcp PORT 22"
  enabled = true
}

resource "triton_firewall_rule" "http" {
  rule    = "FROM any TO vm ${triton_machine.nginx.id} ALLOW tcp PORT 80"
  enabled = true
}

output "nginx_ip" {
  value = ["${triton_machine.nginx.primaryip}"]
}
