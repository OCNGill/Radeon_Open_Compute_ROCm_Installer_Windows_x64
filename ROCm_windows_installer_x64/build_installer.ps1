# Improvements: use Start-Process to capture exit codes and show stdout/stderr from candle/light for easier CI debugging
# Improve installer directory detection and fix exit code typos
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

# Try to find candle.exe and light.exe in PATH first
$candleCmd = Get-Command candle.exe -ErrorAction SilentlyContinue
$lightCmd = Get-Command light.exe -ErrorAction SilentlyContinue

# If not found, try common WiX install locations (including Chocolatey path)
if (-not $candleCmd) {
    $possible = @(
                   "C:\Program Files (x86)\WiX Toolset v3.11\bin\candle.exe",
                   "C:\Program Files (x86)\WiX Toolset v3.14\bin\candle.exe",
                   "C:\Program Files\WiX Toolset v3.11\bin\candle.exe",
                   "C:\ProgramData\chocolatey\lib\wixtoolset\tools\wix\bin\candle.exe"
 )
    foreach ($p in $possible) { if (Test-Path $p) { $candleCmd = $p; break } }
}
if (-not $lightCmd) {
    $possible = @(
                   "C:\Program Files (x86)\WiX Toolset v3.11\bin\light.exe",
                   "C:\Program Files (x86)\WiX Toolset v3.14\bin\light.exe",
                   "C:\Program Files\WiX Toolset v3.11\bin\light.exe",
                   "C:\ProgramData\chocolatey\lib\wixtoolset\tools\wix\bin\light.exe"
 )
    foreach ($p in $possible) { if (Test-Path $p) { $lightCmd = $p; break } }
}

if (-not $candleCmd -or -not $lightCmd) {
    Write-ColorOutput "ERROR: candle.exe or light.exe not found. Ensure WiX is installed or available in PATH." "Red"
    Write-ColorOutput "Found candle: $candleCmd" "Gray"
    Write-ColorOutput "Found light: $lightCmd" "Gray"
    exit 1
}

# Normalize to executable paths
$candleExe = if ($candleCmd -is [System.Management.Automation.CommandInfo]) { $candleCmd.Source } else { $candleCmd }
$lightExe = if ($lightCmd -is [System.Management.Automation.CommandInfo]) { $lightCmd.Source } else { $lightCmd }

Write-ColorOutput "Using candle: $candleExe" "Green"
Write-ColorOutput "Using light: $lightExe" "Green"

# Navigate to installer directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Determine where the WiX source files live. Support multiple layouts by searching several likely locations
$installerCandidates = @(
 Join-Path $scriptDir "installer",
 $scriptDir,
 Join-Path $scriptDir "..\installer",
 Join-Path $scriptDir "..",
 Join-Path $scriptDir "..\..\installer",
 Join-Path $scriptDir "..\.."
)
$installerDir = $null
foreach ($cand in $installerCandidates) {
 try {
 $candPath = Resolve-Path -Path $cand -ErrorAction SilentlyContinue
 if ($candPath -and (Test-Path (Join-Path $cand "Product.wxs"))) {
 $installerDir = (Get-Item $cand).FullName
 break
 }
 } catch {
 # Silently continue if path resolution fails
 }
} # end foreach

# Fallback: search repository tree for any Product.wxs if not found yet
if (-not $installerDir) {
 Write-ColorOutput "Product.wxs not found in expected candidates. Searching repository for Product.wxs..." "Yellow"
 $found = Get-ChildItem -Path (Join-Path $scriptDir "..") -Filter Product.wxs -Recurse -ErrorAction SilentlyContinue | Select-Object -First1
 if ($found) {
 $installerDir = $found.Directory.FullName
 Write-ColorOutput "Found Product.wxs at: $($found.FullName)" "Gray"
 }
}

