# Master ROCm Installation Orchestrator for Windows 11
# Coordinates the complete installation process from start to finish

param(
    [switch]$SkipDriverCheck,
    [switch]$SkipWSLSetup,
    [switch]$AutoYes
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Write-StepLog {
param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
  "ERROR" { "Red" }
  "WARNING" { "Yellow" }
        "SUCCESS" { "Green" }
        "STEP" { "Cyan" }
      default { "White" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Test-AdminRights {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Confirm-Step {
    param([string]$Message)
    
    if ($AutoYes) {
      return $true
    }
    
    $response = Read-Host "$Message (Y/N)"
    return ($response -eq 'Y' -or $response -eq 'y')
}

function Invoke-Step {
    param(
      [string]$StepName,
     [string]$ScriptPath,
        [hashtable]$Parameters = @{}
    )
    
    Write-StepLog "=== STEP: $StepName ===" "STEP"
    
    if (-not (Test-Path $ScriptPath)) {
        Write-StepLog "Script not found: $ScriptPath" "ERROR"
        return $false
}
    
    try {
        & $ScriptPath @Parameters
    if ($LASTEXITCODE -ne 0 -and $null -ne $LASTEXITCODE) {
     Write-StepLog "$StepName completed with warnings" "WARNING"
   return (Confirm-Step "Continue anyway?")
    }
    Write-StepLog "$StepName completed successfully" "SUCCESS"
     return $true
    } catch {
 Write-StepLog "$StepName failed: $_" "ERROR"
return $false
    }
}

function Invoke-WSLCommand {
    param([string]$Command, [string]$Description)
    
    Write-StepLog $Description
    
 try {
        wsl -d Ubuntu-22.04 -e bash -c $Command
      return ($LASTEXITCODE -eq 0)
    } catch {
  Write-StepLog "WSL command failed: $_" "ERROR"
   return $false
    }
}

# Main Installation Flow
Write-StepLog "======================================"
Write-StepLog "ROCm Windows 11 Master Installer"
Write-StepLog "======================================"
Write-StepLog ""

# Check admin rights
if (-not (Test-AdminRights)) {
    Write-StepLog "This installer requires administrator privileges" "ERROR"
    Write-StepLog "Please run PowerShell as Administrator and try again" "ERROR"
    exit 1
}

Write-StepLog "Running as Administrator - OK" "SUCCESS"
Write-StepLog ""

# Installation Steps
$steps = @(
    @{
Name = "Hardware Compatibility Check"
     Script = Join-Path $ScriptDir "detect_hardware.ps1"
        Skip = $SkipDriverCheck
Description = "Verifying AMD GPU and Windows 11..."
    },
    @{
Name = "AMD Driver Verification"
    Script = Join-Path $ScriptDir "verify_amd_compatibility.ps1"
     Skip = $SkipDriverCheck
      Description = "Checking AMD driver version..."
    },
    @{
Name = "WSL2 Setup"
      Script = Join-Path $ScriptDir "wsl2_setup.ps1"
        Skip = $SkipWSLSetup
  Description = "Installing and configuring WSL2..."
    }
)

$allSuccessful = $true

# Execute Windows-side steps
foreach ($step in $steps) {
    if ($step.Skip) {
  Write-StepLog "Skipping: $($step.Name)" "WARNING"
    continue
    }
    
    Write-StepLog ""
    Write-StepLog $step.Description
 
    if (-not (Confirm-Step "Execute $($step.Name)?")) {
     Write-StepLog "Skipped by user: $($step.Name)" "WARNING"
        continue
  }
    
    $success = Invoke-Step -StepName $step.Name -ScriptPath $step.Script
    
    if (-not $success) {
   $allSuccessful = $false
        if (-not (Confirm-Step "An error occurred. Continue with remaining steps?")) {
       Write-StepLog "Installation aborted by user" "ERROR"
  exit 1
        }
    }
}

# WSL-side installation steps
Write-StepLog ""
Write-StepLog "=== WSL2 Installation Phase ===" "STEP"
Write-StepLog "The following steps will be executed inside WSL2 Ubuntu 22.04"
Write-StepLog ""

if (Confirm-Step "Proceed with ROCm installation in WSL2?") {
 
    # Copy scripts to WSL
 Write-StepLog "Copying installation scripts to WSL..."
    $wslScriptPath = "/tmp/rocm_install"
    Invoke-WSLCommand "mkdir -p $wslScriptPath" "Creating WSL script directory"
    
# Copy install_rocm.sh
    $rocmScript = Join-Path $ScriptDir "install_rocm.sh"
    if (Test-Path $rocmScript) {
     $windowsPath = $rocmScript -replace '\\', '/'
        $windowsPath = $windowsPath -replace ':', ''
        $windowsPath = "/mnt/" + $windowsPath.Substring(0,1).ToLower() + $windowsPath.Substring(1)
        Invoke-WSLCommand "cp $windowsPath $wslScriptPath/install_rocm.sh" "Copying ROCm install script"
        Invoke-WSLCommand "chmod +x $wslScriptPath/install_rocm.sh" "Making script executable"
    }
    
    # Execute ROCm installation
    Write-StepLog "Installing ROCm (this will take several minutes)..." "STEP"
    $rocmSuccess = Invoke-WSLCommand "$wslScriptPath/install_rocm.sh" "Running ROCm installation"
    
    if ($rocmSuccess) {
        Write-StepLog "ROCm installation completed" "SUCCESS"
  
        # Proceed with PyTorch installation
        if (Confirm-Step "Install PyTorch with ROCm support?") {
      $pytorchScript = Join-Path $ScriptDir "install_pytorch.sh"
   if (Test-Path $pytorchScript) {
       $windowsPath = $pytorchScript -replace '\\', '/'
        $windowsPath = $windowsPath -replace ':', ''
       $windowsPath = "/mnt/" + $windowsPath.Substring(0,1).ToLower() + $windowsPath.Substring(1)
     Invoke-WSLCommand "cp $windowsPath $wslScriptPath/install_pytorch.sh" "Copying PyTorch install script"
         Invoke-WSLCommand "chmod +x $wslScriptPath/install_pytorch.sh" "Making script executable"
   
 Write-StepLog "Installing PyTorch with ROCm (this will take several minutes)..." "STEP"
      $pytorchSuccess = Invoke-WSLCommand "$wslScriptPath/install_pytorch.sh" "Running PyTorch installation"
          
     if ($pytorchSuccess) {
 Write-StepLog "PyTorch installation completed" "SUCCESS"
       }
            }
        }
    } else {
      Write-StepLog "ROCm installation failed" "ERROR"
    $allSuccessful = $false
    }
}

# Final Summary
Write-StepLog ""
Write-StepLog "======================================" "STEP"
Write-StepLog "Installation Complete!" "STEP"
Write-StepLog "======================================" "STEP"
Write-StepLog ""

if ($allSuccessful) {
    Write-StepLog "All steps completed successfully!" "SUCCESS"
    Write-StepLog ""
  Write-StepLog "Next Steps:" "INFO"
 Write-StepLog "1. Open WSL2: wsl -d Ubuntu-22.04" "INFO"
    Write-StepLog "2. Verify ROCm: rocminfo" "INFO"
    Write-StepLog "3. Test PyTorch: python3 -c 'import torch; print(torch.cuda.is_available())'" "INFO"
    Write-StepLog "4. Start building your AI applications!" "INFO"
} else {
    Write-StepLog "Installation completed with some errors or warnings" "WARNING"
    Write-StepLog "Please review the logs above for details" "WARNING"
}

Write-StepLog ""
Write-StepLog "For support and documentation, visit:" "INFO"
Write-StepLog "  https://rocm.docs.amd.com/projects/radeon/en/latest/" "INFO"
Write-StepLog "======================================" "STEP"
