variable "vm_name" {
  description = "Basnamn på de virtuella maskinerna (syns i VirtualBox). Vid fler än 1 läggs -01, -02 ... till."
  type        = string
  default     = "ubuntu-terraform"
}

variable "vm_count" {
  description = "Antal virtuella maskiner att skapa"
  type        = number
  default     = 1
}

variable "hostname" {
  description = "Bas-hostname som sätts på servrarna. Vid fler än 1 läggs -01, -02 ... till."
  type        = string
  default     = "ubuntu-terraform"
}

variable "users" {
  description = "Användarkonton att skapa på servern"
  type = list(object({
    name     = string
    password = string
    sudo     = optional(bool, false)
  }))
  default = []
}

variable "box_url" {
  description = "URL till en Vagrant-box för VirtualBox. Måste vara en BIOS-box; UEFI-boxar ger \"no bootable medium\" med denna provider (t.ex. bento/ubuntu-26.04)."
  type        = string
  default     = "https://vagrantcloud.com/bento/boxes/ubuntu-24.04/versions/202510.26.0/providers/virtualbox/amd64/vagrant.box"
}

variable "cpus" {
  description = "Antal virtuella processorkärnor"
  type        = number
  default     = 2
}

variable "memory" {
  description = "Mängd RAM, skriv i gib med en decimal (t.ex. \"2.0 gib\", \"4.0 gib\")"
  type        = string
  default     = "2.0 gib"
}

variable "bridge_interface" {
  description = "Värddatorns fysiska nätverkskort att brygga till (se: VBoxManage list bridgedifs)"
  type        = string
  default     = "wlp2s0"
}
