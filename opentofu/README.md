# OpenTofu layer

This folder creates the Proxmox VM that will run Docker and Asterisk.

It assumes you already have a cloud-init template VM in Proxmox. That template should have:

- Debian or Ubuntu Server
- QEMU Guest Agent installed and enabled
- Cloud-init installed
- SSH enabled
- A serial device if your template requires it

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
pbx1 ansible_host=192.168.1.50 ansible_user=ansible
```
