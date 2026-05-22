provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_insecure_tls

  # Helpful for provider operations that need SSH to the Proxmox node.
  # Keep ssh-agent loaded with the matching key on your workstation.
  ssh {
    agent    = var.proxmox_ssh_agent
    username = var.proxmox_ssh_username
  }
}
