class_name HybridTacticalPolicy
extends RefCounted


const Schema := preload("res://ai/hybrid/tactical_schema.gd")
const ObservationBuilder := preload("res://ai/hybrid/tactical_observation_builder.gd")

var _policy: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _action_usage: Dictionary = {}
var _recent_actions: Array[StringName] = []
var _recent_decision_signatures: Array[String] = []
var _maximum_recent_actions: int = 24
var _last_scores: Dictionary = {}


func _init(seed_value: int = 0) -> void:
	_rng.seed = seed_value if seed_value != 0 else 104729
	_policy = get_default_policy_document()


func set_policy_document(document: Dictionary) -> bool:
	var normalized := normalize_policy_document(document)
	if normalized.is_empty():
		return false
	_policy = normalized
	return true


func get_policy_document() -> Dictionary:
	return _policy.duplicate(true)


func get_last_scores() -> Dictionary:
	return _last_scores.duplicate(true)


func choose(
	observation: Dictionary,
	candidates: Array[Dictionary],
	training: bool = false,
	exploration_override: float = -1.0,
	policy_strength: float = 1.0
) -> Dictionary:
	if observation.is_empty() or candidates.is_empty():
		return Schema.empty_decision("no_observation_or_candidates")
	var features := ObservationBuilder.flatten(observation)
	var scored: Array[Dictionary] = []
	_last_scores.clear()
	for candidate_variant in candidates:
		if not candidate_variant is Dictionary:
			continue
		var candidate := candidate_variant as Dictionary
		if not bool(candidate.get("possible", true)):
			continue
		var action := StringName(candidate.get("action", Schema.ACTION_IDLE))
		if not Schema.is_known_action(action) or action == Schema.ACTION_IDLE:
			continue
		var candidate_features := features
		var feature_overrides := candidate.get(
			"feature_overrides",
			{}
		) as Dictionary
		if not feature_overrides.is_empty():
			candidate_features = features.duplicate(true)
			for feature_variant in feature_overrides.keys():
				candidate_features[str(feature_variant)] = float(
					feature_overrides[feature_variant]
				)
		var score := float(candidate.get("base_score", 0.0))
		# Difficulty scales learned tactical preference, not physical ability.
		score += (
			_score_action(action, candidate_features)
			* clampf(policy_strength, 0.0, 1.0)
		)
		if training:
			score += _contextual_diversity_adjustment(
				action,
				candidate
			)
		candidate["score"] = score
		scored.append(candidate)
		_last_scores[str(action)] = score
	if scored.is_empty():
		return Schema.empty_decision("no_possible_candidates")
	scored.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("score", -INF)) > float(b.get("score", -INF))
	)
	var exploration: float = 0.0
	if training:
		exploration = float(
			_policy.get("exploration", 0.0)
		)
		if exploration_override >= 0.0:
			exploration = exploration_override
		exploration = maxf(
			exploration,
			float(
				_policy.get(
					"training_exploration",
					0.08
				)
			)
		)
	var selected := scored[0]
	if scored.size() > 1 and _rng.randf() < clampf(exploration, 0.0, 0.75):
		selected = _sample_softmax(scored)
	_record_action(
		StringName(selected.get("action", Schema.ACTION_IDLE)),
		selected
	)
	return selected


func reset_episode_history() -> void:
	_action_usage.clear()
	_recent_actions.clear()
	_recent_decision_signatures.clear()
	_last_scores.clear()


func get_action_usage() -> Dictionary:
	return _action_usage.duplicate(true)


func _score_action(action: StringName, features: Dictionary) -> float:
	var action_name := str(action)
	var biases := _policy.get("bias", {}) as Dictionary
	var action_weights := (_policy.get("weights", {}) as Dictionary).get(action_name, {}) as Dictionary
	var score := float(biases.get(action_name, 0.0))
	for feature_variant in action_weights.keys():
		var feature_name := str(feature_variant)
		score += float(action_weights[feature_name]) * float(features.get(feature_name, 0.0))
	return score


