#!/bin/bash
# ROCm WSL2 Setup Script
# This script installs ROCm in Ubuntu22.04 running under WSL2

set -e
LOG=/tmp/rocm_wsl2_setup.log
exec > >(tee -a "$LOG")2>&1

echo "[ROCm WSL2 Setup] Starting ROCm installation in WSL2..."

# Check for AMD GPU (should be visible via lspci in WSL2 with correct drivers)
if ! lspci | grep -i 'AMD' | grep -i 'VGA' >/dev/null; then
 echo "[ERROR] No AMD GPU detected in WSL2. Ensure your Windows host has a supported AMD GPU and drivers."
 exit1
fi

echo "[INFO] AMD GPU detected. Proceeding with ROCm install."

# Add ROCm repo and install ROCm
sudo apt-get update
sudo apt-get install -y wget gnupg2 lsb-release
wget -qO - https://repo.radeon.com/rocm/rocm.gpg.key | sudo apt-key add -
echo 'deb [arch=amd64] https://repo.radeon.com/rocm/apt/6.1.3 jammy main' | sudo tee /etc/apt/sources.list.d/rocm.list
sudo apt-get update
sudo apt-get install -y rocm-dkms

echo 'export PATH=/opt/rocm/bin:$PATH' | sudo tee -a /etc/profile.d/rocm.sh

echo "[SUCCESS] ROCm installation complete. Please reboot WSL2 or restart your shell."
exit0
