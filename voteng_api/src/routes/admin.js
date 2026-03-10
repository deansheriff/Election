const express = require('express');
const router = express.Router();
const db = require('../db');
const { authenticate, adminOnly } = require('../middleware/auth');

// All admin routes require auth + admin role
router.use(authenticate, adminOnly);

// ── CANDIDATES ──────────────────────────────────────
// GET /admin/candidates
router.get('/candidates', async (req, res) => {
    try {
        const [rows] = await db.query(
            `SELECT c.*, p.name AS party_name, p.abbreviation, p.color_hex, s.name AS state_name
       FROM candidates c
       JOIN parties p ON c.party_id = p.id
       LEFT JOIN states s ON c.state_id = s.id
       ORDER BY c.election_type, c.full_name`
        );
        return res.json({ candidates: rows });
    } catch (err) {
        return res.status(500).json({ error: 'Server error' });
    }
});

// POST /admin/candidates
router.post('/candidates', async (req, res) => {
    try {
        const { full_name, photo_url, party_id, election_type, state_id, senatorial_zone_id, constituency_id,
            running_mate_name, running_mate_photo_url, bio, age, is_incumbent } = req.body;
        const [result] = await db.query(
            `INSERT INTO candidates (full_name, photo_url, party_id, election_type, state_id, senatorial_zone_id, constituency_id,
        running_mate_name, running_mate_photo_url, bio, age, is_incumbent)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
            [full_name, photo_url || null, party_id, election_type, state_id || null, senatorial_zone_id || null,
                constituency_id || null, running_mate_name || null, running_mate_photo_url || null, bio || null, age || null, is_incumbent ? 1 : 0]
        );
        return res.status(201).json({ message: 'Candidate added', id: result.insertId });
    } catch (err) {
        return res.status(500).json({ error: 'Server error', details: err.message });
    }
});

// PUT /admin/candidates/:id
router.put('/candidates/:id', async (req, res) => {
    try {
        const { full_name, photo_url, party_id, running_mate_name, running_mate_photo_url, bio, age, is_incumbent } = req.body;
        await db.query(
            `UPDATE candidates SET full_name=?, photo_url=?, party_id=?, running_mate_name=?, running_mate_photo_url=?, bio=?, age=?, is_incumbent=?
       WHERE id=?`,
            [full_name, photo_url || null, party_id, running_mate_name || null, running_mate_photo_url || null, bio || null, age || null, is_incumbent ? 1 : 0, req.params.id]
        );
        return res.json({ message: 'Candidate updated' });
    } catch (err) {
        return res.status(500).json({ error: 'Server error' });
    }
});

// DELETE /admin/candidates/:id
router.delete('/candidates/:id', async (req, res) => {
    try {
        await db.query('DELETE FROM candidates WHERE id = ?', [req.params.id]);
        return res.json({ message: 'Candidate deleted' });
    } catch (err) {
        return res.status(500).json({ error: 'Server error' });
    }
});

// ── PARTIES ──────────────────────────────────────
// GET /admin/parties
router.get('/parties', async (req, res) => {
    try {
        const [rows] = await db.query('SELECT * FROM parties ORDER BY name');
        return res.json({ parties: rows });
    } catch (err) {
        return res.status(500).json({ error: 'Server error' });
    }
});

// PUT /admin/parties/:id
router.put('/parties/:id', async (req, res) => {
    try {
        const { name, abbreviation, color_hex, logo_url, manifesto } = req.body;
        await db.query(
            'UPDATE parties SET name=?, abbreviation=?, color_hex=?, logo_url=?, manifesto=? WHERE id=?',
            [name, abbreviation, color_hex, logo_url || null, manifesto || null, req.params.id]
        );
        return res.json({ message: 'Party updated' });
    } catch (err) {
        return res.status(500).json({ error: 'Server error' });
    }
});

// ── ELECTION CONFIG ──────────────────────────────────────
// GET /admin/election-config
router.get('/election-config', async (req, res) => {
    try {
        const [rows] = await db.query('SELECT * FROM election_config ORDER BY election_type');
        return res.json({ config: rows });
    } catch (err) {
        return res.status(500).json({ error: 'Server error' });
    }
});

// PUT /admin/election-config/:type
router.put('/election-config/:type', async (req, res) => {
    try {
        const { is_open, open_date, close_date, label } = req.body;
        await db.query(
            'UPDATE election_config SET is_open=?, open_date=?, close_date=?, label=? WHERE election_type=?',
            [is_open ? 1 : 0, open_date || null, close_date || null, label || null, req.params.type]
        );
        return res.json({ message: 'Election config updated' });
    } catch (err) {
        return res.status(500).json({ error: 'Server error' });
    }
});

// ── ACTUAL RESULTS ──────────────────────────────────────
// POST /admin/actual-results
router.post('/actual-results', async (req, res) => {
    try {
        const { results } = req.body; // [{ candidate_id, election_type, real_vote_count, real_percentage }]
        if (!Array.isArray(results)) return res.status(400).json({ error: 'results must be an array' });

        for (const r of results) {
            await db.query(
                `INSERT INTO actual_results (candidate_id, election_type, real_vote_count, real_percentage)
         VALUES (?, ?, ?, ?)
         ON DUPLICATE KEY UPDATE real_vote_count=VALUES(real_vote_count), real_percentage=VALUES(real_percentage)`,
                [r.candidate_id, r.election_type, r.real_vote_count, r.real_percentage]
            );
        }
        return res.json({ message: 'Actual results saved', count: results.length });
    } catch (err) {
        return res.status(500).json({ error: 'Server error', details: err.message });
    }
});

// ── USERS / FLAGGING ──────────────────────────────────────
// GET /admin/users?flagged=true
router.get('/users', async (req, res) => {
    try {
        const { flagged, page = 1, limit = 50 } = req.query;
        const offset = (parseInt(page) - 1) * parseInt(limit);
        let query = 'SELECT id, full_name, email, phone, state, gender, age, is_verified, is_admin, is_flagged, created_at FROM users';
        const params = [];
        if (flagged === 'true') { query += ' WHERE is_flagged = 1'; }
        query += ` ORDER BY created_at DESC LIMIT ? OFFSET ?`;
        params.push(parseInt(limit), offset);
        const [rows] = await db.query(query, params);
        const [[{ total }]] = await db.query(`SELECT COUNT(*) AS total FROM users${flagged === 'true' ? ' WHERE is_flagged=1' : ''}`);
        return res.json({ users: rows, total: Number(total), page: parseInt(page) });
    } catch (err) {
        return res.status(500).json({ error: 'Server error' });
    }
});

// PUT /admin/users/:id/flag
router.put('/users/:id/flag', async (req, res) => {
    try {
        const { flagged } = req.body;
        await db.query('UPDATE users SET is_flagged = ? WHERE id = ?', [flagged ? 1 : 0, req.params.id]);
        return res.json({ message: `User ${flagged ? 'flagged' : 'unflagged'}` });
    } catch (err) {
        return res.status(500).json({ error: 'Server error' });
    }
});

// ── STATS OVERVIEW ──────────────────────────────────────
// GET /admin/stats
router.get('/stats', async (req, res) => {
    try {
        const [[{ total_users }]] = await db.query('SELECT COUNT(*) AS total_users FROM users WHERE is_verified=1');
        const [[{ total_votes }]] = await db.query('SELECT COUNT(*) AS total_votes FROM votes');
        const [[{ flagged }]] = await db.query('SELECT COUNT(*) AS flagged FROM users WHERE is_flagged=1');
        const [openTiers] = await db.query('SELECT election_type, label FROM election_config WHERE is_open=1');
        return res.json({
            total_registered: Number(total_users),
            total_votes_cast: Number(total_votes),
            flagged_accounts: Number(flagged),
            open_tiers: openTiers,
        });
    } catch (err) {
        return res.status(500).json({ error: 'Server error' });
    }
});

// ── BROADCAST NOTIFICATION ──────────────────────────────
// POST /admin/notifications
router.post('/notifications', async (req, res) => {
    try {
        const { title, body } = req.body;
        if (!title || !body) return res.status(400).json({ error: 'title and body required' });
        const [result] = await db.query(
            'INSERT INTO notifications (title, body, sent_by) VALUES (?, ?, ?)',
            [title, body, req.user.id]
        );
        return res.status(201).json({ message: 'Notification broadcast', id: result.insertId });
    } catch (err) {
        return res.status(500).json({ error: 'Server error' });
    }
});

// GET /admin/notifications
router.get('/notifications', async (req, res) => {
    try {
        const [rows] = await db.query('SELECT * FROM notifications ORDER BY sent_at DESC LIMIT 50');
        return res.json({ notifications: rows });
    } catch (err) {
        return res.status(500).json({ error: 'Server error' });
    }
});

module.exports = router;