if (-not $installerDir -or -not (Test-Path (Join-Path $installerDir "Product.wxs"))) {
 Write-ColorOutput "ERROR: Could not locate Product.wxs. Please ensure WiX source files are present." "Red"
 exit 1
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
$missing = @()
foreach ($wixFile in $wixFiles) {
 $sourceFile = Join-Path $installerDir $wixFile
 $objFile = Join-Path $objDir ([System.IO.Path]::GetFileNameWithoutExtension($wixFile) + ".wixobj")

 if (-not (Test-Path $sourceFile)) {
 Write-ColorOutput "WARNING: Source file not found: $sourceFile" "Yellow"
 $missing += $sourceFile
 continue
 }

 Write-ColorOutput "Compiling: $wixFile" "Gray"

 $argList = "-out `"$objFile`" -dProductVersion=$Version -dConfiguration=$Configuration -ext WixUIExtension -ext WixUtilExtension -arch x64 `"$sourceFile`""
 if ($Verbose) { $argList += " -v" }

 Write-ColorOutput "Running: $candleExe $argList" "Gray"

 $stdout = [System.IO.Path]::Combine($env:TEMP, "candle_stdout.txt")
 $stderr = [System.IO.Path]::Combine($env:TEMP, "candle_stderr.txt")
 if (Test-Path $stdout) { Remove-Item $stdout -Force }
 if (Test-Path $stderr) { Remove-Item $stderr -Force }

 $proc = Start-Process -FilePath $candleExe -ArgumentList $argList -NoNewWindow -Wait -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr

 # Dump outputs for CI logs
 if (Test-Path $stdout) { Get-Content $stdout | ForEach-Object { Write-Host $_ } }
 if (Test-Path $stderr) { Get-Content $stderr | ForEach-Object { Write-Host $_ } }

 if ($proc.ExitCode -ne0) {
 Write-ColorOutput "ERROR: Compilation failed for $wixFile (exit code $($proc.ExitCode))" "Red"
 exit $proc.ExitCode
 }

 if (-not (Test-Path $objFile)) {
 Write-ColorOutput "ERROR: Expected .wixobj not found after compiling ${wixFile}: $objFile" "Red"
 exit 1
 }

 $wixObjFiles += $objFile
}

if ($wixObjFiles.Count -eq0) {
 Write-ColorOutput "ERROR: No .wixobj files were generated. Missing source files:" "Red"
 foreach ($m in $missing) { Write-ColorOutput " - $m" "Red" }
 exit 1
}

Write-ColorOutput "Generated .wixobj files:" "Gray"
foreach ($f in $wixObjFiles) { Write-ColorOutput " - $f" "Gray" }

Write-ColorOutput "`n===== Linking MSI Package =====" "Cyan"

$msiFile = Join-Path $outputDir "ROCm_Installer_Win11_v$Version.msi"

if (Test-Path $msiFile) { Remove-Item $msiFile -Force }

$lightArgList = "-ext WixUIExtension -ext WixUtilExtension -out `"$msiFile`""
foreach ($o in $wixObjFiles) { $lightArgList += " `"$o`"" }
if ($Verbose) { $lightArgList += " -v" }

Write-ColorOutput "Running: $lightExe $lightArgList" "Gray"

$stdoutL = [System.IO.Path]::Combine($env:TEMP, "light_stdout.txt")
$stderrL = [System.IO.Path]::Combine($env:TEMP, "light_stderr.txt")
if (Test-Path $stdoutL) { Remove-Item $stdoutL -Force }
if (Test-Path $stderrL) { Remove-Item $stderrL -Force }

$procLight = Start-Process -FilePath $lightExe -ArgumentList $lightArgList -NoNewWindow -Wait -PassThru -RedirectStandardOutput $stdoutL -RedirectStandardError $stderrL

if (Test-Path $stdoutL) { Get-Content $stdoutL | ForEach-Object { Write-Host $_ } }
if (Test-Path $stderrL) { Get-Content $stderrL | ForEach-Object { Write-Host $_ } }

if ($procLight.ExitCode -ne0) {
 Write-ColorOutput "ERROR: Linking failed (exit code $($procLight.ExitCode))" "Red"
 exit $procLight.ExitCode
}

# Verify MSI exists
if (-not (Test-Path $msiFile)) {
 Write-ColorOutput "ERROR: MSI was not created at expected path - $msiFile" "Red"
 exit 1
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

Write-Host "Reached end of script"
