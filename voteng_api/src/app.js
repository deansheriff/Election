const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { WebSocketServer } = require('ws');
const http = require('http');
require('dotenv').config();

const app = express();
const server = http.createServer(app);

// ── MIDDLEWARE ───────────────────────────────────────────
app.set('trust proxy', 1); // Trust Traefik / Coolify reverse proxy
app.use(helmet());
app.use(cors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization'],
}));
app.use(express.json());

const limiter = rateLimit({ windowMs: 15 * 60 * 1000, max: 200 });
app.use(limiter);

// ── ROUTES ───────────────────────────────────────────────
app.use('/auth', require('./routes/auth'));
app.use('/candidates', require('./routes/candidates'));
app.use('/votes', require('./routes/votes'));
app.use('/analytics', require('./routes/analytics'));
app.use('/admin', require('./routes/admin'));

// ── TEMP: one-time admin setup (visit in browser, then remove) ──
app.get('/setup-admin', async (req, res) => {
    try {
        const bcrypt = require('bcryptjs');
        const adminEmail = 'admin@voteng.ng';
        const adminPhone = '+2340000000000';
        const adminPass = 'Admin@2027';

        const [existing] = await db.query(
            'SELECT id FROM users WHERE email = ? OR phone = ?',
            [adminEmail, adminPhone]
        );

        if (existing.length) {
            // Admin exists — reset their password to make sure it's correct
            const hash = await bcrypt.hash(adminPass, 10);
            await db.query(
                'UPDATE users SET password_hash = ?, is_verified = 1, is_admin = 1 WHERE id = ?',
                [hash, existing[0].id]
            );
            return res.send('<h1>✅ Admin user already existed — password reset to Admin@2027</h1><p>Email: admin@voteng.ng</p><p>Password: Admin@2027</p>');
        }

        const hash = await bcrypt.hash(adminPass, 10);
        await db.query(
            `INSERT INTO users (full_name, email, phone, state, lga, gender, age, geopolitical_zone, password_hash, is_verified, is_admin)
             VALUES (?, ?, ?, 'FCT Abuja', 'AMAC', 'male', 35, 'North-Central', ?, 1, 1)`,
            ['VoteNG Admin', adminEmail, adminPhone, hash]
        );
        return res.send('<h1>✅ Admin user created!</h1><p>Email: admin@voteng.ng</p><p>Password: Admin@2027</p>');
    } catch (err) {
        return res.status(500).send('<h1>❌ Error</h1><pre>' + err.message + '</pre>');
    }
});

// Health check
app.get('/health', (req, res) => res.json({ status: 'ok', time: new Date().toISOString() }));

// ── WEBSOCKET (real-time analytics) ─────────────────────
const wss = new WebSocketServer({ server });
const db = require('./db');

wss.on('connection', (ws) => {
    console.log('[WS] Client connected');

    const sendUpdate = async () => {
        try {
            const [results] = await db.query(
                `SELECT c.id, c.full_name, p.abbreviation, p.color_hex, COUNT(v.id) AS votes
         FROM candidates c
         JOIN parties p ON c.party_id = p.id
         LEFT JOIN votes v ON v.candidate_id = c.id AND v.election_type = 'presidential'
         WHERE c.election_type = 'presidential'
         GROUP BY c.id ORDER BY votes DESC`
            );
            const [[{ total }]] = await db.query("SELECT COUNT(*) AS total FROM votes WHERE election_type='presidential'");
            const payload = {
                type: 'RESULTS_UPDATE',
                election_type: 'presidential',
                total_votes: Number(total),
                results: results.map(r => ({
                    ...r,
                    votes: Number(r.votes),
                    pct: Number(total) > 0 ? +((Number(r.votes) / Number(total)) * 100).toFixed(2) : 0,
                })),
                timestamp: new Date().toISOString(),
            };
            if (ws.readyState === ws.OPEN) ws.send(JSON.stringify(payload));
        } catch (err) {
            console.error('[WS] Error fetching update:', err.message);
        }
    };

    sendUpdate(); // Send immediately on connect
    const interval = setInterval(sendUpdate, 30000); // Every 30 seconds

    ws.on('close', () => {
        clearInterval(interval);
        console.log('[WS] Client disconnected');
    });
});

// ── START ────────────────────────────────────────────────
const PORT = process.env.PORT || 3000;
const initDatabase = require('./db-init');

initDatabase()
  .then(() => {
    server.listen(PORT, () => {
      console.log(`\n🗳️  VoteNG 2027 API running on http://localhost:${PORT}`);
      console.log(`📡  WebSocket server active on ws://localhost:${PORT}`);
    });
  })
  .catch((err) => {
    console.error('[DB Init] Fatal error — could not initialise database:', err.message);
    process.exit(1);
  });
