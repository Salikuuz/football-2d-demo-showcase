class_name TheodoreRLV2MultisizePromotionGate
extends RefCounted

const TeamPromotionGate := preload("res://ai_v2/rl_team_promotion_gate.gd")


static func evaluate(evaluations: Dictionary, mixed_evaluations: Dictionary) -> Dictionary:
	var size_gates: Dictionary = {}
	var reasons: Array[String] = []
	var all_sizes_passed: bool = true
	for team_size in [2, 3, 4]:
		var key: String = "%dv%d" % [team_size, team_size]
		var metrics: Dictionary = evaluations.get(key, {}) as Dictionary
		var gate: Dictionary = TeamPromotionGate.evaluate(metrics, team_size)
		size_gates[key] = gate
		if not bool(gate.get("promoted", false)):
			all_sizes_passed = false
			reasons.append("%s_league_gate_failed" % key)
	var mixed_complete: bool = true
	for team_size in [2, 3, 4]:
		var key: String = "%dv%d" % [team_size, team_size]
		var metrics: Dictionary = mixed_evaluations.get(key, {}) as Dictionary
		var requested: int = int(metrics.get("requested_matches", 0))
		var completed: int = int(metrics.get("completed_matches", 0))
		var human_count: int = int(metrics.get("human_teammate_count", 0))
		if requested <= 0 or completed != requested or human_count != 1:
			mixed_complete = false
			reasons.append("%s_mixed_human_evaluation_incomplete" % key)
	return {
		"promoted": all_sizes_passed and mixed_complete,
		"all_sizes_passed": all_sizes_passed,
		"mixed_human_complete": mixed_complete,
		"size_gates": size_gates,
		"reasons": reasons
	}
