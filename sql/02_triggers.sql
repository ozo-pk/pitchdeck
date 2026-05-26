USE pitchdeck;

DELIMITER //

-- Trigger 1: After Evaluation Insert
CREATE TRIGGER trg_AfterEvalInsert
AFTER INSERT ON evaluations
FOR EACH ROW
BEGIN
    INSERT INTO score_aggregates (sub_id, total_raw, weighted_total, judge_count)
    SELECT 
        NEW.sub_id,
        COALESCE(SUM(e.score), 0) AS total_raw,
        COALESCE(SUM((e.score / c.max_score) * c.weight), 0) AS weighted_total,
        COUNT(DISTINCT e.assignment_id) AS judge_count
    FROM evaluations e
    JOIN criteria c ON e.criterion_id = c.criterion_id
    WHERE e.sub_id = NEW.sub_id
    ON DUPLICATE KEY UPDATE
        total_raw = VALUES(total_raw),
        weighted_total = VALUES(weighted_total),
        judge_count = VALUES(judge_count);
END //

-- Trigger 2: After Evaluation Update
CREATE TRIGGER trg_AfterEvalUpdate
AFTER UPDATE ON evaluations
FOR EACH ROW
BEGIN
    INSERT INTO score_aggregates (sub_id, total_raw, weighted_total, judge_count)
    SELECT 
        NEW.sub_id,
        COALESCE(SUM(e.score), 0) AS total_raw,
        COALESCE(SUM((e.score / c.max_score) * c.weight), 0) AS weighted_total,
        COUNT(DISTINCT e.assignment_id) AS judge_count
    FROM evaluations e
    JOIN criteria c ON e.criterion_id = c.criterion_id
    WHERE e.sub_id = NEW.sub_id
    ON DUPLICATE KEY UPDATE
        total_raw = VALUES(total_raw),
        weighted_total = VALUES(weighted_total),
        judge_count = VALUES(judge_count);
END //

-- Trigger 3: Audit User Update
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
