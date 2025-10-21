#!/bin/bash

###############################################################################
# TappPlus - Database Seeding Script
###############################################################################
#
# This script seeds the database with initial demo data.
#
# Usage:
#   chmod +x seed.sh
#   ./seed.sh
#
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
CONTAINER_NAME="tappplus-app"
SEED_SCRIPT="scripts/seed-db.js"

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

check_container() {
  print_header "Vérification du Conteneur"

  if ! docker ps | grep -q $CONTAINER_NAME; then
    print_error "Le conteneur $CONTAINER_NAME n'est pas en cours d'exécution"
    echo ""
    echo "Démarrez le conteneur avec :"
    echo -e "  ${CYAN}docker compose up -d${NC}"
    echo ""
    exit 1
  fi

  print_success "Conteneur $CONTAINER_NAME en cours d'exécution"
}

check_database() {
  print_header "Vérification de la Base de Données"

  print_info "Vérification de l'existence de la base de données..."

  if docker exec $CONTAINER_NAME test -f /app/data/meditache.db; then
    print_success "Base de données trouvée"
  else
    print_warning "Base de données non trouvée"
    print_info "Initialisation de la base de données..."

    # Create database schema
    docker exec $CONTAINER_NAME npx prisma db push --schema=/app/apps/api/prisma/schema.prisma > /dev/null 2>&1

    print_success "Base de données initialisée"
  fi
}

seed_database() {
  print_header "Chargement des Données de Test"

  print_info "Exécution du script de seeding..."
  echo ""

  # Run the seed script and capture output
  docker exec $CONTAINER_NAME node $SEED_SCRIPT

  echo ""
}

restart_services() {
  print_header "Redémarrage des Services"

  print_info "Redémarrage du worker..."
  docker exec $CONTAINER_NAME pm2 restart worker > /dev/null 2>&1
  print_success "Worker redémarré"

  print_info "Attente de la stabilisation (3s)..."
  sleep 3

  print_info "Vérification de l'état des processus..."
  echo ""
  docker exec $CONTAINER_NAME pm2 status
}

show_credentials() {
  print_header "Informations de Connexion"

  echo -e "${CYAN}Accès à l'Application${NC}"
  echo -e "  ${BLUE}URL:${NC} http://localhost"
  echo ""

  echo -e "${CYAN}Credentials${NC}"
  echo ""

  echo -e "${YELLOW}👨‍💼 Compte Admin${NC}"
  echo -e "  Email:    ${GREEN}admin@tappplus.com${NC}"
  echo -e "  Password: ${GREEN}Admin123!${NC}"
  echo ""

  echo -e "${YELLOW}👨‍⚕️  Compte Docteur${NC}"
  echo -e "  Email:    ${GREEN}docteur@tappplus.com${NC}"
  echo -e "  Password: ${GREEN}Doctor123!${NC}"
  echo ""

  echo -e "${YELLOW}🏥 Organisation${NC}"
  echo -e "  Nom: ${GREEN}Clinique Médicale Demo${NC}"
  echo ""

  echo -e "${YELLOW}👤 Patient de Test${NC}"
  echo -e "  Nom: ${GREEN}Jean Dupont${NC}"
  echo ""
}

show_next_steps() {
  print_header "Prochaines Étapes"

  echo "Vous pouvez maintenant :"
  echo ""
  echo -e "  ${BLUE}1.${NC} Accéder à l'application : ${CYAN}http://localhost${NC}"
  echo -e "  ${BLUE}2.${NC} Vous connecter avec un compte admin ou docteur"
  echo -e "  ${BLUE}3.${NC} Voir les logs : ${CYAN}docker exec $CONTAINER_NAME pm2 logs${NC}"
  echo -e "  ${BLUE}4.${NC} Arrêter l'application : ${CYAN}docker compose down${NC}"
  echo ""
}

confirm_seeding() {
  print_header "Confirmation"

  echo -e "${YELLOW}⚠ ATTENTION${NC}"
  echo ""
  echo "Cette opération va :"
  echo "  • Ajouter des données de démonstration à la base de données"
  echo "  • Créer des comptes utilisateurs de test"
  echo ""
  echo -e "${CYAN}Les données existantes ne seront PAS supprimées.${NC}"
  echo ""

  read -p "Voulez-vous continuer ? (yes/no): " -r
  echo ""

  if [[ ! $REPLY =~ ^[Yy]es$ ]]; then
    print_info "Opération annulée"
    exit 0
  fi
}

# Main execution
main() {
  clear

  print_header "TappPlus - Seeding de la Base de Données"

  confirm_seeding
  check_container
  check_database
  seed_database
  restart_services
  show_credentials
  show_next_steps

  print_header "✅ Seeding Terminé avec Succès !"
}

# Run main function
main
