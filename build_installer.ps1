# Build ROCm Windows Installer
# This script compiles the WiX installer project

param(
    [string]$Configuration = "Release",
    [string]$Version = "1.0.0.0",
    [switch]$Clean,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

# Colors for output
function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

Write-ColorOutput "`n===== Building ROCm Windows Installer =====" "Cyan"
Write-ColorOutput "Configuration: $Configuration" "Yellow"
Write-ColorOutput "Version: $Version" "Yellow"

# Check if WiX is installed
$wixPath = "C:\Program Files (x86)\WiX Toolset v3.11\bin"
if (-not (Test-Path $wixPath)) {
    $wixPath = "C:\Program Files (x86)\WiX Toolset v3.14\bin"
}

if (-not (Test-Path $wixPath)) {
    Write-ColorOutput "ERROR: WiX Toolset not found!" "Red"
    Write-ColorOutput "Please install WiX Toolset from: https://wixtoolset.org/releases/" "Red"
    exit 1
}

Write-ColorOutput "WiX Toolset found at: $wixPath" "Green"

# Add WiX to PATH for this session
$env:Path = "$wixPath;$env:Path"

# Navigate to installer directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$installerDir = Join-Path $scriptDir "installer"
$outputDir = Join-Path $scriptDir "bin\$Configuration"
$objDir = Join-Path $installerDir "obj\$Configuration"

Write-ColorOutput "`nInstaller directory: $installerDir" "Gray"

if (-not (Test-Path $installerDir)) {
    Write-ColorOutput "ERROR: Installer directory not found: $installerDir" "Red"
    exit 1
}

# Clean if requested
if ($Clean) {
    Write-ColorOutput "`nCleaning build directories..." "Yellow"
    if (Test-Path $objDir) {
 Remove-Item $objDir -Recurse -Force
        Write-ColorOutput "  Cleaned: $objDir" "Gray"
    }
    if (Test-Path $outputDir) {
        Remove-Item $outputDir -Recurse -Force
     Write-ColorOutput "  Cleaned: $outputDir" "Gray"
  }
}

# Create output directories
New-Item -ItemType Directory -Path $objDir -Force | Out-Null
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

# List of WiX source files
$wixFiles = @(
    "Product.wxs",
    "Components\Driver.wxs",
    "Components\ROCm.wxs",
    "Components\WSL2.wxs",
    "Components\Python.wxs",
    "Components\LLM_GUI.wxs"
)

Write-ColorOutput "`n===== Compiling WiX Source Files =====" "Cyan"

# Compile each WiX file
$wixObjFiles = @()
foreach ($wixFile in $wixFiles) {
    $sourceFile = Join-Path $installerDir $wixFile
    $objFile = Join-Path $objDir ([System.IO.Path]::GetFileNameWithoutExtension($wixFile) + ".wixobj")
    
    if (-not (Test-Path $sourceFile)) {
      Write-ColorOutput "WARNING: Source file not found: $sourceFile" "Yellow"
        continue
    }
    
    Write-ColorOutput "Compiling: $wixFile" "Gray"
    
  $candleArgs = @(
 $sourceFile,
        "-dProductVersion=$Version",
    "-dConfiguration=$Configuration",
      "-ext", "WixUIExtension",
     "-ext", "WixUtilExtension",
"-arch", "x64",
        "-out", $objFile
    )
    
  if ($Verbose) {
      $candleArgs += "-v"
    }
    
    & candle.exe $candleArgs
    
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "ERROR: Compilation failed for $wixFile" "Red"
     exit $LASTEXITCODE
    }
    
  $wixObjFiles += $objFile
}

Write-ColorOutput "`n===== Linking MSI Package =====" "Cyan"

$msiFile = Join-Path $outputDir "ROCm_Installer_Win11_v$Version.msi"

$lightArgs = @(
    $wixObjFiles,
    "-ext", "WixUIExtension",
    "-ext", "WixUtilExtension",
    "-out", $msiFile,
    "-sval",  # Suppress ICE validation (for development)
    "-spdb"   # Suppress PDB creation
)

if ($Verbose) {
    $lightArgs += "-v"
}

& light.exe $lightArgs

if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput "ERROR: Linking failed" "Red"
exit $LASTEXITCODE
}

Write-ColorOutput "`n===== Build Complete! =====" "Green"
Write-ColorOutput "MSI created: $msiFile" "Green"

# Get file size
$msiSize = [math]::Round((Get-Item $msiFile).Length / 1MB, 2)
Write-ColorOutput "File size: ${msiSize} MB" "Gray"

# Calculate checksum
Write-ColorOutput "`nCalculating checksums..." "Yellow"
$sha256 = (Get-FileHash -Path $msiFile -Algorithm SHA256).Hash
$md5 = (Get-FileHash -Path $msiFile -Algorithm MD5).Hash

Write-ColorOutput "SHA256: $sha256" "Gray"
Write-ColorOutput "MD5: $md5" "Gray"

# Save checksums
"$sha256  $(Split-Path -Leaf $msiFile)" | Out-File -FilePath "$msiFile.sha256" -Encoding utf8
"$md5  $(Split-Path -Leaf $msiFile)" | Out-File -FilePath "$msiFile.md5" -Encoding utf8

Write-ColorOutput "`nChecksum files created." "Green"
Write-ColorOutput "`n===== Installation Instructions =====" "Cyan"
Write-ColorOutput "1. Right-click on the MSI file" "White"
Write-ColorOutput "2. Select 'Run as Administrator'" "White"
Write-ColorOutput "3. Follow the installation wizard" "White"
Write-ColorOutput "4. Reboot if prompted" "White"
Write-ColorOutput "`nFor testing, you can also run:" "Yellow"
Write-ColorOutput "  msiexec /i `"$msiFile`" /L*V install.log" "Gray"
Write-ColorOutput "==========================================`n" "Cyan"
