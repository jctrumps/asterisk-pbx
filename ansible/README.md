# Ansible layer

This folder configures the PBX VM and deploys Asterisk using Docker Compose.

## First-time setup

```bash
cp inventory/hosts.ini.example inventory/hosts.ini
cp group_vars/asterisk_vault.yml.example group_vars/asterisk_vault.yml
vim group_vars/asterisk_vault.yml
export ANSIBLE_CONFIG="$PWD/ansible.cfg"
ansible-galaxy collection install -r requirements.yml
ansible-playbook site.yml
```

If you use the OpenTofu layer, it will generate `inventory/hosts.ini` for you.

If you run Ansible from WSL against a repo under `/mnt/c/...`, Ansible may ignore `ansible.cfg` because the directory is world writable. Export `ANSIBLE_CONFIG="$PWD/ansible.cfg"` first, or pass `-i inventory/hosts.ini` explicitly.

WSL also needs the private key that matches `ssh_public_keys` from `opentofu/terraform.tfvars`. If your key is passphrase-protected, start `ssh-agent` and run `ssh-add` before running Ansible.

## Useful commands

```bash
export ANSIBLE_CONFIG="$PWD/ansible.cfg"
ansible all -m ping
ansible-playbook site.yml --syntax-check
ansible-playbook site.yml
```

SSH to the VM and inspect Asterisk:

```bash
sudo docker ps
sudo docker exec -it asterisk asterisk -rvvv
sudo docker exec asterisk asterisk -rx "pjsip show endpoints"
sudo docker exec asterisk asterisk -rx "pjsip show contacts"
sudo docker exec asterisk asterisk -rx "core show channels"
sudo docker logs -f asterisk
```
