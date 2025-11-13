#!/bin/bash
# ROCm Installation Script for WSL2 Ubuntu 22.04
# Based on AMD's official installation guide
# https://ROCm.docs.amd.com/projects/radeon/en/latest/docs/install/wsl/install-radeon.html

set -e  # Exit on error

ROCm_VERSION="6.1.3"
ROCm_BUILD="6.1.60103-1"
LOG_FILE="/tmp/ROCm_install_$(date +%Y%m%d_%H%M%S).log"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1" | tee -a "$LOG_FILE"
}

check_ubuntu_version() {
    log "Checking Ubuntu version..."
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [ "$VERSION_ID" != "22.04" ]; then
            log_error "This script requires Ubuntu 22.04. Detected: $VERSION_ID"
  exit 1
        fi
        log "Ubuntu 22.04 confirmed"
    else
        log_error "Cannot determine Ubuntu version"
        exit 1
 fi
}

update_system() {
    log "Updating system packages..."
    sudo apt update 2>&1 | tee -a "$LOG_FILE"
    log "System packages updated"
}

install_amdgpu() {
    log "Installing AMD GPU drivers for WSL..."
 
    # Download amdgpu-install package
    log "Downloading amdgpu-install package..."
    wget https://repo.radeon.com/amdgpu-install/${ROCm_VERSION}/ubuntu/jammy/amdgpu-install_${ROCm_BUILD}_all.deb \
        -O /tmp/amdgpu-install.deb 2>&1 | tee -a "$LOG_FILE"
    
    # Install the package
    log "Installing amdgpu-install package..."
    sudo apt install /tmp/amdgpu-install.deb -y 2>&1 | tee -a "$LOG_FILE"
    
    # Run amdgpu-install for WSL with ROCm
    log "Installing AMDGPU and ROCm for WSL (this may take several minutes)..."
    sudo amdgpu-install -y --usecase=wsl,ROCm --no-dkms 2>&1 | tee -a "$LOG_FILE"
    
    log "AMD GPU drivers installed successfully"
}

verify_ROCm_installation() {
 log "Verifying ROCm installation..."
    
    if [ -d "/opt/ROCm" ]; then
        log "ROCm directory found at /opt/ROCm"
   
        # Check for ROCminfo
      if command -v ROCminfo &> /dev/null; then
      log "ROCminfo command available"
            ROCminfo 2>&1 | tee -a "$LOG_FILE"
        else
   log_warning "ROCminfo command not found in PATH"
        fi
    else
    log_error "ROCm directory not found at /opt/ROCm"
        return 1
    fi
}

setup_environment() {
    log "Setting up environment variables..."
    
    # Add ROCm to PATH if not already present
    if ! grep -q "/opt/ROCm/bin" ~/.bashrc; then
        echo '' >> ~/.bashrc
     echo '# ROCm Environment Variables' >> ~/.bashrc
        echo 'export PATH=$PATH:/opt/ROCm/bin' >> ~/.bashrc
      echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/ROCm/lib' >> ~/.bashrc
        log "ROCm environment variables added to ~/.bashrc"
    else
        log "ROCm environment variables already present in ~/.bashrc"
  fi
    
    # Source the bashrc
    source ~/.bashrc 2>/dev/null || true
}

display_summary() {
    log "======================================"
    log "ROCm Installation Summary"
    log "======================================"
    log "ROCm Version: ${ROCm_VERSION}"
    log "Installation Log: ${LOG_FILE}"
    log "======================================"
    log "Next Steps:"
    log "1. Close and reopen your terminal to load environment variables"
    log "2. Run 'ROCminfo' to verify GPU detection"
    log "3. Proceed with PyTorch ROCm installation if needed"
    log "======================================"
}

# Main installation flow
main() {
    log "=== Starting ROCm Installation for WSL2 ==="
  log "ROCm Version: ${ROCm_VERSION}"
    
    check_ubuntu_version
    update_system
    install_amdgpu
    verify_ROCm_installation
    setup_environment
    display_summary
    
    log "=== ROCm Installation Complete ==="
}

# Run main function
main
