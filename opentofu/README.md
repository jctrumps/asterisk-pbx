# OpenTofu layer

This folder creates the Proxmox VM that will run Docker and Asterisk.

It assumes you already have a cloud-init template VM in Proxmox. That template should have:

- Debian or Ubuntu Server
- QEMU Guest Agent installed and enabled
- Cloud-init installed
- SSH enabled
- A serial device if your template requires it
- A boot disk on `scsi0`
- `virtio-scsi-single` if you follow the companion `proxmox-ubuntu24` template project
- `iothread=1` on `scsi0` if you follow the companion `proxmox-ubuntu24` template project

This PBX repo clones the template and explicitly enforces `scsi_hardware = "virtio-scsi-single"` plus `iothread = true` on the `scsi0` VM disk. That keeps the cloned VM aligned with the companion `proxmox-ubuntu24` template project's storage settings.

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars

tofu init
tofu plan
tofu apply
```

The `local_file` resource writes:

```text
../ansible/inventory/hosts.ini
```

That makes the Ansible layer ready to run.

## If you already have another OpenTofu VM project

You can skip this folder entirely. Just create or edit:

```text
ansible/inventory/hosts.ini
```

Example:

```ini
[asterisk]
pbx1 ansible_host=10.10.10.50 ansible_user=ansible
```