func _contextual_diversity_adjustment(
	action: StringName,
	candidate: Dictionary
) -> float:
	var diversity_strength := clampf(
		float(_policy.get("diversity_strength", 0.08)),
		0.0,
		0.35
	)
	if diversity_strength <= 0.0:
		return 0.0
	var recent_action_count := 0
	for recent_action in _recent_actions:
		if recent_action == action:
			recent_action_count += 1
	var signature := _decision_signature(action, candidate)
	var recent_signature_count := 0
	for recent_signature in _recent_decision_signatures:
		if recent_signature == signature:
			recent_signature_count += 1
	var recent_size := maxf(1.0, float(_recent_actions.size()))
	var action_share := float(recent_action_count) / recent_size
	var signature_share := float(recent_signature_count) / recent_size
	var objective_advantage := float(candidate.get("objective_advantage", 0.0))
	if objective_advantage >= 0.55:
		return 0.0
	return -(signature_share * 0.76 + action_share * 0.24) * diversity_strength


func _decision_signature(
	action: StringName,
	candidate: Dictionary
) -> String:
	var pass_kind := str(candidate.get("pass_kind", ""))
	if not pass_kind.is_empty():
		return "%s:%s" % [str(action), pass_kind]
	var reason := str(candidate.get("reason", ""))
	if not reason.is_empty():
		return "%s:%s" % [str(action), reason]
	return str(action)


func _record_action(
	action: StringName,
	candidate: Dictionary = {}
) -> void:
	_action_usage[str(action)] = int(_action_usage.get(str(action), 0)) + 1
	_recent_actions.append(action)
	_recent_decision_signatures.append(
		_decision_signature(action, candidate)
	)
	while _recent_actions.size() > _maximum_recent_actions:
		_recent_actions.pop_front()
	while _recent_decision_signatures.size() > _maximum_recent_actions:
		_recent_decision_signatures.pop_front()


func _sample_softmax(scored: Array[Dictionary]) -> Dictionary:
	var temperature := clampf(float(_policy.get("temperature", 0.24)), 0.03, 2.0)
	var maximum_score := float(scored[0].get("score", 0.0))
	var weights: Array[float] = []
	var total := 0.0
	for candidate in scored:
		var weight := exp(clampf((float(candidate.get("score", 0.0)) - maximum_score) / temperature, -30.0, 0.0))
		weights.append(weight)
		total += weight
	if total <= 0.0:
		return scored[0]
	var roll := _rng.randf() * total
	for index in range(scored.size()):
		roll -= weights[index]
		if roll <= 0.0:
			return scored[index]
	return scored[scored.size() - 1]


static func normalize_policy_document(document: Dictionary) -> Dictionary:
	if document.is_empty():
		return {}
	var source := document
	if document.has("policy") and document["policy"] is Dictionary:
		source = document["policy"] as Dictionary
	var result := get_default_policy_document()
	result["temperature"] = clampf(float(source.get("temperature", result["temperature"])), 0.03, 2.0)
	result["exploration"] = clampf(float(source.get("exploration", result["exploration"])), 0.0, 0.75)
	result["training_exploration"] = clampf(float(source.get("training_exploration", result["training_exploration"])), 0.0, 0.75)
	result["diversity_strength"] = clampf(float(source.get("diversity_strength", result["diversity_strength"])), 0.0, 0.35)
	var source_bias := source.get("bias", {}) as Dictionary
	var result_bias := result.get("bias", {}) as Dictionary
	for action in Schema.ALL_ACTIONS:
		var action_name := str(action)
		if source_bias.has(action_name):
			result_bias[action_name] = clampf(float(source_bias[action_name]), -8.0, 8.0)
	result["bias"] = result_bias
	var source_weights := source.get("weights", {}) as Dictionary
	var result_weights := result.get("weights", {}) as Dictionary
	for action in Schema.ALL_ACTIONS:
		var action_name := str(action)
		if not source_weights.has(action_name) or not source_weights[action_name] is Dictionary:
			continue
		var action_result := result_weights.get(action_name, {}) as Dictionary
		for feature_variant in (source_weights[action_name] as Dictionary).keys():
			var feature_name := str(feature_variant)
			action_result[feature_name] = clampf(float((source_weights[action_name] as Dictionary)[feature_name]), -8.0, 8.0)
		result_weights[action_name] = action_result
	_apply_own_goal_safety_weight_guards(result_weights)
	result["weights"] = result_weights
	return result


