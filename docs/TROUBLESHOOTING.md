# ?? Troubleshooting Guide - rOCM Windows 11 Installer

## Table of Contents
1. [Pre-Installation Issues](#pre-installation-issues)
2. [WSL2 Problems](#wsl2-problems)
3. [ROCm Installation Issues](#rocm-installation-issues)
4. [PyTorch Problems](#pytorch-problems)
5. [GPU Detection Issues](#gpu-detection-issues)
6. [Performance Problems](#performance-problems)
7. [Common Error Messages](#common-error-messages)

---

## Pre-Installation Issues

### Windows Version Not Supported
**Problem**: "Windows 11 not detected" error

**Solutions**:
1. Verify Windows version:
   ```powershell
   winver
   ```
   Need: Build 22000 or later

2. Update Windows:
   - Settings ? Windows Update ? Check for updates
   - Install all pending updates
   - Restart

### AMD GPU Not Detected
**Problem**: "No AMD GPU detected" error

**Solutions**:
1. Check Device Manager:
   - Win + X ? Device Manager
   - Display adapters ? Look for AMD/Radeon

2. Update AMD Drivers:
   - Visit [AMD Support](https://www.amd.com/en/support)
   - Download AMD Software 24.6.1 or later
   - Install and restart

3. Check BIOS settings:
   - Ensure GPU is enabled
   - Check PCIe settings

### Virtualization Not Enabled
**Problem**: "Virtualization not supported" error

**Solutions**:
1. Check if enabled:
   ```powershell
   systeminfo | findstr /I "hyper"
   ```

2. Enable in BIOS:
   - Restart ? Enter BIOS (usually F2, F10, or Del)
   - Look for Intel VT-x or AMD-V
   - Enable and save
   - Restart

---

## WSL2 Problems

### WSL Installation Fails
**Problem**: `wsl --install` doesn't work

**Solutions**:
1. Enable WSL manually:
   ```powershell
   # Run as Administrator
   dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
   dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
   ```

2. Restart computer

3. Download WSL2 kernel update:
   - [WSL2 Kernel Update](https://aka.ms/wsl2kernel)
   - Install manually

4. Set WSL2 as default:
 ```powershell
   wsl --set-default-version 2
   ```

### Ubuntu Won't Start
**Problem**: WSL distribution fails to launch

**Solutions**:
1. Check WSL status:
   ```powershell
   wsl --list --verbose
   ```

2. Update WSL:
   ```powershell
   wsl --update
   wsl --shutdown
   ```

3. Reset distribution (last resort):
   ```powershell
   wsl --unregister Ubuntu-22.04
   wsl --install -d Ubuntu-22.04
   ```

### WSL Network Issues
**Problem**: Can't access internet from WSL

**Solutions**:
1. Restart WSL:
   ```powershell
   wsl --shutdown
   wsl
   ```

2. Check DNS in WSL:
   ```bash
   cat /etc/resolv.conf
   # Should show nameserver (like 8.8.8.8)
   ```

3. Fix DNS manually:
   ```bash
   sudo rm /etc/resolv.conf
   echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
   ```

4. Disable auto-generation:
   ```bash
   echo "[network]" | sudo tee /etc/wsl.conf
   echo "generateResolvConf = false" | sudo tee -a /etc/wsl.conf
   ```

---

## ROCm Installation Issues

### amdgpu-install Package Not Found
**Problem**: 404 error when downloading package

**Solutions**:
1. Check AMD repository status:
   ```bash
   ping repo.radeon.com
   ```

2. Try alternative download:
   ```bash
   wget --no-check-certificate https://repo.radeon.com/amdgpu-install/6.1.3/ubuntu/jammy/amdgpu-install_6.1.60103-1_all.deb
   ```

3. Verify Ubuntu version:
   ```bash
   lsb_release -a
   # Must be 22.04 (jammy)
   ```

### ROCm Installation Hangs
**Problem**: Installation freezes during `amdgpu-install`

**Solutions**:
1. Check disk space:
 ```bash
   df -h
   # Need at least 20GB free
   ```

2. Check memory:
   ```bash
   free -h
   # Close unnecessary Windows applications
   ```

3. Run with verbose logging:
   ```bash
   sudo amdgpu-install -y --usecase=wsl,rocm --no-dkms 2>&1 | tee install.log
   ```

4. Install in smaller steps:
   ```bash
   sudo apt update
   sudo apt install -y rocm-hip-runtime
   sudo apt install -y rocminfo
   ```

### Permission Denied Errors
**Problem**: "Permission denied" during installation

**Solutions**:
1. Ensure using sudo:
   ```bash
   sudo amdgpu-install -y --usecase=wsl,rocm --no-dkms
   ```

2. Check file permissions:
   ```bash
   ls -la /tmp/amdgpu-install.deb
   ```

3. Change ownership:
   ```bash
   sudo chown $USER:$USER /tmp/amdgpu-install.deb
   ```

---

## PyTorch Problems

### PyTorch Installation Fails
**Problem**: Wheel files won't install

**Solutions**:
1. Verify Python version:
   ```bash
   python3 --version
   # Should be 3.10.x
   ```

2. Update pip:
   ```bash
   pip3 install --upgrade pip setuptools wheel
   ```

3. Install dependencies first:
   ```bash
   sudo apt install -y python3-dev build-essential
 ```

4. Download wheels manually:
   ```bash
   cd /tmp
   wget https://repo.radeon.com/rocm/manylinux/rocm-rel-6.1.3/torch-2.1.2%2Brocm6.1.3-cp310-cp310-linux_x86_64.whl
   ```

### HSA Runtime Error
**Problem**: "Could not load HSA runtime" error

**Solutions**:
1. Find torch location:
   ```bash
   pip3 show torch | grep Location
   ```

2. Fix manually:
   ```bash
   cd $(pip3 show torch | grep Location | awk '{print $2}')/torch/lib
   sudo rm -f libhsa-runtime64.so*
   sudo cp /opt/rocm/lib/libhsa-runtime64.so.1.2 libhsa-runtime64.so
   ```

3. Verify fix:
   ```bash
   ldd $(pip3 show torch | grep Location | awk '{print $2}')/torch/lib/libtorch_hip.so | grep hsa
   ```

### PyTorch Can't Find GPU
**Problem**: `torch.cuda.is_available()` returns False

**Solutions**:
1. Check ROCm installation:
   ```bash
   rocminfo
   # Should show your GPU
   ```

2. Check environment variables:
   ```bash
   echo $PATH | grep rocm
   echo $LD_LIBRARY_PATH | grep rocm
   ```

3. Add to .bashrc if missing:
   ```bash
   echo 'export PATH=$PATH:/opt/rocm/bin' >> ~/.bashrc
   echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/rocm/lib' >> ~/.bashrc
   source ~/.bashrc
   ```

4. Test with verbose output:
   ```python
   import torch
   print(f"PyTorch version: {torch.__version__}")
   print(f"CUDA available: {torch.cuda.is_available()}")
   print(f"Device count: {torch.cuda.device_count()}")
   if torch.cuda.is_available():
   print(f"Device name: {torch.cuda.get_device_name(0)}")
   ```

---

## GPU Detection Issues

### rocminfo Shows No GPU
**Problem**: `rocminfo` doesn't list GPU

**Solutions**:
1. Check Windows GPU visibility:
   ```powershell
   # In Windows PowerShell
   Get-WmiObject Win32_VideoController | Select Name, DriverVersion
   ```

2. Update Windows AMD drivers:
   - Must be AMD Software 24.6.1 or later
   - Download from [AMD.com](https://www.amd.com/en/support)

3. Restart WSL after driver update:
   ```powershell
   wsl --shutdown
   wsl
   ```

4. Check WSL GPU access:
   ```bash
   ls -la /dev/dri
   # Should show renderD* devices
```

### Wrong GPU Detected
**Problem**: rocminfo shows different GPU

**Solutions**:
1. Check all GPUs:
   ```bash
   rocminfo | grep "Marketing Name"
   ```

2. Select correct GPU in PyTorch:
   ```python
   import torch
   torch.cuda.set_device(0)  # or 1, 2, etc.
   ```

---

## Performance Problems

### Slow Training/Inference
**Problem**: AI models run slower than expected

**Solutions**:
1. Verify GPU is being used:
   ```python
   import torch
   x = torch.rand(5, 3).cuda()
   print(x.device)  # Should show cuda:0
   ```

2. Check GPU utilization:
   ```bash
 rocm-smi
   ```

3. Optimize batch size:
   - Increase batch size for better GPU utilization
   - Monitor VRAM usage

4. Use mixed precision:
   ```python
   from torch.cuda.amp import autocast
   with autocast():
       output = model(input)
   ```

### High Memory Usage
**Problem**: Running out of VRAM

**Solutions**:
1. Check current usage:
   ```bash
   rocm-smi --showmeminfo vram
   ```

2. Reduce batch size

3. Enable gradient checkpointing

4. Clear cache:
 ```python
   import torch
   torch.cuda.empty_cache()
   ```

---

## Common Error Messages

### "WslRegisterDistribution failed with error: 0x800701bc"
**Cause**: WSL kernel not updated

**Fix**:
```powershell
wsl --update
wsl --shutdown
```

### "The attempted operation is not supported for the type of object referenced"
**Cause**: Virtualization not enabled

**Fix**: Enable VT-x/AMD-V in BIOS

### "Unresolved symbol HSA"
**Cause**: HSA runtime library mismatch

**Fix**: Run PyTorch installation script again or fix manually (see HSA Runtime Error above)

### "CUDA out of memory"
**Cause**: Model too large for GPU

**Fix**:
- Reduce batch size
- Use gradient accumulation
- Enable model parallelism

### "ImportError: libamdhip64.so.6: cannot open shared object file"
**Cause**: ROCm libraries not in library path

**Fix**:
```bash
echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/rocm/lib' >> ~/.bashrc
source ~/.bashrc
```

---

## Getting Additional Help

### Collect Diagnostic Information
```bash
# System info
uname -a
lsb_release -a

# ROCm info
rocminfo > rocm_info.txt
rocm-smi > rocm_smi.txt

# PyTorch info
python3 -c "import torch; print(torch.__version__); print(torch.cuda.is_available())" > pytorch_info.txt

# Logs
cat /tmp/rocm_install_*.log > installation_log.txt
```

### Where to Get Help
1. **Check installation logs**: `logs/` directory
2. **AMD ROCm Documentation**: https://rocm.docs.amd.com/
3. **GitHub Issues**: https://github.com/OCNGill/rOCM_Installer_Win11/issues
4. **AMD Community Forums**: https://community.amd.com/
5. **Reddit r/ROCm**: https://www.reddit.com/r/ROCm/

### Reporting Bugs
When reporting issues, include:
- Windows version (`winver`)
- GPU model
- AMD driver version
- Installation logs
- Error messages (full text)
- Steps to reproduce

---

## Last Resort: Clean Reinstall

If all else fails:

```powershell
# In Windows PowerShell (as Administrator)
wsl --unregister Ubuntu-22.04
wsl --install -d Ubuntu-22.04
```

Then run the installer again from the beginning.

---

**Still stuck? Create a GitHub issue with your diagnostic information!**
