# WSL2 Setup Script for ROCm Installer
# Installs and configures WSL2 with Ubuntu 22.04 for ROCm compatibility

param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  Write-Host "[$timestamp] [$Level] $Message"
}

function Test-WSLInstalled {
  try {
        $wslVersion = wsl --version 2>&1
        return $LASTEXITCODE -eq 0
    } catch {
        return $false
  }
}

function Test-Administrator {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Enable-WSLFeatures {
    Write-Log "Enabling WSL and Virtual Machine Platform features..."
    
  dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
    
    Write-Log "WSL features enabled. System restart may be required."
}

function Install-WSL2 {
    Write-Log "Installing WSL2..."
    
    if (Test-WSLInstalled) {
    Write-Log "WSL is already installed" "INFO"
        wsl --set-default-version 2
    } else {
        Write-Log "Installing WSL with default distribution..."
        wsl --install --no-distribution
        Write-Log "WSL installed. Please restart your computer and run this script again."
    return $false
    }
    return $true
}

function Install-Ubuntu2204 {
    Write-Log "Checking for Ubuntu 22.04 installation..."
    
    $distributions = wsl --list --quiet
    if ($distributions -match "Ubuntu-22.04") {
    Write-Log "Ubuntu 22.04 is already installed" "INFO"
      return $true
    }
    
    Write-Log "Installing Ubuntu 22.04..."
    wsl --install -d Ubuntu-22.04
    
    Write-Log "Ubuntu 22.04 installed successfully"
    Write-Log "Please complete the Ubuntu setup (username/password) when prompted"
    return $true
}

function Set-WSLDefaultDistro {
    Write-Log "Setting Ubuntu 22.04 as default distribution..."
    wsl --set-default Ubuntu-22.04
    wsl --set-version Ubuntu-22.04 2
}

function Test-WSLWorking {
    Write-Log "Testing WSL installation..."
    
    try {
        $result = wsl -d Ubuntu-22.04 -e bash -c "echo 'WSL is working'"
 if ($result -eq "WSL is working") {
            Write-Log "WSL test successful" "SUCCESS"
         return $true
 }
    } catch {
        Write-Log "WSL test failed: $_" "ERROR"
        return $false
    }
    return $false
}

# Main execution
Write-Log "=== WSL2 Setup for ROCm Installation ===" "INFO"

if (-not (Test-Administrator)) {
    Write-Log "This script requires administrator privileges" "ERROR"
    Write-Log "Please run PowerShell as Administrator and try again" "ERROR"
    exit 1
}

try {
    # Step 1: Enable WSL features
Enable-WSLFeatures
    
    # Step 2: Install WSL2
    $wslReady = Install-WSL2
    if (-not $wslReady) {
        Write-Log "Please restart your computer and run this script again" "WARNING"
        exit 0
    }
    
    # Step 3: Install Ubuntu 22.04
    Install-Ubuntu2204
    
    # Step 4: Set as default
    Set-WSLDefaultDistro
    
    # Step 5: Test installation
    if (Test-WSLWorking) {
        Write-Log "=== WSL2 Setup Complete ===" "SUCCESS"
      Write-Log "You can now proceed with ROCm installation" "INFO"
        exit 0
    } else {
   Write-Log "WSL setup completed but testing failed" "WARNING"
        Write-Log "You may need to restart and complete Ubuntu setup" "INFO"
        exit 1
    }
    
} catch {
  Write-Log "An error occurred: $_" "ERROR"
    exit 1
}