static func _apply_own_goal_safety_weight_guards(
	weights: Dictionary
) -> void:
	var clear_weights := weights.get(
		str(Schema.ACTION_CLEAR_OPEN_SIDE),
		{}
	) as Dictionary
	clear_weights["own_goal_danger"] = maxf(
		5.5,
		float(clear_weights.get("own_goal_danger", 0.0))
	)
	weights[str(Schema.ACTION_CLEAR_OPEN_SIDE)] = clear_weights

	var challenge_weights := weights.get(
		str(Schema.ACTION_CHALLENGE_BALL),
		{}
	) as Dictionary
	challenge_weights["own_goal_danger"] = minf(
		-0.55,
		float(
			challenge_weights.get(
				"own_goal_danger",
				-0.55
			)
		)
	)
	weights[str(Schema.ACTION_CHALLENGE_BALL)] = (
		challenge_weights
	)

	var guarded_penalties: Dictionary = {
		str(Schema.ACTION_WALL_BANK_SHOT): -3.8,
		str(Schema.ACTION_PASS_AHEAD): -2.4,
		str(Schema.ACTION_SAFE_PASS): -1.8,
		str(Schema.ACTION_CARRY): -3.2,
		str(Schema.ACTION_DELAY_TOUCH): -2.8
	}
	for action_name_variant in guarded_penalties.keys():
		var action_name := str(action_name_variant)
		var action_weights := weights.get(
			action_name,
			{}
		) as Dictionary
		action_weights["own_goal_danger"] = minf(
			float(guarded_penalties[action_name]),
			float(
				action_weights.get(
					"own_goal_danger",
					guarded_penalties[action_name]
				)
			)
		)
		weights[action_name] = action_weights


static func _add_ability_learning_weights(weights: Dictionary) -> void:
	# Existing checkpoints remain compatible: normalization starts from this
	# default document, so every old champion gains zero-initialized ability
	# matchup weights that future self-play mutations can optimize.
	for action_variant in Schema.ALL_ACTIONS:
		var action := str(action_variant)
		var action_weights := weights.get(action, {}) as Dictionary
		for ability_id in range(1, FootballPlayer.ABILITY_COUNT + 1):
			for prefix in [
				"opponent_ability_%d_ready",
				"opponent_ability_%d_active",
				"team_ability_%d_ready",
				"team_ability_%d_active"
			]:
				var feature_name: String = String(prefix) % ability_id
				if not action_weights.has(feature_name):
					action_weights[feature_name] = 0.0
		weights[action] = action_weights


