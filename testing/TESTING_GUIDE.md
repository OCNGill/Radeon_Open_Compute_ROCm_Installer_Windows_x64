# ROCm Windows Installer - Testing Guide

## ?? Purpose

This guide walks you through testing your ROCm MSI installer using two complementary approaches:
1. **Hyper-V VM**: Full-featured testing environment (persistent, snapshot-capable)
2. **Windows Sandbox**: Quick disposable testing (fast, clean every time)

---

## ?? Prerequisites

### System Requirements
- ? Windows 11 Pro (Build 22000+)
- ? Ryzen 5900X with 48GB RAM
- ? Radeon 7900 XTX 24GB
- ? F:\ drive with 130GB+ free space
- ? Administrator privileges

### Software Requirements
- ? Hyper-V enabled (for VM testing)
- ? Windows Sandbox enabled (for quick testing)
- ? Built MSI installer file

### Enable Features (if not already enabled)

```powershell
# Run as Administrator

# Enable Hyper-V
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -NoRestart

# Enable Windows Sandbox
Enable-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM -NoRestart

# Reboot after enabling
Restart-Computer
```

---

## ??? Method 1: Hyper-V VM Testing (Recommended for Full Testing)

### Overview
Hyper-V provides a full Windows 11 VM where you can:
- Test complete installer behavior
- Verify WSL2 installation within the VM
- Check registry modifications
- Test rollback/uninstall
- Take snapshots before/after installation
- Simulate real user environment

### Step 1: Create the VM

```powershell
# Navigate to repository
cd C:\Users\steph\source\repos\OCNGill\rOCM_Installer_Win11

# Run VM setup script
.\testing\vm_setup_hyperv.ps1

# With custom settings (optional)
.\testing\vm_setup_hyperv.ps1 -VMName "ROCm_Test_VM" -MemoryGB 24 -ProcessorCount 4
```

**What this script does:**
- ? Creates VM directory structure on F:\ROCm_VM_Testing
- ? Creates 127GB dynamic VHD (grows as needed)
- ? Configures 4 vCPUs (8 threads)
- ? Sets up 24GB RAM (dynamic: 4-24GB)
- ? Enables TPM 2.0 (required for Windows 11)
- ? Enables Secure Boot
- ? Enables nested virtualization (for WSL2)
- ? Attaches Windows 11 ISO (if found)

### Step 2: Install Windows 11 in the VM

```powershell
# Start the VM
Start-VM -Name "ROCm_Test_VM"

# Connect to VM console
vmconnect localhost "ROCm_Test_VM"
```

**Installation Steps:**

1. **Boot from ISO**
   - VM will boot from Windows 11 ISO
   - Press any key when prompted

2. **Windows 11 Setup Wizard**
   - Language: English (United States)
   - Time: (Your timezone)
   - Keyboard: US
   - Click "Install now"

3. **Product Key**
   - Click "I don't have a product key"
   - (You can activate later if needed)

4. **Edition Selection**
   - Choose **Windows 11 Pro**
   - (Pro is required for Hyper-V features)

5. **License Agreement**
   - Accept terms

6. **Installation Type**
   - Choose "Custom: Install Windows only (advanced)"

7. **Disk Configuration**
   - Select the 127GB drive
   - Click "Next" (installer will create partitions)

8. **Wait for Installation**
   - Files will copy (5-10 minutes)
   - VM will reboot automatically

9. **Out-of-Box Experience (OOBE)**
   - Region: United States
   - Keyboard: US
   - **Network**: Skip for now (Click "I don't have internet")
   - Name your PC: `ROCm-TestVM`
   - Create local account:
     - Username: `tester`
     - Password: (your choice)
     - Security questions: (answer them)

10. **Privacy Settings**
    - Disable all telemetry (recommended for testing)
    - Click "Accept"

11. **First Login**
  - Wait for desktop to appear
    - Dismiss any setup prompts

### Step 3: Configure Fresh Windows 11 Installation

```powershell
# Inside the VM, open PowerShell as Administrator
```

```powershell
# Update Windows (important!)
Install-Module PSWindowsUpdate -Force
Get-WindowsUpdate -Install -AcceptAll -AutoReboot

# Wait for all updates to complete and reboots to finish
```

After updates:

```powershell
# Disable Windows Defender (optional, for testing speed)
Set-MpPreference -DisableRealtimeMonitoring $true

# Enable script execution
Set-ExecutionPolicy RemoteSigned -Force

# Create a clean checkpoint
```

Back on your host machine:

```powershell
# Create snapshot of clean Windows install
Checkpoint-VM -Name "ROCm_Test_VM" -SnapshotName "Clean_Win11_Updated"
```

### Step 4: Copy Installer to VM

#### Option A: Enhanced Session (Easiest)

1. Enable Enhanced Session:
```powershell
# On host
Set-VM -VMName "ROCm_Test_VM" -EnhancedSessionTransportType HVSocket
```

2. Connect with Enhanced Session:
```powershell
vmconnect localhost "ROCm_Test_VM"
```

3. When prompted, select "Use my computer's resources"
   - Enable clipboard sharing
 - You can now copy/paste between host and VM!

4. Copy the MSI:
   - On host: Copy MSI file location
   - In VM: Open Explorer, paste path, copy MSI to Desktop

#### Option B: PowerShell Direct (More Reliable)

```powershell
# On host machine

# Copy MSI to VM
$msiPath = "C:\Users\steph\source\repos\OCNGill\rOCM_Installer_Win11\bin\Release\ROCm_Installer_Win11_v1.0.0.0.msi"
$vmName = "ROCm_Test_VM"
$vmDestination = "C:\Users\tester\Desktop\"

# Create session to VM
$password = ConvertTo-SecureString "YOUR_VM_PASSWORD" -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ("tester", $password)

# Copy file
Copy-VMFile -Name $vmName -SourcePath $msiPath -DestinationPath $vmDestination -FileSource Host -CreateFullPath -Force

Write-Host "? MSI copied to VM desktop" -ForegroundColor Green
```

#### Option C: Shared Folder (Alternative)

1. Stop the VM
2. Add shared folder:
```powershell
# Not directly supported in Hyper-V Gen2 VMs
# Use PowerShell Direct or Enhanced Session instead
```

### Step 5: Run Pre-Installation Tests

**Inside the VM, open PowerShell as Administrator:**

```powershell
# Test 1: Verify Windows version
Write-Host "`n=== Windows Version ===" -ForegroundColor Cyan
Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, OsBuildNumber

# Test 2: Check available disk space
Write-Host "`n=== Disk Space ===" -ForegroundColor Cyan
Get-PSDrive C | Select-Object Used, Free, @{N='FreeGB';E={[math]::Round($_.Free/1GB,2)}}

# Test 3: Check for existing WSL installations
Write-Host "`n=== WSL Status ===" -ForegroundColor Cyan
wsl --status

# Test 4: Check for conflicting software
Write-Host "`n=== Installed Software Check ===" -ForegroundColor Cyan
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | 
  Where-Object {$_.DisplayName -like "*AMD*" -or $_.DisplayName -like "*ROCm*"} |
  Select-Object DisplayName, DisplayVersion

# Save baseline
$baseline = @{
    'WindowsVersion' = (Get-ComputerInfo).WindowsVersion
    'DiskSpaceGB' = [math]::Round((Get-PSDrive C).Free/1GB,2)
    'WSLInstalled' = $null -ne (Get-Command wsl -ErrorAction SilentlyContinue)
    'Timestamp' = Get-Date
}

$baseline | ConvertTo-Json | Out-File "C:\Users\tester\Desktop\baseline.json"
Write-Host "`n? Baseline saved" -ForegroundColor Green
```

### Step 6: Install the MSI

**Create checkpoint before installation:**

```powershell
# On host
Checkpoint-VM -Name "ROCm_Test_VM" -SnapshotName "Before_Installer"
```

**Inside the VM:**

```powershell
# Navigate to installer location
cd C:\Users\tester\Desktop

# Test 1: Verify MSI file integrity
$msi = Get-Item "*.msi" | Select-Object -First 1
Write-Host "Installer: $($msi.Name)" -ForegroundColor Yellow
Write-Host "Size: $([math]::Round($msi.Length/1MB,2)) MB" -ForegroundColor Yellow

# Test 2: Run installer with logging
$logFile = "C:\Users\tester\Desktop\install_log.txt"

