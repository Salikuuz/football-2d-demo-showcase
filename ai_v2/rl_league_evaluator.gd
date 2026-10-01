class_name TheodoreRLV2LeagueEvaluator
extends RefCounted

const TrainingSession := preload("res://ai_v2/rl_training_session.gd")


static func evaluate(policy, league, matches_per_opponent: int, seed_value: int, episode_seconds: float, goals_to_win: int) -> Dictionary:
	var entries: Array = league.state.get("entries", []) as Array
	var per_opponent: Array[Dictionary] = []
	var report: Dictionary = {
		"requested_matches": 0,
		"completed_matches": 0,
		"candidate_wins": 0,
		"opponent_wins": 0,
		"draws": 0,
		"candidate_goals": 0,
		"opponent_goals": 0,
		"candidate_shots": 0,
		"candidate_ability_uses": 0,
		"categories": {},
		"sides": {
			"blue": _empty_metrics(),
			"red": _empty_metrics()
		},
		"opponents": per_opponent
	}
	var games_per_opponent: int = maxi(2, matches_per_opponent)
	if games_per_opponent % 2 != 0:
		games_per_opponent += 1
	for entry_index in range(entries.size()):
		var entry := entries[entry_index] as Dictionary
		var opponent = league.build_opponent(entry, seed_value + entry_index * 10007)
		var session := TrainingSession.new(policy, seed_value, episode_seconds, goals_to_win, opponent)
		var metrics: Dictionary = session.evaluate_against(opponent, games_per_opponent, seed_value + entry_index * 1009)
		var normalized: Dictionary = _normalized_metrics(metrics)
		normalized["opponent_id"] = str(entry.get("id", "unknown"))
		normalized["opponent_name"] = str(entry.get("name", "Opponent"))
		normalized["category"] = str(entry.get("category", "unknown"))
		per_opponent.append(normalized)
		_accumulate(report, normalized)
		var category_key: String = _gate_category(str(entry.get("category", "unknown")))
		var categories: Dictionary = report.get("categories", {}) as Dictionary
		if not categories.has(category_key):
			categories[category_key] = _empty_metrics()
		var category_metrics := categories[category_key] as Dictionary
		_accumulate(category_metrics, normalized)
		categories[category_key] = category_metrics
		report["categories"] = categories
		_record_league_results(league, entry, normalized)
		var sides: Dictionary = report.get("sides", {}) as Dictionary
		for match_variant in normalized.get("matches", []) as Array:
			var match_result := match_variant as Dictionary
			var side_name: String = str(match_result.get("candidate_team", "blue"))
			var side := sides.get(side_name, _empty_metrics()) as Dictionary
			side["completed_matches"] = int(side.get("completed_matches", 0)) + 1
			var candidate_score: int = int(match_result.get("candidate_score", 0))
			var opponent_score: int = int(match_result.get("opponent_score", 0))
			side["candidate_goals"] = int(side.get("candidate_goals", 0)) + candidate_score
			side["opponent_goals"] = int(side.get("opponent_goals", 0)) + opponent_score
			if candidate_score > opponent_score:
				side["candidate_wins"] = int(side.get("candidate_wins", 0)) + 1
			elif candidate_score < opponent_score:
				side["opponent_wins"] = int(side.get("opponent_wins", 0)) + 1
			else:
				side["draws"] = int(side.get("draws", 0)) + 1
			sides[side_name] = side
		report["sides"] = sides
	report["opponents"] = per_opponent
	return report


static func _record_league_results(league, entry: Dictionary, metrics: Dictionary) -> void:
	var matches: Array = metrics.get("matches", []) as Array
	if matches.is_empty():
		return
	var opponent_id: String = str(entry.get("id", ""))
	for match_variant in matches:
		var match_result := match_variant as Dictionary
		league.record_match(
			opponent_id,
			int(match_result.get("candidate_score", 0)),
			int(match_result.get("opponent_score", 0)),
			StringName(str(match_result.get("candidate_team", "blue")))
		)


static func _normalized_metrics(metrics: Dictionary) -> Dictionary:
	return {
		"requested_matches": int(metrics.get("requested_matches", 0)),
		"completed_matches": int(metrics.get("completed_matches", 0)),
		"candidate_wins": int(metrics.get("candidate_wins", 0)),
		"opponent_wins": int(metrics.get("champion_wins", 0)),
		"draws": int(metrics.get("draws", 0)),
		"candidate_goals": int(metrics.get("candidate_goals", 0)),
		"opponent_goals": int(metrics.get("champion_goals", 0)),
		"candidate_shots": int(metrics.get("candidate_shots", 0)),
		"candidate_ability_uses": int(metrics.get("candidate_ability_uses", 0)),
		"matches": (metrics.get("matches", []) as Array).duplicate(true)
	}


static func _empty_metrics() -> Dictionary:
	return {
		"requested_matches": 0,
		"completed_matches": 0,
		"candidate_wins": 0,
		"opponent_wins": 0,
		"draws": 0,
		"candidate_goals": 0,
		"opponent_goals": 0,
		"candidate_shots": 0,
		"candidate_ability_uses": 0
	}


static func _accumulate(target: Dictionary, source: Dictionary) -> void:
	for key in ["requested_matches", "completed_matches", "candidate_wins", "opponent_wins", "draws", "candidate_goals", "opponent_goals", "candidate_shots", "candidate_ability_uses"]:
		target[key] = int(target.get(key, 0)) + int(source.get(key, 0))


static func _gate_category(category: String) -> String:
	if category in ["current", "current_v2", "historical_v2"]:
		return "current"
	return category
