# GPU Detection Custom Action
# Validates AMD GPU hardware compatibility

param(
 [switch]$Detailed
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  Write-Host "[$timestamp] [$Level] $Message"
}

function Test-AMDDriverInstalled {
    Write-Log "Checking for AMD driver installation..."
    
    $amdDriver = Get-WmiObject Win32_PnPSignedDriver | Where-Object {
        $_.DeviceName -match "AMD|Radeon" -and $_.DriverProviderName -match "AMD|Advanced Micro Devices"
    }
    
    return ($null -ne $amdDriver)
}

function Get-AMDGPUInfo {
    Write-Log "Detecting AMD GPU hardware..."
    
  $gpus = Get-WmiObject Win32_VideoController | Where-Object { 
        $_.Name -match "AMD|Radeon" 
 }
    
    if (-not $gpus) {
        Write-Log "No AMD GPU detected" "ERROR"
      return $null
    }
    
    $gpuList = @()
foreach ($gpu in $gpus) {
 $gpuInfo = @{
     Name = $gpu.Name
      DriverVersion = $gpu.DriverVersion
DriverDate = $gpu.DriverDate
          AdapterRAM = [math]::Round($gpu.AdapterRAM / 1GB, 2)
            Status = $gpu.Status
            DeviceID = $gpu.DeviceID
        }
        
        Write-Log "Found GPU: $($gpuInfo.Name)"
        Write-Log "  Driver Version: $($gpuInfo.DriverVersion)"
    Write-Log "  VRAM: $($gpuInfo.AdapterRAM) GB"
   
        $gpuList += $gpuInfo
    }
    
    return $gpuList
}

function Test-GPUCompatibility {
    param($GPUName)
    
    # Supported GPU families
    $supportedGPUs = @{
        "RDNA3" = @("RX 7900 XTX", "RX 7900 XT", "RX 7800 XT", "RX 7700 XT", "RX 7600")
        "RDNA4" = @("RX 9070 XT", "RX 9070", "RX 9060 XT", "RX 9060")
   "APU" = @("Radeon 890M", "Radeon 880M", "Radeon 780M", "Ryzen AI")
    }
    
    foreach ($family in $supportedGPUs.Keys) {
        foreach ($model in $supportedGPUs[$family]) {
            if ($GPUName -match [regex]::Escape($model)) {
      Write-Log "GPU family: $family" "SUCCESS"
      return @{
       Supported = $true
     Family = $family
              Model = $model
             }
    }
    }
    }
    
    Write-Log "GPU may not be officially supported" "WARNING"
    return @{
        Supported = $false
        Family = "Unknown"
   Model = $GPUName
}
}

function Test-DriverVersion {
    param($DriverVersion)
    
    Write-Log "Validating driver version..."
    
    # AMD Adrenalin 25.9.2 uses driver version 31.0.24033.1003 or higher
    # We check if major version is >= 31
    
    if ($DriverVersion -match '^(\d+)\.') {
        $majorVersion = [int]$Matches[1]
        
        if ($majorVersion -ge 31) {
          Write-Log "Driver version is compatible (v$DriverVersion)" "SUCCESS"
            return $true
     } else {
  Write-Log "Driver version may be outdated (v$DriverVersion). Recommended: 31.x+" "WARNING"
    return $false
 }
    }
    
    Write-Log "Could not parse driver version: $DriverVersion" "WARNING"
    return $false
}

# Main execution
Write-Log "===== AMD GPU Detection ====="

# Check if AMD driver is installed
if (-not (Test-AMDDriverInstalled)) {
    Write-Log "AMD driver not found. Please install AMD Adrenalin 25.9.2 or later." "ERROR"
    exit 1
}

# Get GPU information
$gpus = Get-AMDGPUInfo
if (-not $gpus) {
    Write-Log "No compatible AMD GPU found" "ERROR"
    exit 1
}

# Test each GPU
$allCompatible = $true
foreach ($gpu in $gpus) {
    $compatibility = Test-GPUCompatibility -GPUName $gpu.Name
    
    if (-not $compatibility.Supported) {
        $allCompatible = $false
    }
    
    $driverOK = Test-DriverVersion -DriverVersion $gpu.DriverVersion
    if (-not $driverOK) {
        Write-Log "Please update to AMD Adrenalin 25.9.2 or later" "WARNING"
  Write-Log "Download: https://www.amd.com/en/support" "INFO"
    }
}

if ($allCompatible) {
    Write-Log "===== GPU Detection: PASSED =====" "SUCCESS"
 exit 0
} else {
    Write-Log "===== GPU Detection: WARNING - Unsupported GPU =====" "WARNING"
    # Don't fail installation, just warn
    exit 0
}
