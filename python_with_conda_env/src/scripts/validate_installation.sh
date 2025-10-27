#!/bin/bash
# Comprehensive Validation Script for ROCm Installation
# Tests all components and generates a detailed report

set -e

VALIDATION_LOG="/tmp/ROCm_validation_$(date +%Y%m%d_%H%M%S).log"
PASSED_TESTS=0
FAILED_TESTS=0
WARNING_TESTS=0

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1" | tee -a "$VALIDATION_LOG"
}

log_success() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] ? $1${NC}" | tee -a "$VALIDATION_LOG"
    ((PASSED_TESTS++))
}

log_error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] ? $1${NC}" | tee -a "$VALIDATION_LOG"
    ((FAILED_TESTS++))
}

log_warning() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] ??  $1${NC}" | tee -a "$VALIDATION_LOG"
    ((WARNING_TESTS++))
}

log_header() {
    echo "" | tee -a "$VALIDATION_LOG"
    echo -e "${BLUE}========================================${NC}" | tee -a "$VALIDATION_LOG"
    echo -e "${BLUE}$1${NC}" | tee -a "$VALIDATION_LOG"
    echo -e "${BLUE}========================================${NC}" | tee -a "$VALIDATION_LOG"
}

# Test 1: Check Ubuntu version
test_ubuntu_version() {
    log_header "TEST 1: Ubuntu Version Check"
    
    if [ -f /etc/os-release ]; then
  . /etc/os-release
     log "Ubuntu Version: $VERSION"
        
        if [ "$VERSION_ID" = "22.04" ]; then
    log_success "Ubuntu 22.04 confirmed"
            return 0
 else
   log_error "Ubuntu version is $VERSION_ID, expected 22.04"
            return 1
        fi
    else
        log_error "Cannot determine Ubuntu version"
    return 1
    fi
}

# Test 2: Check ROCm installation
test_ROCm_installation() {
    log_header "TEST 2: ROCm Installation Check"
    
    if [ -d "/opt/ROCm" ]; then
        log_success "ROCm directory found at /opt/ROCm"
        
    if [ -f "/opt/ROCm/.info/version" ]; then
            ROCm_VERSION=$(cat /opt/ROCm/.info/version)
    log "ROCm Version: $ROCm_VERSION"
        fi
        
        return 0
    else
  log_error "ROCm directory not found at /opt/ROCm"
        return 1
    fi
}

# Test 3: Check ROCminfo command
test_ROCminfo() {
    log_header "TEST 3: ROCminfo Command Check"
    
    if command -v ROCminfo &> /dev/null; then
        log_success "ROCminfo command available"
        
        log "Running ROCminfo..."
     if ROCminfo &>> "$VALIDATION_LOG"; then
    log_success "ROCminfo executed successfully"
      
            # Check if GPU is detected
    if ROCminfo | grep -q "Name.*gfx"; then
  GPU_NAME=$(ROCminfo | grep "Marketing Name" | head -1 | awk -F: '{print $2}' | xargs)
        log_success "GPU detected: $GPU_NAME"
         return 0
            else
              log_error "No GPU detected by ROCminfo"
       return 1
            fi
        else
     log_error "ROCminfo execution failed"
            return 1
        fi
    else
        log_error "ROCminfo command not found"
     return 1
    fi
}

# Test 4: Check Python installation
test_python() {
    log_header "TEST 4: Python Installation Check"
    
    if command -v python3 &> /dev/null; then
      PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
        log "Python Version: $PYTHON_VERSION"
        
        if [[ "$PYTHON_VERSION" =~ ^3\.10 ]]; then
      log_success "Python 3.10 detected"
            return 0
    else
log_warning "Python version is $PYTHON_VERSION (3.10 recommended)"
    return 0
        fi
    else
        log_error "Python 3 not found"
        return 1
    fi
}

# Test 5: Check PyTorch installation
test_pytorch() {
    log_header "TEST 5: PyTorch Installation Check"
    
  if python3 -c "import torch" &> /dev/null; then
 log_success "PyTorch module found"
        
        TORCH_VERSION=$(python3 -c "import torch; print(torch.__version__)")
        log "PyTorch Version: $TORCH_VERSION"
        
        if [[ "$TORCH_VERSION" == *"ROCm"* ]]; then
         log_success "PyTorch built with ROCm support"
            return 0
    else
            log_warning "PyTorch may not have ROCm support"
   return 0
     fi
    else
        log_error "PyTorch not installed"
        return 1
    fi
}

# Test 6: Check CUDA/ROCm availability in PyTorch
test_pytorch_cuda() {
    log_header "TEST 6: PyTorch CUDA/ROCm Availability"
    
python3 << 'EOF' 2>&1 | tee -a "$VALIDATION_LOG"
import torch

print(f"PyTorch version: {torch.__version__}")
print(f"CUDA available: {torch.cuda.is_available()}")

if torch.cuda.is_available():
    print(f"CUDA/ROCm device count: {torch.cuda.device_count()}")
    print(f"Current device: {torch.cuda.current_device()}")
    print(f"Device name: {torch.cuda.get_device_name(0)}")
    print(f"Device capability: {torch.cuda.get_device_capability(0)}")
    exit(0)
else:
print("ERROR: CUDA/ROCm not available in PyTorch")
    exit(1)
EOF
    
    if [ $? -eq 0 ]; then
        log_success "PyTorch can access GPU via ROCm"
        return 0
    else
        log_error "PyTorch cannot access GPU"
        return 1
    fi
}

