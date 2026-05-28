const express = require('express');
const router = express.Router();
const { getPool, callSP } = require('../db/connection');
const { requireRole } = require('../middleware/auth');

router.post('/scores/submit', requireRole('judge'), async (req, res) => {
  const { assignment_id, sub_id, criterion_id, score, comments } = req.body;
  const pool = getPool('judge');

  try {
    const result = await callSP(pool, 'sp_SubmitScore', 
      [assignment_id, sub_id, criterion_id, score, comments], 
      ['@p_status']
    );
    res.json({ status: result['@p_status'] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message || 'Database error' });
  }
});

router.get('/judge/assignments', requireRole('judge'), async (req, res) => {
  const judge_id = req.session.user.user_id;
  const pool = getPool('admin');

  try {
    const [rows] = await pool.query(`
      SELECT ja.*, h.title 
      FROM judge_assignments ja 
      JOIN hackathons h ON ja.hackathon_id = h.hackathon_id 
      WHERE ja.judge_id = ? AND h.status != 'closed'
    `, [judge_id]);
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Database error' });
  }
});

router.get('/judge/submissions/:hackathonId', requireRole('judge'), async (req, res) => {
  const { hackathonId } = req.params;
  const pool = getPool('admin');
  
  try {
    const [rows] = await pool.query(`
      SELECT s.sub_id, s.title, s.description, s.github_url, s.demo_url, t.team_name 
      FROM submissions s
      JOIN teams t ON s.team_id = t.team_id
      WHERE s.hackathon_id = ?
    `, [hackathonId]);
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Database error' });
  }
});

module.exports = router;
