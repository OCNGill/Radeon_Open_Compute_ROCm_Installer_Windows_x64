# Installation Validation Custom Action
# Verifies ROCm, PyTorch, and system configuration

param(
    [switch]$Detailed
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message"
}

function Test-WSL2Installation {
    Write-Log "Validating WSL2 installation..."
    
    try {
        # Check WSL version
     $wslVersion = wsl --version 2>&1
  if ($LASTEXITCODE -ne 0) {
            Write-Log "WSL not properly installed" "ERROR"
return $false
        }
        
     # Check Ubuntu 22.04
   $distributions = wsl --list --verbose
        if ($distributions -match "Ubuntu-22.04.*Running") {
Write-Log "WSL2 with Ubuntu 22.04: OK" "SUCCESS"
       return $true
   } else {
Write-Log "Ubuntu 22.04 not found or not running" "WARNING"
     return $false
   }
    } catch {
  Write-Log "Error checking WSL2: $_" "ERROR"
        return $false
    }
}

function Test-ROCmInstallation {
    Write-Log "Validating ROCm installation..."

    try {
    # Check if ROCminfo is available
   $ROCmCheck = wsl -d Ubuntu-22.04 -e bash -c "which ROCminfo" 2>&1
 
     if ($LASTEXITCODE -eq 0) {
 Write-Log "ROCminfo found: $ROCmCheck" "SUCCESS"
       
  # Get ROCm version
            $ROCmVersion = wsl -d Ubuntu-22.04 -e bash -c "ROCminfo 2>&1 | grep -i 'Runtime Version' | head -1"
       Write-Log "ROCm Version: $ROCmVersion" "INFO"
       
return $true
 } else {
  Write-Log "ROCminfo not found in WSL" "ERROR"
      return $false
        }
    } catch {
        Write-Log "Error checking ROCm: $_" "ERROR"
  return $false
    }
}

function Test-PyTorchInstallation {
    Write-Log "Validating PyTorch installation..."
    
    try {
        # Check PyTorch import
  $pytorchCheck = wsl -d Ubuntu-22.04 -e bash -c "python3 -c 'import torch; print(torch.__version__)'" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
      Write-Log "PyTorch version: $pytorchCheck" "SUCCESS"
       
     # Check ROCm support
     $ROCmSupport = wsl -d Ubuntu-22.04 -e bash -c "python3 -c 'import torch; print(torch.cuda.is_available())'" 2>&1
     
   if ($ROCmSupport -match "True") {
      Write-Log "PyTorch ROCm support: ENABLED" "SUCCESS"
    
          # Get device count
         $deviceCount = wsl -d Ubuntu-22.04 -e bash -c "python3 -c 'import torch; print(torch.cuda.device_count())'" 2>&1
      Write-Log "Detected GPUs: $deviceCount" "INFO"
      
         # Get GPU name
          $gpuName = wsl -d Ubuntu-22.04 -e bash -c "python3 -c 'import torch; print(torch.cuda.get_device_name(0) if torch.cuda.is_available() else \"None\")'" 2>&1
  Write-Log "GPU: $gpuName" "INFO"
             
   return $true
      } else {
    Write-Log "PyTorch ROCm support: DISABLED" "WARNING"
    return $false
     }
 } else {
       Write-Log "PyTorch not properly installed" "ERROR"
            return $false
    }
    } catch {
 Write-Log "Error checking PyTorch: $_" "ERROR"
        return $false
    }
}

function Test-AMDDriver {
    Write-Log "Validating AMD driver..."
    
    try {
        $gpus = Get-WmiObject Win32_VideoController | Where-Object { $_.Name -match "AMD|Radeon" }
        
        if ($gpus) {
       foreach ($gpu in $gpus) {
     Write-Log "GPU: $($gpu.Name)" "INFO"
       Write-Log "  Driver: $($gpu.DriverVersion)" "INFO"
         Write-Log "  Status: $($gpu.Status)" "INFO"
            }
return $true
   } else {
  Write-Log "No AMD GPU found" "ERROR"
  return $false
      }
    } catch {
        Write-Log "Error checking AMD driver: $_" "ERROR"
     return $false
  }
}

function Test-NetworkConnectivity {
    Write-Log "Testing network connectivity..."
    
    $testSites = @(
        "https://repo.radeon.com",
        "https://pypi.org",
 "https://github.com"
    )
    
    $allOk = $true
 foreach ($site in $testSites) {
 try {
       $response = Invoke-WebRequest -Uri $site -Method Head -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
       Write-Log "Connectivity to $site : OK" "SUCCESS"
   } catch {
     Write-Log "Connectivity to $site : FAILED" "WARNING"
         $allOk = $false
  }
    }
    
    return $allOk
}

function Test-DiskSpace {
    Write-Log "Checking disk space..."
    
    try {
        $systemDrive = $env:SystemDrive
        $drive = Get-PSDrive -Name $systemDrive.Trim(':')
     $freeSpaceGB = [math]::Round($drive.Free / 1GB, 2)
     
  Write-Log "Free space on ${systemDrive}: ${freeSpaceGB} GB" "INFO"
        
        if ($freeSpaceGB -lt 20) {
   Write-Log "Low disk space detected (< 20 GB free)" "WARNING"
            return $false
   } else {
Write-Log "Disk space: OK" "SUCCESS"
  return $true
    }
    } catch {
        Write-Log "Error checking disk space: $_" "WARNING"
     return $false
 }
}

function Get-ValidationReport {
    $report = @"

========================================
ROCm Installation Validation Report
========================================
Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

"@
    
    return $report
}

# Main execution
Write-Log "===== Installation Validation ====="

$results = @{
 WSL2 = Test-WSL2Installation
    ROCm = Test-ROCmInstallation
    PyTorch = Test-PyTorchInstallation
    AMDDriver = Test-AMDDriver
    Network = Test-NetworkConnectivity
    DiskSpace = Test-DiskSpace
}

# Display results
Write-Log "`n========================================" "INFO"
Write-Log "Validation Results:" "INFO"
Write-Log "========================================" "INFO"

foreach ($test in $results.Keys) {
    $status = if ($results[$test]) { "PASSED" } else { "FAILED" }
    $level = if ($results[$test]) { "SUCCESS" } else { "ERROR" }
    Write-Log "${test}: $status" $level
}

Write-Log "========================================" "INFO"

# Determine overall result
$criticalTests = @("WSL2", "AMDDriver")
$criticalPassed = $true

foreach ($test in $criticalTests) {
    if (-not $results[$test]) {
  $criticalPassed = $false
        break
    }
}

if ($criticalPassed) {
 Write-Log "===== Installation Validation: PASSED =====" "SUCCESS"
    exit 0
} else {
    Write-Log "===== Installation Validation: FAILED =====" "ERROR"
    Write-Log "Some components may not be properly installed" "ERROR"
    # Don't fail the installation, just warn
    exit 0
}
