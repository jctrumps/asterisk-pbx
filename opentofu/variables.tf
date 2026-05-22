variable "proxmox_endpoint" {
  description = "Proxmox API endpoint, for example https://pve.example.local:8006/"
  type        = string
}

variable "proxmox_api_token" {
  description = "Proxmox API token in the format user@realm!tokenid=secret"
  type        = string
  sensitive   = true
}

variable "proxmox_insecure_tls" {
  description = "Set true for self-signed Proxmox certificates in a lab. Use false with trusted TLS."
  type        = bool
  default     = true
}

variable "proxmox_ssh_username" {
  description = "SSH username for the Proxmox node when provider operations require SSH."
  type        = string
  default     = "root"
}

variable "proxmox_ssh_agent" {
  description = "Use local ssh-agent for provider SSH operations."
  type        = bool
  default     = true
}

variable "proxmox_node" {
  description = "Proxmox node name, for example pve."
  type        = string
  default     = "pve"
}

variable "template_vm_id" {
  description = "Existing Proxmox cloud-init template VM ID to clone."
  type        = number
}

variable "vm_id" {
  description = "Target VM ID for the PBX VM."
  type        = number
  default     = 150
}

variable "vm_name" {
  description = "Name of the PBX VM."
  type        = string
  default     = "pbx1"
}

variable "vm_description" {
  description = "Description stored on the VM in Proxmox."
  type        = string
  default     = "Asterisk PBX VM managed by OpenTofu"
}

variable "vm_tags" {
  description = "Tags applied to the VM."
  type        = list(string)
  default     = ["opentofu", "asterisk", "pbx"]
}

variable "vm_cpu_cores" {
  description = "vCPU cores."
  type        = number
  default     = 2
}

variable "vm_memory_mb" {
  description = "Dedicated memory in MB."
  type        = number
  default     = 2048
}

variable "vm_disk_datastore_id" {
  description = "Datastore for the VM disk."
  type        = string
  default     = "local-lvm"
}

variable "vm_disk_size_gb" {
  description = "Boot disk size in GB."
  type        = number
  default     = 32
}

variable "cloud_init_datastore_id" {
  description = "Datastore for the cloud-init disk. Usually same as VM disk datastore."
  type        = string
  default     = "local-lvm"
}

variable "vm_bridge" {
  description = "Proxmox Linux bridge for the VM NIC."
  type        = string
  default     = "vmbr0"
}

variable "vm_vlan_id" {
  description = "Optional VLAN ID. Set null for untagged."
  type        = number
  default     = null
}

variable "vm_ipv4_address" {
  description = "CIDR address for cloud-init, for example 192.168.1.50/24, or dhcp."
  type        = string
  default     = "192.168.1.50/24"
}

variable "vm_ipv4_gateway" {
  description = "IPv4 gateway. Ignored when vm_ipv4_address is dhcp."
  type        = string
  default     = "192.168.1.1"
}

variable "dns_domain" {
  description = "Optional DNS search domain."
  type        = string
  default     = "local"
}

variable "dns_servers" {
  description = "DNS servers for the VM."
  type        = list(string)
  default     = ["1.1.1.1", "8.8.8.8"]
}

variable "vm_username" {
  description = "Cloud-init admin user created in the VM."
  type        = string
  default     = "ansible"
}

variable "vm_user_password" {
  description = "Optional cloud-init password. Prefer SSH keys; leave null when not needed."
  type        = string
  default     = null
  sensitive   = true
}

variable "ssh_public_keys" {
  description = "SSH public keys authorized for the cloud-init user."
  type        = list(string)
  default     = []
}

variable "ansible_host_override" {
  description = "Optional explicit Ansible host/IP. Useful when using DHCP and you already know the lease."
  type        = string
  default     = ""
}
