# Hardware Detection Script for ROCm Installer
# Checks for AMD GPU compatibility and Windows 11 requirements

function Test-AMDGPUCompatibility {
    $gpuInfo = Get-WmiObject Win32_VideoController
    
    Write-Host "Detecting GPU hardware..."
    foreach ($gpu in $gpuInfo) {
        if ($gpu.Name -match "AMD|Radeon") {
            Write-Host "Found AMD GPU: $($gpu.Name)"
            return $true
        }
    }
    
    Write-Host "No compatible AMD GPU detected"
    return $false
}

function Test-Windows11Compatibility {
    $osInfo = Get-WmiObject Win32_OperatingSystem
    $version = [System.Environment]::OSVersion.Version
    
    Write-Host "Checking Windows version..."
    if ($version.Major -ge 10 -and $version.Build -ge 22000) {
        Write-Host "Windows 11 detected"
        return $true
    }
    
    Write-Host "Windows 11 not detected. This installer requires Windows 11"
    return $false
}

# Main detection logic
$results = @{
    "GPUCompatible" = Test-AMDGPUCompatibility
    "WindowsCompatible" = Test-Windows11Compatibility
}

return $results