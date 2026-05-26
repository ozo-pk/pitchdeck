const express = require('express');
const router = express.Router();
const { getPool } = require('../db/connection');
const { requireRole } = require('../middleware/auth');

router.get('/leaderboard', async (req, res) => {
  const { hackathon_id } = req.query;
  if (!hackathon_id) return res.status(400).json({ error: 'hackathon_id required' });

  // Use student pool for public access (or a dedicated read-only pool)
  const pool = getPool('student'); 
  
  try {
    const [rows] = await pool.query('SELECT * FROM vw_Leaderboard WHERE hackathon_id = ?', [hackathon_id]);
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Database error' });
  }
});

router.get('/criteria/:hackathonId', requireRole('judge', 'student'), async (req, res) => {
  const { hackathonId } = req.params;
  const pool = getPool(req.session.user.role);

  try {
    const [rows] = await pool.query('SELECT * FROM criteria WHERE hackathon_id = ?', [hackathonId]);
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Database error' });
  }
});

router.get('/hackathons', async (req, res) => {
  const pool = getPool('student'); 
  try {
    const [rows] = await pool.query('SELECT hackathon_id, title, status FROM hackathons ORDER BY start_date DESC');
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Database error' });
  }
});

module.exports = router;
