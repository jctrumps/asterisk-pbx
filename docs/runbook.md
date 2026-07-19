# Operator runbook

## What this repo does

This project stands up a PBX VM on Proxmox and then configures that VM to run Asterisk in a Docker container.

The deployment chain is:

```text
OpenTofu -> Proxmox VM -> Ansible -> Docker -> Asterisk -> Phones
```

## First deployment

1. Prepare a Proxmox cloud-init template.
2. Configure OpenTofu variables.
3. Apply infrastructure.
4. Set Asterisk secrets.
5. Run Ansible.
6. Register phones and test calls.

## Step 1: prepare the Proxmox template

Use `docs/template-prep.md` as the template checklist.

Minimum expectations:

- Debian or Ubuntu cloud-init template
- `cloud-init` installed
- `openssh-server` installed
- `qemu-guest-agent` installed and enabled
- a usable admin user path via cloud-init SSH keys

## Step 2: configure OpenTofu

Copy:

```bash
cp opentofu/terraform.tfvars.example opentofu/terraform.tfvars
```

Fill in at least:

- `proxmox_endpoint`
- `proxmox_api_token`
- `proxmox_node`
- `template_vm_id`
- `vm_id`
- `vm_name`
- `vm_bridge`
- `vm_ipv4_address`
- `vm_ipv4_gateway` when not using DHCP
- `ssh_public_keys`

## Step 3: apply infrastructure

From `opentofu/`:

```bash
tofu init
tofu plan
tofu apply
```

Expected result:

- a Proxmox VM is cloned from the template
- the VM is started
- `ansible/inventory/hosts.ini` is generated

## Step 4: validate inventory

Open `ansible/inventory/hosts.ini` and confirm the generated host is correct.

Important DHCP caveat:

- if `vm_ipv4_address` is `dhcp` and `ansible_host_override` is empty, inventory may contain `REPLACE_WITH_DHCP_IP`
- replace it with the actual lease or set `ansible_host_override` before applying again

## Step 5: configure Asterisk variables and secrets

Copy:

```bash
cp ansible/group_vars/asterisk_local.yml.example ansible/group_vars/asterisk_local.yml
cp ansible/group_vars/asterisk_vault.yml.example ansible/group_vars/asterisk_vault.yml
```

Then review:

- `ansible/group_vars/asterisk.yml`
- `ansible/group_vars/asterisk_local.yml`
- `ansible/group_vars/asterisk_vault.yml`

Use `asterisk_local.yml` for local non-secret settings such as `asterisk_local_net`, NAT addresses, ARI allowed origins, and fallback queue members. Use `asterisk_vault.yml` for SIP passwords, ARI password, and voicemail PINs. Do not leave placeholder passwords in place. The playbook is designed to fail when passwords still start with `CHANGE_ME` or similar placeholders.

## Step 6: run Ansible

From `ansible/`:

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/asterisk_pbx_ed25519
export ANSIBLE_CONFIG="$PWD/ansible.cfg"
ansible-galaxy collection install -r requirements.yml
ansible all -m ping
ansible-playbook site.yml
```

If you run from WSL on `/mnt/c/...`, this matters. Without `ANSIBLE_CONFIG`, Ansible may ignore the repository's `ansible.cfg`, which means it will not automatically use `inventory/hosts.ini`.

WSL must also have access to the private key that matches the public key in `ssh_public_keys`. If the key is passphrase-protected, start `ssh-agent` and load it with `ssh-add` before running Ansible.

The `ansible all -m ping` check is worth doing every time you bring up a brand new VM. It catches SSH key and inventory issues before the full playbook runs.

What Ansible does:

- installs base packages
- installs Docker Engine and the Compose plugin
- creates `/opt/asterisk-pbx`
- renders `compose.yml`, `Dockerfile`, startup script, and Asterisk config
- builds and starts the `asterisk` container

## Step 7: verify the deployment

Basic checks:

```bash
ansible all -m ping
ssh <vm_username>@<pbx-vm-ip>
sudo docker ps
sudo docker exec asterisk asterisk -rx "pjsip show endpoints"
sudo docker exec asterisk asterisk -rx "pjsip show contacts"
```

Expected behavior:

- container `asterisk` is running
- extensions appear as endpoints
- registered phones appear as contacts

For a live console:

```bash
sudo docker exec -it asterisk asterisk -rvvv
```

For live container logs:

```bash
sudo docker logs -f asterisk
```

## Step 8: register phones

Use the VM IP as the SIP server.

Defaults:

- SIP transport: UDP
- SIP port: `5060`
- RTP range: `10000-10100`
- test extensions: `1001`, `1002`
- test numbers: `600`, `700`

See `docs/phone-setup.md` for the exact softphone fields.

## Troubleshooting

### OpenTofu apply fails

Check:

- Proxmox API endpoint and token format
- template VM ID exists and is a cloud-init template
- target `vm_id` is unused
- bridge, storage, and VLAN values exist on the target node

### VM exists but Ansible cannot connect

Check:

- `ansible/inventory/hosts.ini` has the right IP
- the VM received the expected cloud-init network config
- the cloud-init username matches `ansible_user`
- your SSH key was included in `ssh_public_keys`
- WSL has the matching private key available for SSH authentication
- port `22/tcp` is reachable from the operator machine

If the error is `Permission denied (publickey)`, run:

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/asterisk_pbx_ed25519
export ANSIBLE_CONFIG="$PWD/ansible.cfg"
ansible all -m ping
```

If that still fails, test direct SSH with:

```bash
ssh <vm_username>@<pbx-vm-ip>
```

If direct SSH fails, fix SSH access first. Ansible will not succeed until normal SSH login works.

### Docker install fails

Check:

- the guest OS is Debian-family
- outbound internet access from the VM works
- DNS resolution works from the guest

The current Docker role is intentionally Debian/Ubuntu-focused.

### Phones do not register

Check:

- the phone is pointed at the PBX VM IP, not the Proxmox host
- UDP `5060` is open between phone and VM
- extension passwords in `asterisk_vault.yml` match the phone config
- `asterisk_local_net` matches the real LAN or VLAN

Useful command:

```bash
sudo docker exec -it asterisk asterisk -rvvv
```

Then run:

```text
pjsip show endpoints
pjsip show contacts
```

### Calls connect but audio is one-way or missing

Check:

- UDP `10000-10100` is open end to end
- the phone and PBX are on the expected network
- NAT-related settings are correct if the PBX is not LAN-only
- `asterisk_external_signaling_address` and `asterisk_external_media_address` are set when needed

## Security reminders

This repo is a starter lab environment, not a hardened internet-facing PBX.

Before exposing it outside a trusted LAN:

- rotate every SIP password
- restrict SIP and RTP to trusted networks
- prefer VPN access for remote phones
- add Fail2ban or equivalent protection
- move secrets into encrypted Ansible Vault usage

See `docs/security.md` for the baseline checklist.
