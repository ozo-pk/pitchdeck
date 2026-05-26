USE pitchdeck;

DELIMITER //

-- SP 1: Register Team
CREATE PROCEDURE sp_RegisterTeam(
    IN p_hackathon_id INT,
    IN p_team_name VARCHAR(100),
    IN p_leader_id INT,
    OUT p_team_id INT,
    OUT p_status VARCHAR(100)
)
BEGIN
    DECLARE v_status ENUM('draft', 'open', 'judging', 'closed');
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status = 'Error: Registration failed due to database exception.';
    END;

    SELECT status INTO v_status FROM hackathons WHERE hackathon_id = p_hackathon_id;

    IF v_status != 'open' THEN
        SET p_status = 'Error: Hackathon is not open for registration.';
    ELSE
        START TRANSACTION;
        INSERT INTO teams (hackathon_id, team_name) VALUES (p_hackathon_id, p_team_name);
        SET p_team_id = LAST_INSERT_ID();
        INSERT INTO team_members (team_id, user_id) VALUES (p_team_id, p_leader_id);
        COMMIT;
        SET p_status = 'Success';
    END IF;
END //

-- SP 2: Submit Project
CREATE PROCEDURE sp_SubmitProject(
    IN p_team_id INT,
    IN p_hackathon_id INT,
    IN p_title VARCHAR(200),
    IN p_description TEXT,
    IN p_github_url VARCHAR(500),
    IN p_demo_url VARCHAR(500),
    OUT p_sub_id INT,
    OUT p_status VARCHAR(100)
)
BEGIN
    DECLARE v_ddl DATETIME;
    DECLARE v_is_late TINYINT(1) DEFAULT 0;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status = 'Error: Submission failed due to database exception.';
    END;

    SELECT submission_ddl INTO v_ddl FROM hackathons WHERE hackathon_id = p_hackathon_id;

    IF NOW() > v_ddl THEN
        SET v_is_late = 1;
    END IF;

    START TRANSACTION;
    INSERT INTO submissions (team_id, hackathon_id, title, description, github_url, demo_url, is_late)
    VALUES (p_team_id, p_hackathon_id, p_title, p_description, p_github_url, p_demo_url, v_is_late);
    
    SET p_sub_id = LAST_INSERT_ID();
    
    INSERT INTO score_aggregates (sub_id) VALUES (p_sub_id);
    
    COMMIT;
    SET p_status = 'Success';
END //

-- SP 3: Submit Score
CREATE PROCEDURE sp_SubmitScore(
    IN p_assignment_id INT,
    IN p_sub_id INT,
    IN p_criterion_id INT,
    IN p_score DECIMAL(5,2),
    IN p_comments TEXT,
    OUT p_status VARCHAR(100)
)
BEGIN
    DECLARE v_max_score DECIMAL(5,2);
    DECLARE v_judge_id INT;
    DECLARE v_team_id INT;
    DECLARE v_hackathon_status ENUM('draft', 'open', 'judging', 'closed');
    DECLARE v_coi_count INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status = 'Error: Scoring failed due to database exception.';
    END;

    -- Get hackathon status and max score
    SELECT c.max_score, h.status 
    INTO v_max_score, v_hackathon_status
    FROM criteria c
    JOIN hackathons h ON c.hackathon_id = h.hackathon_id
    WHERE c.criterion_id = p_criterion_id;

    IF v_hackathon_status != 'judging' THEN
        SET p_status = 'Error: Hackathon is not in judging phase.';
    ELSEIF p_score < 0 OR p_score > v_max_score THEN
        SET p_status = 'Error: Score is out of bounds.';
    ELSE
        -- Check Conflict of Interest
        SELECT judge_id INTO v_judge_id FROM judge_assignments WHERE assignment_id = p_assignment_id;
        SELECT team_id INTO v_team_id FROM submissions WHERE sub_id = p_sub_id;
        
        SELECT COUNT(*) INTO v_coi_count 
        FROM conflict_of_interest 
        WHERE judge_id = v_judge_id AND team_id = v_team_id;
        
        IF v_coi_count > 0 THEN
            SET p_status = 'Error: Conflict of interest flagged for this team.';
        ELSE
            START TRANSACTION;
            INSERT INTO evaluations (assignment_id, sub_id, criterion_id, score, comments)
            VALUES (p_assignment_id, p_sub_id, p_criterion_id, p_score, p_comments)
            ON DUPLICATE KEY UPDATE 
                score = VALUES(score), 
                comments = VALUES(comments);
            -- Trigger 1 (trg_AfterEvalInsert) or Trigger 2 (trg_AfterEvalUpdate) will auto-fire
            COMMIT;
            SET p_status = 'Success';
        END IF;
    END IF;
END //

-- SP 4: Close Hackathon
CREATE PROCEDURE sp_CloseHackathon(
    IN p_hackathon_id INT,
    IN p_admin_id INT,
    OUT p_status VARCHAR(100)
)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_sub_id INT;
    DECLARE v_total_raw DECIMAL(8,2);
    DECLARE v_weighted_total DECIMAL(8,4);
    
    DECLARE cur CURSOR FOR SELECT sub_id FROM submissions WHERE hackathon_id = p_hackathon_id;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_status = 'Error: Closing failed due to database exception.';
    END;

    START TRANSACTION;
    UPDATE hackathons SET status = 'closed' WHERE hackathon_id = p_hackathon_id;

    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO v_sub_id;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        SELECT total_raw, weighted_total INTO v_total_raw, v_weighted_total 
        FROM score_aggregates WHERE sub_id = v_sub_id;
        
        INSERT INTO audit_log (user_id, action, table_name, record_id, new_value)
        VALUES (
            p_admin_id, 
            'UPDATE', 
            'submissions', 
            v_sub_id, 
            JSON_OBJECT('final_total_raw', v_total_raw, 'final_weighted_total', v_weighted_total)
        );
    END LOOP;
    CLOSE cur;
    
    COMMIT;
    SET p_status = 'Success';
END //

DELIMITER ;
