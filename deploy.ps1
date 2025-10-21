# TappPlus - Quick Deployment Script (PowerShell)
# Usage: .\deploy.ps1
# Options: .\deploy.ps1 -Rebuild -ResetDb -Seed

param(
    [switch]$Rebuild,
    [switch]$ResetDb,
    [switch]$Seed,
    [switch]$Help
)

$CONTAINER_NAME = "tappplus-app"
$DB_INIT_SCRIPT = "scripts/init-db.js"

function Print-Header {
    param([string]$Title)
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
}

function Print-Success {
    param([string]$Message)
    Write-Host "OK $Message" -ForegroundColor Green
}

function Print-Warning {
    param([string]$Message)
    Write-Host "WARN $Message" -ForegroundColor Yellow
}

function Print-Error {
    param([string]$Message)
    Write-Host "ERROR $Message" -ForegroundColor Red
}

function Print-Info {
    param([string]$Message)
    Write-Host "-> $Message" -ForegroundColor Cyan
}

function Show-Help {
    Write-Host "TappPlus Deployment Script"
    Write-Host ""
    Write-Host "Usage: .\deploy.ps1 [options]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Rebuild    Force rebuild of Docker image"
    Write-Host "  -ResetDb    Reset database (WARNING: deletes all data!)"
    Write-Host "  -Seed       Initialize database with test data"
    Write-Host "  -Help       Show this help message"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\deploy.ps1                    # Standard deployment"
    Write-Host "  .\deploy.ps1 -Seed              # Deploy with test data"
    Write-Host "  .\deploy.ps1 -Rebuild -Seed     # Rebuild and seed"
    exit 0
}

function Check-Prerequisites {
    Print-Header "Checking Prerequisites"

    try {
        $dockerVersion = docker --version
        Print-Success "Docker installed: $dockerVersion"
    }
    catch {
        Print-Error "Docker is not installed"
        Write-Host "Install Docker: https://docs.docker.com/get-docker/"
        exit 1
    }

    try {
        $composeVersion = docker compose version
        Print-Success "Docker Compose installed: $composeVersion"
    }
    catch {
        Print-Error "Docker Compose is not installed"
        exit 1
    }

    if (-not (Test-Path ".env")) {
        Print-Warning ".env file not found"
        Print-Info "Creating .env from .env.example..."
        Copy-Item ".env.example" ".env"
        Print-Warning "IMPORTANT: Edit .env and change JWT secrets!"
        Read-Host "Press Enter to continue after editing .env"
    }
    Print-Success ".env file found"
}

function Stop-ExistingContainer {
    Print-Header "Stopping Existing Containers"

    Print-Info "Running docker compose down..."
    try {
        docker compose down 2>&1 | Out-Null
        Print-Success "Cleanup complete"
    }
    catch {
        Print-Info "No containers to stop"
    }
}

function Reset-Database {
    if ($ResetDb) {
        Print-Header "Resetting Database"
        Print-Warning "WARNING: This will delete all data!"

        $response = Read-Host "Are you sure you want to reset the database? (yes/no)"

        if ($response -eq "yes") {
            Print-Info "Removing volumes..."
            docker volume rm tappplus_data 2>$null
            Print-Success "Database reset"
        }
        else {
            Print-Info "Reset cancelled"
            $script:ResetDb = $false
        }
    }
}

function Build-Image {
    Print-Header "Building Docker Image"

    if ($Rebuild) {
        Print-Info "Forcing rebuild..."
        docker compose build --no-cache
    }
    else {
        Print-Info "Building image..."
        docker compose build
    }

    if ($LASTEXITCODE -eq 0) {
        Print-Success "Image built successfully"
    }
    else {
        Print-Error "Build failed"
        exit 1
    }
}

function Start-Container {
    Print-Header "Starting Container"

    Print-Info "Launching TappPlus..."
    docker compose up -d

    if ($LASTEXITCODE -eq 0) {
        Print-Info "Waiting for startup (30s)..."
        Start-Sleep -Seconds 30
        Print-Success "Container started"
    }
    else {
        Print-Error "Failed to start container"
        exit 1
    }
}

function Initialize-Database {
    Print-Header "Initializing Database"

    $dbExists = docker exec $CONTAINER_NAME test -f /app/data/meditache.db 2>$null

    if ($LASTEXITCODE -ne 0 -or $ResetDb) {
        Print-Info "Initializing database..."

        if ($Seed) {
            docker exec $CONTAINER_NAME node $DB_INIT_SCRIPT --seed
        }
        else {
            docker exec $CONTAINER_NAME node $DB_INIT_SCRIPT
        }

        if ($LASTEXITCODE -eq 0) {
            Print-Success "Database initialized"
        }
        else {
            Print-Warning "Initialization failed, using prisma db push"
            docker exec $CONTAINER_NAME npx prisma db push --schema=/app/apps/api/prisma/schema.prisma
        }
    }
    else {
        Print-Info "Database already initialized (use -ResetDb to reset)"
    }
}

function Check-Health {
    Print-Header "Checking Health"

    Print-Info "PM2 process status:"
    docker exec $CONTAINER_NAME pm2 status

    Write-Host ""
    Print-Info "Testing API..."
    try {
        $response = Invoke-WebRequest -Uri "http://localhost/health" -UseBasicParsing -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            Print-Success "API is accessible"
        }
    }
    catch {
        Print-Warning "API not accessible yet (may need more time)"
    }
}

function Show-Info {
    Print-Header "Deployment Complete!"

    Write-Host "TappPlus is now online!" -ForegroundColor Green
    Write-Host ""

    Write-Host "Access:"
    Write-Host "  Frontend: http://localhost" -ForegroundColor Cyan
    Write-Host "  API:      http://localhost/api/v1" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Useful commands:"
    Write-Host "  View logs:        docker compose logs -f" -ForegroundColor Cyan
    Write-Host "  Process status:   docker exec $CONTAINER_NAME pm2 status" -ForegroundColor Cyan
    Write-Host "  PM2 logs:         docker exec $CONTAINER_NAME pm2 logs" -ForegroundColor Cyan
    Write-Host "  Stop:             docker compose down" -ForegroundColor Cyan
    Write-Host "  Restart:          docker compose restart" -ForegroundColor Cyan
    Write-Host ""

    if (-not $Seed) {
        Write-Host "Note: No test data loaded." -ForegroundColor Yellow
        Write-Host "To load test data, run:"
        Write-Host "  .\seed.ps1" -ForegroundColor Cyan
        Write-Host ""
    }

    Write-Host "For more information, see DEPLOYMENT.md"
}

function Main {
    Clear-Host

    if ($Help) {
        Show-Help
    }

    Print-Header "TappPlus - Automatic Deployment"

    Check-Prerequisites
    Stop-ExistingContainer
    Reset-Database
    Build-Image
    Start-Container
    Initialize-Database
    Check-Health
    Show-Info
}

try {
    Main
}
catch {
    $msg = $_.Exception.Message
    Print-Error "Fatal error: $msg"
    exit 1
}
