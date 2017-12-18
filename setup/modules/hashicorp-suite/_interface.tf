terraform {
  required_version = "~> 0.11.0"
}

#
# Providers.
#
provider "triton" {
  version = "~> 0.3.0"
}

#
# Variables
#
variable "hashicorp_environment" {
  description = "The name of the environment."
  type        = "string"
}

variable "private_key_path" {
  description = "Path to the private key to use for connecting to machines."
  type        = "string"
  default     = "~/.ssh/id_rsa"
}

#
# Consul Variables
#
variable "consul_image" {
  description = "The image to deploy as the Consul machine(s)."
  type        = "string"
}

variable "consul_package" {
  description = "The package to deploy as the Consul machine(s)."
  type        = "string"
}

variable "consul_user" {
  description = "The User to use for provisioning the machine(s)."
  type        = "string"
  default     = "ubuntu"
}

variable "consul_networks" {
  description = "The networks to deploy the Consul machine(s) within."
  type        = "list"
}

variable "consul_role_tag" {
  description = "The 'role' tag for the Consul machine(s)."
  type        = "string"
  default     = "consul"
}

variable "consul_provision" {
  description = "Boolean 'switch' to indicate if Terraform should do the machine provisioning to install and configure Consul."
  type        = "string"
}

variable "consul_version" {
  description = "The version of Consul to install. See https://releases.hashicorp.com/consul/."
  type        = "string"
  default     = "1.0.2"
}

variable "consul_template_version" {
  description = "The version of Consul Template to install. See https://releases.hashicorp.com/consul-template/."
  type        = "string"
  default     = "0.19.4"
}

variable "consul_machine_count" {
  description = "The number of Consul to provision."
  type        = "string"
  default     = "3"
}

variable "consul_cns_service_name" {
  description = "The service name to use for Triton CNS."
  type        = "string"
  default     = "consul"
}

variable "consul_client_access" {
  description = <<EOF
'From' targets to allow client access to Consul' web port - i.e. access from other VMs or public internet.
See https://docs.joyent.com/public-cloud/network/firewall/cloud-firewall-rules-reference#target
for target syntax.
EOF

  type = "list"
}

#
# Vault Variables
#
variable "vault_image" {
  description = "The image to deploy as the Vault machine(s)."
  type        = "string"
}

variable "vault_package" {
  description = "The package to deploy as the Vault machine(s)."
  type        = "string"
}

variable "vault_user" {
  description = "The User to use for provisioning the machine(s)."
  type        = "string"
  default     = "ubuntu"
}

variable "vault_networks" {
  description = "The networks to deploy the Vault machine(s) within."
  type        = "list"
}

variable "vault_role_tag" {
  description = "The 'role' tag for the Vault machine(s)."
  type        = "string"
  default     = "vault"
}

variable "vault_provision" {
  description = "Boolean 'switch' to indicate if Terraform should do the machine provisioning to install and configure Vault."
  type        = "string"
}

variable "vault_version" {
  description = "The version of Vault to install. See https://releases.hashicorp.com/vault/."
  type        = "string"
  default     = "0.9.0"
}

variable "vault_machine_count" {
  description = "The number of Vault servers to provision."
  type        = "string"
  default     = "2"
}

variable "vault_cns_service_name" {
  description = "The service name to use for Triton CNS."
  type        = "string"
  default     = "vault"
}

variable "vault_client_access" {
  description = <<EOF
'From' targets to allow client access to Vault's web port - i.e. access from other VMs or public internet.
See https://docs.joyent.com/public-cloud/network/firewall/cloud-firewall-rules-reference#target
for target syntax.
EOF

  type = "list"
}

#
# Nomad Variables
#
variable "nomad_image" {
  description = "The image to deploy as the Nomad machine(s)."
  type        = "string"
}

variable "nomad_package" {
  description = "The package to deploy as the Nomad machine(s)."
  type        = "string"
}

variable "nomad_user" {
  description = "The User to use for provisioning the machine(s)."
  type        = "string"
  default     = "ubuntu"
}

variable "nomad_networks" {
  description = "The networks to deploy the Nomad machine(s) within."
  type        = "list"
}

variable "nomad_role_tag" {
  description = "The 'role' tag for the Nomad machine(s)."
  type        = "string"
  default     = "nomad"
}

variable "nomad_client_role_tag" {
  description = "The 'role' tag for the Nomad machine(s)."
  type        = "string"
  default     = "nomad_client"
}

variable "nomad_provision" {
  description = "Boolean 'switch' to indicate if Terraform should do the machine provisioning to install and configure Nomad."
  type        = "string"
}

variable "nomad_version" {
  description = "The version of Nomad to install. See https://releases.hashicorp.com/nomad/."
  type        = "string"
  default     = "0.7.0"
}

variable "nomad_machine_count" {
  description = "The number of Nomad servers to provision."
  type        = "string"
  default     = "3"
}

variable "nomad_client_count" {
  description = "The number of Nomad clients to provision."
  type        = "string"
  default     = "3"
}

variable "nomad_cns_service_name" {
  description = "The service name to use for Triton CNS."
  type        = "string"
  default     = "nomad"
}

variable "nomad_client_cns_service_name" {
  description = "The service name to use for Triton CNS."
  type        = "string"
  default     = "nomad-client"
}

variable "nomad_client_access" {
  description = <<EOF
'From' targets to allow client access to Nomad's web port - i.e. access from other VMs or public internet.
See https://docs.joyent.com/public-cloud/network/firewall/cloud-firewall-rules-reference#target
for target syntax.
EOF

  type = "list"
}

#
# Bastion Variables
#
variable "bastion_host" {
  description = "The Bastion host to use for provisioning."
  type        = "string"
}

variable "bastion_user" {
  description = "The Bastion user to use for provisioning."
  type        = "string"
}

variable "bastion_role_tag" {
  description = "The 'role' tag for the Prometheus machine(s) to allow access FROM the Bastion machine(s)."
  type        = "string"
}

#
# Outputs
#
output "consul_ip" {
  value = ["${triton_machine.consul.*.primaryip}"]
}

output "consul_role_tag" {
  value = "${var.consul_role_tag}"
}

output "consul_cns_service_name" {
  value = "${var.consul_cns_service_name}"
}

output "vault_ip" {
  value = ["${triton_machine.vault.*.primaryip}"]
}

output "vault_role_tag" {
  value = "${var.vault_role_tag}"
}

output "vault_cns_service_name" {
  value = "${var.vault_cns_service_name}"
}

output "nomad_ip" {
  value = ["${triton_machine.nomad.*.primaryip}"]
}

output "nomad_role_tag" {
  value = "${var.nomad_role_tag}"
}

output "nomad_cns_service_name" {
  value = "${var.nomad_cns_service_name}"
}

output "nomad_client_ip" {
  value = ["${triton_machine.nomad_client.*.primaryip}"]
}

output "nomad_client_role_tag" {
  value = "${var.nomad_client_role_tag}"
}

output "nomad_client_cns_service_name" {
  value = "${var.nomad_client_cns_service_name}"
}