Write-Host "`n=== Installing ROCm Installer ===" -ForegroundColor Cyan
Write-Host "Log file: $logFile" -ForegroundColor Gray

# Run MSI with verbose logging
Start-Process msiexec.exe -ArgumentList "/i `"$($msi.FullName)`" /L*V `"$logFile`"" -Wait -Verb RunAs

Write-Host "`n? Installation completed" -ForegroundColor Green
```

**Alternative: GUI Installation**

```powershell
# Or simply:
# 1. Double-click the MSI file
# 2. Click "Yes" to UAC prompt
# 3. Follow installation wizard
# 4. Take notes of each step
```

### Step 7: Post-Installation Verification

```powershell
# Inside VM, PowerShell as Administrator

Write-Host "`n=== Post-Installation Verification ===" -ForegroundColor Cyan

# Test 1: Check installed files
Write-Host "`n[1] Installed Files:" -ForegroundColor Yellow
$installPath = "C:\Program Files\ROCm"  # Adjust based on your installer
if (Test-Path $installPath) {
    Get-ChildItem $installPath -Recurse | Measure-Object -Property Length -Sum | 
      Format-Table Count, @{N='SizeMB';E={[math]::Round($_.Sum/1MB,2)}}
    Write-Host "? Files installed" -ForegroundColor Green
} else {
    Write-Host "? Installation directory not found!" -ForegroundColor Red
}

# Test 2: Check registry entries
Write-Host "`n[2] Registry Entries:" -ForegroundColor Yellow
$regPaths = @(
    "HKLM:\SOFTWARE\AMD\ROCm",
    "HKLM:\SOFTWARE\WOW6432Node\AMD\ROCm",
    "HKLM:\SYSTEM\CurrentControlSet\Services\*AMD*"
)

foreach ($regPath in $regPaths) {
    if (Test-Path $regPath) {
        Write-Host "? Found: $regPath" -ForegroundColor Green
        Get-ItemProperty $regPath -ErrorAction SilentlyContinue | Format-List
    }
}

# Test 3: Check environment variables
Write-Host "`n[3] Environment Variables:" -ForegroundColor Yellow
$envVars = @('PATH', 'ROCM_PATH', 'HSA_PATH')
foreach ($var in $envVars) {
    $value = [Environment]::GetEnvironmentVariable($var, 'Machine')
    if ($value -like "*ROCm*" -or $value -like "*AMD*") {
        Write-Host "? $var contains ROCm paths" -ForegroundColor Green
    }
}

# Test 4: Check installed programs
Write-Host "`n[4] Installed Programs:" -ForegroundColor Yellow
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | 
  Where-Object {$_.DisplayName -like "*ROCm*"} |
  Select-Object DisplayName, DisplayVersion, InstallDate |
  Format-Table -AutoSize

# Test 5: Check WSL installation
Write-Host "`n[5] WSL Status:" -ForegroundColor Yellow
wsl --status
wsl --list --verbose

# Test 6: Test WSL ROCm (if WSL was installed)
if (wsl --list | Select-String "Ubuntu") {
    Write-Host "`n[6] ROCm in WSL:" -ForegroundColor Yellow
    wsl -d Ubuntu-22.04 -e bash -c "if command -v rocminfo &> /dev/null; then echo '? rocminfo available'; rocminfo | head -20; else echo '? rocminfo not found'; fi"
}

# Test 7: Check services
Write-Host "`n[7] Services:" -ForegroundColor Yellow
Get-Service | Where-Object {$_.Name -like "*AMD*" -or $_.Name -like "*ROCm*"} |
  Format-Table Name, Status, StartType -AutoSize

# Save verification report
$report = @{
    'InstallationDate' = Get-Date
    'InstalledFiles' = (Test-Path $installPath)
    'RegistryEntries' = ($regPaths | Where-Object {Test-Path $_}).Count
    'WSLInstalled' = $null -ne (wsl --list | Select-String "Ubuntu")
    'LogFile' = $logFile
}

$report | ConvertTo-Json | Out-File "C:\Users\tester\Desktop\verification_report.json"

Write-Host "`n? Verification complete - Report saved" -ForegroundColor Green
```

### Step 8: Test Uninstallation (Optional)

```powershell
# Inside VM

