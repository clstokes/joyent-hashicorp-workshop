resource "triton_machine" "vault" {
  count = "${var.vault_machine_count}"

  name = "${var.hashicorp_environment}-vault-${count.index}"

  package = "${var.vault_package}"
  image   = "${var.vault_image}"

  firewall_enabled = true

  networks = ["${var.vault_networks}"]

  tags {
    role = "${var.vault_role_tag}"
  }

  cns {
    services = ["${var.vault_cns_service_name}"]
  }

  metadata {
    consul_version          = "${var.consul_version}"
    consul_template_version = "${var.consul_template_version}"
    consul_cns_service_name = "${var.consul_cns_service_name}"
    consul_mode             = "client"

    vault_version          = "${var.vault_version}"
    vault_cns_service_name = "${var.vault_cns_service_name}"
  }

  depends_on = ["triton_machine.consul"]
}
