resource "triton_machine" "consul" {
  count = "${var.consul_machine_count}"

  name = "${var.hashicorp_environment}-consul-${count.index}"

  package = "${var.consul_package}"
  image   = "${var.consul_image}"

  firewall_enabled = true

  networks = ["${var.consul_networks}"]

  tags {
    role = "${var.consul_role_tag}"
  }

  cns {
    services = ["${var.consul_cns_service_name}"]
  }

  metadata {
    consul_version          = "${var.consul_version}"
    consul_template_version = "${var.consul_template_version}"
    consul_cns_service_name = "${var.consul_cns_service_name}"
    consul_mode             = "server"
    consul_server_count     = "${var.consul_machine_count}"
  }
}
