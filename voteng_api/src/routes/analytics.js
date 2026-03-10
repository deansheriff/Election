const express = require('express');
const router = express.Router();
const db = require('../db');

// GET /analytics/results?type=presidential
router.get('/results', async (req, res) => {
    try {
        const { type } = req.query;
        const electionType = type || 'presidential';

        const [results] = await db.query(
            `SELECT c.id, c.full_name, c.photo_url, c.running_mate_name, c.is_incumbent,
              p.name AS party_name, p.abbreviation AS party_abbr, p.color_hex,
              COUNT(v.id) AS vote_count
       FROM candidates c
       JOIN parties p ON c.party_id = p.id
       LEFT JOIN votes v ON v.candidate_id = c.id AND v.election_type = ?
       WHERE c.election_type = ?
       GROUP BY c.id
       ORDER BY vote_count DESC`,
            [electionType, electionType]
        );

        const total = results.reduce((sum, r) => sum + Number(r.vote_count), 0);
        const enriched = results.map(r => ({
            ...r,
            vote_count: Number(r.vote_count),
            percentage: total > 0 ? +((Number(r.vote_count) / total) * 100).toFixed(2) : 0,
        }));

        return res.json({ election_type: electionType, total_votes: total, results: enriched });
    } catch (err) {
        return res.status(500).json({ error: 'Server error', details: err.message });
    }
});

// GET /analytics/threshold?type=presidential
// Returns per-candidate how many states they have 25%+ in
router.get('/threshold', async (req, res) => {
    try {
        // Get votes per candidate per state
        const [stateVotes] = await db.query(
            `SELECT v.candidate_id, v.user_state, COUNT(*) AS state_votes
       FROM votes v WHERE v.election_type = 'presidential'
       GROUP BY v.candidate_id, v.user_state`
        );

        // Get total votes per state
        const [stateTotals] = await db.query(
            `SELECT user_state, COUNT(*) AS state_total
       FROM votes WHERE election_type = 'presidential'
       GROUP BY user_state`
        );

        const stateTotalMap = {};
        stateTotals.forEach(st => { stateTotalMap[st.user_state] = Number(st.state_total); });

        // Group by candidate
        const candidateMap = {};
        stateVotes.forEach(sv => {
            const id = sv.candidate_id;
            if (!candidateMap[id]) candidateMap[id] = { qualifying_states: [], states_data: {} };
            const pct = stateTotalMap[sv.user_state] > 0
                ? (Number(sv.state_votes) / stateTotalMap[sv.user_state]) * 100
                : 0;
            candidateMap[id].states_data[sv.user_state] = pct;
            if (pct >= 25) candidateMap[id].qualifying_states.push(sv.user_state);
        });

        // Attach candidate info
        const [candidates] = await db.query(
            `SELECT c.id, c.full_name, p.abbreviation AS party_abbr, p.color_hex
       FROM candidates c JOIN parties p ON c.party_id = p.id WHERE c.election_type = 'presidential'`
        );

        const threshold = candidates.map(c => ({
            ...c,
            qualifying_states_count: (candidateMap[c.id]?.qualifying_states || []).length,
            qualifying_states: candidateMap[c.id]?.qualifying_states || [],
            states_data: candidateMap[c.id]?.states_data || {},
            meets_threshold: (candidateMap[c.id]?.qualifying_states || []).length >= 24,
        }));

        return res.json({ threshold });
    } catch (err) {
        return res.status(500).json({ error: 'Server error', details: err.message });
    }
});

// GET /analytics/demographics?type=presidential
router.get('/demographics', async (req, res) => {
    try {
        const { type } = req.query;
        const electionType = type || 'presidential';

        const [genderRows] = await db.query(
            `SELECT user_gender AS gender, COUNT(*) AS count FROM votes WHERE election_type = ? GROUP BY user_gender`,
            [electionType]
        );

        const [ageRows] = await db.query(
            `SELECT 
        CASE
          WHEN user_age BETWEEN 18 AND 25 THEN '18-25'
          WHEN user_age BETWEEN 26 AND 35 THEN '26-35'
          WHEN user_age BETWEEN 36 AND 45 THEN '36-45'
          WHEN user_age BETWEEN 46 AND 60 THEN '46-60'
          ELSE '60+' END AS age_group,
        COUNT(*) AS count
       FROM votes WHERE election_type = ?
       GROUP BY age_group ORDER BY age_group`,
            [electionType]
        );

        const [zoneRows] = await db.query(
            `SELECT user_zone AS zone, COUNT(*) AS count FROM votes WHERE election_type = ? GROUP BY user_zone`,
            [electionType]
        );

        const [stateRows] = await db.query(
            `SELECT user_state AS state, COUNT(*) AS count FROM votes WHERE election_type = ? GROUP BY user_state ORDER BY count DESC`,
            [electionType]
        );

        return res.json({ gender: genderRows, age_groups: ageRows, zones: zoneRows, states: stateRows });
    } catch (err) {
        return res.status(500).json({ error: 'Server error', details: err.message });
    }
});

