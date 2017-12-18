resource "triton_machine" "nomad" {
  count = "${var.nomad_machine_count}"

  name = "${var.hashicorp_environment}-nomad-${count.index}"

  package = "${var.nomad_package}"
  image   = "${var.nomad_image}"

  firewall_enabled = true

  networks = ["${var.nomad_networks}"]

  tags {
    role = "${var.nomad_role_tag}"
  }

  cns {
    services = ["${var.nomad_cns_service_name}"]
  }

  metadata {
    consul_version          = "${var.consul_version}"
    consul_template_version = "${var.consul_template_version}"
    consul_cns_service_name = "${var.consul_cns_service_name}"
    consul_mode             = "client"

    nomad_version       = "${var.nomad_version}"
    nomad_mode          = "server"
    nomad_machine_count = "${var.nomad_machine_count}"
  }

  depends_on = ["triton_machine.consul"]
}
