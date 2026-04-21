#!/bin/bash
# Exit immediately if a command exits with a non-zero status
set -e

# Check for the --skip-gpu flag
SKIP_GPU=false
if [[ "$1" == "--skip-gpu" ]]; then
    SKIP_GPU=true
fi

# Capture the non-root user who invoked the script
CURRENT_USER=$USER

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
sudo apt-get install -y software-properties-common
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt-get install -y ansible

echo "=> Executing Ansible Playbook..."
if [ "$SKIP_GPU" = true ]; then
    sudo ansible-playbook playbook.yml -e "target_user=$CURRENT_USER" --skip-tags "gpu"
else
    sudo ansible-playbook playbook.yml -e "target_user=$CURRENT_USER"
fi

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
