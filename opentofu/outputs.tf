output "pbx_vm_id" {
  description = "Proxmox VM ID."
  value       = proxmox_virtual_environment_vm.pbx.vm_id
}

output "pbx_name" {
  description = "PBX VM name."
  value       = proxmox_virtual_environment_vm.pbx.name
}

output "pbx_static_ip" {
  description = "Static IP derived from vm_ipv4_address, if not DHCP."
  value       = local.static_vm_ip
}

output "ansible_inventory_path" {
  description = "Generated Ansible inventory path."
  value       = local_file.ansible_inventory.filename
}

output "next_step" {
  description = "Next command after infrastructure apply."
  value       = "cd ../ansible && ansible-galaxy collection install -r requirements.yml && ansible-playbook site.yml"
}