Write-Host "`n=== Testing Uninstallation ===" -ForegroundColor Cyan

# Find the product code
$product = Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -like "*ROCm*"}

if ($product) {
    Write-Host "Found: $($product.Name)" -ForegroundColor Yellow
    Write-Host "Version: $($product.Version)" -ForegroundColor Gray
    
    # Uninstall
    Write-Host "`nUninstalling..." -ForegroundColor Yellow
    $product.Uninstall()
    
    Write-Host "? Uninstallation complete" -ForegroundColor Green
    
    # Verify cleanup
    Write-Host "`nVerifying cleanup..." -ForegroundColor Yellow
    
    if (-not (Test-Path $installPath)) {
  Write-Host "? Installation directory removed" -ForegroundColor Green
    } else {
        Write-Host "? Installation directory still exists" -ForegroundColor Red
    }
}
```

### Step 9: Snapshot Management

```powershell
# On host machine

# List all snapshots
Get-VMSnapshot -VMName "ROCm_Test_VM"

# Restore to clean state
Restore-VMCheckpoint -Name "Clean_Win11_Updated" -VMName "ROCm_Test_VM" -Confirm:$false

# Create new snapshot after successful test
Checkpoint-VM -Name "ROCm_Test_VM" -SnapshotName "Successful_Install_$(Get-Date -Format 'yyyy-MM-dd')"

# Remove old snapshots
Get-VMSnapshot -VMName "ROCm_Test_VM" | Where-Object {$_.Name -like "Before_Installer"} | Remove-VMSnapshot
```

---

## ??? Method 2: Windows Sandbox Testing (Quick & Disposable)

### Overview
Windows Sandbox is perfect for:
- Quick installer tests (clean every time)
- Multiple test runs without VM overhead
- Testing installation wizard UI
- Verifying file deployment
- Fast iteration during development

**Limitations:**
- No WSL2 support (nested virtualization)
- Loses all data when closed
- Limited to testing installer behavior only

### Step 1: Prepare Test Environment

```powershell
# On host machine

# Create folder for test results
New-Item -Path "F:\ROCm_VM_Testing\Sandbox_TestResults" -ItemType Directory -Force

# Build your MSI if not already built
cd C:\Users\steph\source\repos\OCNGill\rOCM_Installer_Win11
.\build_installer.ps1 -Configuration Release

# Verify MSI exists
$msiPath = ".\bin\Release\ROCm_Installer_Win11_v1.0.0.0.msi"
if (Test-Path $msiPath) {
    Write-Host "? MSI ready: $msiPath" -ForegroundColor Green
} else {
  Write-Host "? MSI not found - build first!" -ForegroundColor Red
}
```

### Step 2: Launch Windows Sandbox

```powershell
# Double-click the WSB file
Start-Process "C:\Users\steph\source\repos\OCNGill\rOCM_Installer_Win11\testing\ROCm_Installer_Sandbox.wsb"

# Or from command line
& "C:\Users\steph\source\repos\OCNGill\rOCM_Installer_Win11\testing\ROCm_Installer_Sandbox.wsb"
```

**What happens:**
1. Sandbox creates fresh Windows environment
2. Maps `C:\Installer` (read-only) to your build output
3. Maps `C:\TestResults` (writable) for logs
4. Displays welcome message with instructions
5. Ready for testing in ~30 seconds!

### Step 3: Run Installer in Sandbox

**Inside Windows Sandbox:**

```powershell
# 1. Open PowerShell as Administrator
# (Right-click Start -> Windows PowerShell (Admin))

# 2. Navigate to installer
cd C:\Installer

# 3. List available installers
Get-ChildItem *.msi

# 4. Run installer with logging
$msi = Get-Item "*.msi" | Select-Object -First 1
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = "C:\TestResults\sandbox_install_$timestamp.log"

Write-Host "Installing: $($msi.Name)" -ForegroundColor Yellow
Write-Host "Log: $logFile" -ForegroundColor Gray

msiexec /i "$($msi.FullName)" /L*V "$logFile" /qb

# Wait for completion
Write-Host "`nPress any key after installation completes..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')

# 5. Quick verification
Write-Host "`n=== Quick Verification ===" -ForegroundColor Cyan

