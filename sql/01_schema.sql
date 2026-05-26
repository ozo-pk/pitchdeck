CREATE DATABASE IF NOT EXISTS pitchdeck CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE pitchdeck;

CREATE TABLE users (
    user_id       INT          NOT NULL AUTO_INCREMENT,
    full_name     VARCHAR(100) NOT NULL,
    email         VARCHAR(150) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role          ENUM('admin','judge','student') NOT NULL DEFAULT 'student',
    is_active     TINYINT(1)   NOT NULL DEFAULT 1,
    created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_users  PRIMARY KEY (user_id),
    CONSTRAINT uq_email  UNIQUE (email),
    CONSTRAINT chk_email CHECK (email LIKE '%@%.%')
);

CREATE TABLE hackathons (
    hackathon_id   INT          NOT NULL AUTO_INCREMENT,
    title          VARCHAR(200) NOT NULL,
    description    TEXT,
    start_date     DATE         NOT NULL,
    end_date       DATE         NOT NULL,
    submission_ddl DATETIME     NOT NULL,
    status         ENUM('draft','open','judging','closed') NOT NULL DEFAULT 'draft',
    created_by     INT          NOT NULL,
    CONSTRAINT pk_hackathons    PRIMARY KEY (hackathon_id),
    CONSTRAINT fk_hk_created_by FOREIGN KEY (created_by) REFERENCES users(user_id) ON DELETE RESTRICT,
    CONSTRAINT chk_dates        CHECK (end_date > start_date),
    CONSTRAINT chk_ddl          CHECK (submission_ddl <= end_date)
);

CREATE TABLE criteria (
    criterion_id INT           NOT NULL AUTO_INCREMENT,
    hackathon_id INT           NOT NULL,
    name         VARCHAR(100)  NOT NULL,
    description  TEXT,
    max_score    DECIMAL(5,2)  NOT NULL,
    weight       DECIMAL(5,4)  NOT NULL DEFAULT 1.0000,
    CONSTRAINT pk_criteria       PRIMARY KEY (criterion_id),
    CONSTRAINT fk_crit_hackathon FOREIGN KEY (hackathon_id) REFERENCES hackathons(hackathon_id) ON DELETE CASCADE,
    CONSTRAINT chk_max_score     CHECK (max_score > 0),
    CONSTRAINT chk_weight        CHECK (weight > 0 AND weight <= 1)
);

CREATE TABLE teams (
    team_id      INT          NOT NULL AUTO_INCREMENT,
    hackathon_id INT          NOT NULL,
    team_name    VARCHAR(100) NOT NULL,
    created_at   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_teams          PRIMARY KEY (team_id),
    CONSTRAINT fk_team_hackathon FOREIGN KEY (hackathon_id) REFERENCES hackathons(hackathon_id) ON DELETE CASCADE,
    CONSTRAINT uq_team_name      UNIQUE (hackathon_id, team_name)
);

