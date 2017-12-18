#
# Data Sources
#
data "triton_image" "ubuntu_kvm" {
  name        = "ubuntu-certified-16.04"
  type        = "zvol"
  most_recent = true
}

data "triton_network" "public" {
  name = "Joyent-SDC-Public"
}

data "triton_network" "private" {
  name = "My-Fabric-Network"
}

#
# Variables
#
variable "environment" {
  default = "hashicporp-env"
}

variable "package_kvm" {
  default = "k4-general-kvm-7.75G"
}

variable "consul_provision" {
  default = "true"
}

variable "consul_role_tag" {
  default = "consul"
}

variable "consul_client_access" {
  description = "See module documentation."
  type        = "list"
  default     = ["all vms"]
}

variable "vault_provision" {
  default = "true"
}

variable "vault_role_tag" {
  default = "vault"
}

variable "vault_client_access" {
  description = "See module documentation."
  type        = "list"
  default     = ["all vms"]
}

variable "nomad_provision" {
  default = "true"
}

variable "nomad_role_tag" {
  default = "nomad"
}

variable "nomad_client_access" {
  description = "See module documentation."
  type        = "list"
  default     = ["all vms"]
}

variable "bastion_user" {
  default = "ubuntu"
}

variable "bastion_role_tag" {
  default = "bastion"
}

#
# Outputs
#
output "consul_ip" {
  value = ["${module.hashicorp.consul_ip}"]
}

output "vault_ip" {
  value = ["${module.hashicorp.vault_ip}"]
}

output "nomad_ip" {
  value = ["${module.hashicorp.nomad_ip}"]
}

output "nomad_client_ip" {
  value = ["${module.hashicorp.nomad_client_ip}"]
}
