const mysql = require('mysql2/promise');
const fs = require('fs');
const path = require('path');
const bcrypt = require('bcryptjs');
require('dotenv').config();

/**
 * Connects to MySQL and applies the schema if the users table doesn't exist.
 * Also ensures the admin user always exists.
 */
async function initDatabase() {
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'voteng2027',
    multipleStatements: true,
  });

  try {
    const [[rows]] = await connection.query(
      "SELECT COUNT(*) AS cnt FROM information_schema.tables WHERE table_schema = ? AND table_name = 'users'",
      [process.env.DB_NAME || 'voteng2027']
    );

    if (rows.cnt === 0) {
      console.log('[DB Init] Tables not found — applying schema and seed...');
      const schemaPath = path.join(__dirname, '../database/schema.sql');
      const seedPath = path.join(__dirname, '../database/seed.sql');

      const stripDbStatements = (sql) =>
        sql.split('\n')
          .filter(line => !/^\s*(CREATE DATABASE|USE)\b/i.test(line))
          .join('\n');

      if (fs.existsSync(schemaPath)) {
        const schema = stripDbStatements(fs.readFileSync(schemaPath, 'utf8'));
        await connection.query(schema);
        console.log('[DB Init] Schema applied.');
      }

      if (fs.existsSync(seedPath)) {
        const seed = stripDbStatements(fs.readFileSync(seedPath, 'utf8'));
        await connection.query(seed);
        console.log('[DB Init] Seed data applied.');
      }
    } else {
      console.log('[DB Init] Tables already exist, skipping init.');
    }

    // ── Always ensure admin user exists ──────────────────────
    await ensureAdminUser(connection);

  } finally {
    await connection.end();
  }
}

/**
 * Creates the admin user if it doesn't already exist.
 * Runs on every startup so it works even if the seed was never applied.
 */
async function ensureAdminUser(connection) {
  const adminEmail = 'admin@voteng.ng';
  const adminPhone = '+2340000000000';
  const adminPassword = 'Admin@2027';

  const [[existing]] = await connection.query(
    'SELECT id FROM users WHERE email = ? OR phone = ?',
    [adminEmail, adminPhone]
  );

  if (existing) {
    console.log('[DB Init] Admin user already exists (id=' + existing.id + ').');
    return;
  }

  const hash = await bcrypt.hash(adminPassword, 10);
  await connection.query(
    `INSERT INTO users (full_name, email, phone, state, lga, gender, age, geopolitical_zone, password_hash, is_verified, is_admin)
     VALUES (?, ?, ?, 'FCT Abuja', 'AMAC', 'male', 35, 'North-Central', ?, 1, 1)`,
    ['VoteNG Admin', adminEmail, adminPhone, hash]
  );
  console.log('[DB Init] Admin user created — email: ' + adminEmail + ', password: ' + adminPassword);
}

module.exports = initDatabase;
