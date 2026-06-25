USE pitchdeck;

CREATE INDEX idx_sub_hackathon  ON submissions(hackathon_id);
CREATE INDEX idx_agg_weighted   ON score_aggregates(weighted_total DESC);
CREATE INDEX idx_eval_sub       ON evaluations(sub_id);
CREATE INDEX idx_eval_criterion ON evaluations(criterion_id);
CREATE INDEX idx_ja_judge       ON judge_assignments(judge_id);
CREATE INDEX idx_ja_hackathon   ON judge_assignments(hackathon_id);

