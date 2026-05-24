# AGENTS.md

## Project overview

This repository builds a lab-style Asterisk PBX on Proxmox using a layered flow:

1. `opentofu/` clones and configures a VM on Proxmox.
2. `opentofu/` writes `ansible/inventory/hosts.ini`.
3. `ansible/` installs Docker on the guest VM.
4. `ansible/` renders Asterisk config and deploys a container with Docker Compose.
5. Phones register directly to the PBX VM IP.

The intended target is a dedicated Debian or Ubuntu VM, not Docker directly on the Proxmox host.

## Important paths

- `README.md`: top-level workflow and prerequisites
- `opentofu/main.tf`: VM creation and inventory generation
- `opentofu/variables.tf`: infrastructure inputs
- `ansible/site.yml`: Ansible entry point
- `ansible/group_vars/asterisk.yml`: non-secret PBX defaults
- `ansible/group_vars/asterisk_vault.yml`: secret SIP passwords
- `ansible/roles/asterisk/templates/`: rendered Asterisk and Compose templates
- `docs/`: architecture, security, template prep, phone setup, runbook

## Working assumptions

- This is a lab/starter PBX with minimal hardening by default.
- `ansible/ansible.cfg` disables SSH host key checking for convenience.
- `ansible/roles/asterisk/tasks/main.yml` intentionally fails if extension passwords are still placeholders.
- The Asterisk container uses host networking inside the guest VM.

## Common operator workflow

1. Copy `opentofu/terraform.tfvars.example` to `opentofu/terraform.tfvars` and fill in Proxmox-specific values.
2. Copy `ansible/group_vars/asterisk_vault.yml.example` to `ansible/group_vars/asterisk_vault.yml` and replace all placeholder passwords.
3. Run `tofu init && tofu apply` in `opentofu/`.
4. Confirm `ansible/inventory/hosts.ini` contains the correct VM IP or hostname.
5. Run `ansible-galaxy collection install -r requirements.yml` and `ansible-playbook site.yml` in `ansible/`.
6. Register phones to the VM IP on UDP `5060`.

## Repo-specific gotchas

- If `vm_ipv4_address = "dhcp"`, OpenTofu may write `REPLACE_WITH_DHCP_IP` into `ansible/inventory/hosts.ini` unless `ansible_host_override` is set.
- `scripts/install-prereqs-wsl.sh` installs Ansible tooling, but not OpenTofu.
- When running Ansible from WSL under `/mnt/c/...`, export `ANSIBLE_CONFIG="$PWD/ansible.cfg"` or Ansible may ignore the repo config and inventory.
- WSL must have the private key that matches `ssh_public_keys`; if the key is encrypted, start `ssh-agent` and run `ssh-add` before `ansible-playbook`.
- `Makefile` and `scripts/*.sh` assume a Unix-like shell; the PowerShell scripts are the Windows-oriented helpers.
- Security controls like firewalling, Fail2ban, SIP TLS, and trunk-specific hardening are documented but not automated.

## Validated status

- OpenTofu provisioning succeeded with template VM ID `9024`.
- Ansible deployment succeeded to VM `pbx-1`.
- The Asterisk container starts healthy as `local/asterisk-pbx:latest`.
- Extensions `1001` and `1002` register and can call each other.

## Change guidance for future agents

- Keep the layering clean: infrastructure in `opentofu/`, guest/app deployment in `ansible/`, supporting docs in `docs/`.
- Prefer changing Ansible templates and variables rather than hardcoding generated output.
- Do not commit real secrets from `terraform.tfvars`, `terraform.tfstate`, `ansible/inventory/hosts.ini`, or `ansible/group_vars/asterisk_vault.yml`.
- When updating docs, keep them aligned with the actual templates, defaults, and scripts in this repo.
