const express = require('express');
const router = express.Router();
const { getPool, callSP } = require('../db/connection');
const { requireRole } = require('../middleware/auth');

router.post('/teams/register', requireRole('student'), async (req, res) => {
  const { hackathon_id, team_name } = req.body;
  const leader_id = req.session.user.user_id;
  const pool = getPool('student');

  try {
    const result = await callSP(pool, 'sp_RegisterTeam', 
      [hackathon_id, team_name, leader_id], 
      ['@p_team_id', '@p_status']
    );
    res.json({ team_id: result['@p_team_id'], status: result['@p_status'] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message || 'Database error' });
  }
});

router.post('/teams/:teamId/members', requireRole('student'), async (req, res) => {
  const { teamId } = req.params;
  const { user_id } = req.body;
  const pool = getPool('student');

  try {
    await pool.query('INSERT INTO team_members (team_id, user_id) VALUES (?, ?)', [teamId, user_id]);
    res.json({ success: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Database error' });
  }
});

router.post('/submissions/submit', requireRole('student'), async (req, res) => {
  const { team_id, hackathon_id, title, description, github_url, demo_url } = req.body;
  const pool = getPool('student');

  try {
    const result = await callSP(pool, 'sp_SubmitProject', 
      [team_id, hackathon_id, title, description, github_url, demo_url], 
      ['@p_sub_id', '@p_status']
    );
    res.json({ sub_id: result['@p_sub_id'], status: result['@p_status'] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message || 'Database error' });
  }
});

router.get('/teams/my-teams', requireRole('student'), async (req, res) => {
  const user_id = req.session.user.user_id;
  const pool = getPool('admin');
  try {
    const [rows] = await pool.query(`
      SELECT t.team_id, t.team_name, h.hackathon_id, h.title AS hackathon_title 
      FROM teams t 
      JOIN team_members tm ON t.team_id = tm.team_id 
      JOIN hackathons h ON t.hackathon_id = h.hackathon_id
      WHERE tm.user_id = ? AND h.status != 'closed'
    `, [user_id]);
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Database error' });
  }
});

router.get('/student/history', requireRole('student'), async (req, res) => {
  const user_id = req.session.user.user_id;
  const pool = getPool('admin');
  try {
    const [rows] = await pool.query(`
      SELECT t.team_name, h.title AS hackathon_title, h.status 
      FROM teams t 
      JOIN team_members tm ON t.team_id = tm.team_id 
      JOIN hackathons h ON t.hackathon_id = h.hackathon_id
      WHERE tm.user_id = ? AND h.status != 'closed'
      ORDER BY h.start_date DESC
    `, [user_id]);
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Database error' });
  }
});

module.exports = router;
