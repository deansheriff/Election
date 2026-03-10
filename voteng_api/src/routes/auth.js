const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../db');
require('dotenv').config();

// Helper: generate 6-digit OTP
function generateOTP() {
    return Math.floor(100000 + Math.random() * 900000).toString();
}

// Helper: map state to geopolitical zone
function getZone(stateName) {
    const zoneMap = {
        'North-West': ['Jigawa', 'Kaduna', 'Kano', 'Katsina', 'Kebbi', 'Sokoto', 'Zamfara'],
        'North-East': ['Adamawa', 'Bauchi', 'Borno', 'Gombe', 'Taraba', 'Yobe'],
        'North-Central': ['Benue', 'FCT Abuja', 'Kogi', 'Kwara', 'Nasarawa', 'Niger', 'Plateau'],
        'South-West': ['Ekiti', 'Lagos', 'Ogun', 'Ondo', 'Osun', 'Oyo'],
        'South-East': ['Abia', 'Anambra', 'Ebonyi', 'Enugu', 'Imo'],
        'South-South': ['Akwa Ibom', 'Bayelsa', 'Cross River', 'Delta', 'Edo', 'Rivers'],
    };
    for (const [zone, states] of Object.entries(zoneMap)) {
        if (states.includes(stateName)) return zone;
    }
    return 'North-Central';
}

// POST /auth/register
router.post('/register', async (req, res) => {
    try {
        const { full_name, email, phone, state, lga, gender, age, password } = req.body;
        if (!full_name || !phone || !state || !lga || !gender || !age || !password) {
            return res.status(400).json({ error: 'All fields are required' });
        }
        // Check duplicate
        const [existing] = await db.query('SELECT id FROM users WHERE phone = ?', [phone]);
        if (existing.length) return res.status(409).json({ error: 'Phone number already registered' });

        const password_hash = await bcrypt.hash(password, 10);
        const otp_code = generateOTP();
        const otp_expires_at = new Date(Date.now() + (parseInt(process.env.OTP_EXPIRY_MINUTES || 10)) * 60 * 1000);
        const zone = getZone(state);

        const [result] = await db.query(
            `INSERT INTO users (full_name, email, phone, state, lga, gender, age, geopolitical_zone, password_hash, otp_code, otp_expires_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
            [full_name, email || null, phone, state, lga, gender, age, zone, password_hash, otp_code, otp_expires_at]
        );

        // In production, send OTP via SMS/Email. For dev, return in response.
        console.log(`[OTP] User ${phone}: ${otp_code}`);

        return res.status(201).json({
            message: 'Registration successful. OTP sent.',
            user_id: result.insertId,
            // Remove otp from response in production!
            dev_otp: process.env.NODE_ENV !== 'production' ? otp_code : undefined,
        });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ error: 'Server error', details: err.message });
    }
});

// POST /auth/verify-otp
router.post('/verify-otp', async (req, res) => {
    try {
        const { phone, otp } = req.body;
        const [rows] = await db.query('SELECT * FROM users WHERE phone = ?', [phone]);
        if (!rows.length) return res.status(404).json({ error: 'User not found' });

        const user = rows[0];
        if (user.is_verified) return res.status(400).json({ error: 'Already verified' });
        if (user.otp_code !== otp) return res.status(400).json({ error: 'Invalid OTP' });
        if (new Date() > new Date(user.otp_expires_at)) return res.status(400).json({ error: 'OTP expired' });

        await db.query('UPDATE users SET is_verified = 1, otp_code = NULL, otp_expires_at = NULL WHERE id = ?', [user.id]);

        const token = jwt.sign(
            { id: user.id, phone: user.phone, is_admin: user.is_admin, state: user.state, zone: user.geopolitical_zone },
            process.env.JWT_SECRET,
            { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
        );

        return res.json({ message: 'Verified successfully', token, user: { id: user.id, full_name: user.full_name, state: user.state } });
    } catch (err) {
        return res.status(500).json({ error: 'Server error', details: err.message });
    }
});

// POST /auth/login
router.post('/login', async (req, res) => {
    try {
        const { phone, password } = req.body;
        const [rows] = await db.query('SELECT * FROM users WHERE phone = ?', [phone]);
        if (!rows.length) return res.status(404).json({ error: 'User not found' });

        const user = rows[0];
        if (!user.is_verified) return res.status(403).json({ error: 'Account not verified. Please verify OTP.' });
        if (user.is_flagged) return res.status(403).json({ error: 'Account flagged. Contact support.' });

        const valid = await bcrypt.compare(password, user.password_hash);
        if (!valid) return res.status(401).json({ error: 'Invalid credentials' });

        const token = jwt.sign(
            { id: user.id, phone: user.phone, is_admin: user.is_admin, state: user.state, zone: user.geopolitical_zone },
            process.env.JWT_SECRET,
            { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
        );

        return res.json({
            message: 'Login successful',
            token,
            user: { id: user.id, full_name: user.full_name, email: user.email, state: user.state, lga: user.lga, gender: user.gender, age: user.age, is_admin: user.is_admin }
        });
    } catch (err) {
        return res.status(500).json({ error: 'Server error', details: err.message });
    }
});

// POST /auth/resend-otp
router.post('/resend-otp', async (req, res) => {
    try {
        const { phone } = req.body;
        const [rows] = await db.query('SELECT id, is_verified FROM users WHERE phone = ?', [phone]);
        if (!rows.length) return res.status(404).json({ error: 'User not found' });
        if (rows[0].is_verified) return res.status(400).json({ error: 'Already verified' });

        const otp_code = generateOTP();
        const otp_expires_at = new Date(Date.now() + 10 * 60 * 1000);
        await db.query('UPDATE users SET otp_code = ?, otp_expires_at = ? WHERE id = ?', [otp_code, otp_expires_at, rows[0].id]);

        console.log(`[OTP Resend] ${phone}: ${otp_code}`);
        return res.json({ message: 'OTP resent', dev_otp: process.env.NODE_ENV !== 'production' ? otp_code : undefined });
    } catch (err) {
        return res.status(500).json({ error: 'Server error' });
    }
});

// GET /auth/me (get current user profile)
const { authenticate } = require('../middleware/auth');
router.get('/me', authenticate, async (req, res) => {
    try {
        const [rows] = await db.query(
            'SELECT id, full_name, email, phone, state, lga, gender, age, geopolitical_zone, is_admin, created_at FROM users WHERE id = ?',
            [req.user.id]
        );
        if (!rows.length) return res.status(404).json({ error: 'User not found' });
        return res.json({ user: rows[0] });
    } catch (err) {
        return res.status(500).json({ error: 'Server error' });
    }
});

module.exports = router;
