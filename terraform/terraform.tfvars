vm_count         = 1
hostname         = "ubuntu-terraform"
bridge_interface = "wlp2s0"

users = [
  { name = "elev", password = "byt-mig", sudo = true },
]
