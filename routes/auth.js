const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const { getPool } = require('../db/connection');

router.post('/auth/login', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) return res.status(400).json({ error: 'Email and password required' });

  try {
    // Authentication needs access to the users table.
    // The admin pool has the necessary SELECT privileges to verify users.
    const pool = getPool('admin'); 
    const [rows] = await pool.query('SELECT user_id, full_name, role, password_hash FROM users WHERE email = ? AND is_active = 1', [email]);
    
    if (rows.length === 0) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const user = rows[0];
    const match = await bcrypt.compare(password, user.password_hash);
    
    if (!match) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    req.session.user = {
      user_id: user.user_id,
      full_name: user.full_name,
      role: user.role
    };

    res.json({ role: user.role, full_name: user.full_name });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.post('/auth/logout', (req, res) => {
  req.session.destroy(err => {
    if (err) return res.status(500).json({ error: 'Could not log out' });
    res.status(200).json({ message: 'Logged out successfully' });
  });
});

module.exports = router;