static func _add_team_sequence_learning_weights(
	weights: Dictionary
) -> void:
	var sequence_features: Array[String] = [
		"team_sequence_available",
		"team_sequence_confidence",
		"team_sequence_actor",
		"team_sequence_receiver",
		"team_sequence_runner",
		"team_sequence_safety",
		"team_sequence_pass",
		"team_sequence_wall_pass",
		"team_sequence_combination",
		"team_sequence_shot",
		"team_sequence_carry",
		"team_sequence_arrival_margin",
		"team_sequence_lane",
		"team_sequence_continuation",
		"team_sequence_counter_risk"
	]
	for action_variant in Schema.ALL_ACTIONS:
		var action_name := str(action_variant)
		var action_weights := weights.get(action_name, {}) as Dictionary
		for feature_name in sequence_features:
			if not action_weights.has(feature_name):
				action_weights[feature_name] = 0.0
		weights[action_name] = action_weights

	var pass_ahead := weights.get(
		str(Schema.ACTION_PASS_AHEAD),
		{}
	) as Dictionary
	pass_ahead["team_sequence_actor"] = 0.45
	pass_ahead["team_sequence_pass"] = 0.72
	pass_ahead["team_sequence_combination"] = 0.62
	pass_ahead["team_sequence_confidence"] = 0.58
	pass_ahead["team_sequence_arrival_margin"] = 0.78
	pass_ahead["team_sequence_lane"] = 0.52
	pass_ahead["team_sequence_continuation"] = 0.66
	pass_ahead["team_sequence_counter_risk"] = -0.72
	weights[str(Schema.ACTION_PASS_AHEAD)] = pass_ahead

	var safe_pass := weights.get(
		str(Schema.ACTION_SAFE_PASS),
		{}
	) as Dictionary
	safe_pass["team_sequence_actor"] = 0.38
	safe_pass["team_sequence_pass"] = 0.48
	safe_pass["team_sequence_confidence"] = 0.54
	safe_pass["team_sequence_arrival_margin"] = 0.86
	safe_pass["team_sequence_lane"] = 0.70
	safe_pass["team_sequence_counter_risk"] = -0.92
	weights[str(Schema.ACTION_SAFE_PASS)] = safe_pass

	for shot_action in [
		Schema.ACTION_DIRECT_SHOT,
		Schema.ACTION_NEAR_POST_SHOT,
		Schema.ACTION_FAR_POST_SHOT
	]:
		var shot_weights := weights.get(str(shot_action), {}) as Dictionary
		shot_weights["team_sequence_actor"] = 0.28
		shot_weights["team_sequence_shot"] = 0.42
		shot_weights["team_sequence_confidence"] = 0.30
		shot_weights["team_sequence_lane"] = 0.38
		weights[str(shot_action)] = shot_weights

	var carry_weights := weights.get(
		str(Schema.ACTION_CARRY),
		{}
	) as Dictionary
	carry_weights["team_sequence_actor"] = 0.22
	carry_weights["team_sequence_carry"] = 0.34
	carry_weights["team_sequence_confidence"] = 0.20
	carry_weights["team_sequence_counter_risk"] = -0.34
	weights[str(Schema.ACTION_CARRY)] = carry_weights

	var support_weights := weights.get(
		str(Schema.ACTION_SUPPORT_TEAMMATE),
		{}
	) as Dictionary
	support_weights["team_sequence_receiver"] = 0.72
	support_weights["team_sequence_runner"] = 0.68
	support_weights["team_sequence_available"] = 0.26
	support_weights["team_sequence_continuation"] = 0.48
	weights[str(Schema.ACTION_SUPPORT_TEAMMATE)] = support_weights

	var move_open_weights := weights.get(
		str(Schema.ACTION_MOVE_OPEN),
		{}
	) as Dictionary
	move_open_weights["team_sequence_receiver"] = 0.62
	move_open_weights["team_sequence_runner"] = 0.58
	move_open_weights["team_sequence_available"] = 0.24
	weights[str(Schema.ACTION_MOVE_OPEN)] = move_open_weights

	var rotate_weights := weights.get(
		str(Schema.ACTION_ROTATE_BACK),
		{}
	) as Dictionary
	rotate_weights["team_sequence_safety"] = 0.74
	rotate_weights["team_sequence_counter_risk"] = 0.48
	weights[str(Schema.ACTION_ROTATE_BACK)] = rotate_weights