# Check install directory
Write-Host "`nInstallation directory:" -ForegroundColor Yellow
Get-ChildItem "C:\Program Files\ROCm\" -ErrorAction SilentlyContinue | Select-Object Name, Length

# Check registry
Write-Host "`nRegistry entries:" -ForegroundColor Yellow
Get-ItemProperty "HKLM:\SOFTWARE\AMD\ROCm" -ErrorAction SilentlyContinue

# Save quick report
@{
    'Timestamp' = Get-Date
    'Installer' = $msi.Name
    'Result' = 'Check log file'
    'LogFile' = $logFile
} | ConvertTo-Json | Out-File "C:\TestResults\quick_report_$timestamp.json"

Write-Host "`n? Test complete - Close sandbox" -ForegroundColor Green
Write-Host "  Results saved to: F:\ROCm_VM_Testing\Sandbox_TestResults" -ForegroundColor Gray
```

### Step 4: Review Results

```powershell
# Back on host machine

# Open test results folder
explorer "F:\ROCm_VM_Testing\Sandbox_TestResults"

# View latest log
$latestLog = Get-ChildItem "F:\ROCm_VM_Testing\Sandbox_TestResults\*.log" | 
  Sort-Object LastWriteTime -Descending | 
  Select-Object -First 1

if ($latestLog) {
    Write-Host "Latest test log: $($latestLog.Name)" -ForegroundColor Yellow
    
    # Check for errors
    $errors = Select-String -Path $latestLog.FullName -Pattern "error|fail|exception" -AllMatches

    if ($errors) {
        Write-Host "? Found $($errors.Count) potential issues" -ForegroundColor Yellow
        $errors | Select-Object -First 10 | Format-Table Line, LineNumber
    } else {
        Write-Host "? No obvious errors in log" -ForegroundColor Green
    }
    
    # Open in notepad
    notepad $latestLog.FullName
}
```

### Step 5: Iterate Quickly

```powershell
# Workflow for rapid testing:

# 1. Make changes to installer
# 2. Rebuild
.\build_installer.ps1 -Configuration Release

# 3. Launch new sandbox (previous one must be closed)
& ".\testing\ROCm_Installer_Sandbox.wsb"

# 4. Test in sandbox
# 5. Review results
# 6. Repeat!
```

---

## ?? Testing Checklist

### Pre-Installation Tests
- [ ] Windows 11 version check (should pass)
- [ ] Disk space verification (50GB+ free)
- [ ] No conflicting software installed
- [ ] No previous ROCm installations
- [ ] Administrator privileges confirmed

### Installation Tests
- [ ] UAC prompt appears
- [ ] Installation wizard launches
- [ ] All wizard pages display correctly
- [ ] Progress bar updates smoothly
- [ ] No error dialogs appear
- [ ] Installation completes successfully
- [ ] No system crash or freeze

### Post-Installation Tests
- [ ] Files copied to correct locations
- [ ] Registry entries created
- [ ] Environment variables set
- [ ] Start menu shortcuts created
- [ ] WSL2 installed (if applicable)
- [ ] Ubuntu distribution installed (if applicable)
- [ ] ROCm packages installed in WSL (if applicable)
- [ ] Services registered and running

### Functional Tests
- [ ] WSL can be launched
- [ ] `rocminfo` command works in WSL
- [ ] GPU detected in WSL
- [ ] Python packages accessible
- [ ] Sample code runs without errors

### Uninstallation Tests
- [ ] Uninstaller runs successfully
- [ ] Files removed completely
- [ ] Registry entries cleaned up
- [ ] Environment variables removed
- [ ] No orphaned files remain
- [ ] System stable after uninstall

### Edge Cases
- [ ] Installation with limited disk space
- [ ] Installation without internet
- [ ] Installation with conflicting software
- [ ] Installation as non-admin (should fail gracefully)
- [ ] Reinstallation over existing installation
- [ ] Installation on minimal Windows install

---

## ?? Common Issues & Solutions

### Issue: VM Won't Start

**Symptoms:** Error when starting VM

**Solutions:**
```powershell
# Check Hyper-V service
Get-Service vmms, vmcompute | Restart-Service

# Verify VM configuration
Get-VM -Name "ROCm_Test_VM" | Format-List *

# Check for resource conflicts
Get-VM | Where-Object {$_.State -eq "Running"}

