output "instance_public_ip" {
  value = oci_core_instance.openclaw.public_ip
}

output "ssh_command" {
  value = "ssh -i ~/.ssh/openclaw_vm ubuntu@${oci_core_instance.openclaw.public_ip}"
}