# Test 7: Test tensor operations on GPU
test_gpu_operations() {
    log_header "TEST 7: GPU Tensor Operations"
    
    python3 << 'EOF' 2>&1 | tee -a "$VALIDATION_LOG"
import torch

try:
    # Create tensors on GPU
 x = torch.rand(1000, 1000, device='cuda')
    y = torch.rand(1000, 1000, device='cuda')
    
    # Perform operations
    z = torch.matmul(x, y)
    
 print(f"Created tensors on GPU: {x.device}")
    print(f"Matrix multiplication result shape: {z.shape}")
    print(f"Result on device: {z.device}")
    
    # Test moving to CPU
  z_cpu = z.cpu()
    print(f"Successfully moved result to CPU")
    
    print("? All GPU operations successful")
    exit(0)
except Exception as e:
    print(f"ERROR: {str(e)}")
    exit(1)
EOF
    
    if [ $? -eq 0 ]; then
      log_success "GPU tensor operations working"
        return 0
    else
        log_error "GPU tensor operations failed"
        return 1
    fi
}

# Test 8: Check environment variables
test_environment() {
    log_header "TEST 8: Environment Variables"
    
    log "Checking PATH..."
    if echo $PATH | grep -q "/opt/ROCm/bin"; then
        log_success "ROCm bin directory in PATH"
    else
        log_warning "ROCm bin directory not in PATH"
    fi
 
log "Checking LD_LIBRARY_PATH..."
    if echo $LD_LIBRARY_PATH | grep -q "/opt/ROCm/lib"; then
        log_success "ROCm lib directory in LD_LIBRARY_PATH"
    else
        log_warning "ROCm lib directory not in LD_LIBRARY_PATH"
    fi
}

# Test 9: Check HSA runtime
test_hsa_runtime() {
    log_header "TEST 9: HSA Runtime Check"
    
    TORCH_LOCATION=$(python3 -c "import torch; import os; print(os.path.dirname(torch.__file__))" 2>/dev/null)
    
    if [ -n "$TORCH_LOCATION" ]; then
        HSA_LIB="$TORCH_LOCATION/lib/libhsa-runtime64.so"
        
        if [ -f "$HSA_LIB" ]; then
            log_success "HSA runtime library found in PyTorch"
  
            # Check if it's the correct version
   if ldd "$HSA_LIB" &> /dev/null; then
          log_success "HSA runtime library is properly linked"
        return 0
    else
     log_warning "HSA runtime library may have linking issues"
       return 0
            fi
        else
     log_error "HSA runtime library not found in PyTorch"
            return 1
        fi
    else
 log_error "Cannot locate PyTorch installation"
   return 1
    fi
}

# Test 10: Performance benchmark
test_performance() {
    log_header "TEST 10: Performance Benchmark"
    
    python3 << 'EOF' 2>&1 | tee -a "$VALIDATION_LOG"
import torch
import time

device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
print(f"Running benchmark on: {device}")

# Matrix multiplication benchmark
size = 5000
iterations = 10

torch.cuda.synchronize()
start_time = time.time()

for _ in range(iterations):
    a = torch.rand(size, size, device=device)
    b = torch.rand(size, size, device=device)
    c = torch.matmul(a, b)
    torch.cuda.synchronize()

end_time = time.time()
elapsed = end_time - start_time

print(f"Completed {iterations} matrix multiplications ({size}x{size})")
print(f"Total time: {elapsed:.2f} seconds")
print(f"Average time per operation: {elapsed/iterations:.3f} seconds")
print(f"TFLOPS: {(2 * size**3 * iterations) / (elapsed * 1e12):.2f}")

# Memory test
print(f"\nGPU Memory Usage:")
print(f"Allocated: {torch.cuda.memory_allocated(0) / 1024**2:.2f} MB")
print(f"Cached: {torch.cuda.memory_reserved(0) / 1024**2:.2f} MB")
EOF
    
    if [ $? -eq 0 ]; then
        log_success "Performance benchmark completed"
        return 0
    else
        log_error "Performance benchmark failed"
  return 1
    fi
}

# Run all tests
log_header "ROCm Installation Validation"
log "Starting comprehensive validation..."
log "Log file: $VALIDATION_LOG"

test_ubuntu_version || true
test_ROCm_installation || true
test_ROCminfo || true
test_python || true
test_pytorch || true
test_pytorch_cuda || true
test_gpu_operations || true
test_environment || true
test_hsa_runtime || true
test_performance || true

# Summary
log_header "Validation Summary"
log "Passed: $PASSED_TESTS"
log "Failed: $FAILED_TESTS"
log "Warnings: $WARNING_TESTS"

TOTAL_TESTS=$((PASSED_TESTS + FAILED_TESTS + WARNING_TESTS))
if [ $TOTAL_TESTS -gt 0 ]; then
    SUCCESS_RATE=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    log "Success Rate: $SUCCESS_RATE%"
fi

log ""
log "Full validation log saved to: $VALIDATION_LOG"

if [ $FAILED_TESTS -eq 0 ]; then
    log_success "? All critical tests passed! Your ROCm installation is working correctly."
    exit 0
else
    log_error "Some tests failed. Please review the log and troubleshoot."
    exit 1
fi
