#!/usr/bin/env node

/**
 * Database Initialization Script
 *
 * This script initializes the SQLite database for TappPlus:
 * 1. Checks if database file exists
 * 2. Runs Prisma migrations
 * 3. Optionally seeds the database with initial data
 *
 * Usage:
 *   node scripts/init-db.js
 *   node scripts/init-db.js --seed
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

// Configuration
const DB_PATH = process.env.DATABASE_URL?.replace('file:', '') || '/app/data/meditache.db';
const PRISMA_SCHEMA = '/app/apps/api/prisma/schema.prisma';
const SEED_DATA = process.argv.includes('--seed');

// Colors for console output
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  red: '\x1b[31m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function execCommand(command, description) {
  log(`\n→ ${description}...`, 'blue');
  try {
    const output = execSync(command, {
      encoding: 'utf8',
      stdio: 'inherit',
      cwd: '/app/apps/api'
    });
    log(`✓ ${description} - Terminé`, 'green');
    return true;
  } catch (error) {
    log(`✗ ${description} - Échec`, 'red');
    console.error(error.message);
    return false;
  }
}

async function main() {
  log('\n========================================', 'blue');
  log('  TappPlus - Initialisation BD SQLite', 'blue');
  log('========================================\n', 'blue');

  // Check if database directory exists
  const dbDir = path.dirname(DB_PATH);
  if (!fs.existsSync(dbDir)) {
    log(`Création du répertoire de données: ${dbDir}`, 'yellow');
    fs.mkdirSync(dbDir, { recursive: true });
  }

  // Check if database already exists
  const dbExists = fs.existsSync(DB_PATH);
  if (dbExists) {
    log(`⚠ Base de données existante détectée: ${DB_PATH}`, 'yellow');
    log('Les migrations vont être appliquées...', 'yellow');
  } else {
    log(`Nouvelle base de données: ${DB_PATH}`, 'green');
  }

  // Step 1: Generate Prisma Client
  if (!execCommand(
    'npx prisma generate',
    'Génération du client Prisma'
  )) {
    process.exit(1);
  }

  // Step 2: Run Migrations
  if (!execCommand(
    'npx prisma migrate deploy',
    'Application des migrations'
  )) {
    // If migrate deploy fails, try to create initial migration
    log('\nTentative de création de la migration initiale...', 'yellow');
    if (!execCommand(
      'npx prisma migrate dev --name init --skip-seed',
      'Création de la migration initiale'
    )) {
      process.exit(1);
    }
  }

  // Step 3: Seed Database (if requested)
  if (SEED_DATA) {
    log('\nChargement des données de test...', 'yellow');
    if (!execCommand(
      'npx prisma db seed',
      'Chargement des données'
    )) {
      log('⚠ Seed échoué, mais la base de données est prête', 'yellow');
    }
  }

  // Step 4: Verify database
  log('\nVérification de la base de données...', 'blue');
  try {
    execSync(`sqlite3 ${DB_PATH} ".tables"`, { encoding: 'utf8', stdio: 'inherit' });
    log('✓ Base de données vérifiée', 'green');
  } catch (error) {
    log('⚠ Impossible de vérifier la base de données', 'yellow');
  }

  // Success
  log('\n========================================', 'green');
  log('  ✓ Initialisation terminée avec succès!', 'green');
  log('========================================\n', 'green');

  log('Informations:', 'blue');
  log(`  - Base de données: ${DB_PATH}`);
  log(`  - Schéma Prisma: ${PRISMA_SCHEMA}`);
  log(`  - Données de test: ${SEED_DATA ? 'Oui' : 'Non'}\n`);

  log('Prochaines étapes:', 'yellow');
  log('  1. Vérifier que tous les processus PM2 sont actifs: pm2 status');
  log('  2. Créer un utilisateur admin (voir DEPLOYMENT.md)');
  log('  3. Accéder à l\'application: http://localhost:5500\n');
}

// Run the script
main().catch((error) => {
  log('\n✗ Erreur fatale lors de l\'initialisation', 'red');
  console.error(error);
  process.exit(1);
});
