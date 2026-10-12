output "server" {
  description = "Namn, VM-ID och IP för prod-servern"
  value = {
    namn  = proxmox_virtual_environment_vm.prod.name
    vm_id = proxmox_virtual_environment_vm.prod.vm_id
    ip    = var.ip
  }
}

output "ssh_kommando" {
  description = "Logga in på prod-servern (med lösenordet)"
  value       = "ssh ${var.username}@${var.ip}"
}
