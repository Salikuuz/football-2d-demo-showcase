class_name TheodoreRLV2TeamPromotionGate
extends RefCounted

const LeagueGate := preload("res://ai_v2/rl_league_promotion_gate.gd")

const MINIMUM_TEAM_ACTIONS: int = 2


static func evaluate(metrics: Dictionary, required_team_size: int = 2) -> Dictionary:
	var football_gate: Dictionary = LeagueGate.evaluate(metrics)
	var safe_required_size: int = clampi(required_team_size, 2, 4)
	var correct_team_size: bool = int(metrics.get("team_size", 0)) == safe_required_size
	var team_actions: int = int(metrics.get("candidate_passes", 0)) + int(metrics.get("candidate_receiver_targets", 0))
	var teamplay_exercised: bool = team_actions >= MINIMUM_TEAM_ACTIONS
	var promoted: bool = bool(football_gate.get("promoted", false)) and correct_team_size and teamplay_exercised
	var reasons: Array[String] = []
	if not correct_team_size:
		reasons.append("evaluation_not_%dv%d" % [safe_required_size, safe_required_size])
	if not teamplay_exercised:
		reasons.append("shared_policy_did_not_exercise_team_actions")
	if not bool(football_gate.get("promoted", false)):
		reasons.append("broad_football_league_gate_failed")
	return {
		"promoted": promoted,
		"required_team_size": safe_required_size,
		"team_size_valid": correct_team_size,
		"team_actions": team_actions,
		"teamplay_exercised": teamplay_exercised,
		"football_gate": football_gate,
		"reasons": reasons
	}
