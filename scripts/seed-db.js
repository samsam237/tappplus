#!/usr/bin/env node

/**
 * Database Seeding Script
 *
 * This script seeds the SQLite database with initial data:
 * - Organization
 * - Admin user
 * - Doctor user
 *
 * Usage:
 *   node scripts/seed-db.js
 */

const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

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

async function main() {
  try {
    log('\n========================================', 'blue');
    log('  🌱 Seeding Database', 'blue');
    log('========================================\n', 'blue');

    // ===================================
    // 1. Create Organization
    // ===================================
    log('→ Creating organization...', 'blue');
    const org = await prisma.organization.upsert({
      where: { id: 'org-demo' },
      update: {},
      create: {
        id: 'org-demo',
        name: 'Clinique Médicale Demo',
      },
    });
    log(`✓ Organization created: ${org.name}`, 'green');

    // ===================================
    // 2. Create Admin User
    // ===================================
    log('\n→ Creating admin user...', 'blue');
    const adminPassword = 'Admin123!';
    const admin = await prisma.user.upsert({
      where: { email: 'admin@tappplus.com' },
      update: {},
      create: {
        email: 'admin@tappplus.com',
        password: bcrypt.hashSync(adminPassword, 10),
        role: 'ADMIN',
        timezone: 'Africa/Douala',
        isActive: true,
        organizationId: org.id,
      },
    });
    log(`✓ Admin user created`, 'green');
    log(`  Email: ${admin.email}`, 'yellow');
    log(`  Password: ${adminPassword}`, 'yellow');

    // ===================================
    // 3. Create Doctor User
    // ===================================
    log('\n→ Creating doctor user...', 'blue');
    const doctorPassword = 'Doctor123!';
    const doctorUser = await prisma.user.upsert({
      where: { email: 'docteur@tappplus.com' },
      update: {},
      create: {
        email: 'docteur@tappplus.com',
        password: bcrypt.hashSync(doctorPassword, 10),
        role: 'DOCTOR',
        timezone: 'Africa/Douala',
        isActive: true,
        organizationId: org.id,
      },
    });

    const doctor = await prisma.doctor.upsert({
      where: { userId: doctorUser.id },
      update: {},
      create: {
        userId: doctorUser.id,
        speciality: 'Médecine Générale',
        license: 'MD-2024-001',
        isActive: true,
      },
    });
    log(`✓ Doctor user created`, 'green');
    log(`  Email: ${doctorUser.email}`, 'yellow');
    log(`  Password: ${doctorPassword}`, 'yellow');
    log(`  Speciality: ${doctor.speciality}`, 'yellow');

    // ===================================
    // 4. Create Sample Patient (Optional)
    // ===================================
    log('\n→ Creating sample patient...', 'blue');
    const patient = await prisma.person.upsert({
      where: { id: 'patient-demo' },
      update: {},
      create: {
        id: 'patient-demo',
        fullName: 'samuel Nguema',
        birthdate: new Date('1985-05-15'),
        phone: '+237650000000',
        email: 'samuel.nguema@example.com',
        address: 'Douala, Cameroun',
      },
    });

    // Link patient to organization
    await prisma.personOrganization.upsert({
      where: {
        personId_orgId: {
          personId: patient.id,
          orgId: org.id,
        },
      },
      update: {},
      create: {
        personId: patient.id,
        orgId: org.id,
        role: 'PATIENT',
        isActive: true,
      },
    });
    log(`✓ Sample patient created: ${patient.fullName}`, 'green');

    // ===================================
    // Success Summary
    // ===================================
    log('\n========================================', 'green');
    log('  ✅ Seeding completed successfully!', 'green');
    log('========================================\n', 'green');

    log('Login Credentials:', 'blue');
    log('', 'reset');
    log('👨‍💼 Admin:', 'yellow');
    log(`   Email:    admin@tappplus.com`, 'reset');
    log(`   Password: Admin123!`, 'reset');
    log('', 'reset');
    log('👨‍⚕️  Doctor:', 'yellow');
    log(`   Email:    docteur@tappplus.com`, 'reset');
    log(`   Password: Doctor123!`, 'reset');
    log('', 'reset');
    log('🏥 Organization:', 'yellow');
    log(`   Name: ${org.name}`, 'reset');
    log('', 'reset');
    log('👤 Sample Patient:', 'yellow');
    log(`   Name: ${patient.fullName}`, 'reset');
    log('', 'reset');

  } catch (error) {
    log('\n✗ Error during seeding', 'red');
    console.error(error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

// Run the seeding
main();
