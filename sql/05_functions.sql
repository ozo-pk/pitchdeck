USE pitchdeck;

DELIMITER //

-- Function 1: Grade Label
CREATE FUNCTION fn_GradeLabel(p_score DECIMAL(8,4), p_max DECIMAL(5,2)) 
RETURNS VARCHAR(2) 
DETERMINISTIC
BEGIN
    DECLARE v_percent DECIMAL(5,2);
    IF p_max = 0 THEN
        RETURN 'N/A';
    END IF;
    
    SET v_percent = (p_score / p_max) * 100;
    
    IF v_percent >= 90 THEN RETURN 'A+';
    ELSEIF v_percent >= 80 THEN RETURN 'A';
    ELSEIF v_percent >= 70 THEN RETURN 'B+';
    ELSEIF v_percent >= 60 THEN RETURN 'B';
    ELSEIF v_percent >= 50 THEN RETURN 'C';
    ELSE RETURN 'F';
    END IF;
END //

-- Function 2: Is On Time
CREATE FUNCTION fn_IsOnTime(p_hackathon_id INT, p_submitted_at DATETIME) 
RETURNS TINYINT(1) 
READS SQL DATA
BEGIN
    DECLARE v_ddl DATETIME;
    SELECT submission_ddl INTO v_ddl FROM hackathons WHERE hackathon_id = p_hackathon_id;
    
    IF p_submitted_at <= v_ddl THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;
END //

DELIMITER ;
