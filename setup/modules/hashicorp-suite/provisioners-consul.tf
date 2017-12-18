resource "null_resource" "consul_install" {
  count = "${var.consul_provision == "true" ? var.consul_machine_count : 0}"

  triggers {
    machine_ids = "${triton_machine.consul.*.id[count.index]}"
  }

  connection {
    bastion_host        = "${var.bastion_host}"
    bastion_user        = "${var.bastion_user}"
    bastion_private_key = "${file(var.private_key_path)}"

    host        = "${triton_machine.consul.*.primaryip[count.index]}"
    user        = "${var.consul_user}"
    private_key = "${file(var.private_key_path)}"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /tmp/consul_installer/",
    ]
  }

  provisioner "file" {
    source      = "${path.module}/scripts/install_consul.sh"
    destination = "/tmp/consul_installer/install_consul.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 0755 /tmp/consul_installer/install_consul.sh",
      "sudo /tmp/consul_installer/install_consul.sh",
    ]
  }

  # clean up
  provisioner "remote-exec" {
    inline = [
      "rm -rf /tmp/consul_installer/",
    ]
  }
}
