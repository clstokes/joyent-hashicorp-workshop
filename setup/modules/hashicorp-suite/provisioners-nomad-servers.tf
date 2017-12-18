resource "null_resource" "nomad_install" {
  count = "${var.nomad_provision == "true" ? var.nomad_machine_count : 0}"

  triggers {
    machine_ids = "${triton_machine.nomad.*.id[count.index]}"
  }

  connection {
    bastion_host        = "${var.bastion_host}"
    bastion_user        = "${var.bastion_user}"
    bastion_private_key = "${file(var.private_key_path)}"

    host        = "${triton_machine.nomad.*.primaryip[count.index]}"
    user        = "${var.nomad_user}"
    private_key = "${file(var.private_key_path)}"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /tmp/nomad_installer/",
    ]
  }

  provisioner "file" {
    source      = "${path.module}/scripts/install_consul.sh"
    destination = "/tmp/nomad_installer/install_consul.sh"
  }

  # note: sudo below because we're likely running in a kvm image.
  provisioner "remote-exec" {
    inline = [
      "chmod 0755 /tmp/nomad_installer/install_consul.sh",
      "sudo /tmp/nomad_installer/install_consul.sh",
    ]
  }

  provisioner "file" {
    source      = "${path.module}/scripts/install_nomad.sh"
    destination = "/tmp/nomad_installer/install_nomad.sh"
  }

  # note: sudo below because we're likely running in a kvm image.
  provisioner "remote-exec" {
    inline = [
      "chmod 0755 /tmp/nomad_installer/install_nomad.sh",
      "sudo /tmp/nomad_installer/install_nomad.sh",
    ]
  }

  # clean up
  provisioner "remote-exec" {
    inline = [
      "rm -rf /tmp/nomad_installer/",
    ]
  }
}
