# Testing Directory - ROCm Windows Installer

This directory contains all testing resources for the ROCm Windows MSI installer.

## ?? Contents

### Setup Scripts
- **`vm_setup_hyperv.ps1`** - Automated Hyper-V VM creation script
  - Creates Windows 11 VM on F:\ROCm_VM_Testing
  - Configures 4 cores, 24GB RAM, 127GB disk
  - Enables nested virtualization for WSL2
  - Sets up TPM and Secure Boot for Windows 11

### Sandbox Configuration
- **`ROCm_Installer_Sandbox.wsb`** - Windows Sandbox configuration
  - Quick disposable testing environment
  - Maps installer directory (read-only)
  - Maps test results directory (read-write)
  - Perfect for rapid iteration

### Documentation
- **`TESTING_GUIDE.md`** - Comprehensive testing documentation
  - Detailed Hyper-V VM setup and testing procedures
  - Windows Sandbox usage guide
  - Verification checklists
  - Troubleshooting guide
  - Performance tips

- **`QUICK_START.md`** - Quick reference guide
  - Fast command-line workflows
  - Essential checks
  - Common fixes
  - Rapid testing loops

## ?? Quick Start

### First Time Setup

1. **Enable Hyper-V** (if not already enabled):
```powershell
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
Restart-Computer
```

2. **Enable Windows Sandbox** (if not already enabled):
```powershell
Enable-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM
Restart-Computer
```

3. **Create Hyper-V VM**:
```powershell
.\testing\vm_setup_hyperv.ps1
```

### Quick Test (Sandbox)

```powershell
# 1. Build installer
.\build_installer.ps1 -Configuration Release

# 2. Launch Sandbox
.\testing\ROCm_Installer_Sandbox.wsb

# 3. Test in Sandbox
# (See QUICK_START.md for details)
```

### Full Test (VM)

```powershell
# 1. Start VM
Start-VM -Name "ROCm_Test_VM"
vmconnect localhost "ROCm_Test_VM"

# 2. Copy installer to VM
# 3. Test installation
# 4. Verify components
# (See TESTING_GUIDE.md for complete workflow)
```

## ?? Test Storage Locations

### Host Machine
- **VM Storage**: `F:\ROCm_VM_Testing\ROCm_Test_VM\`
  - Virtual hard disks
  - VM configuration
  - Checkpoints

- **Sandbox Results**: `F:\ROCm_VM_Testing\Sandbox_TestResults\`
  - Installation logs
  - Test reports
  - Quick verification results

### Inside VM
- **Installer**: `C:\Users\tester\Desktop\`
- **Logs**: `C:\Users\tester\Desktop\install_log.txt`
- **Reports**: `C:\Users\tester\Desktop\*.json`

### Inside Sandbox
- **Installer**: `C:\Installer\` (mapped from build output)
- **Results**: `C:\TestResults\` (mapped to F:\ROCm_VM_Testing\Sandbox_TestResults)

## ? Testing Checklist

Before declaring installer ready:

- [ ] VM setup script runs successfully
- [ ] Windows 11 installs in VM
- [ ] Installer MSI copies to VM
- [ ] Installation completes without errors
- [ ] Files deployed correctly
- [ ] Registry entries created
- [ ] WSL2 components installed
- [ ] Uninstaller removes everything
- [ ] Sandbox testing successful
- [ ] All logs reviewed
- [ ] No critical issues found

## ?? Documentation

- **Comprehensive Guide**: Read `TESTING_GUIDE.md`
- **Quick Reference**: Read `QUICK_START.md`
- **Main README**: See parent directory

## ?? Troubleshooting

### VM Issues
```powershell
# Restart Hyper-V services
Get-Service vmms, vmcompute | Restart-Service

# Check VM status
Get-VM -Name "ROCm_Test_VM" | Format-List

# Force start
Start-VM -Name "ROCm_Test_VM" -Force
```

### Sandbox Issues
```powershell
# Verify feature is enabled
Get-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM

# Check WSB file paths
Get-Content ".\testing\ROCm_Installer_Sandbox.wsb"
```

### Build Issues
```powershell
# Clean rebuild
.\build_installer.ps1 -Clean -Configuration Release -Verbose
```

## ?? Testing Strategy

1. **Sandbox First**: Quick validation of installer mechanics
2. **VM Second**: Full integration testing with WSL2
3. **Iterate**: Make changes, rebuild, test again
4. **Document**: Record all findings and issues

## ?? Support

- Review troubleshooting sections in TESTING_GUIDE.md
- Check installation logs for specific errors
- Create GitHub issue with:
  - Test environment details
- Full logs
  - Screenshots
  - Steps to reproduce

---

**Happy Testing! Make AMD proud! ??**
