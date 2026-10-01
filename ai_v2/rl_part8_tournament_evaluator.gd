class_name TheodoreRLV2Part8TournamentEvaluator
extends RefCounted

const HeadlessEnvironment := preload("res://ai_v2/rl_headless_environment.gd")
const SharedTeamPolicy := preload("res://ai_v2/rl_shared_team_policy.gd")
const TeamOpponent := preload("res://ai_v2/rl_team_opponent.gd")
const ScriptedHuman := preload("res://ai_v2/rl_scripted_human_teammate.gd")
const Scenarios := preload("res://ai_v2/rl_evaluation_scenarios.gd")
const Telemetry := preload("res://ai_v2/rl_tournament_telemetry.gd")


static func evaluate_size(
	candidate_policy,
	team_size: int,
	match_count: int,
	seed_value: int,
	episode_seconds: float,
	goals_to_win: int,
	human_teammate: bool = false
) -> Dictionary:
	var requested_matches: int = maxi(2, match_count)
	if requested_matches % 2 != 0:
		requested_matches += 1
	var metrics: Dictionary = _empty_metrics(team_size, requested_matches, human_teammate)
	var scenario_documents: Array[Dictionary] = []
	for match_index in range(requested_matches):
		var candidate_team: StringName = &"blue" if match_index % 2 == 0 else &"red"
		var opponent_team: StringName = &"red" if candidate_team == &"blue" else &"blue"
		var pair_index: int = floori(float(match_index) * 0.5)
		var scenario: Dictionary = Scenarios.build(team_size, pair_index, seed_value + pair_index * 7919)
		scenario_documents.append(scenario)
		var environment := HeadlessEnvironment.new(team_size, seed_value + match_index, episode_seconds, goals_to_win)
		var human_slots := PackedInt32Array([0]) if human_teammate and team_size > 1 else PackedInt32Array()
		environment.configure_human_slots(candidate_team, human_slots)
		environment.configure_evaluation_scenario(scenario)
		var shared_candidate := SharedTeamPolicy.new(candidate_policy)
		var scripted_human := ScriptedHuman.new()
		var current_entry: Dictionary = {
			"id": "frozen_current_%dv%d" % [team_size, team_size],
			"kind": "legacy",
			"profile": str(scenario.get("opponent_profile", "balanced")),
			"checkpoint_path": "res://training/hybrid_checkpoints/%dv%d_active.json" % [team_size, team_size]
		}
		var current_ai := TeamOpponent.new(current_entry, seed_value + match_index * 31)
		var telemetry := Telemetry.new()
		telemetry.begin(environment)
		var maximum_steps: int = ceili(episode_seconds / environment.fixed_step_seconds) + 2
		var step_result: Dictionary = {}
		for _step_index in range(maximum_steps):
			var observations: Array[PackedFloat32Array] = environment.observe_all()
			var candidate_actions: Array[Dictionary] = _candidate_actions(
				environment,
				observations,
				candidate_team,
				shared_candidate,
				scripted_human,
				human_slots
			)
			var current_actions: Array[Dictionary] = current_ai.actions_for(environment, opponent_team)
			var actions_by_team: Dictionary = {
				String(candidate_team): candidate_actions,
				String(opponent_team): current_actions
			}
			telemetry.before_step(environment, actions_by_team)
			step_result = environment.step(_ordered_actions(candidate_team, candidate_actions, current_actions))
			telemetry.after_step(environment, step_result)
			if not StringName(str(step_result.get("goal_team", ""))).is_empty():
				shared_candidate.reset_all()
				scripted_human.reset()
				current_ai.reset()
			if bool(step_result.get("terminated", false)):
				break
		_record_match(metrics, step_result, scenario, candidate_team, telemetry.result(candidate_team))
		environment.dispose()
	metrics["scenario_coverage"] = Scenarios.coverage(scenario_documents)
	metrics["candidate"] = _normalized_stats(metrics["candidate"] as Dictionary)
	metrics["current_ai"] = _normalized_stats(metrics["current_ai"] as Dictionary)
	return metrics


static func _candidate_actions(
	environment,
	all_observations: Array[PackedFloat32Array],
	team: StringName,
	shared_candidate,
	scripted_human,
	human_slots: PackedInt32Array
) -> Array[Dictionary]:
	var offset: int = 0 if team == &"blue" else environment.blue_players.size()
	var neural_observations: Array[PackedFloat32Array] = []
	var neural_slots := PackedInt32Array()
	for slot in range(environment.team_size):
		if not human_slots.has(slot):
			neural_observations.append(all_observations[offset + slot])
			neural_slots.append(slot)
	var samples: Array[Dictionary] = shared_candidate.sample_slots(neural_observations, neural_slots, team, true)
	var result: Array[Dictionary] = []
	result.resize(environment.team_size)
	var team_players: Array = environment.blue_players if team == &"blue" else environment.red_players
	for slot in range(environment.team_size):
		if human_slots.has(slot):
			result[slot] = scripted_human.action_for(environment, team_players[slot], team)
		else:
			var sample_index: int = neural_slots.find(slot)
			result[slot] = samples[sample_index].get("action", {}) as Dictionary
	return result


