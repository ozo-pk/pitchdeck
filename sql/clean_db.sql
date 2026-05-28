-- 1. Delete the dummy seed hackathons (IDs 1 and 2). 
-- This will cascade and automatically delete their dummy teams and submissions.
DELETE FROM hackathons WHERE hackathon_id IN (1, 2);

-- 2. Inject the 3 new standard criteria into ANY existing hackathon that currently has 0 criteria.
INSERT INTO criteria (hackathon_id, name, description, max_score, weight)
SELECT h.hackathon_id, v.name, v.description, v.max_score, v.weight
FROM hackathons h
LEFT JOIN criteria c ON h.hackathon_id = c.hackathon_id
CROSS JOIN (
    SELECT 'Innovation & Uniqueness' AS name, 'Does the project introduce a novel approach or idea?' AS description, 10.00 AS max_score, 0.33 AS weight
    UNION ALL
    SELECT 'Problem Solving & Practicality', 'Does the project effectively solve the stated problem? Is it usable in the real world?', 10.00, 0.33
    UNION ALL
    SELECT 'Technical Execution', 'Is the codebase robust, well-architected, and fully functional?', 10.00, 0.34
) v
GROUP BY h.hackathon_id, v.name, v.description, v.max_score, v.weight
HAVING COUNT(c.criterion_id) = 0;
