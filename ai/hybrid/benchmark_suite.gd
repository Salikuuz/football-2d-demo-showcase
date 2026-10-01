class_name HybridBenchmarkSuite
extends RefCounted


const MINIMUM_BENCHMARK_MATCHES: int = 8

var _results: Dictionary = {}
var _promotion_threshold: float = 0.56
var _minimum_goal_difference: float = -0.05
var _maximum_own_goal_rate: float = 0.05
var _minimum_strategy_categories: int = 3


func configure(config: Dictionary) -> void:
	_promotion_threshold = clampf(float(config.get("promotion_threshold", _promotion_threshold)), 0.5, 0.9)
	_minimum_goal_difference = clampf(float(config.get("minimum_goal_difference", _minimum_goal_difference)), -1.0, 2.0)
	_maximum_own_goal_rate = clampf(float(config.get("maximum_own_goal_rate", _maximum_own_goal_rate)), 0.0, 0.5)
	_minimum_strategy_categories = clampi(int(config.get("minimum_strategy_categories", _minimum_strategy_categories)), 1, 10)


func reset() -> void:
	_results.clear()


func record(opponent_id: String, summary: Dictionary) -> void:
	var stats := _results.get(opponent_id, _empty_stats()) as Dictionary
	stats["matches"] = int(stats.get("matches", 0)) + 1
	stats["wins"] = int(stats.get("wins", 0)) + int(summary.get("win", 0))
	stats["draws"] = int(stats.get("draws", 0)) + int(summary.get("draw", 0))
	stats["goals_for"] = int(stats.get("goals_for", 0)) + int(summary.get("goals_for", 0))
	stats["goals_against"] = int(stats.get("goals_against", 0)) + int(summary.get("goals_against", 0))
	stats["own_goals"] = int(stats.get("own_goals", 0)) + int(summary.get("own_goals", 0))
	for safety_key in [
		"avoidable_own_goals",
		"forced_deflection_own_goals",
		"dangerous_own_goal_touch_attempts",
		"dangerous_own_goal_touch_rejections",
		"own_goal_prevention_redirects"
	]:
		stats[safety_key] = (
			int(stats.get(safety_key, 0))
			+ int(summary.get(safety_key, 0))
		)
	stats["shots"] = int(stats.get("shots", 0)) + int(summary.get("shots", 0))
	stats["on_target"] = int(stats.get("on_target", 0)) + int(summary.get("on_target", 0))
	stats["passes"] = int(stats.get("passes", 0)) + int(summary.get("passes", 0))
	stats["completed_passes"] = int(stats.get("completed_passes", 0)) + int(summary.get("completed_passes", 0))
	stats["saves"] = int(stats.get("saves", 0)) + int(summary.get("saves", 0))
	stats["goals_conceded"] = int(stats.get("goals_conceded", 0)) + int(summary.get("goals_conceded", 0))
	var actions := summary.get("action_usage", {}) as Dictionary
	var action_usage := stats.get("action_usage", {}) as Dictionary
	for action in actions.keys():
		action_usage[str(action)] = int(action_usage.get(str(action), 0)) + int(actions[action])
	stats["action_usage"] = action_usage
	_results[opponent_id] = stats


