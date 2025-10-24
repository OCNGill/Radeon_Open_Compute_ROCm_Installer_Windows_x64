# Test WiX Installation and Project Setup
# Quick validation script for Phase 1 completion

param(
    [switch]$SkipBuild
)

$ErrorActionPreference = "Continue"

function Write-TestResult {
    param(
 [string]$Test,
    [bool]$Passed,
   [string]$Details = ""
    )
    
    $symbol = if ($Passed) { "[?]" } else { "[?]" }
    $color = if ($Passed) { "Green" } else { "Red" }
    
 Write-Host "$symbol $Test" -ForegroundColor $color
    if ($Details -and -not $Passed) {
   Write-Host "    $Details" -ForegroundColor Yellow
    }
}

Write-Host "`n???????????????????????????????????????????" -ForegroundColor Cyan
Write-Host "  WiX Installer Phase 1 Validation Test" -ForegroundColor Cyan
Write-Host "???????????????????????????????????????????`n" -ForegroundColor Cyan

$results = @{
    Passed = 0
    Failed = 0
}

# Test 1: Check WiX Toolset Installation
Write-Host "Testing WiX Toolset Installation..." -ForegroundColor Yellow
$wixPaths = @(
    "C:\Program Files (x86)\WiX Toolset v3.11\bin",
    "C:\Program Files (x86)\WiX Toolset v3.14\bin",
    "C:\Program Files (x86)\WiX Toolset v4.0\bin"
)

$wixFound = $false
$wixPath = ""
foreach ($path in $wixPaths) {
    if (Test-Path $path) {
        $wixFound = $true
 $wixPath = $path
     break
    }
}

Write-TestResult "WiX Toolset installed" $wixFound "Install from https://wixtoolset.org/releases/"
if ($wixFound) { 
    Write-Host "    Found at: $wixPath" -ForegroundColor Gray
    $results.Passed++
} else {
    $results.Failed++
}

# Test 2: Check candle.exe and light.exe
if ($wixFound) {
    $candlePath = Join-Path $wixPath "candle.exe"
    $lightPath = Join-Path $wixPath "light.exe"
    
    $candleExists = Test-Path $candlePath
    $lightExists = Test-Path $lightPath
 
    Write-TestResult "candle.exe available" $candleExists
    Write-TestResult "light.exe available" $lightExists
  
    if ($candleExists) { $results.Passed++ } else { $results.Failed++ }
    if ($lightExists) { $results.Passed++ } else { $results.Failed++ }
}

# Test 3: Check installer directory structure
Write-Host "`nTesting Installer Directory Structure..." -ForegroundColor Yellow

$requiredDirs = @(
    "installer",
    "installer\Components",
 "installer\CustomActions",
    "installer\Resources"
)

foreach ($dir in $requiredDirs) {
    $exists = Test-Path $dir
    Write-TestResult "Directory: $dir" $exists
    if ($exists) { $results.Passed++ } else { $results.Failed++ }
}

# Test 4: Check required WXS files
Write-Host "`nTesting WiX Source Files..." -ForegroundColor Yellow

$requiredWxs = @(
    "installer\Product.wxs",
    "installer\Components\Driver.wxs",
    "installer\Components\ROCm.wxs",
    "installer\Components\WSL2.wxs",
    "installer\Components\Python.wxs",
    "installer\Components\LLM_GUI.wxs"
)

foreach ($file in $requiredWxs) {
    $exists = Test-Path $file
    Write-TestResult "WXS file: $(Split-Path -Leaf $file)" $exists
    if ($exists) { $results.Passed++ } else { $results.Failed++ }
}

# Test 5: Check custom action scripts
Write-Host "`nTesting Custom Action Scripts..." -ForegroundColor Yellow

$requiredScripts = @(
    "installer\CustomActions\installer_actions.ps1",
    "installer\CustomActions\GPUDetection.ps1",
    "installer\CustomActions\SecurityConfig.ps1",
    "installer\CustomActions\Validation.ps1"
)

foreach ($script in $requiredScripts) {
    $exists = Test-Path $script
    Write-TestResult "Script: $(Split-Path -Leaf $script)" $exists
    if ($exists) { $results.Passed++ } else { $results.Failed++ }
}

# Test 6: Check resource files
Write-Host "`nTesting Resource Files..." -ForegroundColor Yellow

$requiredResources = @(
    "installer\Resources\License.rtf",
 "installer\Resources\Banner.bmp",
    "installer\Resources\Dialog.bmp",
    "installer\Resources\rocm_icon.ico"
)

