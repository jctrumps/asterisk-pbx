#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

printf '== Installing/checking WSL/Linux prerequisites ==\n'

sudo apt update
sudo apt install -y python3 pipx python3-venv openssh-client git curl

python3 -m pipx ensurepath
export PATH="$HOME/.local/bin:$PATH"

if ! command -v ansible-playbook >/dev/null 2>&1; then
  printf 'Installing Ansible with pipx...\n'
  pipx install --include-deps ansible
else
  printf 'Ansible is already installed.\n'
fi

export PATH="$HOME/.local/bin:$PATH"

if [[ -f "$PROJECT_ROOT/ansible/requirements.yml" ]]; then
  printf 'Installing Ansible collection requirements for this project...\n'
  cd "$PROJECT_ROOT/ansible"
  ansible-galaxy collection install -r requirements.yml
fi

printf '\nInstalled versions:\n'
python3 --version
ansible --version | head -n 1
ansible-playbook --version | head -n 1
ansible-galaxy --version | head -n 1

printf '\nDone. If ansible commands are not found in a new terminal, close and reopen WSL or run:\n'
printf '  export PATH="$HOME/.local/bin:$PATH"\n'
