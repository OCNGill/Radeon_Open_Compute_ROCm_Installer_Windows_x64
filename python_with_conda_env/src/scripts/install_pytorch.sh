#!/bin/bash
# PyTorch ROCm Installation Script for WSL2
# Based on AMD's official PyTorch installation guide
# https://ROCm.docs.amd.com/projects/radeon/en/latest/docs/install/wsl/install-pytorch.html

set -e  # Exit on error

ROCm_VERSION="6.1.3"
TORCH_VERSION="2.1.2"
TORCHVISION_VERSION="0.16.1"
TRITON_VERSION="2.1.0"
PYTHON_VERSION="cp310"  # Python 3.10

LOG_FILE="/tmp/pytorch_install_$(date +%Y%m%d_%H%M%S).log"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1" | tee -a "$LOG_FILE"
}

check_python_version() {
    log "Checking Python version..."
    
    if ! command -v python3 &> /dev/null; then
        log_error "Python 3 is not installed"
        exit 1
    fi
    
    PYTHON_VER=$(python3 --version | awk '{print $2}')
    log "Python version: $PYTHON_VER"
    
    # Check if it's Python 3.10
    if [[ ! "$PYTHON_VER" =~ ^3\.10 ]]; then
        log_warning "Python 3.10 is recommended. You have: $PYTHON_VER"
        log_warning "Installation may still work but compatibility is not guaranteed"
    fi
}

install_python_dependencies() {
    log "Installing Python 3 pip..."
    sudo apt install python3-pip -y 2>&1 | tee -a "$LOG_FILE"
    
    log "Upgrading pip and wheel..."
  pip3 install --upgrade pip wheel 2>&1 | tee -a "$LOG_FILE"
}

download_pytorch_wheels() {
    log "Downloading PyTorch ROCm wheel files..."
    
    cd /tmp
    
    # Download torch
    log "Downloading torch ${TORCH_VERSION}+ROCm${ROCm_VERSION}..."
    wget https://repo.radeon.com/ROCm/manylinux/ROCm-rel-${ROCm_VERSION}/torch-${TORCH_VERSION}%2BROCm${ROCm_VERSION}-${PYTHON_VERSION}-${PYTHON_VERSION}-linux_x86_64.whl \
        -O torch-${TORCH_VERSION}+ROCm${ROCm_VERSION}-${PYTHON_VERSION}-${PYTHON_VERSION}-linux_x86_64.whl 2>&1 | tee -a "$LOG_FILE"
    
    # Download torchvision
    log "Downloading torchvision ${TORCHVISION_VERSION}+ROCm${ROCm_VERSION}..."
    wget https://repo.radeon.com/ROCm/manylinux/ROCm-rel-${ROCm_VERSION}/torchvision-${TORCHVISION_VERSION}%2BROCm${ROCm_VERSION}-${PYTHON_VERSION}-${PYTHON_VERSION}-linux_x86_64.whl \
     -O torchvision-${TORCHVISION_VERSION}+ROCm${ROCm_VERSION}-${PYTHON_VERSION}-${PYTHON_VERSION}-linux_x86_64.whl 2>&1 | tee -a "$LOG_FILE"
    
    # Download pytorch_triton_ROCm
    log "Downloading pytorch_triton_ROCm ${TRITON_VERSION}+ROCm${ROCm_VERSION}..."
 wget https://repo.radeon.com/ROCm/manylinux/ROCm-rel-${ROCm_VERSION}/pytorch_triton_ROCm-${TRITON_VERSION}%2BROCm${ROCm_VERSION}.4d510c3a44-${PYTHON_VERSION}-${PYTHON_VERSION}-linux_x86_64.whl \
        -O pytorch_triton_ROCm-${TRITON_VERSION}+ROCm${ROCm_VERSION}.4d510c3a44-${PYTHON_VERSION}-${PYTHON_VERSION}-linux_x86_64.whl 2>&1 | tee -a "$LOG_FILE"
    
    log "All wheel files downloaded successfully"
}

uninstall_existing_pytorch() {
    log "Uninstalling any existing PyTorch installations..."
    
    pip3 uninstall -y torch torchvision pytorch-triton-ROCm numpy torchaudio 2>&1 | tee -a "$LOG_FILE" || true
    
    log "Existing PyTorch packages uninstalled"
}

install_pytorch_wheels() {
    log "Installing PyTorch ROCm wheel files..."

    cd /tmp
 
    pip3 install \
        torch-${TORCH_VERSION}+ROCm${ROCm_VERSION}-${PYTHON_VERSION}-${PYTHON_VERSION}-linux_x86_64.whl \
 torchvision-${TORCHVISION_VERSION}+ROCm${ROCm_VERSION}-${PYTHON_VERSION}-${PYTHON_VERSION}-linux_x86_64.whl \
        pytorch_triton_ROCm-${TRITON_VERSION}+ROCm${ROCm_VERSION}.4d510c3a44-${PYTHON_VERSION}-${PYTHON_VERSION}-linux_x86_64.whl \
        numpy==1.26.4 \
        2>&1 | tee -a "$LOG_FILE"
    
    log "Installing torchaudio..."
  pip3 install torchaudio==${TORCH_VERSION} 2>&1 | tee -a "$LOG_FILE"
    
    log "PyTorch packages installed successfully"
}

