output "servrar" {
  description = "Namn → IP-adress för varje server"
  value       = { for vm in virtualbox_vm.ubuntu : vm.name => vm.network_adapter[0].ipv4_address }
}

output "ssh_kommandon" {
  description = "SSH-kommando per server – lösenordet är \"vagrant\""
  value       = [for vm in virtualbox_vm.ubuntu : "ssh vagrant@${vm.network_adapter[0].ipv4_address}"]
}
