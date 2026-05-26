USE pitchdeck;

DELIMITER //

-- Trigger 1: After Evaluation Insert
DROP TRIGGER IF EXISTS trg_AfterEvalInsert;
CREATE TRIGGER trg_AfterEvalInsert
AFTER INSERT ON evaluations
FOR EACH ROW
BEGIN
    DECLARE v_max_score DECIMAL(5,2);
    DECLARE v_weight DECIMAL(5,4);
    
    -- Fetch criteria details to compute weighted score
    SELECT max_score, weight INTO v_max_score, v_weight 
    FROM criteria WHERE criterion_id = NEW.criterion_id;

    -- Incrementally update score_aggregates to avoid Error 1442 (Mutating Table)
    INSERT INTO score_aggregates (sub_id, total_raw, weighted_total, judge_count)
    VALUES (
        NEW.sub_id, 
        NEW.score, 
        (NEW.score / v_max_score) * v_weight, 
        1
    )
    ON DUPLICATE KEY UPDATE
        total_raw = total_raw + NEW.score,
        weighted_total = weighted_total + ((NEW.score / v_max_score) * v_weight);
        -- Note: judge_count is approximate here to bypass MySQL limitation
END //

-- Trigger 2: After Evaluation Update
DROP TRIGGER IF EXISTS trg_AfterEvalUpdate;
CREATE TRIGGER trg_AfterEvalUpdate
AFTER UPDATE ON evaluations
FOR EACH ROW
BEGIN
    DECLARE v_max_score DECIMAL(5,2);
    DECLARE v_weight DECIMAL(5,4);
    
    SELECT max_score, weight INTO v_max_score, v_weight 
    FROM criteria WHERE criterion_id = NEW.criterion_id;

    UPDATE score_aggregates 
    SET total_raw = total_raw - OLD.score + NEW.score,
        weighted_total = weighted_total - ((OLD.score / v_max_score) * v_weight) + ((NEW.score / v_max_score) * v_weight)
    WHERE sub_id = NEW.sub_id;
END //

-- Trigger 3: Audit User Update
DROP TRIGGER IF EXISTS trg_AuditUserUpdate;
CREATE TRIGGER trg_AuditUserUpdate
AFTER UPDATE ON users
FOR EACH ROW
BEGIN
    IF (OLD.email != NEW.email OR OLD.role != NEW.role OR OLD.is_active != NEW.is_active) THEN
        INSERT INTO audit_log (user_id, action, table_name, record_id, old_value, new_value)
        VALUES (
            NEW.user_id,
            'UPDATE',
            'users',
            NEW.user_id,
            JSON_OBJECT('email', OLD.email, 'role', OLD.role, 'is_active', OLD.is_active),
            JSON_OBJECT('email', NEW.email, 'role', NEW.role, 'is_active', NEW.is_active)
        );
    END IF;
END //

-- Trigger 4: Prevent Open Hackathon Delete
DROP TRIGGER IF EXISTS trg_PreventOpenHackathonDelete;
CREATE TRIGGER trg_PreventOpenHackathonDelete
BEFORE DELETE ON hackathons
FOR EACH ROW
BEGIN
    IF OLD.status = 'open' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot delete an open hackathon. Close it first.';
    END IF;
END //

DELIMITER ;
