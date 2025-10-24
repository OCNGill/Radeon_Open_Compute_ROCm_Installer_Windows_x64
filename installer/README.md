# WiX Installer Directory

This directory contains the WiX Toolset installer project for the AMD ROCm Windows 11 Installer.

## Directory Structure

```
installer/
??? Product.wxs              # Main product definition
??? ROCmInstaller.wixproj    # WiX project file
??? Components/       # Feature component definitions
?   ??? Driver.wxs        # AMD driver & diagnostic tools
?   ??? ROCm.wxs    # Core ROCm runtime components
?   ??? WSL2.wxs             # WSL2 configuration
?   ??? Python.wxs           # Python environment & PyTorch
?   ??? LLM_GUI.wxs          # LM Studio & Streamlit GUI
??? CustomActions/  # PowerShell scripts for custom actions
?   ??? installer_actions.ps1 # Main custom action dispatcher
?   ??? GPUDetection.ps1     # GPU hardware detection
?   ??? SecurityConfig.ps1   # Windows security configuration
?   ??? Validation.ps1       # Post-install validation
??? Resources/        # Installer UI resources
 ??? Banner.bmp    # Top banner (493x58)
    ??? Dialog.bmp           # Dialog background (493x312)
    ??? License.rtf          # End User License Agreement
    ??? rocm_icon.ico        # Application icon
```

## Building the Installer

### Prerequisites

1. **WiX Toolset v3.11+**
   - Download from: https://wixtoolset.org/releases/
   - Or install via: `dotnet tool install --global wix`

2. **Visual Studio 2022** (optional, but recommended)
   - Install "WiX Toolset Visual Studio Extension"
   - Provides IntelliSense and debugging support

3. **Administrator Privileges**
   - Required for building and testing

### Build Methods

#### Method 1: Using the Build Script (Recommended)

```powershell
# Build release version
.\build_installer.ps1

# Build with specific version
.\build_installer.ps1 -Version "1.0.1.0"

# Clean build
.\build_installer.ps1 -Clean

# Debug build with verbose output
.\build_installer.ps1 -Configuration Debug -Verbose
```

#### Method 2: Using MSBuild

```powershell
cd installer
msbuild ROCmInstaller.wixproj /p:Configuration=Release /p:ProductVersion=1.0.0.0
```

#### Method 3: Manual Compilation

```powershell
cd installer

# Compile WiX sources
candle.exe Product.wxs Components\*.wxs `
  -dProductVersion="1.0.0.0" `
  -ext WixUIExtension `
  -ext WixUtilExtension `
  -arch x64 `
  -out obj\

# Link into MSI
light.exe obj\*.wixobj `
  -ext WixUIExtension `
  -ext WixUtilExtension `
  -out ..\bin\ROCm_Installer.msi `
  -sval `
  -spdb
```

## Testing the Installer

### Installation Testing

```powershell
# Install with logging
msiexec /i "bin\Release\ROCm_Installer_Win11.msi" /L*V install.log

# Silent installation
msiexec /i "bin\Release\ROCm_Installer_Win11.msi" /qn /L*V install.log

# Uninstall
msiexec /x "bin\Release\ROCm_Installer_Win11.msi" /L*V uninstall.log
```

### Validation

After installation, verify:

1. **WSL2 Installation**
   ```powershell
 wsl --list --verbose
   # Should show Ubuntu-22.04 running
   ```

2. **ROCm Installation**
   ```bash
   wsl -d Ubuntu-22.04 rocminfo
   ```

3. **PyTorch Installation**
   ```bash
   wsl -d Ubuntu-22.04 python3 -c "import torch; print(torch.cuda.is_available())"
   ```

## Installer Features

### Feature Tree

- **ROCm Runtime** (Required)
  - Core ROCm libraries
  - Installation scripts
  - Documentation

- **WSL2 & Ubuntu 22.04** (Required)
  - Windows Subsystem for Linux
  - Ubuntu 22.04 LTS distribution
  - WSL configuration

- **PyTorch with ROCm** (Required)
  - PyTorch 2.1.2
  - ROCm 6.1.3 support
  - Python environment

- **LM Studio GUI** (Optional)
  - Streamlit dashboard
  - LM Studio integration
  - Desktop shortcuts

- **Development Tools** (Optional)
  - rocminfo
  - amd-smi
  - Diagnostic utilities

### Custom Actions

The installer performs several custom actions:

1. **Pre-Install Checks**
   - GPU detection and validation
   - Driver version verification
   - Windows 11 compatibility check

2. **Installation Steps**
   - Security configuration (disable WDAG)
   - WSL2 installation
   - ROCm installation in WSL
   - PyTorch installation
   - Post-install validation

3. **Post-Install**
   - System restart prompt (if needed)
- Validation report
   - First-run instructions

## Customization

### Modifying Installer UI

Edit `Product.wxs` to customize:

- Product information (name, version, manufacturer)
- License agreement (`Resources\License.rtf`)
- Installer images (`Resources\Banner.bmp`, `Resources\Dialog.bmp`)
- Installation directory
- Feature descriptions

### Adding New Components

1. Create a new `.wxs` file in `Components\`
2. Define components and component groups
3. Reference in `Product.wxs`:
   ```xml
   <Feature Id="NewFeature" Title="..." Level="1">
     <ComponentGroupRef Id="NewComponentGroup" />
   </Feature>
   ```
4. Add to `ROCmInstaller.wixproj`:
   ```xml
<Compile Include="Components\NewFeature.wxs" />
   ```

### Adding Custom Actions

1. Create PowerShell script in `CustomActions\`
2. Add to `Product.wxs`:
   ```xml
   <CustomAction Id="NewAction" 
             BinaryKey="CustomActionScript" 
 Execute="deferred" />
   
   <Custom Action="NewAction" After="InstallFiles">
     NOT Installed
   </Custom>
   ```

## Troubleshooting

### Build Errors

**Error: "The system cannot find the file specified"**
- Ensure all source files referenced in `.wxs` files exist
- Check file paths are relative to the installer directory

**Error: "Unresolved reference to symbol"**
- Verify all `ComponentRef` IDs match component IDs
- Ensure all `.wxs` files are included in the project

**Error: "Invalid directory syntax"**
- Directory IDs must be alphanumeric (no special characters)
- Use proper directory nesting structure

### Installation Errors

**Error 1603: Fatal error during installation**
- Check `install.log` for details
- Common causes:
  - Missing administrator privileges
  - Custom action failures
  - File access denied

**Error 1605: This action is only valid for products that are currently installed**
- Product not properly registered
- Use Product GUID to uninstall manually

**WSL2 Installation Fails**
- Ensure Windows 11 build 22000+
- Enable virtualization in BIOS
- Run: `wsl --install` manually first

## Resources

- **WiX Documentation**: https://wixtoolset.org/documentation/
- **WiX Tutorial**: https://www.firegiant.com/wix/tutorial/
- **MSI Logging**: https://learn.microsoft.com/windows/win32/msi/windows-installer-logging
- **Custom Actions**: https://wixtoolset.org/documentation/manual/v3/wixdev/extensions/authoring_custom_actions.html

## Support

For issues specific to the installer:
- Check build logs in `installer\obj\`
- Review installation logs (specify with `/L*V`)
- Open an issue on GitHub with log files

For ROCm installation issues:
- See main project [TROUBLESHOOTING.md](../docs/TROUBLESHOOTING.md)
- Check [AMD ROCm documentation](https://rocm.docs.amd.com/)
