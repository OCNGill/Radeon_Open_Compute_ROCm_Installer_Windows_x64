# ? Quick Start Guide - ROCm Installer Testing

## ?? Option 1: Hyper-V VM (Full Testing - 1 hour)

### Setup
```powershell
cd C:\Users\steph\source\repos\OCNGill\ROCm_Installer_Win11
.\testing\vm_setup_hyperv.ps1
```

### Start & Connect
```powershell
Start-VM -Name "ROCm_Test_VM"
vmconnect localhost "ROCm_Test_VM"
```

### Install Windows 11
- Boot from ISO
- Choose Windows 11 Pro
- Skip product key
- Create local account: `tester`

### Copy Installer
```powershell
# On HOST (adjust password)
$msiPath = ".\bin\Release\ROCm_Installer_Win11_v1.0.0.0.msi"
$password = ConvertTo-SecureString "YOUR_PASSWORD" -AsPlainText -Force
$cred = New-Object PSCredential ("tester", $password)

Copy-VMFile -Name "ROCm_Test_VM" -SourcePath $msiPath `
  -DestinationPath "C:\Users\tester\Desktop\" -FileSource Host -CreateFullPath -Force
```

### Test in VM
```powershell
# In VM
cd C:\Users\tester\Desktop
$msi = Get-Item "*.msi"
msiexec /i "$($msi.FullName)" /L*V "install.log"
```

### Verify
```powershell
Test-Path "C:\Program Files\ROCm"
Get-ItemProperty "HKLM:\SOFTWARE\AMD\ROCm"
wsl --list --verbose
```

---

## ??? Option 2: Windows Sandbox (Quick Test - 5 minutes)

### Build Installer
```powershell
cd C:\Users\steph\source\repos\OCNGill\ROCm_Installer_Win11
.\build_installer.ps1 -Configuration Release
```

### Launch Sandbox
```powershell
Start-Process ".\testing\ROCm_Installer_Sandbox.wsb"
```

### Test in Sandbox
```powershell
# Inside Sandbox (PowerShell as Admin)
cd C:\Installer
$msi = Get-Item "*.msi"
$log = "C:\TestResults\test_$(Get-Date -Format 'HHmmss').log"
msiexec /i "$($msi.FullName)" /L*V "$log" /qb
```

### Check Results
```powershell
# On HOST after closing Sandbox
explorer "F:\ROCm_VM_Testing\Sandbox_TestResults"
notepad (Get-ChildItem "F:\ROCm_VM_Testing\Sandbox_TestResults\*.log" | 
  Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
```

---

## ? Essential Checks

### Before Installation
- [ ] Windows 11 Pro (Build 22000+)
- [ ] 50GB+ free disk space
- [ ] Administrator privileges
- [ ] No previous ROCm installs

### After Installation
- [ ] Files exist: `C:\Program Files\ROCm\`
- [ ] Registry key: `HKLM:\SOFTWARE\AMD\ROCm`
- [ ] WSL2 installed: `wsl --status`
- [ ] Ubuntu available: `wsl -d Ubuntu-22.04 -e ROCminfo`

### Logs to Review
- Installation: `install.log`
- MSI verbose: Search for "error" and "return value 3"
- Event Viewer: Windows Logs > Application

---

## ?? Quick Fixes

### VM Won't Start
```powershell
Get-Service vmms, vmcompute | Restart-Service
Start-VM -Name "ROCm_Test_VM" -Force
```

### Can't Copy to VM
```powershell
# Alternative: Enhanced Session
Set-VM -VMName "ROCm_Test_VM" -EnhancedSessionTransportType HVSocket
vmconnect localhost "ROCm_Test_VM"
# Now copy/paste works!
```

### Sandbox Won't Open
```powershell
Enable-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM
Restart-Computer
```

### Installation Fails
```powershell
# Check log for specific error
Select-String -Path "install.log" -Pattern "error|fail" -Context 2

# Common fixes:
# - Run as Administrator
# - Free up disk space
# - Disable antivirus temporarily
# - Rebuild MSI: .\build_installer.ps1 -Clean
```

---

## ?? Snapshot Commands

### Create Checkpoint
```powershell
Checkpoint-VM -Name "ROCm_Test_VM" -SnapshotName "Clean_Win11"
Checkpoint-VM -Name "ROCm_Test_VM" -SnapshotName "After_Install"
```

### Restore Checkpoint
```powershell
Get-VMSnapshot -VMName "ROCm_Test_VM"
Restore-VMCheckpoint -Name "Clean_Win11" -VMName "ROCm_Test_VM" -Confirm:$false
```

### Delete Checkpoint
```powershell
Get-VMSnapshot -VMName "ROCm_Test_VM" -Name "After_Install" | Remove-VMSnapshot
```

---

## ?? Rapid Testing Loop

```powershell
# 1. Make changes to installer code
# 2. Rebuild
.\build_installer.ps1 -Configuration Release

# 3. Test in Sandbox (closes automatically)
& ".\testing\ROCm_Installer_Sandbox.wsb"
# ... test inside sandbox ...
# ... close sandbox ...

# 4. Check results
explorer "F:\ROCm_VM_Testing\Sandbox_TestResults"

# 5. Repeat!
```

---

## ?? Testing Priority

### Must Test (Every Build)
- ? Installation completes without errors
- ? Files deployed to correct locations
- ? Uninstaller removes everything
- ? No system instability

### Should Test (Major Versions)
- ? WSL2 integration works
- ? ROCm available in WSL
- ? Sample code runs
- ? Multiple install/uninstall cycles

### Nice to Test (Before Release)
- ? Different Windows 11 builds
- ? Limited disk space scenarios
- ? No internet connection
- ? Various hardware configs

---

## ?? Get Help

**Detailed Guide**: See `testing/TESTING_GUIDE.md`

**Common Issues**: Check the troubleshooting section

**Still Stuck?**: Create GitHub issue with:
- Windows version: `winver`
- Installer version
- Full installation log
- Screenshots of errors

---

**? Pro Tip**: Use Sandbox for quick iterations, VM for thorough testing!

**?? Now go make Lisa Su proud!**
