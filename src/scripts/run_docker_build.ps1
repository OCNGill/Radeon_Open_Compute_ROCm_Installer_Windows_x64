param (
    [Parameter(Mandatory=$true)]
    [string]$Path,
    
    [Parameter(Mandatory=$true)]
    [string]$Tag
)

Write-Host "Starting Docker build for $Tag from $Path..."

# Check if Docker is running
$dockerInfo = docker info 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "Docker is not running or not installed. Please start Docker Desktop."
    exit 1
}

# Run the build command
docker build -t $Tag $Path

if ($LASTEXITCODE -eq 0) {
    Write-Host "Docker build completed successfully!"
} else {
    Write-Error "Docker build failed."
    exit 1
}
