# ---- Proxmox ---------------------------------------------------------------

variable "proxmox_endpoint" {
  description = "Adress till Proxmox webbgränssnitt/API"
  type        = string
  default     = "https://192.168.47.11:8006/"
}

variable "proxmox_api_token" {
  description = "Din API-token, formatet: användarnamn@valhalla!terraform=hemlighet"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Proxmox-noden där VM:en ska skapas: asgard-midgard003 eller asgard-midgard004"
  type        = string

  validation {
    condition     = contains(["asgard-midgard003", "asgard-midgard004"], var.proxmox_node)
    error_message = "Prod-servrar får bara skapas på asgard-midgard003 eller asgard-midgard004."
  }
}

variable "image" {
  description = "Ubuntus cloud-avbild på noden, som disken skapas från"
  type        = string
  default     = "local:import/resolute-server-cloudimg-amd64.qcow2"
}

variable "vendor_data" {
  description = "cloud-init-fil på noden som slår på SSH-inloggning med lösenord"
  type        = string
  default     = "local:snippets/prod-elev-vendor-data.yaml"
}

variable "bridge" {
  description = "Nätverksbrygga i Proxmox som VM:en kopplas till"
  type        = string
  default     = "vmbr0"
}

# ---- Din server ------------------------------------------------------------

variable "klass" {
  description = "Din klass. Din pool i Proxmox heter <klass>/<elev>."
  type        = string
  default     = "ee24"
}

variable "elev" {
  description = "Ditt AD-användarnamn (t.ex. itjoab01). VM:en heter prod-<elev>, som också blir hostname."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,20}$", var.elev))
    error_message = "Skriv ditt AD-användarnamn med små bokstäver, t.ex. itjoab01."
  }
}

variable "vm_id" {
  description = "Önskat VM-ID i Proxmox. Lämna tomt (null) så väljer Proxmox nästa lediga."
  type        = number
  default     = null
}

variable "ip" {
  description = "Din Prod-IP från Excel-dokumentet i Teams, utan /24 (t.ex. 192.168.47.150)"
  type        = string

  validation {
    condition     = can(cidrhost("${var.ip}/32", 0))
    error_message = "Ange en IPv4-adress, t.ex. 192.168.47.150 (utan /24)."
  }
}

variable "gateway" {
  description = "Gateway och DNS för labbnätet"
  type        = string
  default     = "192.168.47.1"
}

variable "username" {
  description = "Användarkontot som skapas på servern (samma som på dev-servern)"
  type        = string
}

variable "password" {
  description = "Lösenord för kontot: SSH-inloggning, sudo och Proxmox-konsolen"
  type        = string
  sensitive   = true
}

variable "cpus" {
  description = "Antal vCPU"
  type        = number
  default     = 2
}

variable "memory" {
  description = "RAM i MB"
  type        = number
  default     = 2048
}

variable "disk_size" {
  description = "Diskstorlek i GB"
  type        = number
  default     = 20
}
