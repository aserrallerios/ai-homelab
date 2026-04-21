#!/usr/bin/env bash
set -euo pipefail

# models-server bootstrap script
# This script prepares a headless Ubuntu server for Ansible-based provisioning.
# It installs required dependencies and launches the Ansible playbook.


REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
ANSIBLE_DIR="$REPO_ROOT/ansible"

# Detect the username running the script (not root)
if [[ -n "$SUDO_USER" && "$SUDO_USER" != "root" ]]; then
  BOOTSTRAP_USER="$SUDO_USER"
else
  BOOTSTRAP_USER="$USER"
fi

# Colors for output
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
NC="\033[0m"

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

info "Updating apt cache and installing dependencies..."
sudo apt-get update -y
sudo apt-get install -y python3 python3-pip git

if ! command -v ansible >/dev/null 2>&1; then
  info "Installing Ansible..."
  python3 -m pip install --user ansible
  export PATH="$HOME/.local/bin:$PATH"
else
  info "Ansible already installed."
fi

info "Bootstrapping complete."

echo
echo -e "${GREEN}Detected user:${NC} $BOOTSTRAP_USER"
read -rp "Proceed with this user? (Y/n): " CONFIRM
CONFIRM=${CONFIRM:-Y}
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  warn "Aborting bootstrap."
  exit 1
fi

info "Running Ansible playbook as $BOOTSTRAP_USER..."
ansible-playbook "$ANSIBLE_DIR/site.yml" --connection=local -e "ANSIBLE_USER=$BOOTSTRAP_USER"
