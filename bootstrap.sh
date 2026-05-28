#!/bin/bash
# Exit on errors and unset vars.
set -euo pipefail

SKIP_GPU=false
EXTRA_ANSIBLE_ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-gpu)
            SKIP_GPU=true
            shift
            ;;
        --help|-h)
            cat <<'EOF'
Usage: ./bootstrap.sh [--skip-gpu] [-- <extra ansible-playbook args>]

Options:
  --skip-gpu   Skip NVIDIA-specific tasks (useful for local VM testing)
  --help       Show this help message

Any additional arguments are passed through to ansible-playbook.
EOF
            exit 0
            ;;
        --)
            shift
            EXTRA_ANSIBLE_ARGS+=("$@")
            break
            ;;
        *)
            EXTRA_ANSIBLE_ARGS+=("$1")
            shift
            ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Capture the non-root user who invoked the script
CURRENT_USER=${SUDO_USER:-$USER}

echo "=========================================="
echo " Starting AI Server Bootstrap Process"
echo " Target User: $CURRENT_USER"
if [ "$SKIP_GPU" = true ]; then
    echo " Mode: TESTING (Skipping GPU Setup)"
else
    echo " Mode: PRODUCTION (Including NVIDIA Setup)"
fi
echo "=========================================="

echo "=> Updating apt cache and installing Ansible..."
sudo apt-get update -y
sudo apt-get install -y ansible

echo "=> Installing required Ansible collections..."
sudo ansible-galaxy collection install -r "$SCRIPT_DIR/requirements.yml"

echo "=> Executing Ansible Playbook..."
ANSIBLE_CMD=(sudo ansible-playbook "$SCRIPT_DIR/playbook.yml" -e "target_user=$CURRENT_USER")

if [ "$SKIP_GPU" = true ]; then
    ANSIBLE_CMD+=(--skip-tags "gpu")
fi

ANSIBLE_CMD+=("${EXTRA_ANSIBLE_ARGS[@]}")
"${ANSIBLE_CMD[@]}"

echo ""
echo "========================================================================="
echo "  BOOTSTRAP COMPLETE!"
if [ "$SKIP_GPU" = false ]; then
    echo "  CRITICAL: You must reboot your server now to load the Nvidia drivers."
    echo "  Command: sudo reboot"
    echo ""
    echo "  After rebooting, wait 60 seconds, then open your browser to:"
else
    echo "  (Skipped GPU driver installation. No reboot required.)"
    echo ""
    echo "  Open your browser to:"
fi
echo "  http://<your-server-ip>:5001"
echo "========================================================================="
