# asterisk-pbx

Repeatable Asterisk PBX deployment for a Proxmox VE + OpenTofu + Ansible environment.

This project uses a clean layered approach:

```text
OpenTofu  -> creates the Proxmox VM
Ansible   -> configures the VM
Compose   -> runs the Asterisk container
Asterisk  -> handles extensions, dialplan, SIP/RTP
Phones    -> register to the VM IP
```

The recommended target is a **dedicated Debian/Ubuntu VM** on Proxmox, not Docker directly on the Proxmox host.

## Repository layout

```text
asterisk-pbx/
├── opentofu/     # Proxmox VM definition
├── ansible/      # Guest configuration and Asterisk deployment
├── docs/         # Architecture, security, phone setup notes
├── scripts/      # Convenience wrappers
└── Makefile      # Common workflow commands
```

## Default lab topology

```text
Proxmox VE
└── VM: pbx1
    ├── IP: 192.168.1.50/24
    ├── OS: Debian/Ubuntu cloud-init template clone
    ├── Docker Engine + Compose plugin
    └── Asterisk container using host networking inside the VM
```

Phones and softphones register to the VM IP, for example:

```text
SIP server: 192.168.1.50
Port:       5060/UDP
Extension: 1001 or 1002
```

## Prerequisites

On your workstation:

- OpenTofu
- Ansible
- SSH key available to log into the created VM
- Proxmox API token
- A Proxmox cloud-init VM template, such as Debian or Ubuntu Server

On Proxmox:

- Proxmox VE node with a bridge such as `vmbr0`
- Cloud-init template VM with QEMU Guest Agent installed
- Storage for VM disks, usually `local-lvm` or your shared storage
- Snippets/import content enabled only if your template workflow needs it

## Quick start

### 1. Configure OpenTofu

```bash
cd opentofu
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` for your Proxmox node, template VM ID, target VM ID, IP address, storage, bridge, and API token.

Then:

```bash
tofu init
tofu plan
tofu apply
```

OpenTofu writes an Ansible inventory file here:

```text
ansible/inventory/hosts.ini
```

### 2. Configure Asterisk variables

```bash
cd ../ansible
cp group_vars/asterisk_vault.yml.example group_vars/asterisk_vault.yml
```

Edit passwords in:

```text
ansible/group_vars/asterisk_vault.yml
```

For a first lab run, also review:

```text
ansible/group_vars/asterisk.yml
```

### 3. Deploy the PBX

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/asterisk_pbx_ed25519
export ANSIBLE_CONFIG="$PWD/ansible.cfg"
ansible-galaxy collection install -r requirements.yml
ansible all -m ping
ansible-playbook site.yml
```

If you run Ansible from WSL on `/mnt/c/...`, exporting `ANSIBLE_CONFIG` is important because Ansible may otherwise ignore the repository `ansible.cfg` and skip the generated inventory.

If the first `ansible-playbook` run against a new VM fails with `Permission denied (publickey)`, the usual cause is that WSL does not have the matching private key loaded yet. Start `ssh-agent`, run `ssh-add`, and verify with `ansible all -m ping` before retrying the playbook.

### 4. Register softphones

Default test extensions:

```text
1001
1002
```

Test dialplan:

```text
600 = echo test
700 = hello-world playback
```

Once phones are registered, you can verify the live system with:

```bash
sudo docker ps
sudo docker exec asterisk asterisk -rx "pjsip show endpoints"
sudo docker exec asterisk asterisk -rx "pjsip show contacts"
sudo docker exec asterisk asterisk -rx "core show channels"
```

## One-command helpers

From the repository root:

```bash
make infra-init
make infra-plan
make infra-apply
make app
```

Or:

```bash
./scripts/deploy-all.sh
```

For the day-to-day operator flow and troubleshooting, see `docs/runbook.md`.

If you use the WSL helper scripts, note that `scripts/install-prereqs-wsl.sh` installs Ansible tooling but not OpenTofu. Install `tofu` separately in the environment where you plan to run `scripts/deploy-infra.sh` or `scripts/deploy-all.sh`.

## Important security notes

This project intentionally starts as a simple lab PBX. Before exposing it to the internet:

- Change all SIP passwords.
- Restrict `UDP/5060` to trusted networks or your SIP trunk provider.
- Restrict the RTP range, default `UDP/10000-10100`.
- Consider using a VPN for remote phones instead of exposing SIP directly.
- Add Fail2ban or equivalent protection before any public exposure.
- Move secrets into Ansible Vault.

## Rebuild/redeploy flow

Typical daily workflow:

```bash
# Change Asterisk config variables or templates
cd ansible
export ANSIBLE_CONFIG="$PWD/ansible.cfg"
ansible-playbook site.yml
```

Full rebuild flow:

```bash
cd opentofu
tofu apply

cd ../ansible
export ANSIBLE_CONFIG="$PWD/ansible.cfg"
ansible-playbook site.yml
```

Destroy VM when done:

```bash
cd opentofu
tofu destroy
```

## Where files live on the VM

```text
/opt/asterisk-pbx/
├── compose/
│   ├── compose.yml
│   ├── Dockerfile
│   └── docker-entrypoint.sh
├── config/
│   ├── pjsip.conf
│   ├── extensions.conf
│   ├── rtp.conf
│   ├── logger.conf
│   └── modules.conf
├── log/
└── spool/
```

## Design choice: Docker host networking

The Asterisk container uses `network_mode: host`. Because Docker runs inside the PBX VM, this means the container shares the VM network stack, not the Proxmox host network stack.

That keeps the Proxmox node clean while avoiding most SIP/RTP port-mapping trouble.
