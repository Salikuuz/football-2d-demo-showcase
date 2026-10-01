class_name TheodoreRLV2PromotionGate
extends RefCounted

const MINIMUM_MATCHES: int = 8
const MINIMUM_WIN_RATE: float = 0.55


static func evaluate(metrics: Dictionary) -> Dictionary:
	var requested: int = int(metrics.get("requested_matches", 0))
	var completed: int = int(metrics.get("completed_matches", 0))
	var wins: int = int(metrics.get("candidate_wins", 0))
	var goals_for: int = int(metrics.get("candidate_goals", 0))
	var goals_against: int = int(metrics.get("champion_goals", 0))
	var win_rate: float = float(wins) / float(maxi(1, completed))
	var reasons: Array[String] = []
	if requested < MINIMUM_MATCHES:
		reasons.append("minimum_eight_full_matches_required")
	if completed != requested:
		reasons.append("incomplete_full_game_evaluation")
	if win_rate < MINIMUM_WIN_RATE:
		reasons.append("candidate_win_rate_below_55_percent")
	if goals_for <= goals_against:
		reasons.append("candidate_did_not_win_goal_difference")
	return {
		"promoted": reasons.is_empty(),
		"win_rate": win_rate,
		"goal_difference": goals_for - goals_against,
		"reasons": reasons
	}