func evaluate() -> Dictionary:
	var aggregate := _empty_stats()
	for stats_variant in _results.values():
		var stats := stats_variant as Dictionary
		for key in [
			"matches",
			"wins",
			"draws",
			"goals_for",
			"goals_against",
			"own_goals",
			"avoidable_own_goals",
			"forced_deflection_own_goals",
			"dangerous_own_goal_touch_attempts",
			"dangerous_own_goal_touch_rejections",
			"own_goal_prevention_redirects",
			"shots",
			"on_target",
			"passes",
			"completed_passes",
			"saves",
			"goals_conceded"
		]:
			aggregate[key] = int(aggregate.get(key, 0)) + int(stats.get(key, 0))
		var aggregate_actions := aggregate.get("action_usage", {}) as Dictionary
		for action in (stats.get("action_usage", {}) as Dictionary).keys():
			aggregate_actions[str(action)] = int(aggregate_actions.get(str(action), 0)) + int((stats.get("action_usage", {}) as Dictionary)[action])
		aggregate["action_usage"] = aggregate_actions
	var matches := int(aggregate.get("matches", 0))
	var wins := int(aggregate.get("wins", 0))
	var draws := int(aggregate.get("draws", 0))
	var win_score := (float(wins) + float(draws) * 0.5) / maxf(1.0, float(matches))
	var goal_difference := float(int(aggregate.get("goals_for", 0)) - int(aggregate.get("goals_against", 0))) / maxf(1.0, float(matches))
	var own_goal_rate := float(aggregate.get("own_goals", 0)) / maxf(1.0, float(matches))
	var strategy_categories := _meaningful_action_categories(aggregate.get("action_usage", {}) as Dictionary)
	var enough_matches := matches >= MINIMUM_BENCHMARK_MATCHES
	var passed := (
		enough_matches
		and win_score >= _promotion_threshold
		and goal_difference >= _minimum_goal_difference
		and own_goal_rate <= _maximum_own_goal_rate
		and strategy_categories >= _minimum_strategy_categories
	)
	return {
		"passed": passed,
		"enough_matches": enough_matches,
		"matches": matches,
		"win_score": win_score,
		"goal_difference_per_match": goal_difference,
		"own_goal_rate": own_goal_rate,
		"strategy_categories": strategy_categories,
		"aggregate": aggregate,
		"by_opponent": _results.duplicate(true)
	}


func exploitability_report(counter_results: Dictionary) -> Dictionary:
	var worst_counter := ""
	var worst_win_score := 1.0
	for opponent_id in counter_results.keys():
		var stats := counter_results[opponent_id] as Dictionary
		var matches := maxf(1.0, float(stats.get("matches", 0)))
		var score := (float(stats.get("wins", 0)) + float(stats.get("draws", 0)) * 0.5) / matches
		if score < worst_win_score:
			worst_win_score = score
			worst_counter = str(opponent_id)
	return {
		"worst_counter": worst_counter,
		"worst_win_score": worst_win_score,
		"collapse_detected": not worst_counter.is_empty() and worst_win_score < 0.34
	}


func _meaningful_action_categories(action_usage: Dictionary) -> int:
	var total := 0
	for value in action_usage.values():
		total += int(value)
	if total <= 0:
		return 0
	var categories := 0
	for value in action_usage.values():
		if float(value) / float(total) >= 0.04:
			categories += 1
	return categories


func _empty_stats() -> Dictionary:
	return {
		"matches": 0,
		"wins": 0,
		"draws": 0,
		"goals_for": 0,
		"goals_against": 0,
		"own_goals": 0,
		"avoidable_own_goals": 0,
		"forced_deflection_own_goals": 0,
		"dangerous_own_goal_touch_attempts": 0,
		"dangerous_own_goal_touch_rejections": 0,
		"own_goal_prevention_redirects": 0,
		"shots": 0,
		"on_target": 0,
		"passes": 0,
		"completed_passes": 0,
		"saves": 0,
		"goals_conceded": 0,
		"action_usage": {}
	}


func analyze_exploitability(matches: Array[Dictionary]) -> Dictionary:
	var counters: Dictionary = {}
	for match_variant in matches:
		var match_data := match_variant as Dictionary
		var opponent_id := str(match_data.get("opponent", "unknown"))
		var stats := counters.get(opponent_id, {"matches": 0, "wins": 0, "draws": 0}) as Dictionary
		stats["matches"] = int(stats.get("matches", 0)) + 1
		var score := float(match_data.get("score", 0.0))
		if score > 0.0:
			stats["wins"] = int(stats.get("wins", 0)) + 1
		elif is_zero_approx(score):
			stats["draws"] = int(stats.get("draws", 0)) + 1
		counters[opponent_id] = stats
	var report := exploitability_report(counters)
	report["collapsed"] = bool(report.get("collapse_detected", false))
	return report
