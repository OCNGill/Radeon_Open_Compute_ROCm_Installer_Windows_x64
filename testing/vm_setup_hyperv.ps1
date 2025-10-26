# ============================================================================
# ROCm Installer Testing - Hyper-V VM Setup Script
# ============================================================================
# Purpose: Create a Windows 11 VM for testing the ROCm MSI installer
# Target System: Ryzen 5900X, 48GB RAM, Radeon 7900 XTX
# Author: AMD Senior Developer Team
# ============================================================================

#Requires -RunAsAdministrator

param(
    [string]$VMName = "ROCm_Test_VM",
    [string]$VMPath = "F:\ROCm_VM_Testing",
    [int]$ProcessorCount = 4,
    [int64]$MemoryGB = 24,
    [int64]$VHDSizeGB = 127,
    [string]$ISOPath = "",
    [switch]$SkipISO,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

# ============================================================================
# Color Output Functions
# ============================================================================

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Write-Step {
    param([string]$Message)
 Write-ColorOutput "`n[STEP] $Message" "Cyan"
}

function Write-Success {
param([string]$Message)
    Write-ColorOutput "[?] $Message" "Green"
}

function Write-Warning {
    param([string]$Message)
    Write-ColorOutput "[!] $Message" "Yellow"
}

function Write-Error {
    param([string]$Message)
    Write-ColorOutput "[?] $Message" "Red"
}

# ============================================================================
# Main Script
# ============================================================================

Write-ColorOutput @"
????????????????????????????????????????????????????????????????????????
?   ROCm Windows Installer - Hyper-V Test VM Setup           ?
?  AMD Development Team    ?
????????????????????????????????????????????????????????????????????????
"@ "Cyan"

Write-ColorOutput "`nVM Configuration:" "Yellow"
Write-ColorOutput "  Name:       $VMName"
Write-ColorOutput "  Location:   $VMPath"
Write-ColorOutput "  vCPUs:      $ProcessorCount cores (8 threads on 5900X)"
Write-ColorOutput "  Memory:     ${MemoryGB}GB"
Write-ColorOutput "  Disk:       ${VHDSizeGB}GB (Dynamic)"
Write-ColorOutput ""

# ============================================================================
# Step 1: Check Hyper-V Installation
# ============================================================================

Write-Step "Checking Hyper-V Installation"

$hyperV = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All

if ($hyperV.State -ne "Enabled") {
    Write-Error "Hyper-V is not enabled on this system!"
    Write-ColorOutput "`nTo enable Hyper-V, run:" "Yellow"
    Write-ColorOutput "  Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -NoRestart" "Gray"
    Write-ColorOutput "`nThen reboot your system and run this script again." "Yellow"
    exit 1
}

Write-Success "Hyper-V is enabled"

# Check if Hyper-V services are running
$hvServices = @("vmms", "vmcompute")
foreach ($service in $hvServices) {
    $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
    if ($svc -and $svc.Status -eq "Running") {
        Write-Success "Service '$service' is running"
    } else {
     Write-Warning "Service '$service' is not running. Attempting to start..."
        Start-Service -Name $service
        Write-Success "Service '$service' started"
 }
}

# ============================================================================
# Step 2: Create VM Directory Structure
# ============================================================================

Write-Step "Creating VM Directory Structure"

$vmFullPath = Join-Path $VMPath $VMName
$vhdPath = Join-Path $vmFullPath "Virtual Hard Disks"
$checkpointPath = Join-Path $vmFullPath "Checkpoints"

$directories = @($vmFullPath, $vhdPath, $checkpointPath)
foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
  New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Success "Created: $dir"
    } else {
        Write-ColorOutput "  Exists: $dir" "Gray"
    }
}

# ============================================================================
# Step 3: Check for Existing VM
# ============================================================================

Write-Step "Checking for Existing VM"

$existingVM = Get-VM -Name $VMName -ErrorAction SilentlyContinue