// GET /analytics/turnout
router.get('/turnout', async (req, res) => {
    try {
        const [[{ total_users }]] = await db.query('SELECT COUNT(*) AS total_users FROM users WHERE is_verified = 1');
        const [byType] = await db.query(
            `SELECT election_type, COUNT(*) AS votes_cast FROM votes GROUP BY election_type`
        );
        const [byState] = await db.query(
            `SELECT user_state AS state, COUNT(*) AS votes FROM votes WHERE election_type='presidential' GROUP BY user_state`
        );
        const [byZone] = await db.query(
            `SELECT user_zone AS zone, COUNT(*) AS votes FROM votes WHERE election_type='presidential' GROUP BY user_zone`
        );
        const [regOverTime] = await db.query(
            `SELECT DATE(created_at) AS date, COUNT(*) AS registrations FROM users WHERE is_verified=1 GROUP BY DATE(created_at) ORDER BY date`
        );

        return res.json({
            total_registered: Number(total_users),
            by_election_type: byType.map(r => ({ ...r, votes_cast: Number(r.votes_cast) })),
            by_state: byState.map(r => ({ ...r, votes: Number(r.votes) })),
            by_zone: byZone.map(r => ({ ...r, votes: Number(r.votes) })),
            registration_over_time: regOverTime,
        });
    } catch (err) {
        return res.status(500).json({ error: 'Server error', details: err.message });
    }
});

// GET /analytics/comparison?type=presidential
// Platform results vs actual INEC results
router.get('/comparison', async (req, res) => {
    try {
        const { type } = req.query;
        const electionType = type || 'presidential';

        const [platform] = await db.query(
            `SELECT c.id, c.full_name, p.abbreviation AS party_abbr, p.color_hex,
              COUNT(v.id) AS platform_votes
       FROM candidates c
       JOIN parties p ON c.party_id = p.id
       LEFT JOIN votes v ON v.candidate_id = c.id AND v.election_type = ?
       WHERE c.election_type = ?
       GROUP BY c.id ORDER BY platform_votes DESC`,
            [electionType, electionType]
        );

        const [actual] = await db.query(
            `SELECT ar.candidate_id, ar.real_vote_count, ar.real_percentage
       FROM actual_results ar WHERE ar.election_type = ?`,
            [electionType]
        );

        const actualMap = {};
        actual.forEach(a => { actualMap[a.candidate_id] = a; });

        const platformTotal = platform.reduce((s, r) => s + Number(r.platform_votes), 0);

        const comparison = platform.map(r => {
            const platPct = platformTotal > 0 ? +((Number(r.platform_votes) / platformTotal) * 100).toFixed(2) : 0;
            const act = actualMap[r.id];
            return {
                candidate_id: r.id,
                full_name: r.full_name,
                party_abbr: r.party_abbr,
                color_hex: r.color_hex,
                platform_votes: Number(r.platform_votes),
                platform_percentage: platPct,
                actual_vote_count: act ? Number(act.real_vote_count) : null,
                actual_percentage: act ? Number(act.real_percentage) : null,
                difference: act ? +(platPct - Number(act.real_percentage)).toFixed(2) : null,
            };
        });

        // Overall accuracy: average absolute difference
        const withActual = comparison.filter(c => c.actual_percentage !== null);
        const accuracy = withActual.length > 0
            ? +(100 - (withActual.reduce((s, c) => s + Math.abs(c.difference), 0) / withActual.length)).toFixed(2)
            : null;

        return res.json({ election_type: electionType, accuracy_score: accuracy, comparison });
    } catch (err) {
        return res.status(500).json({ error: 'Server error', details: err.message });
    }
});

// GET /analytics/state-results?type=presidential
router.get('/state-results', async (req, res) => {
    try {
        const { type } = req.query;
        const electionType = type || 'presidential';

        const [rows] = await db.query(
            `SELECT v.user_state AS state, v.candidate_id,
              c.full_name AS candidate_name, p.abbreviation AS party_abbr, p.color_hex,
              COUNT(v.id) AS votes
       FROM votes v
       JOIN candidates c ON v.candidate_id = c.id
       JOIN parties p ON c.party_id = p.id
       WHERE v.election_type = ?
       GROUP BY v.user_state, v.candidate_id
       ORDER BY v.user_state, votes DESC`,
            [electionType]
        );

        // Group by state, pick winner
        const stateMap = {};
        rows.forEach(r => {
            if (!stateMap[r.state]) stateMap[r.state] = [];
            stateMap[r.state].push(r);
        });

        const stateResults = Object.entries(stateMap).map(([state, candidates]) => ({
            state,
            winner: candidates[0],
            all_candidates: candidates,
        }));

        return res.json({ election_type: electionType, state_results: stateResults });
    } catch (err) {
        return res.status(500).json({ error: 'Server error', details: err.message });
    }
});

// GET /analytics/timeline?type=presidential
router.get('/timeline', async (req, res) => {
    try {
        const { type } = req.query;
        const electionType = type || 'presidential';
        const [rows] = await db.query(
            `SELECT DATE(v.cast_at) AS date, c.full_name AS candidate, p.abbreviation AS party, p.color_hex, COUNT(*) AS daily_votes
       FROM votes v
       JOIN candidates c ON v.candidate_id = c.id
       JOIN parties p ON c.party_id = p.id
       WHERE v.election_type = ?
       GROUP BY DATE(v.cast_at), v.candidate_id
       ORDER BY date`,
            [electionType]
        );
        return res.json({ election_type: electionType, timeline: rows });
    } catch (err) {
        return res.status(500).json({ error: 'Server error', details: err.message });
    }
});

module.exports = router;
