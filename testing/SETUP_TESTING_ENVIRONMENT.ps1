# ============================================================================
# ROCm Installer Testing - Master Setup Script
# ============================================================================
# Purpose: One-click setup of entire testing environment
# This script checks prerequisites, creates VM, and prepares Sandbox
# ============================================================================

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

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
# Welcome Banner
# ============================================================================

Clear-Host
Write-ColorOutput @"

????????????????????????????????????????????????????????????????????????
?           ?
?  ROCm Windows Installer - Testing Environment Setup        ?
?     ?
?  This script will prepare your complete testing environment     ?
?  AMD-Grade Quality Assurance      ?
?         ?
????????????????????????????????????????????????????????????????????????

"@ "Cyan"

Write-ColorOutput "System: Ryzen 5900X • 48GB RAM • Radeon 7900 XTX" "Gray"
Write-ColorOutput "Storage: F:\ROCm_VM_Testing (High-Bandwidth Drive)" "Gray"
Write-ColorOutput ""

# ============================================================================
# Step 1: Check Prerequisites
# ============================================================================

Write-Step "Checking Prerequisites"

$prereqs = @{
    'Admin Rights' = $true
    'Windows 11 Pro' = $false
    'Hyper-V' = $false
    'Windows Sandbox' = $false
    'F:\ Drive' = $false
    'Disk Space (50GB+)' = $false
}

# Check Windows version
$os = Get-CimInstance Win32_OperatingSystem
if ($os.Caption -like "*Windows 11*" -and $os.Caption -like "*Pro*") {
    $prereqs['Windows 11 Pro'] = $true
    Write-Success "Windows 11 Pro detected"
} else {
    Write-Warning "Not Windows 11 Pro: $($os.Caption)"
}

# Check Hyper-V
$hyperV = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
if ($hyperV.State -eq "Enabled") {
    $prereqs['Hyper-V'] = $true
    Write-Success "Hyper-V is enabled"
} else {
    Write-Warning "Hyper-V is not enabled"
    Write-ColorOutput "  Run: Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All" "Gray"
}

# Check Windows Sandbox
$sandbox = Get-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM
if ($sandbox.State -eq "Enabled") {
    $prereqs['Windows Sandbox'] = $true
    Write-Success "Windows Sandbox is enabled"
} else {
    Write-Warning "Windows Sandbox is not enabled"
    Write-ColorOutput "  Run: Enable-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM" "Gray"
}

# Check F:\ drive
if (Test-Path "F:\") {
    $drive = Get-PSDrive -Name F
 $freeGB = [math]::Round($drive.Free/1GB, 2)
    $prereqs['F:\ Drive'] = $true
    Write-Success "F:\ drive available (${freeGB}GB free)"
    
    if ($freeGB -gt 50) {
        $prereqs['Disk Space (50GB+)'] = $true
        Write-Success "Sufficient disk space available"
} else {
   Write-Warning "Low disk space: ${freeGB}GB (50GB+ recommended)"
    }
} else {
    Write-Warning "F:\ drive not found"
}

# Summary
Write-ColorOutput "`nPrerequisite Summary:" "Yellow"
$allGood = $true
foreach ($check in $prereqs.GetEnumerator()) {
    if ($check.Value) {
   Write-ColorOutput "  ? $($check.Key)" "Green"
    } else {
        Write-ColorOutput "  ? $($check.Key)" "Red"
      $allGood = $false
    }
}

if (-not $allGood) {
    Write-ColorOutput "`n??  Some prerequisites are missing. Please enable required features first." "Yellow"
    Write-ColorOutput "`nTo enable all features, run:" "Cyan"
    Write-ColorOutput "Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All" "Gray"
    Write-ColorOutput "Enable-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM" "Gray"
    Write-ColorOutput "  Restart-Computer" "Gray"
    Write-ColorOutput ""
    
    $response = Read-Host "Continue anyway? (yes/no)"
    if ($response -ne "yes") {
Write-ColorOutput "Exiting. Run this script again after enabling features." "Yellow"
  exit 0
    }
}

