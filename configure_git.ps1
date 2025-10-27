# Configure Git Identity
# Run this once to set up your Git user information

Write-Host "`nConfiguring Git Identity..." -ForegroundColor Cyan
Write-Host "This is required for making commits.`n" -ForegroundColor Gray

# Set your name (shows up in commit history)
git config --global user.name "OCNGill"
Write-Host "? Name set to: OCNGill" -ForegroundColor Green

# Set your email (use your GitHub email)
# Replace with your actual GitHub email
git config --global user.email "stephenpatrickgill@gmail.com"
Write-Host "? Email set" -ForegroundColor Green

Write-Host "`nVerifying configuration:" -ForegroundColor Yellow
git config --global user.name
git config --global user.email

Write-Host "`n? Git is now configured! You can make commits." -ForegroundColor Green
Write-Host "`nNow you can commit through Visual Studio GUI or run:" -ForegroundColor Cyan
Write-Host "  .\testing\commit_testing_files.ps1" -ForegroundColor Gray
