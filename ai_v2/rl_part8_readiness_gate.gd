class_name TheodoreRLV2Part8ReadinessGate
extends RefCounted

const REQUIRED_MATCHES_PER_SIZE: int = 100
const REQUIRED_MIXED_MATCHES_PER_SIZE: int = 10


static func evaluate(tournament: Dictionary, mixed_human: Dictionary) -> Dictionary:
	var reasons: Array[String] = []
	var evidence_complete: bool = true
	var quality_passed: bool = true
	for team_size in [1, 2, 3, 4]:
		var key: String = "%dv%d" % [team_size, team_size]
		var metrics: Dictionary = tournament.get(key, {}) as Dictionary
		var requested: int = int(metrics.get("requested_matches", 0))
		var completed: int = int(metrics.get("completed_matches", 0))
		if requested < REQUIRED_MATCHES_PER_SIZE or completed != requested:
			evidence_complete = false
			reasons.append("%s_requires_%d_complete_matches" % [key, REQUIRED_MATCHES_PER_SIZE])
		var sides: Dictionary = metrics.get("sides", {}) as Dictionary
		var expected_side_matches: int = floori(float(completed) * 0.5)
		if int((sides.get("blue", {}) as Dictionary).get("completed_matches", 0)) != expected_side_matches:
			evidence_complete = false
			reasons.append("%s_blue_side_balance_missing" % key)
		if int((sides.get("red", {}) as Dictionary).get("completed_matches", 0)) != expected_side_matches:
			evidence_complete = false
			reasons.append("%s_red_side_balance_missing" % key)
		var coverage: Dictionary = metrics.get("scenario_coverage", {}) as Dictionary
		if int(coverage.get("formations", 0)) < 6 or int(coverage.get("field_variants", 0)) < 5 or int(coverage.get("abilities", 0)) < 12 or int(coverage.get("score_states", 0)) < 3 or int(coverage.get("opponent_profiles", 0)) < 6:
			evidence_complete = false
			reasons.append("%s_scenario_coverage_incomplete" % key)
		if int(metrics.get("candidate_goals", 0)) < int(metrics.get("current_ai_goals", 0)):
			quality_passed = false
			reasons.append("%s_negative_goal_difference" % key)
		var candidate: Dictionary = metrics.get("candidate", {}) as Dictionary
		var current_ai: Dictionary = metrics.get("current_ai", {}) as Dictionary
		if float(candidate.get("double_commit_rate", 1.0)) > float(current_ai.get("double_commit_rate", 0.0)) * 1.2 + 0.01:
			quality_passed = false
			reasons.append("%s_double_commit_regression" % key)
		if int(candidate.get("own_goals", 0)) > int(current_ai.get("own_goals", 0)):
			quality_passed = false
			reasons.append("%s_own_goal_regression" % key)
		if int(candidate.get("kickoff_mistakes", 0)) > int(current_ai.get("kickoff_mistakes", 0)):
			quality_passed = false
			reasons.append("%s_kickoff_regression" % key)
		if float(candidate.get("possession_loss_rate", 1.0)) > float(current_ai.get("possession_loss_rate", 0.0)) * 1.15 + 0.05:
			quality_passed = false
			reasons.append("%s_possession_safety_regression" % key)
		if int(candidate.get("shots", 0)) <= 0 or int(candidate.get("ability_uses", 0)) <= 0:
			quality_passed = false
			reasons.append("%s_missing_action_evidence" % key)
	for team_size in [2, 3, 4]:
		var key: String = "%dv%d" % [team_size, team_size]
		var metrics: Dictionary = mixed_human.get(key, {}) as Dictionary
		var requested: int = int(metrics.get("requested_matches", 0))
		var completed: int = int(metrics.get("completed_matches", 0))
		if requested < REQUIRED_MIXED_MATCHES_PER_SIZE or completed != requested or int(metrics.get("human_teammate_count", 0)) != 1:
			evidence_complete = false
			reasons.append("%s_mixed_human_evidence_incomplete" % key)
	return {
		"ready_for_runtime_trial": evidence_complete and quality_passed,
		"promotion_performed": false,
		"evidence_complete": evidence_complete,
		"quality_passed": quality_passed,
		"required_matches_per_size": REQUIRED_MATCHES_PER_SIZE,
		"required_mixed_matches_per_size": REQUIRED_MIXED_MATCHES_PER_SIZE,
		"reasons": reasons
	}
