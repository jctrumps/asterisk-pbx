locals {
  static_vm_ip = var.vm_ipv4_address == "dhcp" ? "" : split("/", var.vm_ipv4_address)[0]
  ansible_host = var.ansible_host_override != "" ? var.ansible_host_override : (
    var.vm_ipv4_address == "dhcp" ? "REPLACE_WITH_DHCP_IP" : local.static_vm_ip
  )
}

resource "proxmox_virtual_environment_vm" "pbx" {
  name        = var.vm_name
  description = var.vm_description
  node_name   = var.proxmox_node
  vm_id       = var.vm_id
  tags        = var.vm_tags

  started = true
  on_boot = true
  scsi_hardware = "virtio-scsi-single"

  clone {
    vm_id = var.template_vm_id
    full  = true
  }

  agent {
    enabled = true
    timeout = "15m"
  }

  cpu {
    cores = var.vm_cpu_cores
    type  = "host"
  }

  memory {
    dedicated = var.vm_memory_mb
  }

  operating_system {
    type = "l26"
  }

  # Recommended by the bpg/proxmox provider docs for Debian/Ubuntu cloud images
  # that may kernel panic while resizing without a serial device.
  serial_device {
    device = "socket"
  }

  disk {
    datastore_id = var.vm_disk_datastore_id
    interface    = "scsi0"
    size         = var.vm_disk_size_gb
    discard      = "on"
    iothread     = true
  }

  network_device {
    bridge  = var.vm_bridge
    model   = "virtio"
    vlan_id = var.vm_vlan_id
  }

  initialization {
    datastore_id = var.cloud_init_datastore_id
    interface    = "ide2"

    dns {
      domain  = var.dns_domain
      servers = var.dns_servers
    }

    ip_config {
      ipv4 {
        address = var.vm_ipv4_address
        gateway = var.vm_ipv4_address == "dhcp" ? null : var.vm_ipv4_gateway
      }
    }

    user_account {
      username = var.vm_username
      password = var.vm_user_password
      keys     = var.ssh_public_keys
    }
  }
}

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible/inventory/hosts.ini"

  content = templatefile("${path.module}/templates/hosts.ini.tftpl", {
    host_alias   = var.vm_name
    ansible_host = local.ansible_host
    ansible_user = var.vm_username
  })
}