fix_hsa_runtime() {
    log "Fixing HSA runtime library..."
    
    # Get torch installation location
    TORCH_LOCATION=$(pip3 show torch | grep Location | awk -F ": " '{print $2}')
    
    if [ -z "$TORCH_LOCATION" ]; then
        log_error "Could not find torch installation location"
        return 1
    fi
    
    log "Torch location: ${TORCH_LOCATION}"
    
    cd "${TORCH_LOCATION}/torch/lib/"
    
    # Remove existing HSA runtime library symlinks
    sudo rm -f libhsa-runtime64.so* 2>&1 | tee -a "$LOG_FILE" || true
    
    # Copy the correct HSA runtime library
    sudo cp /opt/ROCm/lib/libhsa-runtime64.so.1.2 libhsa-runtime64.so 2>&1 | tee -a "$LOG_FILE"
    
    log "HSA runtime library fixed"
}

verify_pytorch_installation() {
    log "Verifying PyTorch installation..."
    
 # Create a test script
    cat > /tmp/test_pytorch.py << 'EOF'
import torch
import sys

print(f"PyTorch version: {torch.__version__}")
print(f"CUDA available: {torch.cuda.is_available()}")

if torch.cuda.is_available():
    print(f"CUDA device count: {torch.cuda.device_count()}")
    print(f"Current CUDA device: {torch.cuda.current_device()}")
    print(f"CUDA device name: {torch.cuda.get_device_name(0)}")
    print(f"CUDA capability: {torch.cuda.get_device_capability(0)}")
    
    # Test tensor creation on GPU
    try:
        x = torch.rand(5, 3).cuda()
      print("Successfully created tensor on GPU")
      print(x)
except Exception as e:
  print(f"Error creating tensor on GPU: {e}")
   sys.exit(1)
else:
    print("WARNING: CUDA/ROCm not available in PyTorch")
    sys.exit(1)

print("PyTorch ROCm installation verified successfully!")
EOF
    
    python3 /tmp/test_pytorch.py 2>&1 | tee -a "$LOG_FILE"
    
    if [ $? -eq 0 ]; then
  log "PyTorch verification successful"
        return 0
    else
  log_error "PyTorch verification failed"
        return 1
 fi
}

create_requirements_template() {
  log "Creating requirements.txt template..."
    
    cat > ~/ROCm_requirements.txt << 'EOF'
# PyTorch ROCm Installation
# These packages are already installed by this script
# torch==2.1.2+ROCm6.1.3
# torchvision==0.16.1+ROCm6.1.3
# torchaudio==2.1.2
# numpy==1.26.4

# Additional recommended packages for ML/AI development
transformers>=4.35.0
accelerate>=0.24.0
datasets>=2.14.0
sentencepiece>=0.1.99
protobuf>=3.20.0
safetensors>=0.4.0
huggingface-hub>=0.19.0

# For Stable Diffusion and image generation
diffusers>=0.24.0
omegaconf>=2.3.0
pillow>=10.0.0

# Jupyter and notebook support
jupyter>=1.0.0
ipykernel>=6.25.0
ipywidgets>=8.1.0

# Utilities
tqdm>=4.66.0
requests>=2.31.0
pyyaml>=6.0
EOF
    
log "Requirements template created at ~/ROCm_requirements.txt"
    log "You can install additional packages with: pip3 install -r ~/ROCm_requirements.txt"
}

display_summary() {
    log "======================================"
    log "PyTorch ROCm Installation Summary"
    log "======================================"
    log "PyTorch Version: ${TORCH_VERSION}+ROCm${ROCm_VERSION}"
    log "TorchVision Version: ${TORCHVISION_VERSION}+ROCm${ROCm_VERSION}"
    log "Installation Log: ${LOG_FILE}"
    log "======================================"
    log "Next Steps:"
    log "1. Test PyTorch: python3 -c 'import torch; print(torch.cuda.is_available())'"
log "2. Install additional ML packages: pip3 install -r ~/ROCm_requirements.txt"
    log "3. Start building your AI applications!"
    log "======================================"
    log "Important Note:"
  log "When installing other packages (like ComfyUI, Stable Diffusion, etc.),"
  log "make sure to comment out or skip torch installation in their requirements.txt"
    log "to avoid overwriting your ROCm PyTorch installation."
    log "======================================"
}

# Main installation flow
main() {
    log "=== Starting PyTorch ROCm Installation for WSL2 ==="
    log "PyTorch Version: ${TORCH_VERSION}+ROCm${ROCm_VERSION}"
    
    check_python_version
    install_python_dependencies
    download_pytorch_wheels
    uninstall_existing_pytorch
    install_pytorch_wheels
    fix_hsa_runtime
    
    if verify_pytorch_installation; then
        create_requirements_template
        display_summary
 log "=== PyTorch ROCm Installation Complete ==="
        exit 0
    else
        log_error "=== PyTorch ROCm Installation Failed ==="
     log_error "Please check the log file at: ${LOG_FILE}"
      exit 1
    fi
}

# Run main function
main
