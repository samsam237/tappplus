#!/usr/bin/env node

/**
 * Generate Secure JWT Secrets
 *
 * This script generates cryptographically secure random secrets for:
 * - JWT_SECRET (access tokens)
 * - JWT_REFRESH_SECRET (refresh tokens)
 *
 * Usage:
 *   node scripts/generate-secrets.js
 *   node scripts/generate-secrets.js --env
 *   node scripts/generate-secrets.js --docker
 */

const crypto = require('crypto');

// ANSI color codes for terminal output
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  green: '\x1b[32m',
  blue: '\x1b[34m',
  yellow: '\x1b[33m',
  cyan: '\x1b[36m',
};

/**
 * Generate a cryptographically secure random secret
 * @param {number} bytes - Number of random bytes to generate
 * @returns {string} Base64-encoded secret
 */
function generateSecret(bytes = 32) {
  return crypto.randomBytes(bytes).toString('base64');
}

/**
 * Display secrets in a formatted way
 */
function displaySecrets(jwtSecret, jwtRefreshSecret) {
  console.log('\n' + colors.bright + colors.green + '✓ Secure JWT Secrets Generated!' + colors.reset);
  console.log(colors.cyan + '─'.repeat(70) + colors.reset);

  console.log('\n' + colors.bright + 'Copy these secrets to your .env file:' + colors.reset + '\n');

  console.log(colors.yellow + 'JWT_SECRET' + colors.reset + '=' + colors.green + jwtSecret + colors.reset);
  console.log(colors.yellow + 'JWT_REFRESH_SECRET' + colors.reset + '=' + colors.green + jwtRefreshSecret + colors.reset);

  console.log('\n' + colors.cyan + '─'.repeat(70) + colors.reset);
}

/**
 * Display secrets in .env format
 */
function displayEnvFormat(jwtSecret, jwtRefreshSecret) {
  console.log('\n' + colors.bright + colors.green + '✓ Secrets in .env format:' + colors.reset + '\n');
  console.log(`JWT_SECRET=${jwtSecret}`);
  console.log(`JWT_REFRESH_SECRET=${jwtRefreshSecret}`);
}

/**
 * Display secrets for Docker Compose environment
 */
function displayDockerFormat(jwtSecret, jwtRefreshSecret) {
  console.log('\n' + colors.bright + colors.green + '✓ Secrets for Docker Compose:' + colors.reset + '\n');
  console.log('# Add these to your docker-compose.yml under environment:');
  console.log(`      JWT_SECRET: "${jwtSecret}"`);
  console.log(`      JWT_REFRESH_SECRET: "${jwtRefreshSecret}"`);
}

/**
 * Display secrets for Dockploy
 */
function displayDockployFormat(jwtSecret, jwtRefreshSecret) {
  console.log('\n' + colors.bright + colors.green + '✓ Secrets for Dockploy:' + colors.reset + '\n');
  console.log('Copy-paste these in Dockploy Environment Variables:');
  console.log('\nVariable Name: JWT_SECRET');
  console.log('Value: ' + jwtSecret);
  console.log('\nVariable Name: JWT_REFRESH_SECRET');
  console.log('Value: ' + jwtRefreshSecret);
}

/**
 * Display security recommendations
 */
function displaySecurityTips() {
  console.log('\n' + colors.bright + colors.blue + 'Security Recommendations:' + colors.reset + '\n');
  console.log('  1. ' + colors.green + '✓' + colors.reset + ' Never commit .env file to Git');
  console.log('  2. ' + colors.green + '✓' + colors.reset + ' Use different secrets for staging and production');
  console.log('  3. ' + colors.green + '✓' + colors.reset + ' Rotate secrets periodically (every 90 days)');
  console.log('  4. ' + colors.green + '✓' + colors.reset + ' Store production secrets in a password manager');
  console.log('  5. ' + colors.green + '✓' + colors.reset + ' Never share secrets via email or chat');
  console.log('\n' + colors.cyan + '─'.repeat(70) + colors.reset + '\n');
}

/**
 * Display usage help
 */
function displayHelp() {
  console.log('\n' + colors.bright + 'Generate Secure JWT Secrets' + colors.reset);
  console.log(colors.cyan + '─'.repeat(70) + colors.reset);
  console.log('\n' + colors.bright + 'Usage:' + colors.reset);
  console.log('  node scripts/generate-secrets.js           ' + colors.blue + '# Default display' + colors.reset);
  console.log('  node scripts/generate-secrets.js --env      ' + colors.blue + '# .env format' + colors.reset);
  console.log('  node scripts/generate-secrets.js --docker   ' + colors.blue + '# Docker Compose format' + colors.reset);
  console.log('  node scripts/generate-secrets.js --dockploy ' + colors.blue + '# Dockploy format' + colors.reset);
  console.log('  node scripts/generate-secrets.js --all      ' + colors.blue + '# All formats' + colors.reset);
  console.log('  node scripts/generate-secrets.js --help     ' + colors.blue + '# Show this help' + colors.reset);
  console.log('\n' + colors.cyan + '─'.repeat(70) + colors.reset + '\n');
}

/**
 * Main execution
 */
function main() {
  const args = process.argv.slice(2);

  // Show help
  if (args.includes('--help') || args.includes('-h')) {
    displayHelp();
    return;
  }

  // Generate secrets
  const jwtSecret = generateSecret(32);
  const jwtRefreshSecret = generateSecret(32);

  // Display based on arguments
  if (args.includes('--env')) {
    displayEnvFormat(jwtSecret, jwtRefreshSecret);
  } else if (args.includes('--docker')) {
    displayDockerFormat(jwtSecret, jwtRefreshSecret);
  } else if (args.includes('--dockploy')) {
    displayDockployFormat(jwtSecret, jwtRefreshSecret);
  } else if (args.includes('--all')) {
    displaySecrets(jwtSecret, jwtRefreshSecret);
    displayEnvFormat(jwtSecret, jwtRefreshSecret);
    displayDockerFormat(jwtSecret, jwtRefreshSecret);
    displayDockployFormat(jwtSecret, jwtRefreshSecret);
  } else {
    // Default display
    displaySecrets(jwtSecret, jwtRefreshSecret);
  }

  // Always show security tips
  displaySecurityTips();
}

// Run the script
main();
