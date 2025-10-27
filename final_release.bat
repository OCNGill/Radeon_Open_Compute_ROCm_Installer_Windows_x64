@echo off
echo === Final ROCm Installer v1.3 Release ===
echo.

echo Changing to repository directory...
cd /d "C:\Users\Gillsystems Laptop\source\repos\OCNGill\rOCM_Installer_Win11"
if errorlevel 1 (
    echo ERROR: Could not change to repository directory
    echo Please run this from: C:\Users\Gillsystems Laptop\source\repos\OCNGill\rOCM_Installer_Win11
    pause
    exit /b 1
)

echo Staging all changes...
git add -A

echo.
echo Committing changes...
git commit -m "Fixed readme, ran initial script to provide installer signed."

echo.
echo Pushing to master...
git push origin master

echo.
echo Creating v1.3 tag...
git tag -a v1.3 -m "Version 1.3 - Consolidated branches, major restructuring and renaming"

echo.
echo Pushing tag...
git push origin v1.3

echo.
echo === RELEASE COMPLETE ===
echo GitHub Actions will now automatically build and release the MSI!
echo Check: https://github.com/OCNGill/Radeon_Open_Compute_ROCm_Installer_Windows_x64/actions
echo.
pause