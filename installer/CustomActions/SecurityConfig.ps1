# Security Configuration Custom Action
# Configures Windows security settings for ROCm compatibility

param(
    [switch]$Restore
)

$ErrorActionPreference = "Stop"
$BackupFile = "$env:ProgramData\ROCm\security_backup.json"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message"
}

function Test-AdminPrivileges {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-WindowsVersion {
    Write-Log "Detecting Windows version..."
    
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $build = [int]$os.BuildNumber
        $caption = $os.Caption
        
        Write-Log "OS: $caption (Build $build)"
  
        if ($build -ge 22000) {
  Write-Log "Detected: Windows 11" "SUCCESS"
            return @{
      Version = "Windows11"
       Build = $build
                Caption = $caption
  }
        } elseif ($build -ge 19041) {
        Write-Log "Detected: Windows 10 version 2004 or later" "SUCCESS"
    return @{
             Version = "Windows10_2004Plus"
           Build = $build
    Caption = $caption
    }
 } elseif ($build -ge 18362) {
            Write-Log "Detected: Windows 10 version 1903 or later" "WARNING"
 Write-Log "Consider updating to Windows 10 version 2004 (build 19041) or later" "WARNING"
            return @{
                Version = "Windows10_1903Plus"
  Build = $build
      Caption = $caption
       }
    } else {
Write-Log "Unsupported Windows version (Build $build)" "ERROR"
            return @{
         Version = "Unsupported"
        Build = $build
      Caption = $caption
   }
      }
    } catch {
        Write-Log "Error detecting Windows version: $_" "ERROR"
        return @{
    Version = "Unknown"
    Build = 0
         Caption = "Unknown"
        }
    }
}

function Get-WindowsEdition {
    Write-Log "Detecting Windows edition..."
    
    try {
        $edition = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").EditionID
        Write-Log "Windows Edition: $edition"
        
        $supportedEditions = @("Professional", "ProfessionalWorkstation", "Enterprise", "Education", "ServerStandard", "ServerDatacenter")
        
        if ($edition -in $supportedEditions) {
            Write-Log "Edition supports Hyper-V and WSL2" "SUCCESS"
    return @{
       Edition = $edition
     Supported = $true
            }
 } else {
            Write-Log "Edition may not support Hyper-V: $edition" "WARNING"
            return @{
                Edition = $edition
        Supported = $false
    }
        }
    } catch {
        Write-Log "Error detecting Windows edition: $_" "WARNING"
      return @{
    Edition = "Unknown"
    Supported = $true  # Assume supported if we can't detect
        }
    }
}

function Backup-SecuritySettings {
    Write-Log "Creating backup of security settings..."
    
    $backup = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
 Settings = @{}
    }
    
    # Backup Windows Defender Application Guard state
    try {
        $wdag = Get-WindowsOptionalFeature -Online -FeatureName "Windows-Defender-ApplicationGuard" -ErrorAction SilentlyContinue
        if ($wdag) {
   $backup.Settings.WDAG = @{
    Enabled = ($wdag.State -eq "Enabled")
      }
        }
    } catch {
        Write-Log "Could not backup WDAG state: $_" "WARNING"
    }
    
    # Create backup directory
 $backupDir = Split-Path -Parent $BackupFile
    if (-not (Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
}
    
    # Save backup
    $backup | ConvertTo-Json -Depth 10 | Set-Content -Path $BackupFile
    Write-Log "Backup saved to: $BackupFile" "SUCCESS"
}

function Disable-WindowsDefenderApplicationGuard {
    Write-Log "Checking Windows Defender Application Guard..."
    
    try {
        # Check Windows edition first
   $editionInfo = Get-WindowsEdition
        
    if (-not $editionInfo.Supported) {
   Write-Log "Windows Defender Application Guard may not be available on $($editionInfo.Edition) edition" "INFO"
    }
        
        $wdag = Get-WindowsOptionalFeature -Online -FeatureName "Windows-Defender-ApplicationGuard" -ErrorAction SilentlyContinue

  if (-not $wdag) {
  Write-Log "Windows Defender Application Guard not found (may not be available on this edition)" "INFO"
      return $true
  }
        
        if ($wdag.State -eq "Enabled") {
    Write-Log "Disabling Windows Defender Application Guard..."
     Disable-WindowsOptionalFeature -Online -FeatureName "Windows-Defender-ApplicationGuard" -NoRestart -WarningAction SilentlyContinue
       Write-Log "Windows Defender Application Guard disabled (restart required)" "SUCCESS"
            return $true
    } else {
   Write-Log "Windows Defender Application Guard already disabled" "INFO"
      return $true
      }
    } catch {
    Write-Log "Error disabling Windows Defender Application Guard: $_" "ERROR"
    return $false
    }
}

function Set-HyperVConfiguration {
    Write-Log "Configuring Hyper-V for WSL2..."
    
    try {
    # Enable Hyper-V if not already enabled
        $hyperv = Get-WindowsOptionalFeature -Online -FeatureName "Microsoft-Hyper-V-All" -ErrorAction SilentlyContinue
      
    if ($hyperv -and $hyperv.State -ne "Enabled") {
     Write-Log "Enabling Hyper-V..."
          Enable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Hyper-V-All" -NoRestart -WarningAction SilentlyContinue
       Write-Log "Hyper-V enabled (restart may be required)" "SUCCESS"
        } else {
   Write-Log "Hyper-V already enabled" "INFO"
   }
        
  return $true
    } catch {
   Write-Log "Error configuring Hyper-V: $_" "WARNING"
        return $false
    }
}

