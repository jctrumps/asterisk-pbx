# Proxmox cloud-init template preparation notes

This project expects an existing Debian or Ubuntu cloud-init template.

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

qm create 9000 \
  --name debian-cloud-template \
  --memory 2048 \
  --cores 2 \
  --net0 virtio,bridge=vmbr0 \
  --scsihw virtio-scsi-pci

qm importdisk 9000 /var/lib/vz/template/iso/debian-genericcloud-amd64.qcow2 local-lvm
qm set 9000 --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --serial0 socket --vga serial0
qm set 9000 --agent enabled=1
qm template 9000
```

This is intentionally only a reference. Use your existing OpenTofu template builder if you already have one.
