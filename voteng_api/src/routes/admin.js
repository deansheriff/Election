const express = require('express');
const router = express.Router();
const db = require('../db');
const { authenticate, adminOnly } = require('../middleware/auth');
const fs = require('fs');
const path = require('path');

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

// POST /admin/parties
router.post('/parties', async (req, res) => {
    try {
        const { name, abbreviation, color_hex, logo_url, manifesto } = req.body;
        if (!name || !abbreviation || !color_hex) {
            return res.status(400).json({ error: 'name, abbreviation, and color_hex are required' });
        }
        const [result] = await db.query(
            'INSERT INTO parties (name, abbreviation, color_hex, logo_url, manifesto) VALUES (?, ?, ?, ?, ?)',
            [name, abbreviation, color_hex, logo_url || null, manifesto || null]
        );
        return res.status(201).json({ message: 'Party created', id: result.insertId });
    } catch (err) {
        return res.status(500).json({ error: 'Server error', details: err.message });
    }
});

// DELETE /admin/parties/:id
router.delete('/parties/:id', async (req, res) => {
    try {
        await db.query('DELETE FROM parties WHERE id = ?', [req.params.id]);
        return res.json({ message: 'Party deleted' });
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

// DELETE /admin/users/:id
router.delete('/users/:id', async (req, res) => {
    try {
        // Safety: don't allow deleting yourself or other admins
        if (parseInt(req.params.id) === req.user.id) {
            return res.status(400).json({ error: 'Cannot delete your own account' });
        }
        const [[target]] = await db.query('SELECT is_admin FROM users WHERE id = ?', [req.params.id]);
        if (target && target.is_admin) {
            return res.status(400).json({ error: 'Cannot delete admin accounts' });
        }
        await db.query('DELETE FROM votes WHERE user_id = ?', [req.params.id]);
        await db.query('DELETE FROM users WHERE id = ?', [req.params.id]);
        return res.json({ message: 'User deleted' });
    } catch (err) {
        return res.status(500).json({ error: 'Server error', details: err.message });
    }
});

// PUT /admin/users/:id/verify
router.put('/users/:id/verify', async (req, res) => {
    try {
        const { verified } = req.body;
        await db.query('UPDATE users SET is_verified = ? WHERE id = ?', [verified ? 1 : 0, req.params.id]);
        return res.json({ message: `User ${verified ? 'verified' : 'unverified'}` });
    } catch (err) {
        return res.status(500).json({ error: 'Server error' });
    }
});

// POST /admin/upload – base64 image upload
router.post('/upload', async (req, res) => {
    try {
        const { image, filename } = req.body;
        if (!image || !filename) {
            return res.status(400).json({ error: 'image (base64) and filename are required' });
        }
        // Strip data URI prefix if present
        const base64Data = image.replace(/^data:image\/\w+;base64,/, '');
        const ext = filename.split('.').pop() || 'png';
        const safeName = `${Date.now()}_${Math.random().toString(36).substring(2, 8)}.${ext}`;
        const uploadDir = path.join(__dirname, '../../uploads');
        if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });
        const filePath = path.join(uploadDir, safeName);
        fs.writeFileSync(filePath, base64Data, 'base64');
        return res.json({ url: `/uploads/${safeName}` });
    } catch (err) {
        return res.status(500).json({ error: 'Upload failed', details: err.message });
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

// ── SMTP SETTINGS ──────────────────────────────────
// PUT /admin/smtp-settings  — persists SMTP credentials to smtp.json
const smtpConfigPath = path.join(__dirname, '../../smtp.json');

router.put('/smtp-settings', (req, res) => {
    try {
        const { host, port, user, pass, from } = req.body;
        if (!host || !user || !pass) {
            return res.status(400).json({ error: 'host, user, and pass are required' });
        }
        const config = { host, port: parseInt(port) || 587, user, pass, from: from || user };
        fs.writeFileSync(smtpConfigPath, JSON.stringify(config, null, 2), 'utf8');
        return res.json({ message: 'SMTP settings saved. Emails will now be sent via this server.' });
    } catch (err) {
        return res.status(500).json({ error: 'Failed to save SMTP settings', details: err.message });
    }
});

// GET /admin/smtp-settings  — returns current settings (password masked)
router.get('/smtp-settings', (req, res) => {
    try {
        if (!fs.existsSync(smtpConfigPath)) {
            return res.json({ configured: false });
        }
        const cfg = JSON.parse(fs.readFileSync(smtpConfigPath, 'utf8'));
        return res.json({ configured: true, host: cfg.host, port: cfg.port, user: cfg.user, from: cfg.from });
    } catch (err) {
        return res.status(500).json({ error: 'Failed to read SMTP settings' });
    }
});

// ── ELECTION SIMULATION ──────────────────────────────
// POST /admin/simulate  — generate fake voters + votes
const bcrypt = require('bcryptjs');

const NIGERIAN_STATES = [
    { name: 'Abia', zone: 'South-East' }, { name: 'Adamawa', zone: 'North-East' },
    { name: 'Akwa Ibom', zone: 'South-South' }, { name: 'Anambra', zone: 'South-East' },
    { name: 'Bauchi', zone: 'North-East' }, { name: 'Bayelsa', zone: 'South-South' },
    { name: 'Benue', zone: 'North-Central' }, { name: 'Borno', zone: 'North-East' },
    { name: 'Cross River', zone: 'South-South' }, { name: 'Delta', zone: 'South-South' },
    { name: 'Ebonyi', zone: 'South-East' }, { name: 'Edo', zone: 'South-South' },
    { name: 'Ekiti', zone: 'South-West' }, { name: 'Enugu', zone: 'South-East' },
    { name: 'Gombe', zone: 'North-East' }, { name: 'Imo', zone: 'South-East' },
    { name: 'Jigawa', zone: 'North-West' }, { name: 'Kaduna', zone: 'North-West' },
    { name: 'Kano', zone: 'North-West' }, { name: 'Katsina', zone: 'North-West' },
    { name: 'Kebbi', zone: 'North-West' }, { name: 'Kogi', zone: 'North-Central' },
    { name: 'Kwara', zone: 'North-Central' }, { name: 'Lagos', zone: 'South-West' },
    { name: 'Nasarawa', zone: 'North-Central' }, { name: 'Niger', zone: 'North-Central' },
    { name: 'Ogun', zone: 'South-West' }, { name: 'Ondo', zone: 'South-West' },
    { name: 'Osun', zone: 'South-West' }, { name: 'Oyo', zone: 'South-West' },
    { name: 'Plateau', zone: 'North-Central' }, { name: 'Rivers', zone: 'South-South' },
    { name: 'Sokoto', zone: 'North-West' }, { name: 'Taraba', zone: 'North-East' },
    { name: 'Yobe', zone: 'North-East' }, { name: 'Zamfara', zone: 'North-West' },
    { name: 'FCT Abuja', zone: 'North-Central' },
];

const FIRST_NAMES = ['Chinedu', 'Aisha', 'Emeka', 'Fatima', 'Obi', 'Amina', 'Tunde', 'Ngozi',
    'Musa', 'Chioma', 'Ibrahim', 'Adaeze', 'Yusuf', 'Temitope', 'Bala', 'Nneka', 'Abdullahi',
    'Funke', 'Hassan', 'Blessing', 'Ahmed', 'Ifeoma', 'Sani', 'Grace', 'Danladi', 'Joy',
    'Mohammed', 'Esther', 'Aliyu', 'Peace', 'Umar', 'Ruth', 'Kabiru', 'Mary', 'Garba'];
const LAST_NAMES = ['Okafor', 'Mohammed', 'Adeyemi', 'Ibrahim', 'Okonkwo', 'Bello', 'Abubakar',
    'Eze', 'Suleiman', 'Nnamdi', 'Abdullahi', 'Adekunle', 'Musa', 'Okeke', 'Yusuf', 'Chukwu',
    'Ogundipe', 'Bakare', 'Lawal', 'Onwueme', 'Danjuma', 'Osei', 'Aliyu', 'Nwosu', 'Garuba'];

router.post('/simulate', async (req, res) => {
    try {
        const { voter_count = 500, election_types = ['presidential'] } = req.body;
        const count = Math.min(Math.max(parseInt(voter_count) || 500, 10), 10000);

        // Get candidates for the requested election types
        const [candidates] = await db.query(
            'SELECT c.id, c.full_name, c.election_type, p.abbreviation FROM candidates c JOIN parties p ON c.party_id = p.id WHERE c.election_type IN (?)',
            [election_types]
        );

        if (!candidates.length) {
            return res.status(400).json({ error: 'No candidates found for the requested election types' });
        }

        // Group candidates by election type
        const byType = {};
        for (const c of candidates) {
            if (!byType[c.election_type]) byType[c.election_type] = [];
            byType[c.election_type].push(c);
        }

        // Assign weighted probabilities (incumbent gets a boost, add randomness)
        for (const type of Object.keys(byType)) {
            const cands = byType[type];
            let weights = cands.map(() => 0.5 + Math.random() * 2); // random base weight 0.5–2.5
            const total = weights.reduce((a, b) => a + b, 0);
            byType[type] = cands.map((c, i) => ({ ...c, weight: weights[i] / total }));
        }

        // Create simulated password hash once
        const simHash = await bcrypt.hash('SimUser123!', 4); // low rounds for speed

        const batchSize = 50;
        let totalVotes = 0;

        for (let batch = 0; batch < count; batch += batchSize) {
            const thisBatch = Math.min(batchSize, count - batch);
            const userValues = [];
            const userParams = [];

            for (let i = 0; i < thisBatch; i++) {
                const stateInfo = NIGERIAN_STATES[Math.floor(Math.random() * NIGERIAN_STATES.length)];
                const firstName = FIRST_NAMES[Math.floor(Math.random() * FIRST_NAMES.length)];
                const lastName = LAST_NAMES[Math.floor(Math.random() * LAST_NAMES.length)];
                const gender = Math.random() < 0.5 ? 'male' : 'female';
                const age = 18 + Math.floor(Math.random() * 52); // 18–69
                const phone = `+234${String(7000000000 + batch + i).padStart(10, '0')}`;

                userValues.push('(?, ?, ?, ?, ?, ?, ?, ?, 1, 0)');
                userParams.push(
                    `${firstName} ${lastName}`, phone, stateInfo.name,
                    'N/A', gender, age, stateInfo.zone, simHash
                );
            }

            const [insertResult] = await db.query(
                `INSERT INTO users (full_name, phone, state, lga, gender, age, geopolitical_zone, password_hash, is_verified, is_admin) VALUES ${userValues.join(',')}`,
                userParams
            );

            const firstId = insertResult.insertId;

            // Cast votes for each simulated user
            for (let i = 0; i < thisBatch; i++) {
                const userId = firstId + i;
                // Retrieve the user's state/zone/gender/age for vote metadata
                const stateInfo = NIGERIAN_STATES[Math.floor(Math.random() * NIGERIAN_STATES.length)];
                const gender = Math.random() < 0.5 ? 'male' : 'female';
                const age = 18 + Math.floor(Math.random() * 52);

                for (const type of Object.keys(byType)) {
                    const cands = byType[type];
                    // Weighted random pick
                    let rand = Math.random();
                    let chosen = cands[cands.length - 1];
                    for (const c of cands) {
                        rand -= c.weight;
                        if (rand <= 0) { chosen = c; break; }
                    }

                    // Random cast time within last 60 minutes
                    const minutesAgo = Math.floor(Math.random() * 60);
                    const castAt = new Date(Date.now() - minutesAgo * 60000);

                    try {
                        await db.query(
                            `INSERT INTO votes (user_id, candidate_id, election_type, user_state, user_zone, user_gender, user_age, cast_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
                            [userId, chosen.id, type, stateInfo.name, stateInfo.zone, gender, age, castAt]
                        );
                        totalVotes++;
                    } catch (e) {
                        // Skip duplicate vote errors
                    }
                }
            }
        }

        return res.json({
            message: 'Simulation complete',
            voters_created: count,
            votes_cast: totalVotes,
            election_types: Object.keys(byType),
        });
    } catch (err) {
        return res.status(500).json({ error: 'Simulation failed', details: err.message });
    }
});

// DELETE /admin/simulate  — clear all simulated voters + their votes
router.delete('/simulate', async (req, res) => {
    try {
        // Delete votes from non-admin, sim-generated users (those with phone starting +2347)
        await db.query(`DELETE v FROM votes v JOIN users u ON v.user_id = u.id WHERE u.is_admin = 0 AND u.phone LIKE '+2347%'`);
        const [delResult] = await db.query(`DELETE FROM users WHERE is_admin = 0 AND phone LIKE '+2347%'`);
        return res.json({ message: 'Simulation data cleared', voters_removed: delResult.affectedRows });
    } catch (err) {
        return res.status(500).json({ error: 'Failed to clear simulation', details: err.message });
    }
});

// ── VOTE AUDIT LOG ──────────────────────────────────
// GET /admin/vote-log?page=1&limit=50&type=presidential
router.get('/vote-log', async (req, res) => {
    try {
        const { page = 1, limit = 50, type } = req.query;
        const offset = (parseInt(page) - 1) * parseInt(limit);
        let query = `SELECT v.id, v.election_type, v.user_state, v.user_zone, v.user_gender, v.user_age, v.cast_at,
                     u.full_name AS voter_name, c.full_name AS candidate_name, p.abbreviation AS party
                     FROM votes v
                     JOIN users u ON v.user_id = u.id
                     JOIN candidates c ON v.candidate_id = c.id
                     JOIN parties p ON c.party_id = p.id`;
        const params = [];
        if (type) { query += ' WHERE v.election_type = ?'; params.push(type); }
        query += ' ORDER BY v.cast_at DESC LIMIT ? OFFSET ?';
        params.push(parseInt(limit), offset);
        const [rows] = await db.query(query, params);

        let countQuery = 'SELECT COUNT(*) AS total FROM votes';
        const countParams = [];
        if (type) { countQuery += ' WHERE election_type = ?'; countParams.push(type); }
        const [[{ total }]] = await db.query(countQuery, countParams);

        return res.json({ votes: rows, total: Number(total), page: parseInt(page) });
    } catch (err) {
        return res.status(500).json({ error: 'Server error', details: err.message });
    }
});

module.exports = router;