CREATE TABLE team_members (
    team_id   INT       NOT NULL,
    user_id   INT       NOT NULL,
    joined_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_team_members PRIMARY KEY (team_id, user_id),
    CONSTRAINT fk_tm_team      FOREIGN KEY (team_id) REFERENCES teams(team_id) ON DELETE CASCADE,
    CONSTRAINT fk_tm_user      FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE TABLE submissions (
    sub_id       INT          NOT NULL AUTO_INCREMENT,
    team_id      INT          NOT NULL,
    hackathon_id INT          NOT NULL,
    title        VARCHAR(200) NOT NULL,
    description  TEXT,
    github_url   VARCHAR(500),
    demo_url     VARCHAR(500),
    submitted_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_late      TINYINT(1)   NOT NULL DEFAULT 0,
    CONSTRAINT pk_submissions   PRIMARY KEY (sub_id),
    CONSTRAINT fk_sub_team      FOREIGN KEY (team_id) REFERENCES teams(team_id) ON DELETE CASCADE,
    CONSTRAINT fk_sub_hackathon FOREIGN KEY (hackathon_id) REFERENCES hackathons(hackathon_id) ON DELETE CASCADE,
    CONSTRAINT uq_one_per_team  UNIQUE (team_id, hackathon_id)
);

CREATE TABLE judge_assignments (
    assignment_id INT       NOT NULL AUTO_INCREMENT,
    judge_id      INT       NOT NULL,
    hackathon_id  INT       NOT NULL,
    assigned_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_judge_assign PRIMARY KEY (assignment_id),
    CONSTRAINT uq_judge_hk     UNIQUE (judge_id, hackathon_id),
    CONSTRAINT fk_ja_judge     FOREIGN KEY (judge_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_ja_hackathon FOREIGN KEY (hackathon_id) REFERENCES hackathons(hackathon_id) ON DELETE CASCADE
);

CREATE TABLE evaluations (
    eval_id       INT          NOT NULL AUTO_INCREMENT,
    assignment_id INT          NOT NULL,
    sub_id        INT          NOT NULL,
    criterion_id  INT          NOT NULL,
    score         DECIMAL(5,2) NOT NULL,
    comments      TEXT,
    evaluated_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_evaluations    PRIMARY KEY (eval_id),
    CONSTRAINT uq_one_score      UNIQUE (assignment_id, sub_id, criterion_id),
    CONSTRAINT fk_eval_assign    FOREIGN KEY (assignment_id) REFERENCES judge_assignments(assignment_id) ON DELETE CASCADE,
    CONSTRAINT fk_eval_sub       FOREIGN KEY (sub_id) REFERENCES submissions(sub_id) ON DELETE CASCADE,
    CONSTRAINT fk_eval_criterion FOREIGN KEY (criterion_id) REFERENCES criteria(criterion_id) ON DELETE CASCADE,
    CONSTRAINT chk_score_min     CHECK (score >= 0)
);

-- Maintained ONLY by triggers. Express never writes here directly.
CREATE TABLE score_aggregates (
    sub_id         INT          NOT NULL,
    total_raw      DECIMAL(8,2) NOT NULL DEFAULT 0.00,
    weighted_total DECIMAL(8,4) NOT NULL DEFAULT 0.0000,
    judge_count    INT          NOT NULL DEFAULT 0,
    last_updated   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_score_agg PRIMARY KEY (sub_id),
    CONSTRAINT fk_agg_sub   FOREIGN KEY (sub_id) REFERENCES submissions(sub_id) ON DELETE CASCADE
);

-- Maintained ONLY by triggers. Express never writes here directly.
CREATE TABLE audit_log (
    log_id       BIGINT      NOT NULL AUTO_INCREMENT,
    user_id      INT,
    action       ENUM('INSERT','UPDATE','DELETE') NOT NULL,
    table_name   VARCHAR(64) NOT NULL,
    record_id    INT         NOT NULL,
    old_value    JSON,
    new_value    JSON,
    performed_at TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_audit      PRIMARY KEY (log_id),
    CONSTRAINT fk_audit_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL
);

CREATE TABLE submission_files (
    file_id     INT          NOT NULL AUTO_INCREMENT,
    sub_id      INT          NOT NULL,
    file_name   VARCHAR(255) NOT NULL,
    file_type   ENUM('pdf','zip','image','video','other') NOT NULL,
    file_url    VARCHAR(500) NOT NULL,
    uploaded_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_sub_files PRIMARY KEY (file_id),
    CONSTRAINT fk_sf_sub    FOREIGN KEY (sub_id) REFERENCES submissions(sub_id) ON DELETE CASCADE
);

CREATE TABLE conflict_of_interest (
    conflict_id INT       NOT NULL AUTO_INCREMENT,
    judge_id    INT       NOT NULL,
    team_id     INT       NOT NULL,
    reason      TEXT,
    flagged_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_conflict  PRIMARY KEY (conflict_id),
    CONSTRAINT uq_conflict  UNIQUE (judge_id, team_id),
    CONSTRAINT fk_coi_judge FOREIGN KEY (judge_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_coi_team  FOREIGN KEY (team_id) REFERENCES teams(team_id) ON DELETE CASCADE
);