# ============================================================================
# Step 2: Create Testing Directory Structure
# ============================================================================

Write-Step "Creating Testing Directory Structure"

$baseDir = "F:\ROCm_VM_Testing"
$sandboxResultsDir = "$baseDir\Sandbox_TestResults"
$vmDir = "$baseDir\ROCm_Test_VM"
$isoDir = "$baseDir\ISOs"

$directories = @($baseDir, $sandboxResultsDir, $vmDir, $isoDir)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
      New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Success "Created: $dir"
    } else {
        Write-ColorOutput "  Exists: $dir" "Gray"
    }
}

# ============================================================================
# Step 3: Search for Windows 11 ISO
# ============================================================================

Write-Step "Searching for Windows 11 ISO"

$searchPaths = @(
  "$env:USERPROFILE\Downloads\*.iso",
    "C:\ISOs\*.iso",
    "D:\ISOs\*.iso",
    "E:\ISOs\*.iso",
    "F:\ISOs\*.iso",
    "$isoDir\*.iso"
)

$foundISOs = @()
foreach ($searchPath in $searchPaths) {
    $isos = Get-ChildItem -Path $searchPath -ErrorAction SilentlyContinue | 
        Where-Object { $_.Name -like "*Win11*" -or $_.Name -like "*Windows11*" }
    $foundISOs += $isos
}

if ($foundISOs.Count -gt 0) {
    Write-Success "Found $($foundISOs.Count) Windows 11 ISO(s)"
    foreach ($iso in $foundISOs) {
        Write-ColorOutput "  • $($iso.FullName)" "Gray"
    }
} else {
    Write-Warning "No Windows 11 ISO found"
  Write-ColorOutput "`nYou can download Windows 11 ISO from:" "Yellow"
    Write-ColorOutput "https://www.microsoft.com/software-download/windows11" "Cyan"
    Write-ColorOutput "`nPlace the ISO in: $isoDir" "Gray"
}

# ============================================================================
# Step 4: Check MSI Installer
# ============================================================================

Write-Step "Checking for Built MSI Installer"

$msiPaths = @(
    ".\bin\Release\*.msi",
    ".\bin\Debug\*.msi"
)

$foundMSIs = @()
foreach ($msiPath in $msiPaths) {
    $msis = Get-ChildItem -Path $msiPath -ErrorAction SilentlyContinue
    $foundMSIs += $msis
}

if ($foundMSIs.Count -gt 0) {
    Write-Success "Found MSI installer(s)"
    foreach ($msi in $foundMSIs) {
        $size?B = [math]::Round($msi.Length/1MB, 2)
        Write-ColorOutput "  • $($msi.Name) (${sizeMB}MB)" "Gray"
    }
} else {
 Write-Warning "No MSI installer found"
Write-ColorOutput "`nBuild the installer first:" "Yellow"
    Write-ColorOutput "  .\build_installer.ps1 -Configuration Release" "Gray"
}

# ============================================================================
# Step 5: User Choice - What to Set Up
# ============================================================================

Write-Step "What would you like to set up?"

Write-ColorOutput "`nOptions:" "Yellow"
Write-ColorOutput "  [1] Create Hyper-V VM (for thorough testing)" "White"
Write-ColorOutput "  [2] Test with Windows Sandbox (quick validation)" "White"
Write-ColorOutput "  [3] Both (recommended)" "White"
Write-ColorOutput "  [4] Just show me the documentation" "White"
Write-ColorOutput "  [5] Exit" "White"
Write-ColorOutput ""

$choice = Read-Host "Select option (1-5)"

