terraform {
  required_version = ">= 1.6.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.106"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}
