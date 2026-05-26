const express = require('express');
const router = express.Router();
const { getPool, callSP } = require('../db/connection');
const { requireRole } = require('../middleware/auth');

router.post('/admin/close-hackathon', requireRole('admin'), async (req, res) => {
  const { hackathon_id } = req.body;
  const admin_id = req.session.user.user_id;
  const pool = getPool('admin');

  try {
    const result = await callSP(pool, 'sp_CloseHackathon', 
      [hackathon_id, admin_id], 
      ['@p_status']
    );
    res.json({ status: result['@p_status'] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Database error' });
  }
});

router.get('/admin/audit', requireRole('admin'), async (req, res) => {
  const pool = getPool('admin');
  try {
    const [rows] = await pool.query('SELECT * FROM vw_AuditReport LIMIT 200');
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Database error' });
  }
});

router.get('/judge/progress', requireRole('admin'), async (req, res) => {
  const pool = getPool('admin');
  try {
    const [rows] = await pool.query('SELECT * FROM vw_JudgeProgress');
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Database error' });
  }
});

module.exports = router;
