# ROCm Windows Installer v1.6.0.0 - Bug Fix Release

This release fixes a critical installation error that prevented the MSI from completing successfully.

## What's New in v1.6.0.0

- **FIXED**: Error 2732 installation bug by including missing CustomActions scripts in the MSI package. The custom actions were failing because the required PowerShell scripts were not bundled in the installer.

---

# ROCm Windows Installer v1.5.0.0 - Bug Fix Release

This release fixes a critical installation error that prevented the MSI from completing successfully.

## What's New in v1.5.0.0

- **FIXED**: Error 2732 installation bug by including missing CustomActions scripts in the MSI package. The custom actions were failing because the required PowerShell scripts were not bundled in the installer.

---

# ROCm Windows Installer v1.3.2.1 - Stability Release

This release addresses numerous issues with the automated build pipeline, ensuring a stable and reproducible MSI installer. While the core functionality remains the same as v1.3, this version represents a significant effort in debugging and refining the CI/CD process.

## The Journey to Stability

The path to a fully automated build was fraught with challenges. We encountered and resolved a series of issues that, while frustrating, have ultimately made the project more robust. I take responsibility for my part in these early struggles; my initial assumptions about the build environment and WiX/YAML syntax were incorrect, leading to a cascade of failures.

Here's a summary of the trials we faced and the fixes implemented:

1.  **YAML Syntax Errors**: The most fundamental issue was an invalid GitHub Actions workflow file. The `jobs:` key was missing, which prevented any part of the workflow from running. This was a basic oversight on my part.

2.  **WiX Toolset Version Conflicts**: The build runner had a newer version of the WiX Toolset than the one we were trying to install. The fix was to make the installation step smarter, using the pre-installed version if available and only installing it if missing.

3.  **Invalid GUIDs**: A significant number of our WiX component files (`.wxs`) contained placeholder or non-hexadecimal GUIDs. This caused the WiX compiler (`candle.exe`) to fail repeatedly. I systematically generated and replaced all invalid GUIDs across `Driver.wxs`, `ROCm.wxs`, `WSL2.wxs`, `Python.wxs`, and `LLM_GUI.wxs`.

4.  **Incorrect CustomAction Declarations**: The method for calling PowerShell scripts from the MSI was incorrect. We cycled through several invalid patterns before landing on the correct one: using `CAQuietExec` with a `Property` to define the command line. This was a complex WiX-specific issue that required a deeper understanding of the toolset.

5.  **Missing Build Artifacts**: At one point, the linker (`light.exe`) was failing because the compiler hadn't produced the necessary `.wixobj` files. I had to make the build script more robust to ensure all source files were found, compiled individually, and that the linker was only called if the compiled objects existed.

## Lessons Learned

This experience has been a masterclass in debugging CI/CD pipelines. It has reinforced the importance of:
-   **Incremental Changes**: Making small, testable changes instead of large, sweeping ones.
-   **Thorough Validation**: Verifying syntax and dependencies at every step.
-   **Clear Error Logging**: Enhancing scripts to provide obvious, actionable error messages.

I am confident that with these fixes, the build process is now stable and ready for future development.

---

## What's New in v1.3.2.1

-   **FIXED**: Critical YAML syntax error preventing workflow execution.
-   **FIXED**: WiX Toolset installation conflicts on the build runner.
-   **FIXED**: All invalid GUIDs across all WiX component files.
-   **FIXED**: Corrected `CustomAction` implementation for running PowerShell scripts.
-   **IMPROVED**: The `build_installer.ps1` script is now more robust and provides clearer error messages.
-   **CLEANED**: Removed numerous unnecessary debug steps from the workflow file.

## How to Use

Download the `ROCm_windows_x64_1.3.2.1.msi` file from the assets below and run it as an administrator.

Thank you for your patience through this process. We now have a solid foundation to build upon.