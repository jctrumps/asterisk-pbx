#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../ansible"
export ANSIBLE_CONFIG="$PWD/ansible.cfg"
ansible-galaxy collection install -r requirements.yml
ansible-playbook site.yml
