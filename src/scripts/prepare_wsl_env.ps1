param()

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message"
}

Write-Log "Preparing WSL environment for ROCm installation..."

# Define paths
$ScriptDir = $PSScriptRoot
$WSLTargetDir = "/tmp/ROCm_install"
$Distro = "Ubuntu-22.04"

# Create target directory in WSL
Write-Log "Creating directory $WSLTargetDir in WSL..."
wsl -d $Distro -e bash -c "mkdir -p $WSLTargetDir"

if ($LASTEXITCODE -ne 0) {
    Write-Log "Failed to create directory in WSL" "ERROR"
    exit 1
}

# Copy scripts to WSL
$ScriptsToCopy = @("install_rocm.sh", "install_pytorch.sh")

foreach ($Script in $ScriptsToCopy) {
    $SourcePath = Join-Path $ScriptDir $Script
    
    if (Test-Path $SourcePath) {
        Write-Log "Copying $Script to WSL..."
        # Use wsl cp or just copy to the network share path
        # Network share path: \\wsl.localhost\Ubuntu-22.04\tmp\ROCm_install
        
        $WSLPath = "\\wsl.localhost\$Distro$WSLTargetDir\$Script"
        
        try {
            Copy-Item -Path $SourcePath -Destination $WSLPath -Force
            
            # Make executable
            wsl -d $Distro -e bash -c "chmod +x $WSLTargetDir/$Script"
            Write-Log "Copied and made executable: $Script" "SUCCESS"
        } catch {
            Write-Log "Failed to copy $Script: $_" "ERROR"
            # Fallback method using cat
            # Get-Content $SourcePath | wsl -d $Distro -e bash -c "cat > $WSLTargetDir/$Script"
        }
    } else {
        Write-Log "Source script not found: $SourcePath" "WARNING"
    }
}

Write-Log "WSL environment preparation complete." "SUCCESS"
