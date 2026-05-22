#!/usr/bin/env bash
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

printf '== WSL/Linux tool checks ==\n'
for c in python3 pipx ansible ansible-playbook ansible-galaxy ssh git curl; do
  if command -v "$c" >/dev/null 2>&1; then
    printf '%-18s YES  %s\n' "$c" "$(command -v "$c")"
  else
    printf '%-18s NO\n' "$c"
  fi
done

if command -v ansible >/dev/null 2>&1; then
  ansible --version | head -n 1
fi

printf '\n== Project file checks ==\n'
for f in \
  "opentofu/terraform.tfvars" \
  "ansible/group_vars/asterisk_vault.yml" \
  "ansible/inventory/hosts.ini"; do
  if [[ -f "$PROJECT_ROOT/$f" ]]; then
    printf '%-45s YES\n' "$f"
  else
    printf '%-45s NO\n' "$f"
  fi
done

printf '\nIf Ansible is missing, run:\n'
printf '  bash scripts/install-prereqs-wsl.sh\n'