static func _ordered_actions(candidate_team: StringName, candidate_actions: Array[Dictionary], current_actions: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if candidate_team == &"blue":
		result.append_array(candidate_actions)
		result.append_array(current_actions)
	else:
		result.append_array(current_actions)
		result.append_array(candidate_actions)
	return result


static func _empty_metrics(team_size: int, requested_matches: int, human_teammate: bool) -> Dictionary:
	return {
		"team_size": team_size,
		"human_teammate_count": 1 if human_teammate and team_size > 1 else 0,
		"requested_matches": requested_matches,
		"completed_matches": 0,
		"candidate_wins": 0,
		"current_ai_wins": 0,
		"draws": 0,
		"candidate_goals": 0,
		"current_ai_goals": 0,
		"sides": {
			"blue": {"completed_matches": 0},
			"red": {"completed_matches": 0}
		},
		"candidate": {},
		"current_ai": {}
	}


static func _record_match(metrics: Dictionary, result: Dictionary, scenario: Dictionary, candidate_team: StringName, match_telemetry: Dictionary) -> void:
	metrics["completed_matches"] = int(metrics["completed_matches"]) + 1
	var blue_goals_earned: int = maxi(0, int(result.get("blue_score", 0)) - int(scenario.get("blue_score", 0)))
	var red_goals_earned: int = maxi(0, int(result.get("red_score", 0)) - int(scenario.get("red_score", 0)))
	var candidate_score: int = blue_goals_earned if candidate_team == &"blue" else red_goals_earned
	var current_score: int = red_goals_earned if candidate_team == &"blue" else blue_goals_earned
	metrics["candidate_goals"] = int(metrics["candidate_goals"]) + candidate_score
	metrics["current_ai_goals"] = int(metrics["current_ai_goals"]) + current_score
	var side_stats: Dictionary = (metrics["sides"] as Dictionary)[String(candidate_team)] as Dictionary
	side_stats["completed_matches"] = int(side_stats["completed_matches"]) + 1
	if candidate_score > current_score:
		metrics["candidate_wins"] = int(metrics["candidate_wins"]) + 1
	elif candidate_score < current_score:
		metrics["current_ai_wins"] = int(metrics["current_ai_wins"]) + 1
	else:
		metrics["draws"] = int(metrics["draws"]) + 1
	_merge_stats(metrics["candidate"] as Dictionary, match_telemetry.get("candidate", {}) as Dictionary)
	_merge_stats(metrics["current_ai"] as Dictionary, match_telemetry.get("current_ai", {}) as Dictionary)


static func _merge_stats(target: Dictionary, source: Dictionary) -> void:
	for key_variant in source.keys():
		var key: String = str(key_variant)
		if key == "ability_usage":
			var target_usage: Dictionary = target.get(key, {}) as Dictionary
			for ability_variant in (source[key] as Dictionary).keys():
				var ability_id: int = int(ability_variant)
				target_usage[ability_id] = int(target_usage.get(ability_id, 0)) + int((source[key] as Dictionary)[ability_variant])
			target[key] = target_usage
		elif source[key] is int or source[key] is float:
			target[key] = float(target.get(key, 0.0)) + float(source[key])


static func _normalized_stats(raw: Dictionary) -> Dictionary:
	var result: Dictionary = raw.duplicate(true)
	var steps: float = maxf(1.0, float(raw.get("steps", 0.0)))
	var kick_requests: float = maxf(1.0, float(raw.get("kick_requests", 0.0)))
	var pass_attempts: float = maxf(1.0, float(raw.get("passes_attempted", 0.0)))
	result["possession_share"] = float(raw.get("possession_steps", 0.0)) / steps
	result["double_commit_rate"] = float(raw.get("double_commit_steps", 0.0)) / steps
	result["kick_execution_rate"] = float(raw.get("successful_kicks", 0.0)) / kick_requests
	result["pass_completion_rate"] = float(raw.get("passes_completed", 0.0)) / pass_attempts
	result["possession_loss_rate"] = float(raw.get("possession_losses", 0.0)) / maxf(1.0, float(raw.get("possession_gains", 0.0)) + 1.0)
	return result
