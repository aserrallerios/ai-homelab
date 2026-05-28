# AI Homelab Headless Server Setup

An Infrastructure as Code (IaC) repository to bootstrap a bare-metal, headless Ubuntu Server for local AI workloads (like Ollama and vLLM).

Using Ansible, this deployment configures NVIDIA drivers, hardware power limits, Docker runtimes, UFW firewalls, and deploys [Dockge](https://dockge.kuma.pet/) for web-based container management—all via a single command.

## 🌟 Features

* **Automated GPU Provisioning:** Installs proprietary NVIDIA drivers, `nvtop`, and the NVIDIA Container Toolkit.
* **Deterministic GPU Driver Option:** Supports pinning an exact NVIDIA driver package (`nvidia_driver_package`) for reproducible builds.
* **Persistent Power Limits:** Deploys a systemd service with NVIDIA Persistence Mode (`-pm 1`) to lock GPU power consumption (default 250W), massively improving thermal efficiency for memory-bound LLM tasks without sacrificing performance.
* **Security First:** Enables UFW with default deny policy, allows SSH, and restricts AI service ports (Ollama 11434, vLLM 8000, Dockge 5001) to private CIDR ranges by default.
* **Safer Dockge Default:** Binds Dockge to `127.0.0.1:5001` by default, so you can expose it intentionally via reverse proxy or by setting `dockge_bind_ip`.
* **Quality of Life Utilities:** Pre-installs essential headless utilities like `htop`, `tmux`, `gdu` (Go Disk Usage), and `ncdu`.
* **Built-in Validation:** Includes `ansible-lint` config and GitHub Actions CI workflow for lint and syntax checks.

## 📂 Repository Structure

```text
ai-homelab/
├── .ansible-lint.yml               # Lint rules for Ansible
├── .github/workflows/
│   └── ansible-lint.yml            # CI lint + syntax checks
├── requirements.yml                # Required Ansible collections
├── templates/
│   ├── dockge-docker-compose.yml.j2
│   └── gpu-limit.service.j2
├── playbook.yml                    # The core Ansible playbook
├── bootstrap.sh                    # Entrypoint execution script
└── README.md
```

## 🚀 Production Deployment (Bare Metal)

**Prerequisites:**

* A fresh installation of Ubuntu Server LTS (22.04 or 24.04)
* An NVIDIA GPU installed in the system
* OpenSSH Server enabled during the OS installation

1. SSH into your fresh Ubuntu Server as your standard (non-root) user:

   ```bash
   ssh your_username@<server-ip>
   ```

1. Clone this repository and run the bootstrap script:

   ```bash
   git clone https://github.com/aserrallerios/ai-homelab.git
   cd ai-homelab
   chmod +x bootstrap.sh
   ./bootstrap.sh
   ```

    You can pass additional `ansible-playbook` flags through bootstrap, for example:

    ```bash
    ./bootstrap.sh -- --check --diff
    ```

1. When the script finishes, **reboot the server** to load the new Linux kernel modules for the NVIDIA drivers:

  ```bash
  sudo reboot
  ```

1. By default, Dockge is bound to localhost (`127.0.0.1:5001`).

   * Use SSH tunneling for secure access:

     ```bash
     ssh -L 5001:127.0.0.1:5001 your_username@<server-ip>
     ```

   * Then open `http://127.0.0.1:5001` in your browser.

   If you want LAN exposure instead, set `dockge_bind_ip` in `playbook.yml` (for example to your server LAN IP) before running bootstrap.

## 🧪 Local Testing (Mac / No-GPU Testing)

If you want to test the directory creation, firewall rules, and Dockge deployment locally on a machine without an NVIDIA GPU (e.g., inside an Ubuntu VM on an Apple Silicon Mac), you can bypass the GPU installation tasks using the `--skip-gpu` flag.

### 1. Spinning up a Test VM (Multipass)

You can use [Multipass](https://multipass.run/) to spin up a local Ubuntu environment on your Mac:

```bash
# Install Multipass via Homebrew
brew install --cask multipass

# Launch a test VM named 'ai-test'
multipass launch 24.04 --name ai-test --cpus 2 --memory 4G --disk 20G

# Drop into the VM shell
multipass shell ai-test
```

### 2. Running the Test Bootstrap

Inside your test VM, clone the repository and execute the bootstrap script with the `--skip-gpu` flag:

```bash
git clone https://github.com/aserrallerios/ai-homelab.git
cd ai-homelab
chmod +x bootstrap.sh
./bootstrap.sh --skip-gpu
```

> [!NOTE]
> _(No reboot is required when running in testing mode. You can immediately access Dockge via the VM's IP address, which you can find by typing `ip a`)._

When finished testing, you can clean up your Mac's resources by exiting the VM (`exit`) and running:

```bash
multipass delete ai-test && multipass purge
```

## ⚙️ Customization

If you are using a lower-end or higher-end GPU, you will want to adjust the maximum wattage limit. Open `playbook.yml` and modify the `gpu_power_limit` variable (in watts) under the `vars:` section before running the bootstrap script:

```yaml
  vars:
    # Set to your desired wattage (e.g., 250 for RTX 3090/4090, 150 for RTX 4070)
    gpu_power_limit: 250
```

For deterministic NVIDIA installs, optionally set a pinned driver package:

```yaml
  vars:
    nvidia_driver_package: "nvidia-driver-550"
```

To control network exposure:

```yaml
  vars:
    dockge_bind_ip: "127.0.0.1"
    dockge_port: "5001"
    ufw_allow_from_cidrs:
      - "10.0.0.0/8"
      - "172.16.0.0/12"
      - "192.168.0.0/16"
```

If you add new GPU-dependent tasks, keep tagging them with `tags: [gpu]` so `--skip-gpu` remains effective.
