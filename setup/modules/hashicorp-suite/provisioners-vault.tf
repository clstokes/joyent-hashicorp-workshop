resource "null_resource" "vault_install" {
  count = "${var.vault_provision == "true" ? var.vault_machine_count : 0}"

  triggers {
    machine_ids = "${triton_machine.vault.*.id[count.index]}"
  }

  connection {
    bastion_host        = "${var.bastion_host}"
    bastion_user        = "${var.bastion_user}"
    bastion_private_key = "${file(var.private_key_path)}"

    host        = "${triton_machine.vault.*.primaryip[count.index]}"
    user        = "${var.vault_user}"
    private_key = "${file(var.private_key_path)}"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /tmp/vault_installer/",
    ]
  }

  provisioner "file" {
    source      = "${path.module}/scripts/install_consul.sh"
    destination = "/tmp/vault_installer/install_consul.sh"
  }

  # note: sudo below because we're likely running in a kvm image.
  provisioner "remote-exec" {
    inline = [
      "chmod 0755 /tmp/vault_installer/install_consul.sh",
      "sudo /tmp/vault_installer/install_consul.sh",
    ]
  }

  provisioner "file" {
    source      = "${path.module}/scripts/install_vault.sh"
    destination = "/tmp/vault_installer/install_vault.sh"
  }

  # note: sudo below because we're likely running in a kvm image.
  provisioner "remote-exec" {
    inline = [
      "chmod 0755 /tmp/vault_installer/install_vault.sh",
      "sudo /tmp/vault_installer/install_vault.sh",
    ]
  }

  # clean up
  provisioner "remote-exec" {
    inline = [
      "rm -rf /tmp/vault_installer/",
    ]
  }
}
