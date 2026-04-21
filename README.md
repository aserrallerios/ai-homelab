# AI Homelab Headless Server Setup

An Infrastructure as Code (IaC) repository to bootstrap a bare-metal, headless Ubuntu Server for local AI workloads (like Ollama and vLLM).

Using Ansible, this deployment configures NVIDIA drivers, hardware power limits, Docker runtimes, UFW firewalls, and deploys [Dockge](https://dockge.kuma.pet/) for web-based container management—all via a single command.

## 🌟 Features

* **Automated GPU Provisioning:** Installs proprietary NVIDIA drivers, `nvtop`, and the NVIDIA Container Toolkit.
* **Persistent Power Limits:** Deploys a systemd service with NVIDIA Persistence Mode (`-pm 1`) to lock GPU power consumption (default 250W), massively improving thermal efficiency for memory-bound LLM tasks without sacrificing performance.
* **Security First:** Automatically configures UFW to block all incoming traffic except SSH, Ollama (11434), vLLM (8000), and Dockge (5001).
* **Dockge Web UI:** Bootstraps standard Docker Compose stacks in `/opt/stacks`, completely bypassing command-line container management.
* **Quality of Life Utilities:** Pre-installs essential headless utilities like `htop`, `tmux`, `gdu` (Go Disk Usage), and `ncdu`.

## 📂 Repository Structure

```text
ai-homelab/
├── files/
│   └── dockge-docker-compose.yml   # Base Docker Compose stack for Dockge
├── templates/
│   └── gpu-limit.service.j2        # Systemd template for GPU power limiting
├── playbook.yml                    # The core Ansible playbook
├── bootstrap.sh                    # Entrypoint execution script
└── README.md
```

## 🚀 Production Deployment (Bare Metal)

**Prerequisites:** * A fresh installation of Ubuntu Server LTS (22.04 or 24.04).

-   An NVIDIA GPU installed in the system.
-   OpenSSH Server enabled during the OS installation.


1.  SSH into your fresh Ubuntu Server as your standard (non-root) user:

    ```bash
    ssh your_username@<server-ip>
    ```

2.  Clone this repository and run the bootstrap script:


    ```bash
    git clone https://github.com/aserrallerios/ai-homelab.git
    cd ai-homelab
    chmod +x bootstrap.sh
    ./bootstrap.sh
    ```

3.  When the script finishes, **reboot the server** to load the new Linux kernel modules for the NVIDIA drivers:


    ```bash
    sudo reboot
    ```

4.  Once the server reboots, navigate to `http://<server-ip>:5001` in your web browser to create your Dockge admin account and start spinning up your AI models!


## 🧪 Local Testing (Mac / No-GPU Testing)

If you want to test the directory creation, firewall rules, and Dockge deployment locally on a machine without an NVIDIA GPU (e.g., inside an Ubuntu VM on an Apple Silicon Mac), you can bypass the GPU installation tasks using the `--skip-gpu` flag.

### 1. Tagging the Playbook

For the `--skip-gpu` flag to work, ensure any GPU-specific tasks in your `playbook.yml` have the `tags: [gpu]` attribute added to them. For example:

```yaml
    - name: Install ubuntu-drivers-common
      apt:
        name: ubuntu-drivers-common
        state: present
      tags: [gpu]  # <--- This tells Ansible to skip this task during local testing
```
> [!IMPORTANT]
> _(Ensure this tag is applied to the NVIDIA drivers, nvtop, the Container Toolkit, and the GPU power limit systemd tasks)._

### 2. Spinning up a Test VM (Multipass)

You can use [Multipass](https://multipass.run/) to spin up a local Ubuntu environment on your Mac:

```bash
# Install Multipass via Homebrew
brew install --cask multipass

# Launch a test VM named 'ai-test'
multipass launch 24.04 --name ai-test --cpus 2 --memory 4G --disk 20G

# Drop into the VM shell
multipass shell ai-test
```

### 3. Running the Test Bootstrap

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

If you add any new tasks to the playbook that require physical GPU hardware, remember to append `tags: [gpu]` to them so you don't break your local testing environment!