# Try forced start
Start-VM -Name "ROCm_Test_VM" -Force
```

### Issue: Can't Copy Files to VM

**Symptoms:** Copy-VMFile fails or Enhanced Session doesn't work

**Solutions:**
```powershell
# Method 1: Use shared network folder
# In VM, map network drive to \\MAIN-PC\C$\Users\steph\...

# Method 2: Use ISO
# Create ISO with installer, mount in VM

# Method 3: Download in VM
# Upload MSI to cloud storage, download in VM
```

### Issue: Sandbox Won't Launch

**Symptoms:** Windows Sandbox doesn't open

**Solutions:**
```powershell
# Verify Sandbox is enabled
Get-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM

# Enable if needed
Enable-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM

# Reboot
Restart-Computer

# Check WSB file paths are correct
Get-Content ".\testing\ROCm_Installer_Sandbox.wsb"

# Fix paths if needed, then try again
```

### Issue: MSI Installation Fails

**Symptoms:** Error dialog during installation

**Solutions:**
```powershell
# Check log file for errors
$logFile = "C:\Users\tester\Desktop\install_log.txt"
Select-String -Path $logFile -Pattern "error" -Context 2,2

# Common issues:
# - Missing dependencies -> Install .NET Framework 3.5
# - Insufficient permissions -> Run as Administrator
# - Corrupted MSI -> Rebuild installer
# - Conflicting software -> Uninstall competing products

# Try manual installation with different options
msiexec /i "installer.msi" /L*V "log.txt" /qr  # Reduced UI
msiexec /i "installer.msi" /L*V "log.txt" /passive  # Progress bar only
```

### Issue: WSL2 Not Installing in VM

**Symptoms:** WSL features fail in VM

**Solutions:**
```powershell
# Verify nested virtualization is enabled
Get-VMProcessor -VMName "ROCm_Test_VM" | Select-Object ExposeVirtualizationExtensions

# Enable if needed
Set-VMProcessor -VMName "ROCm_Test_VM" -ExposeVirtualizationExtensions $true

# In VM, manually enable WSL
wsl --install
wsl --set-default-version 2
```

---

## ?? Performance Tips

### Speed Up Testing

```powershell
# Use differencing disks for quick resets
$baseVHD = "F:\ROCm_VM_Testing\Base\Win11_Clean.vhdx"
$testVHD = "F:\ROCm_VM_Testing\Test\Test_$(Get-Date -Format 'HHmmss').vhdx"

New-VHD -Path $testVHD -ParentPath $baseVHD -Differencing

# Create VM with differencing disk (much faster than full install)
```

### Parallel Testing

```powershell
# Run VM test and Sandbox test simultaneously
Start-Process powershell -ArgumentList "-Command Start-VM -Name 'ROCm_Test_VM'"
Start-Sleep -Seconds 2
Start-Process ".\testing\ROCm_Installer_Sandbox.wsb"
```

### Automated Testing Script

```powershell
# Create automated test runner
$testScript = @'
# Automated ROCm Installer Test
param($MSIPath)

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = "C:\TestResults\auto_test_$timestamp.log"

Start-Transcript -Path $logFile

Write-Host "=== Automated Test Started ===" -ForegroundColor Cyan
Write-Host "Time: $(Get-Date)" -ForegroundColor Gray
Write-Host "MSI: $MSIPath" -ForegroundColor Gray

# Pre-test checks
Write-Host "`n[1] Pre-installation checks..." -ForegroundColor Yellow
$diskSpace = [math]::Round((Get-PSDrive C).Free/1GB, 2)
Write-Host "  Disk space: ${diskSpace}GB"

# Install
Write-Host "`n[2] Installing..." -ForegroundColor Yellow
Start-Process msiexec -ArgumentList "/i `"$MSIPath`" /qn /L*V `"$logFile.msi`"" -Wait

# Post-test checks
Write-Host "`n[3] Post-installation checks..." -ForegroundColor Yellow
$installed = Test-Path "C:\Program Files\ROCm"
Write-Host "  Files installed: $installed"

# Results
Write-Host "`n=== Test Complete ===" -ForegroundColor Green
Write-Host "Result: $(if($installed){'PASS'}else{'FAIL'})" -ForegroundColor $(if($installed){'Green'}else{'Red'})