if ($existingVM) {
    Write-Warning "VM '$VMName' already exists!"
    $response = Read-Host "Do you want to delete it and create a new one? (yes/no)"
    
    if ($response -eq "yes") {
   Write-ColorOutput "  Stopping VM..." "Yellow"
        Stop-VM -Name $VMName -Force -ErrorAction SilentlyContinue
        Write-ColorOutput "  Removing VM..." "Yellow"
        Remove-VM -Name $VMName -Force
        Write-Success "Existing VM removed"
    } else {
        Write-ColorOutput "Exiting without changes." "Yellow"
        exit 0
    }
}

# ============================================================================
# Step 4: Get or Prompt for Windows 11 ISO
# ============================================================================

if (-not $SkipISO) {
    Write-Step "Locating Windows 11 ISO"

    if ([string]::IsNullOrEmpty($ISOPath)) {
Write-ColorOutput "`nSearching common ISO locations..." "Gray"
        
        # Common ISO locations
        $searchPaths = @(
   "$env:USERPROFILE\Downloads\*.iso",
  "C:\ISOs\*.iso",
         "D:\ISOs\*.iso",
       "E:\ISOs\*.iso",
     "F:\ISOs\*.iso"
        )
        
  $foundISOs = @()
        foreach ($searchPath in $searchPaths) {
            $isos = Get-ChildItem -Path $searchPath -ErrorAction SilentlyContinue | 
     Where-Object { $_.Name -like "*Win11*" -or $_.Name -like "*Windows11*" }
            $foundISOs += $isos
   }
        
        if ($foundISOs.Count -gt 0) {
            Write-ColorOutput "`nFound Windows 11 ISO(s):" "Green"
            for ($i = 0; $i -lt $foundISOs.Count; $i++) {
          Write-ColorOutput "  [$i] $($foundISOs[$i].FullName)" "Gray"
     }
     
            if ($foundISOs.Count -eq 1) {
        $ISOPath = $foundISOs[0].FullName
      Write-Success "Using: $ISOPath"
         } else {
        $selection = Read-Host "`nSelect ISO number (or press Enter to manually specify path)"
        if ([string]::IsNullOrEmpty($selection)) {
               $ISOPath = Read-Host "Enter full path to Windows 11 ISO"
     } else {
         $ISOPath = $foundISOs[[int]$selection].FullName
  }
    }
 } else {
         Write-Warning "No Windows 11 ISO found automatically."
            Write-ColorOutput "`nYou can download Windows 11 ISO from:" "Yellow"
       Write-ColorOutput "  https://www.microsoft.com/software-download/windows11" "Cyan"
        Write-ColorOutput ""
            $ISOPath = Read-Host "Enter full path to Windows 11 ISO (or leave blank to create VM without ISO)"
        }
    }

    if (-not [string]::IsNullOrEmpty($ISOPath) -and -not (Test-Path $ISOPath)) {
        Write-Error "ISO file not found: $ISOPath"
        exit 1
    }

    if (-not [string]::IsNullOrEmpty($ISOPath)) {
        Write-Success "ISO Path: $ISOPath"
    } else {
    Write-Warning "VM will be created without ISO attached. You'll need to attach it manually."
    }
}

# ============================================================================
# Step 5: Create Virtual Hard Disk
# ============================================================================

Write-Step "Creating Virtual Hard Disk"

$vhdFile = Join-Path $vhdPath "$VMName.vhdx"
$vhdSizeBytes = $VHDSizeGB * 1GB

if (Test-Path $vhdFile) {
    Write-Warning "VHD file already exists, removing..."
    Remove-Item $vhdFile -Force
}

New-VHD -Path $vhdFile -SizeBytes $vhdSizeBytes -Dynamic | Out-Null
Write-Success "Created ${VHDSizeGB}GB dynamic VHD: $vhdFile"

# ============================================================================
# Step 6: Create Virtual Machine
# ============================================================================

Write-Step "Creating Virtual Machine"

$memoryBytes = $MemoryGB * 1GB

$vm = New-VM `
    -Name $VMName `
    -MemoryStartupBytes $memoryBytes `
    -Generation 2 `
    -Path $VMPath `
    -VHDPath $vhdFile `
    -SwitchName "Default Switch"

