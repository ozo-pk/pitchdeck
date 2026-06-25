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


router.get('/admin/users', requireRole('admin'), async (req, res) => {
  const pool = getPool('admin');
  try {
    const [rows] = await pool.query(`
      SELECT u.user_id, u.full_name, u.email, u.role, u.created_at, u.is_active,
             GROUP_CONCAT(DISTINCT IF(h.status != 'closed', CONCAT(t.team_name, ' (', h.title, ')'), NULL) SEPARATOR ', ') AS teams
      FROM users u
      LEFT JOIN team_members tm ON u.user_id = tm.user_id
      LEFT JOIN teams t ON tm.team_id = t.team_id
      LEFT JOIN hackathons h ON t.hackathon_id = h.hackathon_id
      GROUP BY u.user_id, u.full_name, u.email, u.role, u.created_at, u.is_active
      ORDER BY u.role, u.full_name
    `);
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Database error' });
  }
});

router.post('/admin/create-hackathon', requireRole('admin'), async (req, res) => {
  const { title, start_date, end_date } = req.body;
  const admin_id = req.session.user.user_id;
  const pool = getPool('admin');
  
  try {
    const submission_ddl = `${end_date} 00:00:00`; 
    const [result] = await pool.query(
      'INSERT INTO hackathons (title, start_date, end_date, submission_ddl, status, created_by) VALUES (?, ?, ?, ?, ?, ?)',
      [title, start_date, end_date, submission_ddl, 'open', admin_id]
    );
    const newHackathonId = result.insertId;

    // Automatically create 3 standard scoring criteria
    await pool.query(`
      INSERT INTO criteria (hackathon_id, name, description, max_score, weight) VALUES
      (?, 'Innovation & Uniqueness', 'Does the project introduce a novel approach or idea?', 10.00, 0.33),
      (?, 'Problem Solving & Practicality', 'Does the project effectively solve the stated problem? Is it usable in the real world?', 10.00, 0.33),
      (?, 'Technical Execution', 'Is the codebase robust, well-architected, and fully functional?', 10.00, 0.34)
    `, [newHackathonId, newHackathonId, newHackathonId]);

    res.json({ status: 'Success', hackathon_id: newHackathonId });
  } catch (err) {
    console.error('Hackathon creation failed:', err.message);
    res.status(500).json({ error: err.message });
  }
});

router.get('/admin/fix-sp', requireRole('admin'), async (req, res) => {
  const pool = getPool('admin');
  try {
    await pool.query(`DROP PROCEDURE IF EXISTS sp_RegisterTeam`);
    await pool.query(`
      CREATE PROCEDURE sp_RegisterTeam(
          IN p_hackathon_id INT,
          IN p_team_name VARCHAR(100),
          IN p_leader_id INT,
          OUT p_team_id INT,
          OUT p_status VARCHAR(255)
      )
      BEGIN
          DECLARE v_status ENUM('draft', 'open', 'judging', 'closed');
          DECLARE EXIT HANDLER FOR SQLEXCEPTION
          BEGIN
              GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
              ROLLBACK;
              SET p_status = CONCAT('Error: ', @text);
          END;

          SELECT status INTO v_status FROM hackathons WHERE hackathon_id = p_hackathon_id;

          IF v_status IS NULL THEN
              SET p_status = 'Error: Hackathon ID does not exist.';
          ELSEIF v_status != 'open' THEN
              SET p_status = 'Error: Hackathon is not open for registration.';
          ELSE
              SELECT COUNT(*) INTO @existing_team 
              FROM team_members tm 
              JOIN teams t ON tm.team_id = t.team_id 
              WHERE t.hackathon_id = p_hackathon_id AND tm.user_id = p_leader_id;

              IF @existing_team > 0 THEN
                  SET p_status = 'Error: You are already registered for a team in this Hackathon.';
              ELSE
                  START TRANSACTION;
                  INSERT INTO teams (hackathon_id, team_name) VALUES (p_hackathon_id, p_team_name);
                  SET p_team_id = LAST_INSERT_ID();
                  INSERT INTO team_members (team_id, user_id) VALUES (p_team_id, p_leader_id);
                  COMMIT;
                  SET p_status = 'Success';
              END IF;
          END IF;
      END
    `);
    res.json({ status: 'SP Updated' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

router.get('/admin/sync-judges', requireRole('admin'), async (req, res) => {
  const pool = getPool('admin');
  try {
    await pool.query(`
      INSERT IGNORE INTO judge_assignments (judge_id, hackathon_id)
      SELECT u.user_id, h.hackathon_id 
      FROM users u 
      CROSS JOIN hackathons h 
      WHERE u.role = 'judge' AND u.is_active = 1
    `);
    res.json({ status: 'Judges synchronized with all hackathons.' });
  } catch (err) {
    console.error('Judge sync failed:', err.message);
    res.status(500).json({ error: err.message });
  }
});

router.get('/admin/judges-list', requireRole('admin'), async (req, res) => {
  const pool = getPool('admin');
  try {
    const [rows] = await pool.query('SELECT user_id, full_name, email FROM users WHERE role = "judge" AND is_active = 1');
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Database error' });
  }
});

router.post('/admin/assign-judge', requireRole('admin'), async (req, res) => {
  const { hackathon_id, judge_id } = req.body;
  const pool = getPool('admin');
  try {
    // Prevent duplicate assignment gracefully
    await pool.query('INSERT IGNORE INTO judge_assignments (judge_id, hackathon_id) VALUES (?, ?)', [judge_id, hackathon_id]);
    res.json({ status: 'Success' });
  } catch (err) {
    console.error('Judge assignment failed:', err.message);
    res.status(500).json({ error: err.message });
  }
});

router.get('/admin/clean-and-sync-db', requireRole('admin'), async (req, res) => {
  const pool = getPool('admin');
  try {
    // 1. Delete dummy hackathons (ID 1 and 2)
    await pool.query('DELETE FROM hackathons WHERE hackathon_id IN (1, 2)');

    // 2. Find hackathons that have NO criteria assigned
    const [hackathonsWithoutCriteria] = await pool.query(`
      SELECT h.hackathon_id 
      FROM hackathons h
      LEFT JOIN criteria c ON h.hackathon_id = c.hackathon_id
      GROUP BY h.hackathon_id
      HAVING COUNT(c.criterion_id) = 0
    `);

    // 3. Inject standard criteria into those hackathons
    for (const h of hackathonsWithoutCriteria) {
      await pool.query(`
        INSERT INTO criteria (hackathon_id, name, description, max_score, weight) VALUES
        (?, 'Innovation & Uniqueness', 'Does the project introduce a novel approach or idea?', 10.00, 0.33),
        (?, 'Problem Solving & Practicality', 'Does the project effectively solve the stated problem? Is it usable in the real world?', 10.00, 0.33),
        (?, 'Technical Execution', 'Is the codebase robust, well-architected, and fully functional?', 10.00, 0.34)
      `, [h.hackathon_id, h.hackathon_id, h.hackathon_id]);
    }

    res.json({ status: 'Dummy data purged and criteria synced successfully.' });
  } catch (err) {
    console.error('Clean DB failed:', err.message);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
