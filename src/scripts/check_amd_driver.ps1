# Check AMD Driver Script for ROCm Windows Installer
# Checks for AMD GPU and minimum driver version

$ErrorActionPreference = "Stop"
$minMajorVersion =31 # Adrenalin25.9.2+ (ROCm support)

Write-Host "[INFO] Checking for AMD GPU..."
$gpus = Get-WmiObject Win32_VideoController | Where-Object { $_.Name -match "AMD|Radeon" }
if (-not $gpus) {
 Write-Host "[ERROR] No AMD GPU detected. Please install a supported AMD GPU." -ForegroundColor Red
 exit1
}

Write-Host "[INFO] AMD GPU(s) detected:"
$gpus | ForEach-Object { Write-Host " - $($_.Name)" }

Write-Host "[INFO] Checking AMD driver version..."
$driverOk = $false
foreach ($gpu in $gpus) {
 $driverVersion = $gpu.DriverVersion
 Write-Host "[INFO] Driver version: $driverVersion"
 $versionParts = $driverVersion -split '\.'
 if ($versionParts.Count -gt0) {
 $majorVersion = [int]$versionParts[0]
 if ($majorVersion -ge $minMajorVersion) {
 $driverOk = $true
 }
 }
}

if (-not $driverOk) {
 Write-Host "[ERROR] AMD driver version is too old. Please install Adrenalin25.9.2 or newer." -ForegroundColor Red
 exit1
}

Write-Host "[SUCCESS] AMD GPU and driver version are compatible."
exit0
