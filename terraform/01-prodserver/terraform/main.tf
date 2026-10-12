terraform {
  required_version = ">= 1.5"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.114"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = true # Proxmox kör med ett självsignerat certifikat i labbet
}

locals {
  vm_name   = "prod-${var.elev}"
  datastore = "local-lvm-${trimprefix(var.proxmox_node, "asgard-")}" # t.ex. local-lvm-midgard003
}

resource "proxmox_virtual_environment_vm" "prod" {
  name        = local.vm_name
  description = "Prod-server för ${var.elev}. Skapad med Terraform – ändra i koden, inte i Proxmox."
  tags        = ["prod", "terraform", var.elev]
  node_name   = var.proxmox_node
  vm_id       = var.vm_id
  pool_id     = "${var.klass}/${var.elev}" # din egen pool – utan den nekar Proxmox

  boot_order = ["scsi0"]

  # Ubuntus cloud-avbild har ingen qemu-guest-agent. Vi vet redan IP-adressen (statisk),
  # så Terraform behöver inte fråga VM:en om den.
  agent {
    enabled = false
  }

  cpu {
    cores = var.cpus
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.memory
  }

  # Disken skapas från Ubuntus cloud-avbild, som läraren lagt på noden
  disk {
    datastore_id = local.datastore
    interface    = "scsi0"
    size         = var.disk_size
    import_from  = var.image
    file_format  = "qcow2"
  }

  serial_device {}

  vga {
    type = "serial0"
  }

  operating_system {
    type = "l26"
  }

  network_device {
    bridge = var.bridge
  }

  # cloud-init: körs första gången VM:en startar
  initialization {
    datastore_id        = local.datastore
    vendor_data_file_id = var.vendor_data # slår på SSH med lösenord (Ubuntu har det avstängt)

    ip_config {
      ipv4 {
        address = "${var.ip}/24"
        gateway = var.gateway
      }
    }

    dns {
      servers = [var.gateway]
    }

    user_account {
      username = var.username
      password = var.password
    }
  }

  started = true
  on_boot = true # prod ska starta igen om Proxmox-värden startas om

  # Utan detta skulle Terraform bygga om disken (och radera allt på den)
  # om avbilden på noden någon gång byts ut.
  lifecycle {
    ignore_changes = [disk[0].import_from]
  }
}
