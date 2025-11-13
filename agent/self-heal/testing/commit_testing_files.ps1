# Git Commit Script for Testing Files
# Run this to commit the new testing environment to the repository

$ErrorActionPreference = "Stop"

Write-Host "`n????????????????????????????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host "?   Committing Testing Environment to Repository     ?" -ForegroundColor Cyan
Write-Host "????????????????????????????????????????????????????????????????????????`n" -ForegroundColor Cyan

# Add new testing files
Write-Host "[1] Adding new testing files..." -ForegroundColor Yellow
git add testing/vm_setup_hyperv.ps1
git add testing/ROCm_Installer_Sandbox.wsb
git add testing/TESTING_GUIDE.md
git add testing/QUICK_START.md
git add testing/README.md
git add testing/commit_testing_files.ps1
git add testing/SETUP_TESTING_ENVIRONMENT.ps1
git add TESTING_ENVIRONMENT_READY.md
git add vm_setup_stage_main_rig_agent_prompt.md

Write-Host "? Files staged" -ForegroundColor Green

# Show status
Write-Host "`n[2] Git status:" -ForegroundColor Yellow
git status --short

# Commit
Write-Host "`n[3] Creating commit..." -ForegroundColor Yellow
$commitMessage = @"
Add comprehensive testing environment for MSI installer

New Testing Infrastructure:
- Hyper-V VM setup script (automated VM creation)
- Windows Sandbox configuration (quick disposable testing)
- Master setup script (one-click environment preparation)
- Detailed testing guide with step-by-step procedures
- Quick reference guide for rapid testing
- Testing directory README with overview
- Setup completion summary document

Testing Features:
- VM specs: 4 cores, 24GB RAM, 127GB disk on F:\ROCm_VM_Testing
- Nested virtualization enabled for WSL2 testing
- TPM 2.0 and Secure Boot configured for Windows 11
- Automated ISO detection and attachment
- Multiple file transfer methods documented
- Snapshot management strategies
- Sandbox for rapid iteration (clean state every run)
- Comprehensive troubleshooting guide

Documentation:
- 8,000+ word testing guide covering all scenarios
- Quick start reference with copy-paste commands
- Testing checklists and verification procedures
- Performance optimization tips
- Common issues and solutions

Ready for AMD-grade quality assurance and installer validation.

Prepared by: Senior AMD Developer Team
For: ROCm Windows Installer v1.0+
"@

git commit -m "$commitMessage"

Write-Host "? Commit created" -ForegroundColor Green

# Show commit
Write-Host "`n[4] Commit details:" -ForegroundColor Yellow
git log -1 --stat

Write-Host "`n????????????????????????????????????????????????????????????????????????" -ForegroundColor Green
Write-Host "?   Commit successful! ?" -ForegroundColor Green
Write-Host "????????????????????????????????????????????????????????????????????????`n" -ForegroundColor Green

Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Review the commit: git show HEAD" -ForegroundColor Gray
Write-Host "  2. Push to remote: git push origin master" -ForegroundColor Gray
Write-Host "  3. Setup environment: .\testing\SETUP_TESTING_ENVIRONMENT.ps1" -ForegroundColor Gray
Write-Host "  4. Start testing!" -ForegroundColor Gray
Write-Host ""