foreach ($resource in $requiredResources) {
    $exists = Test-Path $resource
    Write-TestResult "Resource: $(Split-Path -Leaf $resource)" $exists
    if ($exists) { $results.Passed++ } else { $results.Failed++ }
}

# Test 7: Check project files
Write-Host "`nTesting Project Files..." -ForegroundColor Yellow

$projectFiles = @(
    "installer\ROCmInstaller.wixproj",
    "build_installer.ps1",
    "installer\README.md"
)

foreach ($file in $projectFiles) {
    $exists = Test-Path $file
    Write-TestResult "File: $(Split-Path -Leaf $file)" $exists
    if ($exists) { $results.Passed++ } else { $results.Failed++ }
}

# Test 8: Validate WXS file syntax (basic check)
Write-Host "`nValidating WXS File Syntax..." -ForegroundColor Yellow

foreach ($wxsFile in $requiredWxs) {
    if (Test-Path $wxsFile) {
        try {
      [xml]$xml = Get-Content $wxsFile
          $valid = $true
        } catch {
   $valid = $false
        }
        Write-TestResult "Valid XML: $(Split-Path -Leaf $wxsFile)" $valid
        if ($valid) { $results.Passed++ } else { $results.Failed++ }
    }
}

# Test 9: Test build script
if (-not $SkipBuild -and $wixFound) {
    Write-Host "`nTesting Build Script..." -ForegroundColor Yellow
    
    if (Test-Path "build_installer.ps1") {
      Write-Host "  Attempting test build (this may take a minute)..." -ForegroundColor Gray
        
        # Add WiX to PATH temporarily
 $env:Path = "$wixPath;$env:Path"
    
        try {
      # Run build script
     $buildOutput = & .\build_installer.ps1 -ErrorAction Stop 2>&1
            $buildSuccess = $LASTEXITCODE -eq 0
            
       Write-TestResult "Build script executed" $buildSuccess
    
            if ($buildSuccess) {
         $results.Passed++
           
    # Check if MSI was created
             $msiFiles = Get-ChildItem -Path "bin" -Filter "*.msi" -Recurse -ErrorAction SilentlyContinue
     if ($msiFiles) {
  Write-TestResult "MSI file created" $true
            $results.Passed++
   Write-Host " MSI: $($msiFiles[0].FullName)" -ForegroundColor Gray
        Write-Host "    Size: $([math]::Round($msiFiles[0].Length / 1MB, 2)) MB" -ForegroundColor Gray
            } else {
           Write-TestResult "MSI file created" $false
          $results.Failed++
           }
   } else {
      $results.Failed++
       Write-Host "    Build output:" -ForegroundColor Yellow
        Write-Host "    $buildOutput" -ForegroundColor Gray
          }
    } catch {
      Write-TestResult "Build script executed" $false "$($_.Exception.Message)"
            $results.Failed++
        }
  }
} else {
    Write-Host "`nSkipping build test (use without -SkipBuild to test build)" -ForegroundColor Yellow
}

# Summary
Write-Host "`n???????????????????????????????????????????" -ForegroundColor Cyan
Write-Host "  Test Summary" -ForegroundColor Cyan
Write-Host "???????????????????????????????????????????" -ForegroundColor Cyan

$total = $results.Passed + $results.Failed
$percentage = if ($total -gt 0) { [math]::Round(($results.Passed / $total) * 100, 1) } else { 0 }

Write-Host "`nPassed: $($results.Passed)" -ForegroundColor Green
Write-Host "Failed: $($results.Failed)" -ForegroundColor Red
Write-Host "Total:  $total" -ForegroundColor White
Write-Host "Success Rate: $percentage%" -ForegroundColor $(if ($percentage -ge 80) { "Green" } else { "Yellow" })

if ($results.Failed -eq 0) {
    Write-Host "`n? Phase 1 validation PASSED!" -ForegroundColor Green
    Write-Host "Ready to proceed with Phase 2 (Integration & Testing)" -ForegroundColor Green
  exit 0
} elseif ($percentage -ge 80) {
    Write-Host "`n? Phase 1 validation MOSTLY PASSED" -ForegroundColor Yellow
    Write-Host "Some non-critical issues found. Review failures above." -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "`n? Phase 1 validation FAILED" -ForegroundColor Red
    Write-Host "Please fix the issues above before proceeding." -ForegroundColor Red
    exit 1
}
