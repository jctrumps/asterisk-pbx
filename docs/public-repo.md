# Public repository checklist

## Goal

This repository is meant to stay safe to publish publicly.

## Safe tracked files

Tracked files should contain only:

- example IP addresses on `10.10.10.0/24`
- placeholder API tokens
- placeholder SIP passwords
- placeholder SSH public keys
- generic usernames such as `ansible`, `ubuntu`, `user@example-host`, or `pbx-1`

## Files that must stay local only

These files are ignored and should never be committed:

- `opentofu/terraform.tfvars`
- `opentofu/terraform.tfstate`
- `opentofu/terraform.tfstate.backup`
- `ansible/inventory/hosts.ini`
- `ansible/group_vars/asterisk_local.yml`
- `ansible/group_vars/asterisk_vault.yml`
- `ansible/.vault_pass*`
- `*.auto.tfvars`
- `*.tfplan`

## Before publishing

Check for:

- real Proxmox endpoints or API tokens
- real SIP passwords
- real SSH public key comments that identify a person or workstation
- real LAN or WAN IP addresses
- personal names, aliases, or usernames

## Quick review commands

From the repo root:

```bash
git grep -n -I -E "<personal-name>|<alias>|<private-ip>|automation@|api2/json|<private-key-marker>"
```

```bash
git ls-files "opentofu/terraform.tfvars" "opentofu/terraform.tfstate" "opentofu/terraform.tfstate.backup" "ansible/inventory/hosts.ini" "ansible/group_vars/asterisk_local.yml" "ansible/group_vars/asterisk_vault.yml"
```

The second command should return no tracked files.
