class_name TheodoreRLV2LeagueOpponent
extends RefCounted

const Schema := preload("res://ai_v2/rl_schema.gd")
const ChampionAdapter := preload("res://ai_v2/rl_champion_adapter.gd")
const NeuralPolicy := preload("res://ai_v2/rl_neural_policy.gd")

const KIND_LEGACY: StringName = &"legacy"
const KIND_NEURAL: StringName = &"neural"
const KIND_SPECIALIST: StringName = &"specialist"
const KIND_RANDOMIZED: StringName = &"randomized"

var entry: Dictionary = {}
var _legacy = null
var _neural = null
var _rng := RandomNumberGenerator.new()


func _init(requested_entry: Dictionary = {}, requested_seed: int = 1) -> void:
	entry = requested_entry.duplicate(true)
	_rng.seed = requested_seed
	var kind := StringName(str(entry.get("kind", KIND_LEGACY)))
	var checkpoint_path: String = str(entry.get("checkpoint_path", ""))
	if kind == KIND_NEURAL:
		var policy := NeuralPolicy.new()
		if policy.load_checkpoint(checkpoint_path):
			_neural = policy
		else:
			entry["load_fallback"] = true
			_legacy = ChampionAdapter.new()
	else:
		_legacy = ChampionAdapter.new(checkpoint_path) if not checkpoint_path.is_empty() else ChampionAdapter.new()


func action_for(environment, player) -> Dictionary:
	if _neural != null:
		var observations: Array[PackedFloat32Array] = environment.observe_all()
		var player_index: int = 0 if player.team == &"blue" else environment.blue_players.size()
		if player_index >= 0 and player_index < observations.size():
			return (_neural.sample(observations[player_index], player.team, true) as Dictionary).get("action", {}) as Dictionary
	var base_action: Dictionary = _legacy.action_for(environment, player)
	return _apply_profile(base_action, environment, player)


func identity() -> Dictionary:
	var result: Dictionary = entry.duplicate(true)
	result["load_fallback"] = bool(entry.get("load_fallback", false))
	return result


func _apply_profile(base_action: Dictionary, environment, player) -> Dictionary:
	var action: Dictionary = base_action.duplicate(true)
	var profile := StringName(str(entry.get("profile", "balanced")))
	var ball_position: Vector2 = environment.ball.global_position
	var opponent_goal := Vector2(
		environment.field_rect.end.x if player.team == &"blue" else environment.field_rect.position.x,
		environment.field_rect.get_center().y
	)
	var own_goal := Vector2(
		environment.field_rect.position.x if player.team == &"blue" else environment.field_rect.end.x,
		environment.field_rect.get_center().y
	)
	var can_kick: bool = player.global_position.distance_to(ball_position) <= environment.BALL_CONTROL_DISTANCE
	match profile:
		&"aggressive":
			action["move"] = player.global_position.direction_to(ball_position)
			action["aim"] = ball_position.direction_to(opponent_goal)
			if can_kick:
				action["kick_mode"] = Schema.KICK_SHOT
				action["kick_strength"] = 1.0
		&"defensive":
			var attack_sign: float = 1.0 if player.team == &"blue" else -1.0
			var guard_point: Vector2 = ball_position + Vector2(-attack_sign * 210.0, 0.0)
			action["move"] = player.global_position.direction_to(guard_point)
			if can_kick:
				action["aim"] = ball_position.direction_to(opponent_goal)
				action["kick_mode"] = Schema.KICK_SHOT
				action["kick_strength"] = 0.76
			elif player.global_position.distance_to(own_goal) > ball_position.distance_to(own_goal):
				action["move"] = player.global_position.direction_to(own_goal.lerp(ball_position, 0.58))
		&"ability":
			action["ability_trigger"] = can_kick or environment.episode_steps % 90 == 0
			if can_kick:
				action["kick_strength"] = 0.94
		&"passing":
			# The 1v1 league has no receiver. This profile exercises patient touches and
			# becomes a real passing specialist unchanged when team training begins.
			if can_kick:
				action["kick_mode"] = Schema.KICK_SHOT
				action["kick_strength"] = 0.28
				action["aim"] = (Vector2(1.0 if player.team == &"blue" else -1.0, 0.0) + Vector2(0.0, sin(float(environment.episode_steps) * 0.07) * 0.45)).normalized()
		&"randomized":
			var jitter: float = float(entry.get("jitter", 0.18))
			var move: Vector2 = action.get("move", Vector2.ZERO) as Vector2
			var aim: Vector2 = action.get("aim", Vector2.ZERO) as Vector2
			action["move"] = (move + Vector2(_rng.randf_range(-jitter, jitter), _rng.randf_range(-jitter, jitter))).limit_length(1.0)
			action["aim"] = (aim + Vector2(_rng.randf_range(-jitter, jitter), _rng.randf_range(-jitter, jitter))).normalized()
			if can_kick:
				action["kick_strength"] = clampf(float(action.get("kick_strength", 0.75)) + _rng.randf_range(-jitter, jitter), 0.1, 1.0)
	return action
