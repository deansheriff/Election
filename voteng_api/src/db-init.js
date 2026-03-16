const mysql = require('mysql2/promise');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

/**
 * Connects to MySQL and applies the schema if the users table doesn't exist.
 * This is safe to run on every startup (all statements use CREATE TABLE IF NOT EXISTS).
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

      // Helper: strip CREATE DATABASE / USE statements so we can run against an existing connection
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
  } finally {
    await connection.end();
  }
}

module.exports = initDatabase;
