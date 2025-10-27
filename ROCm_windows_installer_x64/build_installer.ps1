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
    Write-ColorOutput "WARNING: WiX Toolset not found in common locations. Relying on system PATH or CI runner." "Yellow"
} else {
    Write-ColorOutput "WiX Toolset found at: $wixPath" "Green"
    # Add WiX to PATH for this session
    $env:Path = "$wixPath;$env:Path"
}

# Navigate to installer directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Determine where the WiX source files live. Support two layouts:
#1) $scriptDir\installer\Product.wxs (old layout)
#2) $scriptDir\Product.wxs (current layout)

$installerDirCandidate1 = Join-Path $scriptDir "installer"
$installerDirCandidate2 = $scriptDir
$installerDir = $null

if (Test-Path (Join-Path $installerDirCandidate1 "Product.wxs")) {
    $installerDir = $installerDirCandidate1
} elseif (Test-Path (Join-Path $installerDirCandidate2 "Product.wxs")) {
    $installerDir = $installerDirCandidate2
} else {
    # If no Product.wxs found, create installer folder and attempt to move WiX sources if present
    Write-ColorOutput "No Product.wxs found in expected locations. Attempting to create installer directory and locate WiX sources..." "Yellow"
    New-Item -ItemType Directory -Path $installerDirCandidate1 -Force | Out-Null
    $installerDir = $installerDirCandidate1

    # Move known WiX source files if they exist at script root
    $toMove = @('Product.wxs', '*.wixproj', 'Components', 'CustomActions', 'Resources')
    foreach ($item in $toMove) {
        $matches = Get-ChildItem -Path $scriptDir -Filter $item -Recurse -Force -ErrorAction SilentlyContinue
        foreach ($m in $matches) {
            try {
                $dest = Join-Path $installerDir $m.Name
                if ($m.PSIsContainer) {
                    Copy-Item -Path $m.FullName -Destination $dest -Recurse -Force
                } else {
                    Copy-Item -Path $m.FullName -Destination $installerDir -Force
                }
                Write-ColorOutput "Moved $($m.FullName) -> $dest" "Gray"
            } catch {
                Write-ColorOutput "Warning: failed to move $($m.FullName): $_" "Yellow"
            }
        }
    }

    if (-not (Test-Path (Join-Path $installerDir "Product.wxs"))) {
        Write-ColorOutput "ERROR: Could not locate Product.wxs. Please ensure WiX source files are present in $installerDir or $scriptDir." "Red"
        exit1
    }
}

Write-ColorOutput "Installer directory: $installerDir" "Gray"

# Prepare output directories
$outputDir = Join-Path $scriptDir "bin\$Configuration"
$objDir = Join-Path $installerDir "obj\$Configuration"

# Clean if requested
if ($Clean) {
    Write-ColorOutput "`nCleaning build directories..." "Yellow"
    if (Test-Path $objDir) {
 Remove-Item $objDir -Recurse -Force
        Write-ColorOutput " Cleaned: $objDir" "Gray"
    }
    if (Test-Path $outputDir) {
        Remove-Item $outputDir -Recurse -Force
     Write-ColorOutput " Cleaned: $outputDir" "Gray"
  }
}

# Create output directories
if (-not (Test-Path $objDir)) { New-Item -ItemType Directory -Path $objDir -Force | Out-Null }
if (-not (Test-Path $outputDir)) { New-Item -ItemType Directory -Path $outputDir -Force | Out-Null }

# List of WiX source files (relative to installerDir)
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

if (Test-Path $msiFile) { Remove-Item $msiFile -Force }

$lightArgs = @(
    $wixObjFiles,
    "-ext", "WixUIExtension",
    "-ext", "WixUtilExtension",
    "-out", $msiFile,
    "-sval",
    "-spdb"
)

if ($Verbose) {
    $lightArgs += "-v"
}

& light.exe $lightArgs

if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput "ERROR: Linking failed" "Red"
 exit $LASTEXITCODE
}

# Verify MSI exists
if (-not (Test-Path $msiFile)) {
 Write-ColorOutput "ERROR: MSI was not created at expected path: $msiFile" "Red"
 exit1
}

Write-ColorOutput "`n===== Build Complete! =====" "Green"
Write-ColorOutput "MSI created: $msiFile" "Green"

# Get file size
$msiSize = [math]::Round((Get-Item $msiFile).Length /1MB,2)
Write-ColorOutput "File size: ${msiSize} MB" "Gray"

# Calculate checksum
Write-ColorOutput "`nCalculating checksums..." "Yellow"
$sha256 = (Get-FileHash -Path $msiFile -Algorithm SHA256).Hash
$md5 = (Get-FileHash -Path $msiFile -Algorithm MD5).Hash

Write-ColorOutput "SHA256: $sha256" "Gray"
Write-ColorOutput "MD5: $md5" "Gray"

# Save checksums
"$sha256 $(Split-Path -Leaf $msiFile)" | Out-File -FilePath "$msiFile.sha256" -Encoding utf8
"$md5 $(Split-Path -Leaf $msiFile)" | Out-File -FilePath "$msiFile.md5" -Encoding utf8

Write-ColorOutput "`nChecksum files created." "Green"
Write-ColorOutput "`n===== Installation Instructions =====" "Cyan"
Write-ColorOutput "1. Right-click on the MSI file" "White"
Write-ColorOutput "2. Select 'Run as Administrator'" "White"
Write-ColorOutput "3. Follow the installation wizard" "White"
Write-ColorOutput "4. Reboot if prompted" "White"
Write-ColorOutput "`nFor testing, you can also run:" "Yellow"
Write-ColorOutput " msiexec /i `"$msiFile`" /L*V install.log" "Gray"
Write-ColorOutput "==========================================`n" "Cyan"
