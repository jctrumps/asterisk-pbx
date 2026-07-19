# Proxmox cloud-init template preparation notes

This project expects an existing Debian or Ubuntu cloud-init template.

If you use the companion `proxmox-ubuntu24` template project, this PBX repo is expected to clone that template with:

- SCSI controller `virtio-scsi-single`
- boot disk on `scsi0`
- `iothread=1` on `scsi0`

A good template should include:

- cloud-init
- openssh-server
- qemu-guest-agent
- sudo
- cleaned machine-id
- cloud-init cleaned before converting to template

High-level manual flow on the Proxmox host:

```bash
# Example only. Adjust image/version/storage for your environment.
wget -O /var/lib/vz/template/iso/debian-genericcloud-amd64.qcow2 \
  https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2

qm create 9024 \
  --name ubuntu-2404-cloudinit \
  --memory 2048 \
  --cores 2 \
  --net0 virtio,bridge=vmbr0 \
  --scsihw virtio-scsi-single

qm set 9024 --scsi0 local-lvm:0,import-from=/var/lib/vz/template/iso/debian-genericcloud-amd64.qcow2,iothread=1
qm set 9024 --ide2 local-lvm:cloudinit
qm set 9024 --boot order=scsi0
qm set 9024 --serial0 socket --vga serial0
qm set 9024 --agent enabled=1
qm template 9024
```

This is intentionally only a reference. Use your existing OpenTofu template builder if you already have one.

When cloning from a proven template, the clone should normally inherit the template's SCSI controller and disk-level options. In this PBX repo, `opentofu/main.tf` now explicitly sets `scsi_hardware = "virtio-scsi-single"` and keeps the boot disk on `scsi0` with `iothread = true`.
