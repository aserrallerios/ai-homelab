# models-server

This repository contains the automation and configuration for deploying and managing the "models-server" stack. It is designed to be bootstrapped and managed from a single entrypoint, making it easy to set up a new server or update an existing one.

## Features

- One-command bootstrap for headless Ubuntu servers
- Ansible-based provisioning (playbooks and roles to be added)
- Designed for public sharing and collaboration

## Quick Start

Clone the repository and run the bootstrap script:

```sh
# On your Ubuntu server
sudo apt update && sudo apt install -y git

git clone https://github.com/YOUR_GITHUB_USERNAME/models-server.git
cd models-server

# Run the bootstrap script (will install Ansible and launch the playbook)
./bootstrap.sh
```

The bootstrap script will:

- Ensure required dependencies are installed (git, python3, pip, ansible)
- Run the Ansible playbook to configure the server (playbook coming soon)

## Structure

- `bootstrap.sh` — Entry point for bootstrapping the server
- `README.md` — This file
- `ansible/` — Ansible playbooks and roles (to be added)

## License

MIT
