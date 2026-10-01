class_name TheodoreRLV2ChampionAdapter
extends RefCounted

const Schema := preload("res://ai_v2/rl_schema.gd")

var source_checkpoint_path: String = ""
var source_checkpoint_checksum: String = ""
var _policy_bias: Dictionary = {}
var _policy_weights: Dictionary = {}


func _init(checkpoint_path: String = "res://training/hybrid_checkpoints/1v1_active.json") -> void:
	source_checkpoint_path = checkpoint_path
	_load_identity()


func action_for(environment, player) -> Dictionary:
	var attack_sign: float = 1.0 if player.team == &"blue" else -1.0
	var own_goal := Vector2(
		environment.field_rect.position.x if player.team == &"blue" else environment.field_rect.end.x,
		environment.field_rect.get_center().y
	)
	var opponent_goal := Vector2(
		environment.field_rect.end.x if player.team == &"blue" else environment.field_rect.position.x,
		environment.field_rect.get_center().y
	)
	var opponent = environment.red_players[0] if player.team == &"blue" else environment.blue_players[0]
	var ball_position: Vector2 = environment.ball.global_position
	var predicted_ball: Vector2 = ball_position + environment.ball.linear_velocity * 0.18
	var goal_side_offset := Vector2(-attack_sign * 175.0, 0.0)
	var target: Vector2 = predicted_ball
	var ball_in_own_half: bool = (ball_position.x - environment.field_rect.get_center().x) * attack_sign < 0.0
	if ball_in_own_half and opponent.global_position.distance_to(ball_position) < 520.0:
		target = ball_position + goal_side_offset
	var can_kick: bool = player.global_position.distance_to(ball_position) <= environment.BALL_CONTROL_DISTANCE
	var opponent_controls: bool = opponent.global_position.distance_to(ball_position) <= environment.BALL_CONTROL_DISTANCE
	var goal_distance_norm: float = clampf(ball_position.distance_to(opponent_goal) / environment.field_rect.size.x, 0.0, 1.0)
	var features: Dictionary = {
		"bias": 1.0,
		"possession_self": 1.0 if can_kick else 0.0,
		"possession_opponent": 1.0 if opponent_controls else 0.0,
		"possession_loose": 1.0 if not can_kick and not opponent_controls else 0.0,
		"primary_chaser": 1.0,
		"local_duel": 1.0 if player.global_position.distance_to(opponent.global_position) < 850.0 else 0.0,
		"one_vs_one": 1.0,
		"kick_ready": 1.0 if can_kick else 0.0,
		"goal_closeness": 1.0 - goal_distance_norm,
		"ball_distance": clampf(player.global_position.distance_to(ball_position) / environment.field_rect.size.x, 0.0, 1.0),
		"shot_lane": clampf(opponent.global_position.distance_to(ball_position) / 1200.0, 0.0, 1.0),
		"opponent_pressure": 1.0 - clampf(opponent.global_position.distance_to(ball_position) / 1400.0, 0.0, 1.0),
		"own_goal_danger": 1.0 if ball_in_own_half else 0.0,
		"ball_race_advantage": clampf((opponent.global_position.distance_to(ball_position) - player.global_position.distance_to(ball_position)) / 1800.0, -1.0, 1.0)
	}
	var tactical_action: StringName = _choose_tactical_action(features, can_kick, opponent_controls)
	var move: Vector2 = player.global_position.direction_to(target)
	var aim: Vector2 = player.global_position.direction_to(opponent_goal)
	if can_kick:
		var keeper_y: float = opponent.global_position.y
		var opening_offset: float = -environment.GOAL_HALF_HEIGHT * 0.62 if keeper_y >= opponent_goal.y else environment.GOAL_HALF_HEIGHT * 0.62
		var shot_target := Vector2(opponent_goal.x, opponent_goal.y + opening_offset)
		aim = ball_position.direction_to(shot_target)
		move = Vector2(attack_sign, 0.0)
		if tactical_action == &"carry" or tactical_action == &"delay_touch":
			move = (Vector2(attack_sign, 0.0) + opponent.global_position.direction_to(player.global_position) * 0.45).normalized()
			return {
				"move": move,
				"aim": move,
				"kick_strength": 0.32,
				"kick_mode": Schema.KICK_SHOT,
				"ability_trigger": false,
				"pass_request": false,
				"receive_mode": Schema.RECEIVE_NONE,
				"receiver_slot": 0
			}
	elif tactical_action == &"protect_goal" or tactical_action == &"shadow_defend":
		move = player.global_position.direction_to(ball_position + goal_side_offset)
	var far_from_ball: bool = player.global_position.distance_to(ball_position) > 900.0
	return {
		"move": move,
		"aim": aim,
		"kick_strength": 0.88,
		"kick_mode": Schema.KICK_SHOT if can_kick else Schema.KICK_NONE,
		"ability_trigger": far_from_ball and environment.episode_steps % 180 == 0,
		"pass_request": false,
		"receive_mode": Schema.RECEIVE_NONE,
		"receiver_slot": 0
	}


func identity() -> Dictionary:
	return {
		"kind": "frozen_current_1v1_champion_adapter",
		"checkpoint_path": source_checkpoint_path,
		"checkpoint_checksum": source_checkpoint_checksum,
		"learned_action_count": _policy_weights.size()
	}


func _load_identity() -> void:
	if not FileAccess.file_exists(source_checkpoint_path):
		return
	var file := FileAccess.open(source_checkpoint_path, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		var document := parsed as Dictionary
		source_checkpoint_checksum = str(document.get("model_checksum", "safe-default"))
		var policy: Dictionary = document.get("policy", {}) as Dictionary
		_policy_bias = (policy.get("bias", {}) as Dictionary).duplicate(true)
		_policy_weights = (policy.get("weights", {}) as Dictionary).duplicate(true)


func _choose_tactical_action(features: Dictionary, can_kick: bool, opponent_controls: bool) -> StringName:
	var candidates: Array[StringName] = []
	if can_kick:
		candidates.assign([&"direct_shot", &"near_post_shot", &"far_post_shot", &"wall_bank_shot", &"carry", &"delay_touch"])
	elif opponent_controls:
		candidates.assign([&"challenge_ball", &"fake_challenge", &"shadow_defend", &"protect_goal"])
	else:
		candidates.assign([&"challenge_ball", &"shadow_defend", &"rotate_back"])
	var best_action: StringName = candidates[0]
	var best_score: float = -INF
	for action in candidates:
		var action_name: String = String(action)
		var score: float = float(_policy_bias.get(action_name, 0.0))
		var weights: Dictionary = _policy_weights.get(action_name, {}) as Dictionary
		for feature_variant in weights.keys():
			var feature_name: String = str(feature_variant)
			score += float(weights[feature_name]) * float(features.get(feature_name, 0.0))
		if score > best_score:
			best_score = score
			best_action = action
	return best_action
