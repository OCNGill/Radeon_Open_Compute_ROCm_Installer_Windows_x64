# VM Setup Guide for Testing on 7900 XTX System

## Overview

This guide will help you set up Windows 10 and Windows 11 virtual machines on your system with the AMD Radeon RX 7900 XTX for testing the ROCm installer.

---

## System Requirements

**Host System (Gillsystems Main)**:
- CPU: AMD Ryzen with virtualization support (AMD-V/SVM)
- GPU: AMD Radeon RX 7900 XTX
- RAM: 64GB+ (for running multiple VMs)
- Storage: 200GB+ free for VMs
- OS: Windows 11 Pro (or Windows Server)

**Why VMs for Testing?**
- Clean, isolated test environment
- Easy snapshot/restore for repeated testing
- Multiple Windows versions for compatibility testing
- No risk to host system

---

## Hypervisor Options

### Option 1: Hyper-V (Recommended for Windows Host)

**Pros**:
- ? Built into Windows Pro/Enterprise
- ? Excellent performance
- ? GPU passthrough support (via GPU-PV)
- ? Native Windows integration

**Cons**:
- ? Conflicts with other hypervisors
- ? GPU passthrough complex for AMD

**Setup Steps**:

1. **Enable Hyper-V**
   ```powershell
   # Run as Administrator
   Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
   
   # Or via GUI:
   # Control Panel > Programs > Turn Windows features on or off
   # Check: Hyper-V
   ```

2. **Restart System**

3. **Open Hyper-V Manager**
   ```powershell
   virtmgmt.msc
   ```

### Option 2: VMware Workstation Pro (Recommended for Advanced Features)

**Pros**:
- ? Better GPU passthrough (limited)
- ? Excellent snapshot management
- ? Better USB passthrough
- ? Works alongside Hyper-V (in newer versions)

**Cons**:
- ? Commercial license ($199, or free trial)
- ? Resource overhead

**Download**: https://www.vmware.com/products/workstation-pro.html

### Option 3: VirtualBox (Not Recommended)

**Pros**:
- ? Free and open source
- ? Easy to use

**Cons**:
- ? Poor GPU support
- ? Slower performance
- ? No GPU passthrough for AMD
- ? NOT RECOMMENDED FOR THIS PROJECT

---

## Recommended Approach: Hyper-V

We'll use **Hyper-V** since it's free, built-in, and works well for our testing needs (GPU detection will work via AMD drivers on host).

### Step 1: Enable Nested Virtualization (Critical for WSL2)

```powershell
# Run on HOST as Administrator

# For each VM you create:
Set-VMProcessor -VMName "Windows10TestVM" -ExposeVirtualizationExtensions $true
Set-VMProcessor -VMName "Windows11TestVM" -ExposeVirtualizationExtensions $true

# Enable nested virtualization BEFORE first boot
```

### Step 2: Create Windows 11 Test VM

```powershell
# Run as Administrator on HOST

# 1. Create VM
New-VM -Name "Windows11TestVM" `
    -MemoryStartupBytes 16GB `
    -Generation 2 `
    -BootDevice VHD `
    -NewVHDPath "C:\VMs\Windows11Test\Windows11Test.vhdx" `
    -NewVHDSizeBytes 120GB `
    -Switch "Default Switch"

# 2. Configure VM
Set-VMProcessor -VMName "Windows11TestVM" -Count 8
Set-VMMemory -VMName "Windows11TestVM" -DynamicMemoryEnabled $true -MinimumBytes 8GB -MaximumBytes 24GB -StartupBytes 16GB

# 3. Enable nested virtualization (CRITICAL!)
Set-VMProcessor -VMName "Windows11TestVM" -ExposeVirtualizationExtensions $true

# 4. Disable Secure Boot for testing (optional)
Set-VMFirmware -VMName "Windows11TestVM" -EnableSecureBoot Off

# 5. Add TPM (required for Windows 11)
Set-VMKeyProtector -VMName "Windows11TestVM" -NewLocalKeyProtector
Enable-VMTPM -VMName "Windows11TestVM"

# 6. Add DVD drive for Windows ISO
Add-VMDvdDrive -VMName "Windows11TestVM" -Path "C:\ISOs\Win11_23H2_English_x64.iso"

# 7. Set boot order
$dvd = Get-VMDvdDrive -VMName "Windows11TestVM"
Set-VMFirmware -VMName "Windows11TestVM" -FirstBootDevice $dvd
```

### Step 3: Create Windows 10 Test VM

