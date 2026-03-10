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
server.listen(PORT, () => {
    console.log(`\n🗳️  VoteNG 2027 API running on http://localhost:${PORT}`);
    console.log(`📡  WebSocket server active on ws://localhost:${PORT}`);
});
