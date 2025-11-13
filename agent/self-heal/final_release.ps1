# Final Commit and Release Script
# Run this to complete the v1.3 release

Write-Host "=== Final ROCm Installer v1.3 Release ===" -ForegroundColor Cyan

# Stage all changes
Write-Host "Staging all changes..." -ForegroundColor Yellow
git add -A

# Commit with message
Write-Host "Committing changes..." -ForegroundColor Yellow
git commit -m "Fixed readme, ran initial script to provide installer signed."

# Push to master
Write-Host "Pushing to master..." -ForegroundColor Yellow
git push origin master

# Create and push tag
Write-Host "Creating v1.3 tag..." -ForegroundColor Yellow
git tag -a v1.3 -m "Version 1.3 - Consolidated branches, major restructuring and renaming"
git push origin v1.3

Write-Host "`n=== RELEASE COMPLETE ===" -ForegroundColor Green
Write-Host "GitHub Actions will now automatically build and release the MSI!" -ForegroundColor Green
Write-Host "Check: https://github.com/OCNGill/Radeon_Open_Compute_ROCm_Installer_Windows_x64/actions" -ForegroundColor Cyan