```powershell
# Run as Administrator on HOST

# 1. Create VM (Generation 2 for UEFI)
New-VM -Name "Windows10TestVM" `
    -MemoryStartupBytes 16GB `
  -Generation 2 `
    -BootDevice VHD `
    -NewVHDPath "C:\VMs\Windows10Test\Windows10Test.vhdx" `
    -NewVHDSizeBytes 120GB `
    -Switch "Default Switch"

# 2. Configure VM
Set-VMProcessor -VMName "Windows10TestVM" -Count 8
Set-VMMemory -VMName "Windows10TestVM" -DynamicMemoryEnabled $true -MinimumBytes 8GB -MaximumBytes 24GB -StartupBytes 16GB

# 3. Enable nested virtualization (CRITICAL!)
Set-VMProcessor -VMName "Windows10TestVM" -ExposeVirtualizationExtensions $true

# 4. Disable Secure Boot (Windows 10 compatible)
Set-VMFirmware -VMName "Windows10TestVM" -EnableSecureBoot Off

# 5. Add DVD drive for Windows ISO
Add-VMDvdDrive -VMName "Windows10TestVM" -Path "C:\ISOs\Win10_22H2_English_x64.iso"

# 6. Set boot order
$dvd = Get-VMDvdDrive -VMName "Windows10TestVM"
Set-VMFirmware -VMName "Windows10TestVM" -FirstBootDevice $dvd
```

### Step 4: Download Windows ISOs

**Windows 11 ISO**:
1. Visit: https://www.microsoft.com/software-download/windows11
2. Download Windows 11 (23H2 recommended)
3. Save to `C:\ISOs\Win11_23H2_English_x64.iso`

**Windows 10 ISO**:
1. Visit: https://www.microsoft.com/software-download/windows10
2. Download Windows 10 (22H2 recommended)
3. Save to `C:\ISOs\Win10_22H2_English_x64.iso`

### Step 5: Install Windows in VMs

1. **Start VM**
   ```powershell
   Start-VM -Name "Windows11TestVM"
   
   # Open VM console
   vmconnect localhost "Windows11TestVM"
   ```

2. **Complete Windows Setup**
   - Select Language/Region
   - Choose "I don't have a product key" (skip activation for testing)
   - Select Windows 11 Pro
   - Accept license
   - Choose "Custom: Install Windows only"
   - Create local account (not Microsoft account)
   - Disable all privacy options

3. **Post-Installation Setup**
   ```powershell
   # Inside VM, run as Administrator:
   
   # 1. Check Windows version
   winver
   # Should show: Build 22621 or later (Win11) or 19041+ (Win10)
   
   # 2. Install VM Integration Services (auto-installed in modern Windows)
   # Already included in Windows 10/11
   
   # 3. Update Windows
   # Settings > Windows Update > Check for updates
   # Install all updates
   
   # 4. Enable Hyper-V / Virtual Machine Platform (for nested WSL2)
   Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -All
   Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -All
   
   # 5. Restart VM
   Restart-Computer
   ```

### Step 6: Install AMD Drivers (on HOST)

**Important**: The VMs will detect the AMD GPU through the host's drivers.

```powershell
# On HOST system:
# 1. Download latest AMD Adrenalin drivers
# Visit: https://www.amd.com/en/support
# Select: RX 7900 XTX

# 2. Install AMD drivers on HOST
# This allows VMs to detect the GPU

# 3. Verify GPU detection
Get-WmiObject Win32_VideoController | Where-Object { $_.Name -match "AMD|Radeon" }
```

### Step 7: Prepare VMs for Testing

**On each VM**:

1. **Create Checkpoint (Snapshot)**
   ```powershell
   # On HOST
   Checkpoint-VM -Name "Windows11TestVM" -SnapshotName "Clean Install - Pre ROCm"
   Checkpoint-VM -Name "Windows10TestVM" -SnapshotName "Clean Install - Pre ROCm"
   ```

2. **Copy Installer to VM**
   ```powershell
   # On HOST, share folder or use Enhanced Session
   # Or download from GitHub inside VM
   ```

3. **Verify Prerequisites**
   ```powershell
   # Inside VM as Administrator
   
   # Check Windows version
   [System.Environment]::OSVersion.Version
   
   # Check build number
   (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuildNumber
   
   # Check edition
   (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").EditionID
   
   # Check virtualization
   systeminfo | findstr /i "Hyper-V"
   ```

---

## GPU Testing Considerations

### Important Note About VMs and GPU Passthrough

**Current Limitation**: 
- Hyper-V does **NOT** support AMD GPU passthrough to VMs
- VMs will **NOT** see the 7900 XTX directly
- WSL2 inside the VM will **NOT** have GPU access

**What CAN We Test**:
- ? MSI installer functionality
- ? GUI and UI components
- ? WSL2 installation process
- ? Script execution and error handling
- ? Installation sequence and workflow
- ? Windows 10/11 compatibility checks
- ? Edition detection (Pro vs Enterprise)
- ? Version detection logic

**What CANNOT Be Tested in VM**:
- ? Actual ROCm GPU detection in WSL2
- ? PyTorch GPU functionality
- ? ROCm driver loading
- ? GPU passthrough features