Write-Success "VM '$VMName' created"

# ============================================================================
# Step 7: Configure VM Settings
# ============================================================================

Write-Step "Configuring VM Settings"

# Set processor count
Set-VMProcessor -VMName $VMName -Count $ProcessorCount
Write-Success "Set CPU count to $ProcessorCount cores"

# Enable dynamic memory (recommended for testing)
Set-VMMemory -VMName $VMName -DynamicMemoryEnabled $true -MinimumBytes (4GB) -MaximumBytes $memoryBytes
Write-Success "Configured dynamic memory (4GB - ${MemoryGB}GB)"

# Disable checkpoints for testing (saves disk space)
Set-VM -VMName $VMName -CheckpointType Disabled
Write-Success "Checkpoints disabled (recommended for testing)"

# Enable nested virtualization (required for WSL2 in VM)
Set-VMProcessor -VMName $VMName -ExposeVirtualizationExtensions $true
Write-Success "Nested virtualization enabled (required for WSL2)"

# Configure automatic start/stop actions
Set-VM -VMName $VMName -AutomaticStartAction Nothing -AutomaticStopAction ShutDown
Write-Success "Configured automatic actions"

# Disable time synchronization (can cause issues)
Get-VMIntegrationService -VMName $VMName | Where-Object {$_.Name -like "*Time*"} | Disable-VMIntegrationService
Write-Success "Time synchronization disabled"

# Enable guest services
Enable-VMIntegrationService -VMName $VMName -Name "Guest Service Interface"
Write-Success "Guest services enabled"

# ============================================================================
# Step 8: Attach Windows 11 ISO
# ============================================================================

if (-not [string]::IsNullOrEmpty($ISOPath) -and (Test-Path $ISOPath)) {
    Write-Step "Attaching Windows 11 ISO"
    
    # Add DVD drive and attach ISO
    Add-VMDvdDrive -VMName $VMName -Path $ISOPath
    Write-Success "ISO attached: $ISOPath"
    
    # Set boot order (DVD first, then hard drive)
    $dvd = Get-VMDvdDrive -VMName $VMName
    $hdd = Get-VMHardDiskDrive -VMName $VMName
    Set-VMFirmware -VMName $VMName -FirstBootDevice $dvd
    Write-Success "Boot order set (DVD first)"
} else {
    Write-Warning "No ISO attached. You'll need to attach Windows 11 ISO manually before starting the VM."
}

# ============================================================================
# Step 9: Configure TPM and Secure Boot (Windows 11 Requirements)
# ============================================================================

Write-Step "Configuring Windows 11 Requirements"

# Enable TPM
Enable-VMTPM -VMName $VMName
Write-Success "TPM 2.0 enabled (required for Windows 11)"

# Configure secure boot
Set-VMFirmware -VMName $VMName -EnableSecureBoot On -SecureBootTemplate "MicrosoftWindows"
Write-Success "Secure Boot enabled"

# ============================================================================
# Step 10: Create Network Adapter Configuration
# ============================================================================

Write-Step "Configuring Network"

# Check if Default Switch exists
$defaultSwitch = Get-VMSwitch -Name "Default Switch" -ErrorAction SilentlyContinue

if (-not $defaultSwitch) {
    Write-Warning "'Default Switch' not found. Creating External switch..."
    
    # Get active network adapter
    $netAdapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -First 1
    
    if ($netAdapter) {
      New-VMSwitch -Name "ROCm_External" -NetAdapterName $netAdapter.Name -AllowManagementOS $true
        Get-VMNetworkAdapter -VMName $VMName | Connect-VMNetworkAdapter -SwitchName "ROCm_External"
        Write-Success "External network switch created and connected"
    } else {
        Write-Warning "No active network adapter found. Network not configured."
    }
} else {
    Write-Success "Connected to 'Default Switch'"
}

# ============================================================================
# Step 11: Display VM Information
# ============================================================================

Write-Step "VM Creation Complete!"

Write-ColorOutput @"

