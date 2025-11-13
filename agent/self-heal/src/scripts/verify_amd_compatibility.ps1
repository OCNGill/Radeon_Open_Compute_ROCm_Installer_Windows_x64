# AMD Driver and GPU Compatibility Verification Script
# Comprehensive check for ROCm requirements

$ErrorActionPreference = "Stop"

function Write-ColorLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
 "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Get-DetailedAMDInfo {
   Write-ColorLog "Detecting AMD hardware and drivers..."
    
    $gpus = Get-WmiObject Win32_VideoController | Where-Object { $_.Name -match "AMD|Radeon" }
    
    if (-not $gpus) {
        Write-ColorLog "No AMD GPUs detected" "ERROR"
        return $null
    }
    
    $results = @()
    foreach ($gpu in $gpus) {
        $info = [PSCustomObject]@{
         Name = $gpu.Name
            DriverVersion = $gpu.DriverVersion
        DriverDate = $gpu.DriverDate
            Status = $gpu.Status
      VRAM_GB = [math]::Round($gpu.AdapterRAM / 1GB, 2)
   VideoProcessor = $gpu.VideoProcessor
            IsROCmCompatible = $false
        }
   
      # Check if it's RX 7000 series
        if ($gpu.Name -match "RX 7[0-9]{3}") {
            $info.IsROCmCompatible = $true
        }
        
        $results += $info
        
        Write-ColorLog "Found: $($gpu.Name)" "SUCCESS"
        Write-ColorLog "  Driver: $($gpu.DriverVersion)"
 Write-ColorLog "  VRAM: $($info.VRAM_GB) GB"
        Write-ColorLog "  ROCm Compatible: $($info.IsROCmCompatible)"
    }
    
    return $results
}

# Main execution
Write-ColorLog "=== AMD ROCm Compatibility Checker ===" "INFO"
$gpuInfo = Get-DetailedAMDInfo

if ($gpuInfo) {
    Write-ColorLog "Compatibility check complete!" "SUCCESS"
    $gpuInfo | Format-Table -AutoSize
} else {
    Write-ColorLog "Compatibility check failed" "ERROR"
    exit 1
}