### Recommended Testing Strategy

**Phase 1: VM Testing (Installation Logic)**
1. Test installer on Windows 11 VM
2. Test installer on Windows 10 Pro VM
3. Verify UI, scripts, and workflow
4. Test error handling

**Phase 2: Bare Metal Testing (GPU Functionality)**
1. Install on HOST system (7900 XTX)
2. Test actual GPU detection
3. Test ROCm in WSL2 with GPU
4. Test PyTorch with GPU
5. Validate full stack

---

## Testing Checklist

### Windows 11 VM Tests
- [ ] MSI installs without errors
- [ ] UI displays correctly
- [ ] Edition detection works (Pro)
- [ ] Build number detected correctly (22000+)
- [ ] WSL2 installation succeeds
- [ ] Scripts execute without errors
- [ ] Error messages are clear
- [ ] Uninstall works cleanly

### Windows 10 Pro VM Tests
- [ ] MSI installs on Windows 10
- [ ] Edition detection works (Pro)
- [ ] Build number detected correctly (19041+)
- [ ] Windows 10-specific logic works
- [ ] Smart App Control warning skipped (Win10 only feature)
- [ ] WSL2 installation succeeds
- [ ] No Windows 11-only features break
- [ ] Uninstall works cleanly

### Bare Metal (HOST) Tests
- [ ] GPU detected (7900 XTX)
- [ ] AMD drivers detected
- [ ] WSL2 can access GPU
- [ ] ROCm installed successfully
- [ ] PyTorch detects GPU
- [ ] `torch.cuda.is_available()` returns True
- [ ] Can create tensors on GPU
- [ ] Full validation passes

---

## Quick Start Commands

```powershell
# === ON HOST SYSTEM ===

# 1. Enable Hyper-V
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All

# 2. Create VMs (run create scripts above)

# 3. Enable nested virtualization
Set-VMProcessor -VMName "Windows11TestVM" -ExposeVirtualizationExtensions $true
Set-VMProcessor -VMName "Windows10TestVM" -ExposeVirtualizationExtensions $true

# 4. Start VMs
Start-VM -Name "Windows11TestVM"
Start-VM -Name "Windows10TestVM"

# 5. Connect to VMs
vmconnect localhost "Windows11TestVM"
vmconnect localhost "Windows10TestVM"

# 6. Take snapshots before testing
Checkpoint-VM -Name "Windows11TestVM" -SnapshotName "Pre-Test"
Checkpoint-VM -Name "Windows10TestVM" -SnapshotName "Pre-Test"

# 7. Restore if needed
Restore-VMSnapshot -VMName "Windows11TestVM" -Name "Pre-Test" -Confirm:$false
Restore-VMSnapshot -VMName "Windows10TestVM" -Name "Pre-Test" -Confirm:$false
```

---

## Alternative: Test on Bare Metal Only

If VM setup is too complex, you can test directly on the HOST:

**Pros**:
- ? Full GPU access
- ? Realistic performance
- ? Simpler setup

**Cons**:
- ? Risk to production system
- ? Hard to reset if issues occur
- ? Can't test multiple Windows versions easily

**Recommendation**: 
1. Use VMs for installation workflow testing
2. Use bare metal for final GPU-specific validation
3. Keep good backups before testing on bare metal

---

## AI Assistant Capabilities

**Regarding your question: "Will you be able to set up the proper VMs when I log on from that machine?"**

**Answer**: Yes, but with some clarification:

? **I CAN**:
- Provide PowerShell commands to create VMs
- Guide you through Hyper-V setup
- Help troubleshoot VM issues
- Generate installation scripts
- Provide testing checklists

? **I CANNOT**:
- Directly execute commands on your system
- Access your system remotely
- Create VMs automatically
- See your screen or interact with GUI

**What I WILL DO**:
1. When you connect from the new system, tell me:
   - System specs (RAM, CPU, storage)
   - Windows version on HOST
   - Whether Hyper-V is already enabled

2. I'll generate customized:
   - VM creation scripts for your system
   - Resource allocation recommendations
   - Step-by-step instructions

3. You'll:
   - Copy and paste commands I provide
   - Run them on your system
   - Report back results

**This guide gives you everything needed to set up VMs manually NOW**, or you can wait and I'll customize it when you're on the 7900 XTX system!

---

## Next Steps

1. ? **Push current branch to GitHub**
   ```bash
   git push -u origin full_msi_installer
   ```

2. ? **Switch to 7900 XTX system**

3. ? **Set up VMs using this guide** (or have me customize)

4. ? **Test installer on both Windows 10 and Windows 11**

5. ? **Validate on bare metal with GPU**

6. ? **Document any issues found**

7. ? **Proceed to Phase 2 Day 4**

---

**Ready when you are!** ??
