const express = require('express');
const router = express.Router();
const db = require('../db');
const { authenticate } = require('../middleware/auth');

// GET /candidates?type=presidential&state_id=24
router.get('/', async (req, res) => {
    try {
        const { type, state_id, zone_id, constituency_id } = req.query;
        let query = `
      SELECT c.*, p.name AS party_name, p.abbreviation AS party_abbr, p.color_hex AS party_color, p.logo_url AS party_logo,
             s.name AS state_name
      FROM candidates c
      JOIN parties p ON c.party_id = p.id
      LEFT JOIN states s ON c.state_id = s.id
      WHERE 1=1
    `;
        const params = [];
        if (type) { query += ' AND c.election_type = ?'; params.push(type); }
        if (state_id) { query += ' AND c.state_id = ?'; params.push(state_id); }
        if (zone_id) { query += ' AND c.senatorial_zone_id = ?'; params.push(zone_id); }
        if (constituency_id) { query += ' AND c.constituency_id = ?'; params.push(constituency_id); }
        query += ' ORDER BY c.election_type, c.full_name';
        const [rows] = await db.query(query, params);
        return res.json({ candidates: rows });
    } catch (err) {
        return res.status(500).json({ error: 'Server error', details: err.message });
    }
});

// GET /candidates/:id
router.get('/:id', async (req, res) => {
    try {
        const [rows] = await db.query(
            `SELECT c.*, p.name AS party_name, p.abbreviation AS party_abbr, p.color_hex AS party_color, p.logo_url AS party_logo
       FROM candidates c JOIN parties p ON c.party_id = p.id WHERE c.id = ?`,
            [req.params.id]
        );
        if (!rows.length) return res.status(404).json({ error: 'Candidate not found' });
        return res.json({ candidate: rows[0] });
    } catch (err) {
        return res.status(500).json({ error: 'Server error' });
    }
});

// GET /parties
router.get('/parties/all', async (req, res) => {
    try {
        const [rows] = await db.query('SELECT * FROM parties ORDER BY name');
        return res.json({ parties: rows });
    } catch (err) {
        return res.status(500).json({ error: 'Server error' });
    }
});

// GET /candidates/states/all — list states with zones
router.get('/states/all', async (req, res) => {
    try {
        const [rows] = await db.query('SELECT * FROM states ORDER BY name');
        return res.json({ states: rows });
    } catch (err) {
        return res.status(500).json({ error: 'Server error' });
    }
});

// GET /candidates/lgas/:state_id
router.get('/lgas/:state_id', async (req, res) => {
    try {
        const [rows] = await db.query('SELECT * FROM lgas WHERE state_id = ? ORDER BY name', [req.params.state_id]);
        return res.json({ lgas: rows });
    } catch (err) {
        return res.status(500).json({ error: 'Server error' });
    }
});

module.exports = router;