switch ($choice) {
    "1" {
        Write-ColorOutput "`nLaunching VM setup script..." "Cyan"
        Start-Sleep -Seconds 1
     & ".\testing\vm_setup_hyperv.ps1"
    }
    
    "2" {
        if ($foundMSIs.Count -eq 0) {
            Write-Error "No MSI found. Build the installer first!"
 exit 1
    }
 
        if ($sandbox.State -ne "Enabled") {
      Write-Error "Windows Sandbox is not enabled!"
     Write-ColorOutput "Enable it with:" "Yellow"
  Write-ColorOutput "  Enable-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM" "Gray"
    exit 1
        }
     
        Write-ColorOutput "`nLaunching Windows Sandbox..." "Cyan"
        Start-Sleep -Seconds 1
        Start-Process ".\testing\ROCm_Installer_Sandbox.wsb"
      
  Write-Success "Sandbox launched!"
        Write-ColorOutput "`nInside Sandbox:" "Yellow"
        Write-ColorOutput "  1. Installer is in: C:\Installer\" "Gray"
        Write-ColorOutput "  2. Save results to: C:\TestResults\" "Gray"
        Write-ColorOutput "  3. Right-click MSI -> Run as Administrator" "Gray"
    }
    
    "3" {
  Write-ColorOutput "`n[1/2] Setting up Hyper-V VM..." "Cyan"
        Start-Sleep -Seconds 1
        & ".\testing\vm_setup_hyperv.ps1"
        
        Write-ColorOutput "`n[2/2] Ready to launch Sandbox" "Cyan"
     $sandboxNow = Read-Host "Launch Windows Sandbox now? (yes/no)"
      if ($sandboxNow -eq "yes") {
     Start-Process ".\testing\ROCm_Installer_Sandbox.wsb"
            Write-Success "Sandbox launched!"
        }
    }
    
    "4" {
        Write-ColorOutput "`nOpening documentation..." "Cyan"
        Start-Sleep -Seconds 1
        
# Open main guides
 if (Test-Path ".\TESTING_ENVIRONMENT_READY.md") {
 notepad ".\TESTING_ENVIRONMENT_READY.md"
   }
        if (Test-Path ".\testing\QUICK_START.md") {
Start-Sleep -Seconds 1
            notepad ".\testing\QUICK_START.md"
        }
        
        Write-ColorOutput "`nDocumentation opened!" "Green"
        Write-ColorOutput "Files:" "Yellow"
        Write-ColorOutput "  • TESTING_ENVIRONMENT_READY.md (Overview)" "Gray"
        Write-ColorOutput "  • testing/QUICK_START.md (Quick reference)" "Gray"
 Write-ColorOutput "  • testing/TESTING_GUIDE.md (Detailed guide)" "Gray"
    }
    
    "5" {
        Write-ColorOutput "`nExiting without changes." "Yellow"
        exit 0
    }
    
    default {
        Write-Error "Invalid choice. Exiting."
   exit 1
    }
}

# ============================================================================
# Final Summary
# ============================================================================

Write-ColorOutput "`n????????????????????????????????????????????????????????????????????????" "Green"
Write-ColorOutput "?       Setup Complete!      ?" "Green"
Write-ColorOutput "????????????????????????????????????????????????????????????????????????`n" "Green"

Write-ColorOutput "Next Steps:" "Yellow"
Write-ColorOutput ""
Write-ColorOutput "?? Read the guides:" "White"
Write-ColorOutput "   • TESTING_ENVIRONMENT_READY.md - Overview" "Gray"
Write-ColorOutput "   • testing/QUICK_START.md - Quick commands" "Gray"
Write-ColorOutput "   • testing/TESTING_GUIDE.md - Detailed procedures" "Gray"
Write-ColorOutput ""
Write-ColorOutput "?? Start testing:" "White"
Write-ColorOutput "   • VM: Start-VM -Name 'ROCm_Test_VM'; vmconnect localhost 'ROCm_Test_VM'" "Gray"
Write-ColorOutput "   • Sandbox: .\testing\ROCm_Installer_Sandbox.wsb" "Gray"
Write-ColorOutput ""
Write-ColorOutput "?? Commit to Git:" "White"
Write-ColorOutput "   • .\testing\commit_testing_files.ps1" "Gray"
Write-ColorOutput ""
Write-ColorOutput "?? You're ready to test like AMD! Good luck!" "Green"
Write-ColorOutput ""
