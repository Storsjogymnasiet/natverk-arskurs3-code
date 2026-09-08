terraform {
  required_version = ">= 1.5"

  required_providers {
    virtualbox = {
      source  = "shekeriev/virtualbox"
      version = "0.0.4"
    }
  }
}

provider "virtualbox" {
  delay      = 90
  mintimeout = 10
}

locals {
  suffixed  = var.vm_count > 1
  vm_names  = [for i in range(var.vm_count) : local.suffixed ? format("%s-%02d", var.vm_name, i + 1) : var.vm_name]
  hostnames = [for i in range(var.vm_count) : local.suffixed ? format("%s-%02d", var.hostname, i + 1) : var.hostname]
}

resource "virtualbox_vm" "ubuntu" {
  count = var.vm_count

  name   = local.vm_names[count.index]
  image  = var.box_url
  cpus   = var.cpus
  memory = var.memory

  network_adapter {
    type           = "bridged"
    device         = "IntelPro1000MTServer"
    host_interface = var.bridge_interface
  }

  connection {
    type     = "ssh"
    user     = "vagrant"
    password = "vagrant"
    host     = self.network_adapter[0].ipv4_address
    timeout  = "4m"
  }

  provisioner "remote-exec" {
    inline = concat(
      ["sudo hostnamectl set-hostname ${local.hostnames[count.index]}"],
      flatten([for u in var.users : [
        "id ${u.name} >/dev/null 2>&1 || sudo useradd -m -s /bin/bash ${u.name}",
        "echo '${u.name}:${u.password}' | sudo chpasswd",
        u.sudo ? "sudo usermod -aG sudo ${u.name}" : ":",
      ]])
    )
  }
}
