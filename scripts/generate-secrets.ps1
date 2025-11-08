# ===================================
# Generate Secure JWT Secrets (PowerShell)
# ===================================
# This script generates cryptographically secure random secrets for:
# - JWT_SECRET (access tokens)
# - JWT_REFRESH_SECRET (refresh tokens)
#
# Usage:
#   .\scripts\generate-secrets.ps1
#   .\scripts\generate-secrets.ps1 -Format env
#   .\scripts\generate-secrets.ps1 -Format docker
#   .\scripts\generate-secrets.ps1 -Format dockploy

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("default", "env", "docker", "dockploy", "all")]
    [string]$Format = "default"
)

# Function to generate a cryptographically secure random secret
function Generate-Secret {
    param(
        [int]$Bytes = 32
    )

    $randomBytes = New-Object byte[] $Bytes
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $rng.GetBytes($randomBytes)
    $rng.Dispose()

    return [Convert]::ToBase64String($randomBytes)
}

# Function to display secrets in default format
function Show-DefaultFormat {
    param(
        [string]$JwtSecret,
        [string]$JwtRefreshSecret
    )

    Write-Host ""
    Write-Host "✓ Secure JWT Secrets Generated!" -ForegroundColor Green
    Write-Host "──────────────────────────────────────────────────────────────────────" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Copy these secrets to your .env file:" -ForegroundColor White
    Write-Host ""
    Write-Host "JWT_SECRET" -NoNewline -ForegroundColor Yellow
    Write-Host "=" -NoNewline
    Write-Host $JwtSecret -ForegroundColor Green
    Write-Host "JWT_REFRESH_SECRET" -NoNewline -ForegroundColor Yellow
    Write-Host "=" -NoNewline
    Write-Host $JwtRefreshSecret -ForegroundColor Green
    Write-Host ""
    Write-Host "──────────────────────────────────────────────────────────────────────" -ForegroundColor Cyan
}

# Function to display secrets in .env format
function Show-EnvFormat {
    param(
        [string]$JwtSecret,
        [string]$JwtRefreshSecret
    )

    Write-Host ""
    Write-Host "✓ Secrets in .env format:" -ForegroundColor Green
    Write-Host ""
    Write-Host "JWT_SECRET=$JwtSecret"
    Write-Host "JWT_REFRESH_SECRET=$JwtRefreshSecret"
}

# Function to display secrets for Docker Compose
function Show-DockerFormat {
    param(
        [string]$JwtSecret,
        [string]$JwtRefreshSecret
    )

    Write-Host ""
    Write-Host "✓ Secrets for Docker Compose:" -ForegroundColor Green
    Write-Host ""
    Write-Host "# Add these to your docker-compose.yml under environment:"
    Write-Host "      JWT_SECRET: `"$JwtSecret`""
    Write-Host "      JWT_REFRESH_SECRET: `"$JwtRefreshSecret`""
}

# Function to display secrets for Dockploy
function Show-DockployFormat {
    param(
        [string]$JwtSecret,
        [string]$JwtRefreshSecret
    )

    Write-Host ""
    Write-Host "✓ Secrets for Dockploy:" -ForegroundColor Green
    Write-Host ""
    Write-Host "Copy-paste these in Dockploy Environment Variables:"
    Write-Host ""
    Write-Host "Variable Name: JWT_SECRET"
    Write-Host "Value: $JwtSecret"
    Write-Host ""
    Write-Host "Variable Name: JWT_REFRESH_SECRET"
    Write-Host "Value: $JwtRefreshSecret"
}

# Function to display security recommendations
function Show-SecurityTips {
    Write-Host ""
    Write-Host "Security Recommendations:" -ForegroundColor Blue
    Write-Host ""
    Write-Host "  1. " -NoNewline
    Write-Host "✓" -NoNewline -ForegroundColor Green
    Write-Host " Never commit .env file to Git"
    Write-Host "  2. " -NoNewline
    Write-Host "✓" -NoNewline -ForegroundColor Green
    Write-Host " Use different secrets for staging and production"
    Write-Host "  3. " -NoNewline
    Write-Host "✓" -NoNewline -ForegroundColor Green
    Write-Host " Rotate secrets periodically (every 90 days)"
    Write-Host "  4. " -NoNewline
    Write-Host "✓" -NoNewline -ForegroundColor Green
    Write-Host " Store production secrets in a password manager"
    Write-Host "  5. " -NoNewline
    Write-Host "✓" -NoNewline -ForegroundColor Green
    Write-Host " Never share secrets via email or chat"
    Write-Host ""
    Write-Host "──────────────────────────────────────────────────────────────────────" -ForegroundColor Cyan
    Write-Host ""
}

# Main execution
try {
    # Generate secrets
    $jwtSecret = Generate-Secret -Bytes 32
    $jwtRefreshSecret = Generate-Secret -Bytes 32

    # Display based on format parameter
    switch ($Format.ToLower()) {
        "env" {
            Show-EnvFormat -JwtSecret $jwtSecret -JwtRefreshSecret $jwtRefreshSecret
        }
        "docker" {
            Show-DockerFormat -JwtSecret $jwtSecret -JwtRefreshSecret $jwtRefreshSecret
        }
        "dockploy" {
            Show-DockployFormat -JwtSecret $jwtSecret -JwtRefreshSecret $jwtRefreshSecret
        }
        "all" {
            Show-DefaultFormat -JwtSecret $jwtSecret -JwtRefreshSecret $jwtRefreshSecret
            Show-EnvFormat -JwtSecret $jwtSecret -JwtRefreshSecret $jwtRefreshSecret
            Show-DockerFormat -JwtSecret $jwtSecret -JwtRefreshSecret $jwtRefreshSecret
            Show-DockployFormat -JwtSecret $jwtSecret -JwtRefreshSecret $jwtRefreshSecret
        }
        default {
            Show-DefaultFormat -JwtSecret $jwtSecret -JwtRefreshSecret $jwtRefreshSecret
        }
    }

    # Always show security tips
    Show-SecurityTips

} catch {
    Write-Host ""
    Write-Host "Error generating secrets:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    exit 1
}
