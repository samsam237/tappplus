# TappPlus - Database Seeding Script (PowerShell)
# Usage: .\seed.ps1

# Configuration
$CONTAINER_NAME = "tappplus-app"
$SEED_SCRIPT = "scripts/seed-db.js"

# Colors
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )

    $colorMap = @{
        "Red" = "Red"
        "Green" = "Green"
        "Yellow" = "Yellow"
        "Blue" = "Cyan"
        "Cyan" = "Cyan"
        "White" = "White"
    }

    Write-Host $Message -ForegroundColor $colorMap[$Color]
}

function Print-Header {
    param([string]$Title)

    Write-Host ""
    Write-ColorOutput "========================================" "Blue"
    Write-ColorOutput "  $Title" "Blue"
    Write-ColorOutput "========================================" "Blue"
    Write-Host ""
}

function Print-Success {
    param([string]$Message)
    Write-ColorOutput "✓ $Message" "Green"
}

function Print-Warning {
    param([string]$Message)
    Write-ColorOutput "⚠ $Message" "Yellow"
}

function Print-Error {
    param([string]$Message)
    Write-ColorOutput "✗ $Message" "Red"
}

function Print-Info {
    param([string]$Message)
    Write-ColorOutput "→ $Message" "Blue"
}

function Check-Container {
    Print-Header "Vérification du Conteneur"

    $running = docker ps --format "{{.Names}}" | Select-String -Pattern $CONTAINER_NAME

    if (-not $running) {
        Print-Error "Le conteneur $CONTAINER_NAME n'est pas en cours d'exécution"
        Write-Host ""
        Write-Host "Démarrez le conteneur avec :"
        Write-ColorOutput "  docker compose up -d" "Cyan"
        Write-Host ""
        exit 1
    }

    Print-Success "Conteneur $CONTAINER_NAME en cours d'exécution"
}

function Check-Database {
    Print-Header "Vérification de la Base de Données"

    Print-Info "Vérification de l'existence de la base de données..."

    $dbExists = docker exec $CONTAINER_NAME test -f /app/data/meditache.db 2>$null

    if ($LASTEXITCODE -eq 0) {
        Print-Success "Base de données trouvée"
    }
    else {
        Print-Warning "Base de données non trouvée"
        Print-Info "Initialisation de la base de données..."

        # Create database schema
        docker exec $CONTAINER_NAME npx prisma db push --schema=/app/apps/api/prisma/schema.prisma | Out-Null

        Print-Success "Base de données initialisée"
    }
}

function Seed-Database {
    Print-Header "Chargement des Données de Test"

    Print-Info "Exécution du script de seeding..."
    Write-Host ""

    # Run the seed script
    docker exec $CONTAINER_NAME node $SEED_SCRIPT

    Write-Host ""
}

function Restart-Services {
    Print-Header "Redémarrage des Services"

    Print-Info "Redémarrage du worker..."
    docker exec $CONTAINER_NAME pm2 restart worker | Out-Null
    Print-Success "Worker redémarré"

    Print-Info "Attente de la stabilisation (3s)..."
    Start-Sleep -Seconds 3

    Print-Info "Vérification de l'état des processus..."
    Write-Host ""
    docker exec $CONTAINER_NAME pm2 status
}

function Show-Credentials {
    Print-Header "Informations de Connexion"

    Write-ColorOutput "Accès à l'Application" "Cyan"
    Write-ColorOutput "  URL: http://localhost" "Blue"
    Write-Host ""

    Write-ColorOutput "Credentials" "Cyan"
    Write-Host ""

    Write-ColorOutput "👨‍💼 Compte Admin" "Yellow"
    Write-ColorOutput "  Email:    admin@tappplus.com" "Green"
    Write-ColorOutput "  Password: Admin123!" "Green"
    Write-Host ""

    Write-ColorOutput "👨‍⚕️  Compte Docteur" "Yellow"
    Write-ColorOutput "  Email:    docteur@tappplus.com" "Green"
    Write-ColorOutput "  Password: Doctor123!" "Green"
    Write-Host ""

    Write-ColorOutput "🏥 Organisation" "Yellow"
    Write-ColorOutput "  Nom: Clinique Médicale Demo" "Green"
    Write-Host ""

    Write-ColorOutput "👤 Patient de Test" "Yellow"
    Write-ColorOutput "  Nom: Samuel Nguema" "Green"
    Write-Host ""
}

function Show-NextSteps {
    Print-Header "Prochaines Étapes"

    Write-Host "Vous pouvez maintenant :"
    Write-Host ""
    Write-ColorOutput "  1. Accéder à l'application : http://localhost" "Blue"
    Write-Host "  2. Vous connecter avec un compte admin ou docteur"
    Write-ColorOutput "  3. Voir les logs : docker exec $CONTAINER_NAME pm2 logs" "Blue"
    Write-ColorOutput "  4. Arrêter l'application : docker compose down" "Blue"
    Write-Host ""
}

function Confirm-Seeding {
    Print-Header "Confirmation"

    Write-ColorOutput "⚠ ATTENTION" "Yellow"
    Write-Host ""
    Write-Host "Cette opération va :"
    Write-Host "  • Ajouter des données de démonstration à la base de données"
    Write-Host "  • Créer des comptes utilisateurs de test"
    Write-Host ""
    Write-ColorOutput "Les données existantes ne seront PAS supprimées." "Cyan"
    Write-Host ""

    $response = Read-Host "Voulez-vous continuer ? (yes/no)"
    Write-Host ""

    if ($response -ne "yes") {
        Print-Info "Opération annulée"
        exit 0
    }
}

# Main execution
function Main {
    Clear-Host

    Print-Header "TappPlus - Seeding de la Base de Données"

    Confirm-Seeding
    Check-Container
    Check-Database
    Seed-Database
    Restart-Services
    Show-Credentials
    Show-NextSteps

    Print-Header "✅ Seeding Terminé avec Succès !"
}

# Run
try {
    Main
}
catch {
    Print-Error "Erreur fatale: $_"
    Write-Host $_.Exception.Message
    exit 1
}