static func get_default_policy_document() -> Dictionary:
	var bias: Dictionary = {}
	var weights: Dictionary = {}
	for action in Schema.ALL_ACTIONS:
		bias[str(action)] = 0.0
		weights[str(action)] = {}
	bias[str(Schema.ACTION_WAIT)] = -0.35
	bias[str(Schema.ACTION_DELAY_TOUCH)] = -0.15
	weights[str(Schema.ACTION_DIRECT_SHOT)] = {
		"opponent_defensive_stop_threat": -1.35,
		"possession_self": 1.4,
		"kick_ready": 1.1,
		"goal_closeness": 1.7,
		"shot_lane": 1.05,
		"opponent_pressure": -0.15,
		"one_vs_one": -0.75,
		"offensive_defender_beaten": 0.85,
		"shot_followup_ready": 1.10,
		"elite_goal_probability": 4.80,
		"elite_finish_open_lane": 1.35,
		"elite_finish_timing_margin": 0.85,
		"elite_finish_force_ratio": 0.55
	}
	weights[str(Schema.ACTION_NEAR_POST_SHOT)] = {
		"opponent_defensive_stop_threat": -0.72,
		"possession_self": 1.1,
		"kick_ready": 0.9,
		"goal_closeness": 1.35,
		"shot_lane": 0.55,
		"one_vs_one": -0.65,
		"offensive_defender_beaten": 0.75,
		"shot_followup_ready": 1.00,
		"elite_goal_probability": 4.15,
		"elite_finish_open_lane": 1.10,
		"elite_finish_timing_margin": 0.70
	}
	weights[str(Schema.ACTION_FAR_POST_SHOT)] = {
		"opponent_defensive_stop_threat": -0.58,
		"possession_self": 1.15,
		"kick_ready": 0.9,
		"goal_closeness": 1.25,
		"shot_lane": 0.7,
		"opponent_pressure": 0.2,
		"one_vs_one": -0.65,
		"offensive_defender_beaten": 0.75,
		"shot_followup_ready": 1.00,
		"elite_goal_probability": 4.15,
		"elite_finish_open_lane": 1.10,
		"elite_finish_timing_margin": 0.70
	}
	weights[str(Schema.ACTION_WALL_BANK_SHOT)] = {
		"possession_self": 1.0,
		"kick_ready": 0.8,
		"goal_closeness": 0.8,
		"shot_lane": -0.65,
		"local_duel": 0.15,
		"one_vs_one": -0.85,
		"offensive_defender_beaten": 0.85,
		"shot_followup_ready": 1.65,
		"own_goal_danger": -3.8
	}
	weights[str(Schema.ACTION_PASS_AHEAD)] = {
		"opponent_defensive_stop_threat": 0.82,
		"opponent_ability_uncertainty": 0.18,
		"possession_self": 0.9,
		"pass_available": 1.4,
		"pass_progress": 0.85,
		"pass_lane": 0.85,
		"pass_receiver_open": 0.45,
		"pass_quality": 1.35,
		"pass_interception_margin": 1.05,
		"pass_receiver_margin": 0.55,
		"pass_chain_value": 0.95,
		"pass_defensive_error": 1.05,
		"pass_counter_risk": -1.45,
		"pass_is_through": 0.42,
		"pass_is_switch": 0.34,
		"pass_is_cutback": 0.44,
		"pass_is_wall": 0.20,
		"pass_is_combination": 0.48,
		"pass_is_pressure_escape": 0.10,
		"pass_is_blindside": 0.48,
		"pass_is_square": 0.12,
		"pass_is_recycle": -0.10,
		"team_size": 0.35,
		"own_goal_danger": -2.4
	}
	weights[str(Schema.ACTION_SAFE_PASS)] = {
		"opponent_defensive_stop_threat": 0.58,
		"opponent_displacement_threat": 0.46,
		"possession_self": 0.85,
		"pass_available": 1.2,
		"pass_lane": 1.0,
		"pass_quality": 1.0,
		"pass_interception_margin": 1.25,
		"pass_receiver_margin": 0.85,
		"pass_chain_value": 0.34,
		"pass_defensive_error": 0.30,
		"pass_counter_risk": -1.75,
		"pass_is_through": -0.18,
		"pass_is_switch": 0.24,
		"pass_is_cutback": 0.16,
		"pass_is_wall": 0.12,
		"pass_is_combination": 0.20,
		"pass_is_pressure_escape": 0.68,
		"pass_is_blindside": -0.08,
		"pass_is_square": 0.34,
		"pass_is_recycle": 0.62,
		"opponent_pressure": 0.65,
		"score_difference": 0.15,
		"own_goal_danger": -1.8
	}
	weights[str(Schema.ACTION_CLEAR_OPEN_SIDE)] = {
		"own_goal_danger": 5.5,
		"possession_self": 0.6,
		"opponent_pressure": 0.4
	}
	weights[str(Schema.ACTION_CARRY)] = {
		"opponent_defensive_stop_threat": 0.34,
		"opponent_displacement_threat": -0.72,
		"possession_self": 1.0,
		"local_duel": 1.15,
		"one_vs_one": 0.82,
		"goal_closeness": 0.20,
		"opponent_pressure": 0.35,
		"pass_available": -0.25,
		"offensive_defender_beaten": -1.10,
		"shot_followup_ready": -0.45,
		"offensive_bypass_margin": 1.35,
		"space_play_available": 1.35,
		"space_play_quality": 1.55,
		"space_play_recovery_margin": 1.15,
		"space_play_shooting_lane": 0.85,
		"space_play_uses_wall": 0.42,
		"space_play_force_ratio": 0.18,
		"elite_goal_probability": -5.20,
		"elite_finish_open_lane": -2.40,
		"elite_finish_available": -1.20,
		"own_goal_danger": -3.2
	}
	weights[str(Schema.ACTION_CHALLENGE_BALL)] = {
		"opponent_power_strike_threat": 0.88,
		"opponent_bypass_threat": -0.78,
		"opponent_displacement_threat": -0.52,
		"possession_loose": 1.0,
		"possession_opponent": 0.75,
		"primary_chaser": 1.2,
		"ball_distance": -0.65,
		"own_goal_danger": -0.55,
		"ball_race_advantage": 2.2,
		"opponent_first_touch": -2.4,
		"opponent_kick_ready": -0.65,
		"opponent_shot_threat": -0.45,
		"goal_cover_available": 0.65,
		"open_net_risk": -1.35,
		"self_clearly_first_to_loose_ball": 3.5,
		"opponent_has_physical_control": -0.55,
		"opponent_stall_strength": 0.72,
		"opponent_stall_duration": 0.48,
		"opponent_commit_signal": 1.35,
		"defensive_goal_proximity": -0.38,
		"attacking_goal_proximity": -0.52,
		"attacker_behind_defender": -4.5,
		"breakaway_goal_side_margin": -2.2,
		"breakaway_recovery_urgency": -3.0
	}
	weights[str(Schema.ACTION_FAKE_CHALLENGE)] = {
		"opponent_bypass_threat": 1.10,
		"opponent_displacement_threat": 0.72,
		"possession_opponent": 0.9,
		"primary_chaser": 0.35,
		"opponent_pressure": 0.25,
		"own_goal_danger": -1.4,
		"ball_race_advantage": -0.45,
		"opponent_first_touch": 1.15,
		"opponent_shot_threat": -0.85,
		"open_net_risk": 0.35,
		"opponent_stall": 0.55,
		"opponent_stall_strength": 1.80,
		"opponent_stall_duration": 0.95,
		"opponent_idle_input": 0.72,
		"opponent_commit_signal": -1.25,
		"defensive_goal_proximity": 0.28,
		"attacking_goal_proximity": 0.46
	}
	weights[str(Schema.ACTION_DELAY_TOUCH)] = {
		"possession_self": 0.8,
		"kick_ready": 0.55,
		"opponent_pressure": -0.65,
		"pass_available": 0.15,
		"own_goal_danger": -2.8
	}
	weights[str(Schema.ACTION_SHADOW_DEFEND)] = {
		"opponent_speed_break_threat": 1.15,
		"opponent_bypass_threat": 1.25,
		"opponent_displacement_threat": 0.66,
		"possession_opponent": 1.2,
		"own_goal_danger": 1.25,
		"primary_chaser": 0.05,
		"goal_closeness": -0.2,
		"ball_race_advantage": -0.85,
		"opponent_first_touch": 1.55,
		"opponent_kick_ready": 0.65,
		"opponent_charging": 1.0,
		"opponent_shot_threat": 1.45,
		"open_net_risk": 1.35,
		"self_clearly_first_to_loose_ball": -3.0,
		"opponent_has_physical_control": 0.8,
		"opponent_stall_strength": 0.42,
		"opponent_commit_signal": 1.55,
		"defensive_goal_proximity": 0.78,
		"attacking_goal_proximity": 0.24,
		"attacker_behind_defender": 4.2,
		"breakaway_goal_side_margin": 2.0,
		"breakaway_recovery_urgency": 3.1
	}
	weights[str(Schema.ACTION_PROTECT_GOAL)] = {
		"opponent_ability_goal_threat": 1.45,
		"opponent_power_strike_threat": 1.65,
		"opponent_curve_shot_threat": 1.05,
		"opponent_first_time_finish_threat": 1.25,
		"possession_opponent": 0.9,
		"own_goal_danger": 2.7,
		"primary_chaser": -0.35,
		"score_difference": 0.12,
		"ball_race_advantage": -0.75,
		"opponent_first_touch": 1.2,
		"opponent_kick_ready": 0.75,
		"opponent_charging": 1.05,
		"opponent_shot_threat": 1.8,
		"goal_cover_available": -0.65,
		"open_net_risk": 2.15,
		"self_clearly_first_to_loose_ball": -3.6,
		"opponent_has_physical_control": 0.9,
		"opponent_stall_strength": 0.28,
		"opponent_commit_signal": 1.35,
		"defensive_goal_proximity": 1.10,
		"attacker_behind_defender": 4.8,
		"breakaway_goal_side_margin": 2.4,
		"breakaway_recovery_urgency": 3.4
	}
	weights[str(Schema.ACTION_MARK_OPPONENT)] = {
		"opponent_combination_threat": 1.30,
		"opponent_first_time_finish_threat": 1.42,
		"possession_opponent": 0.85,
		"primary_chaser": -0.75,
		"team_size": 0.6
	}
	weights[str(Schema.ACTION_ROTATE_BACK)] = {
		"opponent_ability_counter_threat": 1.45,
		"opponent_power_strike_threat": 1.10,
		"opponent_speed_break_threat": 1.24,
		"possession_opponent": 0.75,
		"own_goal_danger": 1.45,
		"primary_chaser": -0.5,
		"score_difference": 0.2,
		"ball_race_advantage": -0.55,
		"opponent_first_touch": 0.75,
		"opponent_shot_threat": 0.9,
		"open_net_risk": 1.5,
		"opponent_commit_signal": 0.72,
		"defensive_goal_proximity": 0.55,
		"attacking_goal_proximity": 0.36,
		"attacker_behind_defender": 3.8,
		"breakaway_goal_side_margin": 1.8,
		"breakaway_recovery_urgency": 2.8
	}
	weights[str(Schema.ACTION_MOVE_OPEN)] = {
		"possession_team": 0.95,
		"possession_self": -1.2,
		"primary_chaser": -0.55,
		"team_size": 0.5
	}
	weights[str(Schema.ACTION_SUPPORT_TEAMMATE)] = {
		"possession_team": 1.0,
		"possession_self": -1.0,
		"primary_chaser": -0.5,
		"pass_available": 0.25
	}
	weights[str(Schema.ACTION_AVOID_DOUBLE_COMMIT)] = {
		"opponent_bypass_threat": 0.84,
		"opponent_displacement_threat": 1.05,
		"possession_loose": 0.5,
		"primary_chaser": -1.4,
		"team_size": 0.75,
		"ball_distance": -0.1
	}
	weights[str(Schema.ACTION_WAIT)] = {
		"possession_team": 0.15,
		"primary_chaser": -0.7,
		"own_goal_danger": -2.5,
		"opponent_pressure": -0.6,
		"opponent_ability_goal_threat": -1.8,
		"opponent_ability_counter_threat": -1.4
	}
	_add_ability_learning_weights(weights)
	_add_team_sequence_learning_weights(weights)
	return {
		"observation_version": Schema.OBSERVATION_VERSION,
		"action_space_version": Schema.ACTION_SPACE_VERSION,
		"temperature": 0.24,
		"exploration": 0.0,
		"training_exploration": 0.08,
		"diversity_strength": 0.08,
		"bias": bias,
		"weights": weights
	}
