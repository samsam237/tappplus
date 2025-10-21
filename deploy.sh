#!/bin/bash

###############################################################################
# TappPlus - Quick Deployment Script
###############################################################################
#
# This script automates the deployment of TappPlus on any server with Docker.
#
# Usage:
#   chmod +x deploy.sh
#   ./deploy.sh
#
# Or with options:
#   ./deploy.sh --rebuild    # Force rebuild of Docker image
#   ./deploy.sh --reset-db   # Reset database (WARNING: deletes all data!)
#   ./deploy.sh --seed       # Initialize database with test data
#
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CONTAINER_NAME="tappplus-app"
DB_INIT_SCRIPT="scripts/init-db.js"

# Parse arguments
REBUILD=false
RESET_DB=false
SEED_DB=false

for arg in "$@"; do
  case $arg in
    --rebuild)
      REBUILD=true
      shift
      ;;
    --reset-db)
      RESET_DB=true
      shift
      ;;
    --seed)
      SEED_DB=true
      shift
      ;;
    --help)
      echo "TappPlus Deployment Script"
      echo ""
      echo "Usage: ./deploy.sh [options]"
      echo ""
      echo "Options:"
      echo "  --rebuild    Force rebuild of Docker image"
      echo "  --reset-db   Reset database (WARNING: deletes all data!)"
      echo "  --seed       Initialize database with test data"
      echo "  --help       Show this help message"
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $arg${NC}"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Functions
print_header() {
  echo -e "\n${BLUE}========================================${NC}"
  echo -e "${BLUE}  $1${NC}"
  echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
  echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
  echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
  echo -e "${RED}✗ $1${NC}"
}

print_info() {
  echo -e "${BLUE}→ $1${NC}"
}

check_prerequisites() {
  print_header "Vérification des prérequis"

  # Check Docker
  if ! command -v docker &> /dev/null; then
    print_error "Docker n'est pas installé"
    echo "Installez Docker: https://docs.docker.com/get-docker/"
    exit 1
  fi
  print_success "Docker installé: $(docker --version)"

  # Check Docker Compose
  if ! docker compose version &> /dev/null; then
    print_error "Docker Compose n'est pas installé"
    echo "Installez Docker Compose: https://docs.docker.com/compose/install/"
    exit 1
  fi
  print_success "Docker Compose installé: $(docker compose version)"

  # Check .env file
  if [ ! -f .env ]; then
    print_warning "Fichier .env non trouvé"
    print_info "Création d'un fichier .env depuis .env.example..."
    cp .env.example .env
    print_warning "IMPORTANT: Éditez le fichier .env et changez les secrets JWT !"
    read -p "Appuyez sur Entrée pour continuer après avoir édité .env..."
  fi
  print_success "Fichier .env trouvé"
}

stop_existing() {
  print_header "Arrêt des conteneurs existants"

  if docker ps -a | grep -q $CONTAINER_NAME; then
    print_info "Arrêt du conteneur $CONTAINER_NAME..."
    docker compose down
    print_success "Conteneur arrêté"
  else
    print_info "Aucun conteneur existant"
  fi
}

reset_database() {
  if [ "$RESET_DB" = true ]; then
    print_header "Réinitialisation de la base de données"
    print_warning "ATTENTION: Cette action supprime toutes les données !"

    read -p "Êtes-vous sûr de vouloir réinitialiser la base de données ? (yes/no): " -r
    if [[ $REPLY =~ ^[Yy]es$ ]]; then
      print_info "Suppression des volumes..."
      docker volume rm tappplus_data 2>/dev/null || true
      print_success "Base de données réinitialisée"
    else
      print_info "Réinitialisation annulée"
      RESET_DB=false
    fi
  fi
}

build_image() {
  print_header "Construction de l'image Docker"

  if [ "$REBUILD" = true ]; then
    print_info "Reconstruction forcée de l'image..."
    docker compose build --no-cache
  else
    print_info "Construction de l'image..."
    docker compose build
  fi

  print_success "Image construite avec succès"
}

start_container() {
  print_header "Démarrage du conteneur"

  print_info "Lancement de TappPlus..."
  docker compose up -d

  print_info "Attente du démarrage (30s)..."
  sleep 30

  print_success "Conteneur démarré"
}

initialize_database() {
  print_header "Initialisation de la base de données"

  # Check if database needs initialization
  DB_EXISTS=$(docker exec $CONTAINER_NAME test -f /app/data/meditache.db && echo "yes" || echo "no")

  if [ "$DB_EXISTS" = "no" ] || [ "$RESET_DB" = true ]; then
    print_info "Initialisation de la base de données..."

    if [ "$SEED_DB" = true ]; then
      docker exec $CONTAINER_NAME node $DB_INIT_SCRIPT --seed
    else
      docker exec $CONTAINER_NAME node $DB_INIT_SCRIPT
    fi

    print_success "Base de données initialisée"
  else
    print_info "Base de données déjà initialisée (utilisez --reset-db pour réinitialiser)"
  fi
}

check_health() {
  print_header "Vérification de l'état"

  # Check PM2 processes
  print_info "État des processus PM2:"
  docker exec $CONTAINER_NAME pm2 status

  # Check API health
  print_info "\nTest de l'API..."
  if docker exec $CONTAINER_NAME curl -f http://localhost:5550/api/v1/health > /dev/null 2>&1; then
    print_success "API accessible"
  else
    print_warning "API non accessible (peut prendre quelques secondes de plus)"
  fi
}

show_info() {
  print_header "Déploiement terminé !"

  echo -e "${GREEN}TappPlus est maintenant en ligne !${NC}\n"

  echo "Accès à l'application:"
  echo -e "  ${BLUE}Frontend:${NC} http://localhost:5500"
  echo -e "  ${BLUE}API:${NC}      http://localhost:5550/api/v1"
  echo ""

  echo "Commandes utiles:"
  echo -e "  ${BLUE}Voir les logs:${NC}        docker compose logs -f"
  echo -e "  ${BLUE}État des processus:${NC}   docker exec $CONTAINER_NAME pm2 status"
  echo -e "  ${BLUE}Logs PM2:${NC}             docker exec $CONTAINER_NAME pm2 logs"
  echo -e "  ${BLUE}Arrêter:${NC}              docker compose down"
  echo -e "  ${BLUE}Redémarrer:${NC}           docker compose restart"
  echo ""

  if [ "$SEED_DB" = false ]; then
    echo -e "${YELLOW}Note: Aucune donnée de test n'a été chargée.${NC}"
    echo "Pour charger des données de test, exécutez:"
    echo -e "  ${BLUE}docker exec $CONTAINER_NAME npx prisma db seed --schema=/app/apps/api/prisma/schema.prisma${NC}"
    echo ""
  fi

  echo "Pour plus d'informations, consultez DEPLOYMENT.md"
}

# Main execution
main() {
  clear

  print_header "TappPlus - Déploiement Automatique"

  check_prerequisites
  stop_existing
  reset_database
  build_image
  start_container
  initialize_database
  check_health
  show_info
}

# Run main function
main
