# WiX Installer Resources

This directory contains resources used by the WiX installer.

## Required Files

### Images

1. **rocm_icon.ico** (32x32, 48x48, 256x256)
 - Application icon for the installed product
   - Shown in Add/Remove Programs
   - Should feature AMD/ROCm branding

2. **Banner.bmp** (493 x 58 pixels)
   - Top banner shown during installation
 - 8-bit or 24-bit BMP format
   - Should contain: "AMD ROCm Windows 11 Installer"

3. **Dialog.bmp** (493 x 312 pixels)
   - Background image for installer dialogs
- 8-bit or 24-bit BMP format
   - Should feature AMD Radeon/ROCm branding

### Documents

4. **License.rtf**
   - End User License Agreement
   - Rich Text Format
   - ? Already created

## Creating Images

### Using PowerShell to create placeholder images:

```powershell
# Create placeholder icon (requires additional tools)
# Recommended: Use GIMP, Paint.NET, or online icon generators

# Create placeholder BMP files
Add-Type -AssemblyName System.Drawing

# Banner (493x58)
$banner = New-Object System.Drawing.Bitmap(493, 58)
$graphics = [System.Drawing.Graphics]::FromImage($banner)
$graphics.Clear([System.Drawing.Color]::White)
$font = New-Object System.Drawing.Font("Arial", 16, [System.Drawing.FontStyle]::Bold)
$brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(237, 28, 36))
$graphics.DrawString("AMD ROCm Windows 11 Installer", $font, $brush, 10, 20)
$banner.Save("$PWD\Banner.bmp", [System.Drawing.Imaging.ImageFormat]::Bmp)
$graphics.Dispose()
$banner.Dispose()

# Dialog (493x312)
$dialog = New-Object System.Drawing.Bitmap(493, 312)
$graphics = [System.Drawing.Graphics]::FromImage($dialog)
$graphics.Clear([System.Drawing.Color]::FromArgb(240, 240, 240))
$font = New-Object System.Drawing.Font("Arial", 24, [System.Drawing.FontStyle]::Bold)
$brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(237, 28, 36))
$graphics.DrawString("ROCm", $font, $brush, 200, 130)
$dialog.Save("$PWD\Dialog.bmp", [System.Drawing.Imaging.ImageFormat]::Bmp)
$graphics.Dispose()
$dialog.Dispose()
```

### Recommended Tools

- **Icon Creation**: 
  - https://www.iconarchive.com/
  - GIMP (https://www.gimp.org/)
  - Paint.NET (https://www.getpaint.net/)
  
- **Banner/Dialog Creation**:
  - GIMP or Photoshop
  - Microsoft Paint
  - Online image editors

### Brand Guidelines

- Use AMD red color: RGB(237, 28, 36) or #ED1C24
- Include ROCm logo if available
- Keep designs professional and clean
- Ensure text is readable at installer size

## Notes

- All images must be exact dimensions
- BMP files should be uncompressed or RLE compressed
- ICO file should contain multiple sizes for best appearance
- Test images in installer before final build
