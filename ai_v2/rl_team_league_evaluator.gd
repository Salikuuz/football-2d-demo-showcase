class_name TheodoreRLV2TeamLeagueEvaluator
extends RefCounted

const TeamTrainingSession := preload("res://ai_v2/rl_team_training_session.gd")
const TeamOpponent := preload("res://ai_v2/rl_team_opponent.gd")


static func evaluate(policy, league, matches_per_opponent: int, seed_value: int, episode_seconds: float, goals_to_win: int, team_size: int = 2, human_slots: PackedInt32Array = PackedInt32Array()) -> Dictionary:
	var safe_team_size: int = clampi(team_size, 1, 4)
	var result: Dictionary = _empty_metrics(safe_team_size)
	result["human_teammate_count"] = human_slots.size()
	var entries: Array = league.state.get("entries", []) as Array
	var per_opponent: int = maxi(2, matches_per_opponent)
	if per_opponent % 2 != 0:
		per_opponent += 1
	for entry_index in range(entries.size()):
		var entry: Dictionary = (entries[entry_index] as Dictionary).duplicate(true)
		var opponent := TeamOpponent.new(entry, seed_value + entry_index * 10007)
		var session := TeamTrainingSession.new(policy, seed_value + entry_index, episode_seconds, goals_to_win, opponent, safe_team_size, human_slots)
		var metrics: Dictionary = session.evaluate_against(opponent, per_opponent, seed_value + 400000 + entry_index * 101)
		var normalized: Dictionary = _normalized_metrics(metrics)
		(result["opponents"] as Array).append({"entry": entry, "metrics": normalized})
		_accumulate(result, normalized)
		var category: String = _gate_category(str(entry.get("category", "unknown")))
		var categories: Dictionary = result["categories"] as Dictionary
		if not categories.has(category):
			categories[category] = _empty_metrics(safe_team_size)
		_accumulate(categories[category] as Dictionary, normalized)
		for match_variant in metrics.get("matches", []) as Array:
			var match_data := match_variant as Dictionary
			var side: String = str(match_data.get("candidate_team", "blue"))
			var sides: Dictionary = result["sides"] as Dictionary
			var side_metrics: Dictionary = sides[side] as Dictionary
			side_metrics["completed_matches"] = int(side_metrics.get("completed_matches", 0)) + 1
			league.record_match(
				str(entry.get("id", "")),
				int(match_data.get("candidate_score", 0)),
				int(match_data.get("opponent_score", 0)),
				StringName(side)
			)
	return result


static func _normalized_metrics(metrics: Dictionary) -> Dictionary:
	return {
		"requested_matches": int(metrics.get("requested_matches", 0)),
		"completed_matches": int(metrics.get("completed_matches", 0)),
		"candidate_wins": int(metrics.get("candidate_wins", 0)),
		"champion_wins": int(metrics.get("champion_wins", 0)),
		"draws": int(metrics.get("draws", 0)),
		"candidate_goals": int(metrics.get("candidate_goals", 0)),
		"opponent_goals": int(metrics.get("champion_goals", 0)),
		"candidate_kicks": int(metrics.get("candidate_kicks", 0)),
		"candidate_passes": int(metrics.get("candidate_passes", 0)),
		"candidate_receiver_targets": int(metrics.get("candidate_receiver_targets", 0)),
		"candidate_ability_uses": int(metrics.get("candidate_ability_uses", 0))
	}


static func _empty_metrics(team_size: int = 2) -> Dictionary:
	return {
		"team_size": team_size,
		"requested_matches": 0,
		"completed_matches": 0,
		"candidate_wins": 0,
		"champion_wins": 0,
		"draws": 0,
		"candidate_goals": 0,
		"opponent_goals": 0,
		"candidate_kicks": 0,
		"candidate_passes": 0,
		"candidate_receiver_targets": 0,
		"candidate_ability_uses": 0,
		"opponents": [],
		"categories": {},
		"sides": {"blue": {"completed_matches": 0}, "red": {"completed_matches": 0}}
	}


static func _accumulate(target: Dictionary, source: Dictionary) -> void:
	for key in ["requested_matches", "completed_matches", "candidate_wins", "champion_wins", "draws", "candidate_goals", "opponent_goals", "candidate_kicks", "candidate_passes", "candidate_receiver_targets", "candidate_ability_uses"]:
		target[key] = int(target.get(key, 0)) + int(source.get(key, 0))


static func _gate_category(category: String) -> String:
	if category in ["current", "current_v2"]:
		return "current"
	if category == "randomized":
		return "randomized"
	return "specialist"
