resource "triton_machine" "nomad_client" {
  count = "${var.nomad_client_count}"

  name = "${var.hashicorp_environment}-nomad-client-${count.index}"

  package = "${var.nomad_package}"
  image   = "${var.nomad_image}"

  firewall_enabled = true

  networks = ["${var.nomad_networks}"]

  tags {
    role = "${var.nomad_client_role_tag}"
  }

  cns {
    services = ["${var.nomad_client_cns_service_name}"]
  }

  metadata {
    consul_version          = "${var.consul_version}"
    consul_template_version = "${var.consul_template_version}"
    consul_cns_service_name = "${var.consul_cns_service_name}"
    consul_mode             = "client"

    nomad_version = "${var.nomad_version}"
    nomad_mode    = "client"
  }

  depends_on = ["triton_machine.consul"]
}
