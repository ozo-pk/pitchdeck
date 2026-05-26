const mysql = require('mysql2/promise');
require('dotenv').config();

const pools = {
  admin: mysql.createPool({
    host: process.env.DB_HOST, database: process.env.DB_NAME,
    user: process.env.DB_ADMIN_USER, password: process.env.DB_ADMIN_PASS,
    waitForConnections: true, connectionLimit: 10
  }),
  judge: mysql.createPool({
    host: process.env.DB_HOST, database: process.env.DB_NAME,
    user: process.env.DB_JUDGE_USER, password: process.env.DB_JUDGE_PASS,
    connectionLimit: 10
  }),
  student: mysql.createPool({
    host: process.env.DB_HOST, database: process.env.DB_NAME,
    user: process.env.DB_STUDENT_USER, password: process.env.DB_STUDENT_PASS,
    connectionLimit: 10
  })
};

// Returns the pool matching the logged-in user's role
function getPool(role) {
  return pools[role] || pools.student;
}

// mysql2 requires a session variable workaround for OUT parameters
async function callSP(pool, spCall, inParams, outParams) {
  const conn = await pool.getConnection();
  try {
    // Set OUT vars to null first
    if (outParams && outParams.length > 0) {
      await conn.query(`SET ${outParams.map(p => `${p} = NULL`).join(', ')}`);
    }
    
    await conn.query(`CALL ${spCall}(${inParams.map(() => '?').join(', ')}, ${outParams.join(', ')})`, inParams);
    
    if (outParams && outParams.length > 0) {
      const [rows] = await conn.query(`SELECT ${outParams.join(', ')}`);
      return rows[0];
    }
    return null;
  } finally {
    conn.release();
  }
}

module.exports = { getPool, callSP };