function Set-WSLConfiguration {
    Write-Log "Configuring WSL settings..."
    
  try {
        # Enable WSL and Virtual Machine Platform
        $wsl = Get-WindowsOptionalFeature -Online -FeatureName "Microsoft-Windows-Subsystem-Linux" -ErrorAction SilentlyContinue
 $vmp = Get-WindowsOptionalFeature -Online -FeatureName "VirtualMachinePlatform" -ErrorAction SilentlyContinue
    
 if ($wsl -and $wsl.State -ne "Enabled") {
    Write-Log "Enabling WSL..."
 Enable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Windows-Subsystem-Linux" -NoRestart -WarningAction SilentlyContinue
  }
        
        if ($vmp -and $vmp.State -ne "Enabled") {
   Write-Log "Enabling Virtual Machine Platform..."
   Enable-WindowsOptionalFeature -Online -FeatureName "VirtualMachinePlatform" -NoRestart -WarningAction SilentlyContinue
}
        
 Write-Log "WSL configuration complete" "SUCCESS"
        return $true
 } catch {
  Write-Log "Error configuring WSL: $_" "ERROR"
return $false
    }
}

function Show-SmartAppControlWarning {
    # Get Windows version to determine if Smart App Control is applicable
    $winVersion = Get-WindowsVersion
    
    if ($winVersion.Version -eq "Windows11") {
        Write-Log "===== IMPORTANT: Smart App Control =====" "WARNING"
  Write-Log "Smart App Control must be manually disabled:" "WARNING"
    Write-Log "1. Open Settings > Privacy & security > Windows Security" "WARNING"
    Write-Log "2. Click 'App & browser control'" "WARNING"
    Write-Log "3. Under 'Smart App Control', select 'Off'" "WARNING"
        Write-Log "===========================================" "WARNING"
    } else {
  Write-Log "Smart App Control not available on Windows 10 - skipping" "INFO"
 }
}

function Restore-SecuritySettings {
    Write-Log "Restoring security settings from backup..."
    
    if (-not (Test-Path $BackupFile)) {
  Write-Log "No backup file found at: $BackupFile" "WARNING"
        return $false
    }
    
    try {
        $backup = Get-Content -Path $BackupFile | ConvertFrom-Json
   
        # Restore Windows Defender Application Guard
  if ($backup.Settings.WDAG.Enabled) {
  Write-Log "Restoring Windows Defender Application Guard..."
Enable-WindowsOptionalFeature -Online -FeatureName "Windows-Defender-ApplicationGuard" -NoRestart -WarningAction SilentlyContinue
        }
        
      Write-Log "Security settings restored" "SUCCESS"
  return $true
    } catch {
        Write-Log "Error restoring security settings: $_" "ERROR"
        return $false
    }
}

# Main execution
Write-Log "===== Security Configuration ====="

if (-not (Test-AdminPrivileges)) {
    Write-Log "Administrator privileges required" "ERROR"
    exit 1603
}

# Detect Windows version and edition
$winVersion = Get-WindowsVersion
$winEdition = Get-WindowsEdition

Write-Log "System Information:" "INFO"
Write-Log "  Windows: $($winVersion.Caption)" "INFO"
Write-Log "  Build: $($winVersion.Build)" "INFO"
Write-Log "  Edition: $($winEdition.Edition)" "INFO"
Write-Log "  Version Type: $($winVersion.Version)" "INFO"

# Check for unsupported versions
if ($winVersion.Version -eq "Unsupported") {
    Write-Log "Unsupported Windows version. Requires Windows 10 build 19041+ or Windows 11." "ERROR"
    exit 1603
}

if ($Restore) {
    # Restore mode
  if (Restore-SecuritySettings) {
 Write-Log "===== Security Restore: COMPLETE =====" "SUCCESS"
 exit 0
    } else {
        Write-Log "===== Security Restore: FAILED =====" "ERROR"
   exit 1603
    }
} else {
    # Configuration mode
    Backup-SecuritySettings
    
    $success = $true
    
    # Disable Windows Defender Application Guard
    if (-not (Disable-WindowsDefenderApplicationGuard)) {
  $success = $false
    }
    
    # Configure Hyper-V
    if (-not (Set-HyperVConfiguration)) {
      # Hyper-V failure is not critical
        Write-Log "Hyper-V configuration had warnings, continuing..." "WARNING"
    }
    
    # Configure WSL
  if (-not (Set-WSLConfiguration)) {
  $success = $false
    }
    
 # Show Smart App Control warning (Windows 11 only)
    Show-SmartAppControlWarning
    
    if ($success) {
   Write-Log "===== Security Configuration: COMPLETE =====" "SUCCESS"
        Write-Log "A system restart may be required for changes to take effect" "INFO"
 exit 0
    } else {
 Write-Log "===== Security Configuration: PARTIAL =====" "WARNING"
        exit 0  # Don't fail installation
    }
}
