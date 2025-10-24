# Windows 10 Pro Compatibility Analysis

## Executive Summary

**Current Status**: Installer is Windows 11-only
**Windows 10 Support**: **Possible with modifications**  
**Effort Level**: **Low to Medium** (2-4 hours)
**Compatibility**: x64 only (both Win10 and Win11)

---

## Technical Analysis

### Current Limitations

The installer currently has a **hard requirement for Windows 11** in `Product.wxs`:

```xml
<Condition Message="This application requires Windows 11 or later.">
  <![CDATA[Installed OR (VersionNT >= 603)]]>
</Condition>
```

**Issue**: VersionNT 603 = Windows 8.1, not Windows 11!  
**Correct codes**:
- Windows 10 = VersionNT >= 600 (6.0) or more specifically >= 603 (10.0)
- Windows 11 = VersionNT >= 603 AND BuildNumber >= 22000

### What Works on Windows 10 Pro

? **Will Work Without Changes**:
- MSI installer format (Windows Installer 5.0+)
- WiX-generated installers
- x64 architecture
- PowerShell 5.1+ (included in Win10 Pro)
- .NET Framework (included)
- File installation
- Registry entries
- Start menu shortcuts
- Add/Remove Programs integration

? **Will Work With Minor Modifications**:
- WSL2 (available since Windows 10 version 1903, build 18362+)
- Hyper-V (available in Windows 10 Pro, not Home)
- Virtual Machine Platform
- AMD GPU detection (same on Win10 and Win11)
- ROCm in WSL (Linux version doesn't care about Windows version)

?? **May Require Adjustments**:
- Windows Defender Application Guard (not available on all Win10 editions)
- Smart App Control (Windows 11 only feature)
- Some security settings APIs

? **Windows 10 Home Limitations**:
- No Hyper-V support
- No Windows Defender Application Guard
- WSL2 requires special enabling

---

## Required Changes for Windows 10 Support

### 1. Version Check (CRITICAL)

**File**: `installer/Product.wxs`

```xml
<!-- Current (Windows 11 only) -->
<Condition Message="This application requires Windows 11 or later.">
  <![CDATA[Installed OR (VersionNT >= 603)]]>
</Condition>

<!-- Option A: Windows 10 Pro/Enterprise/Education (Build 18362+) -->
<Condition Message="This application requires Windows 10 (Build 18362+) or Windows 11 Pro/Enterprise/Education with WSL2 support.">
  <![CDATA[Installed OR ((VersionNT >= 603) AND (MsiNTProductType = 1) AND (WindowsBuild >= 18362))]]>
</Condition>

<!-- Option B: Windows 11 only (strict) -->
<Condition Message="This application requires Windows 11 (Build 22000+).">
  <![CDATA[Installed OR ((VersionNT >= 603) AND (WindowsBuild >= 22000))]]>
</Condition>

<!-- Option C: Flexible (recommended) -->
<Condition Message="This application requires Windows 10 Pro/Enterprise (Build 19041+) or Windows 11.">
  <![CDATA[Installed OR ((VersionNT >= 603) AND (WindowsBuild >= 19041))]]>
</Condition>
```

**Recommendation**: Use **Option C** (flexible) to support:
- Windows 10 Pro version 2004 (build 19041) and later
- Windows 11 all versions

### 2. Edition Detection (IMPORTANT)

Add detection for Pro/Enterprise editions to ensure Hyper-V availability:

```xml
<!-- Add to Product.wxs -->
<Property Id="WINDOWSEDITION">
  <RegistrySearch Id="WindowsEdition" 
       Root="HKLM" 
      Key="SOFTWARE\Microsoft\Windows NT\CurrentVersion" 
        Name="EditionID" 
   Type="raw" />
</Property>

<Condition Message="This application requires Windows Pro, Enterprise, or Education edition for Hyper-V/WSL2 support.">
  <![CDATA[Installed OR (WINDOWSEDITION = "Professional" OR WINDOWSEDITION = "Enterprise" OR WINDOWSEDITION = "Education" OR WINDOWSEDITION = "ServerStandard")]]>
</Condition>
```

### 3. Security Configuration Script Updates (MEDIUM)

**File**: `installer/CustomActions/SecurityConfig.ps1`

```powershell
# Add Windows version detection
function Get-WindowsVersion {
    $os = Get-CimInstance Win32_OperatingSystem
    $build = [int]$os.BuildNumber
    
    if ($build -ge 22000) {
     return "Windows11"
    } elseif ($build -ge 19041) {
   return "Windows10_2004Plus"
    } elseif ($build -ge 18362) {
      return "Windows10_1903Plus"
    } else {
        return "UnsupportedWindows10"
}
}

# Modify Smart App Control section
function Check-SmartAppControl {
    $winVersion = Get-WindowsVersion
    
    if ($winVersion -eq "Windows11") {
        # Show Smart App Control warning for Windows 11
  Show-SmartAppControlWarning
    } else {
    # Windows 10 doesn't have Smart App Control
  Write-InstallLog "Smart App Control not available on Windows 10 - skipping" "INFO"
    }
}

# Modify WDAG section
function Disable-WindowsDefenderApplicationGuard {
    Write-InstallLog "Checking Windows Defender Application Guard..."
    
    # Check Windows edition
    $edition = (Get-WindowsEdition -Online).Edition
    $supportedEditions = @("Professional", "Enterprise", "Education")
    
    if ($edition -notin $supportedEditions) {
      Write-InstallLog "Windows Defender Application Guard not available on $edition edition" "INFO"
        return $true
    }
    
    # Continue with WDAG disable...
}
```

### 4. WSL2 Installation Script Updates (LOW)

**File**: `installer/CustomActions/installer_actions.ps1`

```powershell
function Install-WSL2 {
  Write-InstallLog "Installing WSL2 and Ubuntu 22.04..."
    
  # Check Windows build
    $build = [int](Get-CimInstance Win32_OperatingSystem).BuildNumber
    
    if ($build -lt 18362) {
   Write-InstallLog "WSL2 requires Windows 10 build 18362 or later" "ERROR"
     return 1603
    }
    
    # Continue with installation...
}
```

### 5. Product Naming (LOW)

Update product name to reflect Windows 10 support:

```xml
<!-- installer/Product.wxs -->
<?define ProductName = "AMD ROCm Windows Installer" ?>
<!-- Or -->
<?define ProductName = "AMD ROCm Windows 10/11 Installer" ?>
```

---

## Build Targets

The MSI will work on **x64 only** (both Windows 10 and 11):

```xml
<!-- This is already correct in Product.wxs -->
<Package InstallerVersion="500" 
       Compressed="yes" 
         InstallScope="perMachine" 
Platform="x64" />
```

**ARM64**: Not currently supported by ROCm, so not needed.

---

## Testing Matrix

| OS Version | Edition | Build | WSL2 | Hyper-V | Expected Result |
|------------|---------|-------|------|---------|-----------------|
| Windows 10 | Home | 19041+ | ? | ? | ?? Partial (no Hyper-V) |
| Windows 10 | Pro | 18362-19040 | ?? | ? | ?? Needs update |
| Windows 10 | Pro | 19041+ | ? | ? | ? Full support |
| Windows 10 | Enterprise | 19041+ | ? | ? | ? Full support |
| Windows 11 | Home | 22000+ | ? | ? | ?? Partial (no Hyper-V) |
| Windows 11 | Pro | 22000+ | ? | ? | ? Full support |

---

## Recommended Approach

### Option 1: Dual-Version Strategy (RECOMMENDED)

Create two installer variants:

1. **ROCm_Installer_Win11.msi** (current)
   - Windows 11 only
   - Full feature set
   - Simpler code paths

2. **ROCm_Installer_Win10_Win11.msi** (new)
   - Windows 10 Pro (19041+) and Windows 11
   - Conditional feature enablement
   - Broader compatibility

**Effort**: 3-4 hours  
**Benefits**: 
- Clean separation
- Easier testing
- Users choose appropriate version

### Option 2: Universal Installer (COMPLEX)

Single installer with runtime detection:

```xml
<Property Id="ISWIN11">
  <![CDATA[(VersionNT >= 603) AND (WindowsBuild >= 22000)]]>
</Property>

<Property Id="ISWIN10PRO">
  <![CDATA[(VersionNT >= 603) AND (WindowsBuild >= 19041) AND (WindowsBuild < 22000)]]>
</Property>

<!-- Conditionally enable features -->
<Feature Id="SmartAppControlDisable" Level="100">
  <Condition Level="1">ISWIN11</Condition>
</Feature>
```

**Effort**: 4-6 hours  
**Benefits**: 
- Single MSI to maintain
- Automatic feature detection

---

## Implementation Plan

### Phase 1: Core Compatibility (2 hours)

1. ? Update version check in `Product.wxs`
2. ? Add edition detection
3. ? Test on Windows 10 Pro VM
4. ? Update product name

### Phase 2: Security Adaptations (1 hour)

1. ? Update `SecurityConfig.ps1` with version detection
2. ? Make WDAG disable conditional
3. ? Skip Smart App Control on Win10
4. ? Test security configuration

### Phase 3: Testing & Validation (1 hour)

1. ? Test on Windows 10 Pro 21H2
2. ? Test on Windows 10 Pro 22H2
3. ? Test on Windows 11 22H2
4. ? Update documentation

---

## Code Changes Summary

**Files to Modify**:
1. `installer/Product.wxs` - Version check + edition detection
2. `installer/CustomActions/SecurityConfig.ps1` - Version-aware logic
3. `installer/CustomActions/installer_actions.ps1` - Build number check
4. `installer/CustomActions/GPUDetection.ps1` - No changes needed
5. `installer/CustomActions/Validation.ps1` - No changes needed
6. `README.md` - Update system requirements

**Files to Add**:
1. `docs/WINDOWS10_COMPATIBILITY.md` - This document
2. `docs/TESTING_MATRIX.md` - Testing results

---

## System Requirements Update

**Before**:
```
- Windows 11 (Build 22000+)
- AMD Radeon RX 7000 Series GPU
- 16GB+ RAM
- 50GB+ disk space
```

**After** (if supporting Windows 10):
```
- Windows 10 Pro/Enterprise/Education (Build 19041+) OR Windows 11
- AMD Radeon RX 7000 Series GPU or Ryzen AI APU
- 16GB+ RAM (32GB recommended)
- 50GB+ disk space
- Hyper-V capable system
- Virtualization enabled in BIOS
```

---

## Recommendation

**For your use case**, I recommend:

? **Option 1: Flexible Universal Installer** (4 hours effort)
- Support Windows 10 Pro (19041+) and Windows 11
- Single MSI with conditional features
- Covers ~95% of target users
- Easier to maintain than dual installers

**Why**:
1. Windows 10 Pro users can still use WSL2 + ROCm
2. Most development workstations are Windows 10 Pro or Windows 11 Pro
3. Code changes are minimal and well-isolated
4. Single build pipeline in CI/CD

**Implementation Steps**:
1. Update version check to build 19041+
2. Add edition detection for Pro/Enterprise
3. Make Smart App Control logic conditional
4. Test on both Windows 10 and 11
5. Update documentation

Would you like me to implement these Windows 10 compatibility changes now?