Stop-Transcript

@{
    'Timestamp' = Get-Date
    'MSI' = $MSIPath
    'Result' = $(if($installed){'PASS'}else{'FAIL'})
    'DiskSpace' = $diskSpace
    'LogFile' = $logFile
} | ConvertTo-Json | Out-File "C:\TestResults\result_$timestamp.json"
'@

$testScript | Out-File "F:\ROCm_VM_Testing\Sandbox_TestResults\auto_test.ps1"
```

---

## ?? Test Documentation Template

Create a test report for each installer version:

```markdown
# ROCm Installer Test Report

**Date:** 2025-01-XX
**Tester:** Your Name
**Installer Version:** v1.0.0.0
**Build:** Release

## Test Environment
- OS: Windows 11 Pro (Build XXXXX)
- Hardware: Ryzen 5900X, 48GB RAM, Radeon 7900 XTX
- Test Method: [ ] Hyper-V VM  [ ] Windows Sandbox

## Test Results

### Installation
- [ ] PASS / [ ] FAIL - UAC prompt
- [ ] PASS / [ ] FAIL - Wizard launches
- [ ] PASS / [ ] FAIL - Installation completes
- [ ] PASS / [ ] FAIL - No errors displayed

### File Deployment
- [ ] PASS / [ ] FAIL - Files in Program Files
- [ ] PASS / [ ] FAIL - Shortcuts created
- [ ] PASS / [ ] FAIL - Correct file permissions

### Registry
- [ ] PASS / [ ] FAIL - Registry keys created
- [ ] PASS / [ ] FAIL - Uninstall info added

### WSL Integration
- [ ] PASS / [ ] FAIL - WSL2 installed
- [ ] PASS / [ ] FAIL - Ubuntu distribution added
- [ ] PASS / [ ] FAIL - ROCm available in WSL

### Uninstallation
- [ ] PASS / [ ] FAIL - Uninstaller runs
- [ ] PASS / [ ] FAIL - Files removed
- [ ] PASS / [ ] FAIL - Registry cleaned

## Issues Found
1. 
2. 
3. 

## Notes


## Recommendation
[ ] APPROVED FOR RELEASE
[ ] NEEDS FIXES
```

---

## ?? Lisa Su's Final Checklist

Before declaring your installer "ready for the masses":

- [ ] **Tested on clean Windows 11 install**
- [ ] **Tested without internet connection**
- [ ] **Tested with minimal disk space**
- [ ] **Installation logs are comprehensive**
- [ ] **Error messages are user-friendly**
- [ ] **Uninstaller removes everything**
- [ ] **Works on various hardware configs**
- [ ] **Passes all automated tests**
- [ ] **Documentation is complete**
- [ ] **Ready for AMD's seal of approval!**

---

## ?? Next Steps After Testing

Once your installer passes all tests:

1. **Code Signing** (for distribution)
```powershell
# Sign the MSI for Windows to trust it
# (Requires code signing certificate)
signtool sign /f "cert.pfx" /p "password" /t "http://timestamp.digicert.com" "installer.msi"
```

2. **Create Release Package**
```powershell
# Package everything for release
$version = "1.0.0.0"
$releaseDir = ".\release\v$version"

New-Item -ItemType Directory -Path $releaseDir -Force

Copy-Item ".\bin\Release\*.msi" $releaseDir
Copy-Item ".\README.md" $releaseDir
Copy-Item ".\docs\*" $releaseDir -Recurse

# Create checksums
Get-FileHash "$releaseDir\*.msi" | Format-List | Out-File "$releaseDir\checksums.txt"

# Compress
Compress-Archive -Path $releaseDir -DestinationPath ".\ROCm_Installer_v${version}.zip"
```

3. **Upload to GitHub Release**
4. **Update documentation**
5. **Announce to community!**

---

## ?? Support & Resources

- **VM Setup Issues**: Check Hyper-V documentation
- **Sandbox Issues**: Verify Windows Sandbox requirements
- **Installer Bugs**: Review MSI logs in detail
- **Need Help**: Create GitHub issue with:
  - Test environment details
  - Installation log
  - Screenshots of errors
  - Steps to reproduce

---

**?? Happy Testing! Make AMD proud!**
