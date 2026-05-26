CREATE USER IF NOT EXISTS 'pd_admin'@'localhost'   IDENTIFIED BY 'Admin@PD2025!';
GRANT ALL PRIVILEGES ON pitchdeck.* TO 'pd_admin'@'localhost';

CREATE USER IF NOT EXISTS 'pd_judge'@'localhost'   IDENTIFIED BY 'Judge@PD2025!';
GRANT SELECT  ON pitchdeck.vw_Leaderboard     TO 'pd_judge'@'localhost';
GRANT SELECT  ON pitchdeck.vw_TeamScoreDetail TO 'pd_judge'@'localhost';
GRANT SELECT  ON pitchdeck.submissions        TO 'pd_judge'@'localhost';
GRANT SELECT  ON pitchdeck.criteria           TO 'pd_judge'@'localhost';
GRANT SELECT  ON pitchdeck.judge_assignments  TO 'pd_judge'@'localhost';
GRANT EXECUTE ON pitchdeck.*                  TO 'pd_judge'@'localhost';

CREATE USER IF NOT EXISTS 'pd_student'@'localhost' IDENTIFIED BY 'Student@PD2025!';
GRANT SELECT  ON pitchdeck.vw_Leaderboard     TO 'pd_student'@'localhost';
GRANT SELECT  ON pitchdeck.submissions        TO 'pd_student'@'localhost';
GRANT EXECUTE ON pitchdeck.*                  TO 'pd_student'@'localhost';

FLUSH PRIVILEGES;
