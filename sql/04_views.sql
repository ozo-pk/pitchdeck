USE pitchdeck;

-- View 1: Leaderboard
CREATE OR REPLACE VIEW vw_Leaderboard AS
SELECT 
    h.hackathon_id,
    h.title AS hackathon_title,
    t.team_name,
    s.title AS project_title,
    s.github_url,
    s.demo_url,
    sa.total_raw,
    sa.weighted_total,
    sa.judge_count,
    fn_GradeLabel(sa.weighted_total, 1.0) AS grade, -- Since weights sum to 1.0, max weighted score is 1.0. Wait, the function fn_GradeLabel expects raw score and max score. If weighted total max is 1.0 * max_score? No, wait: SUM((score/max_score)*weight). Max of score/max_score is 1. Weight sums to 1. So max weighted_total is 1.0. 
    RANK() OVER (PARTITION BY h.hackathon_id ORDER BY sa.weighted_total DESC) AS `rank`
FROM score_aggregates sa
JOIN submissions s ON sa.sub_id = s.sub_id
JOIN teams t ON s.team_id = t.team_id
JOIN hackathons h ON s.hackathon_id = h.hackathon_id;



-- View 3: Team Score Detail
CREATE OR REPLACE VIEW vw_TeamScoreDetail AS
SELECT 
    s.sub_id,
    t.team_name,
    c.criterion_id,
    c.name AS criterion_name,
    AVG(e.score) AS avg_score,
    c.max_score,
    c.weight,
    (AVG(e.score) / c.max_score) * 100 AS percentage,
    fn_GradeLabel(AVG(e.score), c.max_score) AS grade
FROM evaluations e
JOIN criteria c ON e.criterion_id = c.criterion_id
JOIN submissions s ON e.sub_id = s.sub_id
JOIN teams t ON s.team_id = t.team_id
JOIN hackathons h ON s.hackathon_id = h.hackathon_id
GROUP BY s.sub_id, c.criterion_id;


