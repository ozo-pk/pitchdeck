USE pitchdeck;

-- Hash for 'password123': $2a$10$CwTycUXWue0Thq9StjUM0u1KVK7iK.2D/w/N./Jg8W4/B4Q7G9uOC

-- 3 users per role
INSERT INTO users (full_name, email, password_hash, role) VALUES
('Admin One', 'admin1@pitchdeck.com', '$2a$10$CwTycUXWue0Thq9StjUM0u1KVK7iK.2D/w/N./Jg8W4/B4Q7G9uOC', 'admin'),
('Admin Two', 'admin2@pitchdeck.com', '$2a$10$CwTycUXWue0Thq9StjUM0u1KVK7iK.2D/w/N./Jg8W4/B4Q7G9uOC', 'admin'),
('Admin Three', 'admin3@pitchdeck.com', '$2a$10$CwTycUXWue0Thq9StjUM0u1KVK7iK.2D/w/N./Jg8W4/B4Q7G9uOC', 'admin'),
('Judge One', 'judge1@pitchdeck.com', '$2a$10$CwTycUXWue0Thq9StjUM0u1KVK7iK.2D/w/N./Jg8W4/B4Q7G9uOC', 'judge'),
('Judge Two', 'judge2@pitchdeck.com', '$2a$10$CwTycUXWue0Thq9StjUM0u1KVK7iK.2D/w/N./Jg8W4/B4Q7G9uOC', 'judge'),
('Judge Three', 'judge3@pitchdeck.com', '$2a$10$CwTycUXWue0Thq9StjUM0u1KVK7iK.2D/w/N./Jg8W4/B4Q7G9uOC', 'judge'),
('Student One', 'student1@pitchdeck.com', '$2a$10$CwTycUXWue0Thq9StjUM0u1KVK7iK.2D/w/N./Jg8W4/B4Q7G9uOC', 'student'),
('Student Two', 'student2@pitchdeck.com', '$2a$10$CwTycUXWue0Thq9StjUM0u1KVK7iK.2D/w/N./Jg8W4/B4Q7G9uOC', 'student'),
('Student Three', 'student3@pitchdeck.com', '$2a$10$CwTycUXWue0Thq9StjUM0u1KVK7iK.2D/w/N./Jg8W4/B4Q7G9uOC', 'student');

-- 2 hackathons (1 judging, 1 closed)
INSERT INTO hackathons (title, description, start_date, end_date, submission_ddl, status, created_by) VALUES
('Global AI Hackathon 2025', 'Build the future of AI', '2025-06-01', '2025-06-03', '2025-06-03 12:00:00', 'judging', 1),
('Web3 Innovators', 'Decentralized apps', '2025-01-01', '2025-01-03', '2025-01-03 12:00:00', 'closed', 1);

-- 4 criteria per hackathon (weights sum to 1.0)
INSERT INTO criteria (hackathon_id, name, max_score, weight) VALUES
(1, 'Innovation', 10, 0.30),
(1, 'Technical Complexity', 10, 0.30),
(1, 'UI/UX', 10, 0.20),
(1, 'Business Value', 10, 0.20),
(2, 'Innovation', 10, 0.30),
(2, 'Smart Contract Sec', 10, 0.30),
(2, 'Decentralization', 10, 0.20),
(2, 'Usability', 10, 0.20);

-- 8 teams
INSERT INTO teams (hackathon_id, team_name) VALUES
(1, 'Team Alpha'), (1, 'Team Beta'), (1, 'Team Gamma'), (1, 'Team Delta'),
(2, 'Team Epsilon'), (2, 'Team Zeta'), (2, 'Team Eta'), (2, 'Team Theta');

-- 8 submissions
INSERT INTO submissions (team_id, hackathon_id, title, description, is_late) VALUES
(1, 1, 'AI Project Alpha', 'Description A', 0),
(2, 1, 'AI Project Beta', 'Description B', 0),
(3, 1, 'AI Project Gamma', 'Description G', 1), -- Late
(4, 1, 'AI Project Delta', 'Description D', 0),
(5, 2, 'Web3 Project E', 'Description E', 0),
(6, 2, 'Web3 Project Z', 'Description Z', 0),
(7, 2, 'Web3 Project H', 'Description H', 0),
(8, 2, 'Web3 Project T', 'Description T', 0);

-- Score Aggregates placeholders
INSERT INTO score_aggregates (sub_id) VALUES (1), (2), (3), (4), (5), (6), (7), (8);

-- 3 judge assignments per hackathon
INSERT INTO judge_assignments (judge_id, hackathon_id) VALUES
(4, 1), (5, 1), (6, 1),
(4, 2), (5, 2), (6, 2);

-- Conflict of interest
INSERT INTO conflict_of_interest (judge_id, team_id, reason) VALUES
(4, 1, 'Mentored team previously'),
(5, 5, 'Knows team member');

-- Evaluations for Hackathon 1 (Open for Judging)
-- We will simulate scores directly. Triggers should run on these inserts.
-- Trigger won't work in a bulk insert if not careful, but the trigger is set up FOR EACH ROW, so it should fire.
INSERT INTO evaluations (assignment_id, sub_id, criterion_id, score, comments) VALUES
-- Judge 4 scores Team 2 (Sub 2)
(1, 2, 1, 9, 'Great'), (1, 2, 2, 8, 'Good'), (1, 2, 3, 9, 'Nice'), (1, 2, 4, 8, 'Decent'),
-- Judge 5 scores Team 1 (Sub 1)
(2, 1, 1, 10, 'Perfect'), (2, 1, 2, 9, 'Awesome'), (2, 1, 3, 8, 'Good'), (2, 1, 4, 9, 'Solid');

-- Since we are directly inserting and triggers fire, score_aggregates will be populated automatically!