????????????????????????????????????????????????????????????????????????
?        VM Successfully Created            ?
????????????????????????????????????????????????????????????????????????

"@ "Green"

$vmInfo = Get-VM -Name $VMName

Write-ColorOutput "VM Details:" "Yellow"
Write-ColorOutput "  Name:          $($vmInfo.Name)"
Write-ColorOutput "  State:    $($vmInfo.State)"
Write-ColorOutput "  CPUs:   $($vmInfo.ProcessorCount) cores"
Write-ColorOutput "  Memory:        $([math]::Round($vmInfo.MemoryStartup/1GB, 2))GB"
Write-ColorOutput "  Generation:    $($vmInfo.Generation)"
Write-ColorOutput "  Path:     $($vmInfo.Path)"
Write-ColorOutput "  VHD:           $vhdFile"
Write-ColorOutput ""

# ============================================================================
# Step 12: Next Steps Instructions
# ============================================================================

Write-ColorOutput @"
????????????????????????????????????????????????????????????????????????
?  NEXT STEPS            ?
????????????????????????????????????????????????????????????????????????

"@ "Cyan"

Write-ColorOutput "To start testing your ROCm installer:" "Yellow"
Write-ColorOutput ""
Write-ColorOutput "1. Start the VM:" "White"
Write-ColorOutput "   Start-VM -Name '$VMName'" "Gray"
Write-ColorOutput "   vmconnect localhost '$VMName'" "Gray"
Write-ColorOutput ""
Write-ColorOutput "2. Install Windows 11:" "White"
Write-ColorOutput "   - Follow the Windows 11 installation wizard" "Gray"
Write-ColorOutput "   - Choose 'Windows 11 Pro' (recommended)" "Gray"
Write-ColorOutput "   - Skip product key (you can activate later)" "Gray"
Write-ColorOutput "   - Create a local account for testing" "Gray"
Write-ColorOutput ""
Write-ColorOutput "3. After Windows Installation:" "White"
Write-ColorOutput "   - Install all Windows updates" "Gray"
Write-ColorOutput "   - Enable .NET Framework 3.5 (if needed)" "Gray"
Write-ColorOutput "   - Take a checkpoint: Checkpoint-VM -Name '$VMName' -SnapshotName 'Clean_Install'" "Gray"
Write-ColorOutput ""
Write-ColorOutput "4. Copy your MSI installer into the VM:" "White"
Write-ColorOutput "   - Use Enhanced Session mode (clipboard sharing)" "Gray"
Write-ColorOutput "   - Or use PowerShell Direct (see testing guide)" "Gray"
Write-ColorOutput ""
Write-ColorOutput "5. Run the installer and test!" "White"
Write-ColorOutput "   - Right-click MSI -> Run as Administrator" "Gray"
Write-ColorOutput "   - Follow installation wizard" "Gray"
Write-ColorOutput "   - Verify all components install correctly" "Gray"
Write-ColorOutput ""

# ============================================================================
# Create Quick Start Script
# ============================================================================

$quickStartScript = @"
# Quick Start - ROCm Test VM
# Run this script to quickly manage your test VM

# Start VM and open console
Start-VM -Name '$VMName'
Start-Sleep -Seconds 3
vmconnect localhost '$VMName'

# Useful commands:
# Stop-VM -Name '$VMName' -Force
# Checkpoint-VM -Name '$VMName' -SnapshotName 'TestPoint1'
# Restore-VMCheckpoint -Name 'TestPoint1' -VMName '$VMName' -Confirm:`$false
# Remove-VM -Name '$VMName' -Force
"@

$quickStartPath = Join-Path $vmFullPath "Quick_Start_VM.ps1"
$quickStartScript | Out-File -FilePath $quickStartPath -Encoding UTF8
Write-Success "Quick start script created: $quickStartPath"

Write-ColorOutput "`n????????????????????????????????????????????????????????????????????????" "Cyan"
Write-ColorOutput "?  Your VM is ready! Review the testing guide for detailed steps.     ?" "Cyan"
Write-ColorOutput "????????????????????????????????????????????????????????????????????????`n" "Cyan"
