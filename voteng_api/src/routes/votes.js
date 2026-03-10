const express = require('express');
const router = express.Router();
const db = require('../db');
const { authenticate } = require('../middleware/auth');

// POST /votes — cast a vote
router.post('/', authenticate, async (req, res) => {
    try {
        const { candidate_id, election_type } = req.body;
        const user_id = req.user.id;

        if (!candidate_id || !election_type) {
            return res.status(400).json({ error: 'candidate_id and election_type are required' });
        }

        // 1. Check election is open
        const [config] = await db.query(
            'SELECT is_open FROM election_config WHERE election_type = ?', [election_type]
        );
        if (!config.length || !config[0].is_open) {
            return res.status(403).json({ error: 'Voting for this election is currently closed' });
        }

        // 2. Check candidate exists and matches election type
        const [cand] = await db.query(
            'SELECT id, election_type, state_id FROM candidates WHERE id = ? AND election_type = ?',
            [candidate_id, election_type]
        );
        if (!cand.length) {
            return res.status(404).json({ error: 'Candidate not found for this election type' });
        }

        // 3. Get user details for demographic storage
        const [users] = await db.query(
            'SELECT state, geopolitical_zone, gender, age FROM users WHERE id = ?',
            [user_id]
        );
        const user = users[0];

        // 4. Try to insert (UNIQUE KEY on user_id + election_type prevents double vote)
        try {
            await db.query(
                `INSERT INTO votes (user_id, candidate_id, election_type, user_state, user_zone, user_gender, user_age)
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
                [user_id, candidate_id, election_type, user.state, user.geopolitical_zone, user.gender, user.age]
            );
        } catch (dupErr) {
            if (dupErr.code === 'ER_DUP_ENTRY') {
                return res.status(409).json({ error: 'You have already voted in this election' });
            }
            throw dupErr;
        }

        // 5. Return vote receipt
        const [voteRow] = await db.query(
            `SELECT v.id AS vote_id, v.cast_at, c.full_name AS candidate_name, p.name AS party_name, p.color_hex
       FROM votes v
       JOIN candidates c ON v.candidate_id = c.id
       JOIN parties p ON c.party_id = p.id
       WHERE v.user_id = ? AND v.election_type = ?`,
            [user_id, election_type]
        );

        return res.status(201).json({
            message: 'Vote cast successfully',
            receipt: voteRow[0],
        });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ error: 'Server error', details: err.message });
    }
});

// GET /votes/status — get all vote statuses for current user
router.get('/status', authenticate, async (req, res) => {
    try {
        const user_id = req.user.id;
        const election_types = ['presidential', 'senate', 'house', 'governorship', 'state_assembly'];

        const [votes] = await db.query(
            `SELECT v.election_type, c.full_name AS candidate_name, p.name AS party_name, p.color_hex, v.cast_at
       FROM votes v
       JOIN candidates c ON v.candidate_id = c.id
       JOIN parties p ON c.party_id = p.id
       WHERE v.user_id = ?`,
            [user_id]
        );

        const status = {};
        for (const et of election_types) {
            const voted = votes.find(v => v.election_type === et);
            status[et] = voted ? { voted: true, candidate: voted.candidate_name, party: voted.party_name, color: voted.color_hex, cast_at: voted.cast_at } : { voted: false };
        }

        return res.json({ status });
    } catch (err) {
        return res.status(500).json({ error: 'Server error' });
    }
});

// GET /votes/receipt/:election_type
router.get('/receipt/:election_type', authenticate, async (req, res) => {
    try {
        const [rows] = await db.query(
            `SELECT v.id AS vote_id, v.election_type, v.cast_at,
              c.full_name AS candidate_name, c.photo_url AS candidate_photo,
              p.name AS party_name, p.abbreviation AS party_abbr, p.color_hex
       FROM votes v
       JOIN candidates c ON v.candidate_id = c.id
       JOIN parties p ON c.party_id = p.id
       WHERE v.user_id = ? AND v.election_type = ?`,
            [req.user.id, req.params.election_type]
        );
        if (!rows.length) return res.status(404).json({ error: 'No vote found for this election' });
        return res.json({ receipt: rows[0] });
    } catch (err) {
        return res.status(500).json({ error: 'Server error' });
    }
});

module.exports = router;
