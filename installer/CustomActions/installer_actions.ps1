# AMD ROCm Windows 11 Installer - Custom Actions
# PowerShell script for WiX custom actions

param(
    [Parameter(Mandatory=$false)]
    [string]$Action
)

$ErrorActionPreference = "Stop"
$LogFile = "$env:TEMP\ROCm_Installer.log"

function Write-InstallLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $logMessage
    Write-Host $logMessage
}

function Test-AdminRights {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
  return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Detect-GPU {
    Write-InstallLog "Detecting AMD GPU hardware..."
    
    $gpus = Get-WmiObject Win32_VideoController | Where-Object { $_.Name -match "AMD|Radeon" }
    
    if (-not $gpus) {
        Write-InstallLog "No AMD GPU detected. Installation cannot continue." "ERROR"
        return 1603 # ERROR_INSTALL_FAILURE
    }
    
$supportedGPUs = @(
   "RX 7900", "RX 7800", "RX 7700", "RX 7600",  # RDNA 3
        "RX 9070", "RX 9060",         # RDNA 4
        "Ryzen AI", "Radeon 890M", "Radeon 880M"      # APUs
    )
    
    $isSupported = $false
    foreach ($gpu in $gpus) {
  Write-InstallLog "Found GPU: $($gpu.Name)"
        
        foreach ($supported in $supportedGPUs) {
       if ($gpu.Name -match $supported) {
     $isSupported = $true
   Write-InstallLog "GPU is supported for ROCm" "SUCCESS"
   break
  }
      }
    }
    
    if (-not $isSupported) {
     Write-InstallLog "GPU may not be fully supported. Proceeding with caution..." "WARNING"
    }
    
    return 0 # SUCCESS
}

function Check-DriverVersion {
    Write-InstallLog "Checking AMD driver version..."
    
    $gpus = Get-WmiObject Win32_VideoController | Where-Object { $_.Name -match "AMD|Radeon" }
    
    foreach ($gpu in $gpus) {
        $driverVersion = $gpu.DriverVersion
        Write-InstallLog "Driver version: $driverVersion"
        
        # Check for minimum version (Adrenalin 25.9.2 = driver 31.x+)
        $versionParts = $driverVersion -split '\.'
        if ($versionParts.Count -gt 0) {
    $majorVersion = [int]$versionParts[0]
            
  if ($majorVersion -lt 31) {
            Write-InstallLog "Driver version may be too old. Please update to AMD Adrenalin 25.9.2 or later." "WARNING"
    Write-InstallLog "Download from: https://www.amd.com/en/support" "INFO"
     # Don't fail, just warn
            }
        }
    }
    
    return 0
}

function Configure-Security {
    Write-InstallLog "Configuring Windows security settings for ROCm..."
    
    if (-not (Test-AdminRights)) {
        Write-InstallLog "Administrator rights required for security configuration" "ERROR"
        return 1603
    }
    
    try {
    # Disable Microsoft Defender Application Guard
        Write-InstallLog "Disabling Microsoft Defender Application Guard..."
  $wdagFeature = Get-WindowsOptionalFeature -Online -FeatureName "Windows-Defender-ApplicationGuard" -ErrorAction SilentlyContinue
        
     if ($wdagFeature -and $wdagFeature.State -eq "Enabled") {
            Disable-WindowsOptionalFeature -FeatureName "Windows-Defender-ApplicationGuard" -Online -NoRestart
            Write-InstallLog "MS Defender Application Guard disabled (reboot may be required)" "SUCCESS"
        }
      
        # Note about Smart App Control
   Write-InstallLog "Smart App Control must be disabled manually:" "INFO"
        Write-InstallLog "Settings > Privacy & security > Windows Security > App & browser control > Smart App Control > Off" "INFO"
        
  return 0
    }
    catch {
        Write-InstallLog "Error configuring security: $_" "ERROR"
return 1603
    }
}

function Install-WSL2 {
    Write-InstallLog "Installing WSL2 and Ubuntu 22.04..."
    
 try {
        # Check Windows build for WSL2 support
  $os = Get-CimInstance Win32_OperatingSystem
      $build = [int]$os.BuildNumber
        
  if ($build -lt 18362) {
      Write-InstallLog "WSL2 requires Windows 10 build 18362 or later. Current build: $build" "ERROR"
     Write-InstallLog "Please update Windows to a newer version." "ERROR"
return 1603
        } elseif ($build -ge 18362 -and $build -lt 19041) {
  Write-InstallLog "Windows 10 build $build detected. WSL2 is supported but may require manual kernel update." "WARNING"
            Write-InstallLog "Recommended: Update to Windows 10 version 2004 (build 19041) or later." "WARNING"
    } else {
      Write-InstallLog "Windows build $build - WSL2 fully supported" "SUCCESS"
  }
        
        # Check if WSL is already installed
  $wslInstalled = $false
        try {
wsl --version 2>&1 | Out-Null
  $wslInstalled = ($LASTEXITCODE -eq 0)
        } catch {
     $wslInstalled = $false
        }
  
   if ($wslInstalled) {
      Write-InstallLog "WSL2 is already installed" "INFO"
     } else {
          Write-InstallLog "Installing WSL2..."
    wsl --install --no-distribution
 }
        
      # Install Ubuntu 22.04
        $distributions = wsl --list --quiet
 if ($distributions -match "Ubuntu-22.04") {
     Write-InstallLog "Ubuntu 22.04 already installed" "INFO"
        } else {
      Write-InstallLog "Installing Ubuntu 22.04..."
      wsl --install -d Ubuntu-22.04
 }
        
        wsl --set-default Ubuntu-22.04
    wsl --set-version Ubuntu-22.04 2

        Write-InstallLog "WSL2 installation complete" "SUCCESS"
      return 0
    }
    catch {
  Write-InstallLog "Error installing WSL2: $_" "ERROR"
  return 1603
    }
}

function Install-ROCm {
    Write-InstallLog "Installing ROCm in WSL2..."
    
    try {
      $scriptPath = "$PSScriptRoot\..\src\scripts\install_rocm.sh"
   
    # Copy script to WSL
    wsl -d Ubuntu-22.04 -e bash -c "mkdir -p /tmp/rocm_install"
    
$windowsPath = $scriptPath -replace '\\', '/'
    $windowsPath = $windowsPath -replace ':', ''
  $windowsPath = "/mnt/" + $windowsPath.Substring(0,1).ToLower() + $windowsPath.Substring(1)
        
        wsl -d Ubuntu-22.04 -e bash -c "cp '$windowsPath' /tmp/rocm_install/install_rocm.sh"
  wsl -d Ubuntu-22.04 -e bash -c "chmod +x /tmp/rocm_install/install_rocm.sh"
      
      # Execute installation
    wsl -d Ubuntu-22.04 -e bash -c "/tmp/rocm_install/install_rocm.sh"
        
        if ($LASTEXITCODE -eq 0) {
            Write-InstallLog "ROCm installation complete" "SUCCESS"
        return 0
      } else {
    Write-InstallLog "ROCm installation failed" "ERROR"
            return 1603
    }
    }
    catch {
        Write-InstallLog "Error installing ROCm: $_" "ERROR"
     return 1603
    }
}

function Install-PyTorch {
    Write-InstallLog "Installing PyTorch with ROCm support..."
    
    try {
        $scriptPath = "$PSScriptRoot\..\src\scripts\install_pytorch.sh"
        
  # Copy script to WSL
    $windowsPath = $scriptPath -replace '\\', '/'
  $windowsPath = $windowsPath -replace ':', ''
        $windowsPath = "/mnt/" + $windowsPath.Substring(0,1).ToLower() + $windowsPath.Substring(1)
        
      wsl -d Ubuntu-22.04 -e bash -c "cp '$windowsPath' /tmp/rocm_install/install_pytorch.sh"
        wsl -d Ubuntu-22.04 -e bash -c "chmod +x /tmp/rocm_install/install_pytorch.sh"
        
        # Execute installation
        wsl -d Ubuntu-22.04 -e bash -c "/tmp/rocm_install/install_pytorch.sh"
        
        if ($LASTEXITCODE -eq 0) {
            Write-InstallLog "PyTorch installation complete" "SUCCESS"
            return 0
        } else {
    Write-InstallLog "PyTorch installation failed" "ERROR"
         return 1603
        }
    }
catch {
      Write-InstallLog "Error installing PyTorch: $_" "ERROR"
        return 1603
    }
}

function Validate-Installation {
    Write-InstallLog "Validating ROCm installation..."
    
    try {
        $scriptPath = "$PSScriptRoot\..\src\scripts\validate_installation.sh"
        
 # Copy script to WSL
        $windowsPath = $scriptPath -replace '\\', '/'
        $windowsPath = $windowsPath -replace ':', ''
        $windowsPath = "/mnt/" + $windowsPath.Substring(0,1).ToLower() + $windowsPath.Substring(1)
  
        wsl -d Ubuntu-22.04 -e bash -c "cp '$windowsPath' /tmp/rocm_install/validate_installation.sh"
        wsl -d Ubuntu-22.04 -e bash -c "chmod +x /tmp/rocm_install/validate_installation.sh"
        
        # Execute validation
        wsl -d Ubuntu-22.04 -e bash -c "/tmp/rocm_install/validate_installation.sh"
        
        if ($LASTEXITCODE -eq 0) {
     Write-InstallLog "Installation validation passed" "SUCCESS"
          return 0
    } else {
    Write-InstallLog "Installation validation had some failures" "WARNING"
            return 0 # Don't fail install on validation warnings
        }
    }
    catch {
   Write-InstallLog "Error during validation: $_" "ERROR"
        return 0 # Don't fail install on validation errors
    }
}

# Main execution dispatcher
Write-InstallLog "Starting custom action: $Action"

switch ($Action) {
    "DetectGPU" { exit (Detect-GPU) }
    "CheckDriverVersion" { exit (Check-DriverVersion) }
    "ConfigureSecurity" { exit (Configure-Security) }
    "InstallWSL2" { exit (Install-WSL2) }
    "InstallROCm" { exit (Install-ROCm) }
    "InstallPyTorch" { exit (Install-PyTorch) }
    "ValidateInstallation" { exit (Validate-Installation) }
    default {
      Write-InstallLog "Unknown action: $Action" "ERROR"
        exit 1603
    }
}
