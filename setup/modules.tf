#
# Modules
#
module "bastion" {
  source = "modules/bastion"

  bastion_environment = "${var.environment}"

  bastion_role_tag = "${var.bastion_role_tag}"
  bastion_user     = "${var.bastion_user}"

  bastion_package = "${var.package_kvm}"
  bastion_image   = "${data.triton_image.ubuntu_kvm.id}"

  # Public and Private
  bastion_networks = [
    "${data.triton_network.public.id}",
    "${data.triton_network.private.id}",
  ]
}

module "hashicorp" {
  source = "modules/hashicorp-suite"

  hashicorp_environment = "${var.environment}"

  bastion_role_tag = "${var.bastion_role_tag}"
  bastion_user     = "${module.bastion.bastion_user}"
  bastion_host     = "${module.bastion.bastion_ip[0]}"

  consul_package = "${var.package_kvm}"
  consul_image   = "${data.triton_image.ubuntu_kvm.id}"

  # Public and Private
  consul_networks = [
    "${data.triton_network.public.id}",
    "${data.triton_network.private.id}",
  ]

  consul_provision     = "${var.consul_provision}"
  consul_client_access = ["${var.consul_client_access}"]

  # Vault is KVM only to support memory locking.
  vault_package = "${var.package_kvm}"
  vault_image   = "${data.triton_image.ubuntu_kvm.id}"

  # Public and Private
  vault_networks = [
    "${data.triton_network.public.id}",
    "${data.triton_network.private.id}",
  ]

  vault_provision     = "${var.vault_provision}"
  vault_client_access = ["${var.vault_client_access}"]

  # Nomad is KVM only to support Docker.
  nomad_package = "${var.package_kvm}"
  nomad_image   = "${data.triton_image.ubuntu_kvm.id}"

  # Public and Private
  nomad_networks = [
    "${data.triton_network.public.id}",
    "${data.triton_network.private.id}",
  ]

  nomad_provision     = "${var.nomad_provision}"
  nomad_client_access = ["${var.nomad_client_access}"]
}
