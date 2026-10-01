class_name TheodoreRLV2LeaguePromotionGate
extends RefCounted

const MINIMUM_TOTAL_MATCHES: int = 14
const MINIMUM_OVERALL_WIN_RATE: float = 0.55
const MINIMUM_CURRENT_WIN_RATE: float = 0.50
const MINIMUM_CATEGORY_SCORE_RATE: float = 0.35


static func evaluate(report: Dictionary) -> Dictionary:
	var requested: int = int(report.get("requested_matches", 0))
	var completed: int = int(report.get("completed_matches", 0))
	var wins: int = int(report.get("candidate_wins", 0))
	var draws: int = int(report.get("draws", 0))
	var goals_for: int = int(report.get("candidate_goals", 0))
	var goals_against: int = int(report.get("opponent_goals", 0))
	var score_rate: float = (float(wins) + float(draws) * 0.5) / float(maxi(1, completed))
	var reasons: Array[String] = []
	if requested < MINIMUM_TOTAL_MATCHES:
		reasons.append("minimum_fourteen_league_matches_required")
	if completed != requested:
		reasons.append("incomplete_league_evaluation")
	if score_rate < MINIMUM_OVERALL_WIN_RATE:
		reasons.append("overall_league_score_rate_below_55_percent")
	if goals_for <= goals_against:
		reasons.append("candidate_did_not_win_league_goal_difference")
	var category_reports: Dictionary = report.get("categories", {}) as Dictionary
	for required_category in ["current", "specialist", "randomized"]:
		if not category_reports.has(required_category):
			reasons.append("missing_%s_opponents" % required_category)
			continue
		var category := category_reports[required_category] as Dictionary
		var category_completed: int = int(category.get("completed_matches", 0))
		var category_score: float = (
			float(category.get("candidate_wins", 0))
			+ float(category.get("draws", 0)) * 0.5
		) / float(maxi(1, category_completed))
		if required_category == "current" and category_score < MINIMUM_CURRENT_WIN_RATE:
			reasons.append("candidate_did_not_hold_even_against_current_champion")
		elif required_category != "current" and category_score < MINIMUM_CATEGORY_SCORE_RATE:
			reasons.append("catastrophic_regression_against_%s_opponents" % required_category)
	var side_reports: Dictionary = report.get("sides", {}) as Dictionary
	for side_name in ["blue", "red"]:
		if not side_reports.has(side_name) or int((side_reports[side_name] as Dictionary).get("completed_matches", 0)) <= 0:
			reasons.append("missing_%s_side_matches" % side_name)
	return {
		"promoted": reasons.is_empty(),
		"score_rate": score_rate,
		"goal_difference": goals_for - goals_against,
		"reasons": reasons
	}
