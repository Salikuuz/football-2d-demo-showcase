class_name TheodoreRLV2FundamentalsCurriculum
extends RefCounted

const Schema := preload("res://ai_v2/rl_schema.gd")
const ActionCodec := preload("res://ai_v2/rl_action_codec.gd")
const LegalActionMask := preload("res://ai_v2/rl_legal_action_mask.gd")
const HeadlessEnvironment := preload("res://ai_v2/rl_headless_environment.gd")
const ScriptedHuman := preload("res://ai_v2/rl_scripted_human_teammate.gd")

const DEFAULT_EPISODE_STEPS: int = 150


static func build_samples(team_sizes: Array[int], scenarios_per_size: int = 24, seed_value: int = 810001) -> Array[Dictionary]:
	var samples: Array[Dictionary] = []
	for team_size in team_sizes:
		if team_size < 1 or team_size > Schema.MAX_TEAM_SIZE:
			continue
		for scenario_index in range(maxi(1, scenarios_per_size)):
			var environment = HeadlessEnvironment.new(team_size, seed_value + team_size * 1009 + scenario_index, 8.0, 2)
			_configure_scenario(environment, scenario_index)
			var scripted := ScriptedHuman.new()
			for step_index in range(DEFAULT_EPISODE_STEPS):
				var observations: Array[PackedFloat32Array] = environment.observe_all()
				var actions: Array[Dictionary] = []
				for player in environment.blue_players:
					var action: Dictionary = scripted.action_for(environment, player, &"blue")
					_promote_attacking_finish(environment, player, action, &"blue", scenario_index)
					_teach_contextual_ability(player, action, step_index)
					actions.append(action)
					samples.append(_sample(observations[player.team_slot], action, &"blue"))
				for player in environment.red_players:
					var action: Dictionary = scripted.action_for(environment, player, &"red")
					_promote_attacking_finish(environment, player, action, &"red", scenario_index)
					_teach_contextual_ability(player, action, step_index)
					actions.append(action)
					samples.append(_sample(observations[team_size + player.team_slot], action, &"red"))
				var step_result: Dictionary = environment.step(actions)
				if not StringName(str(step_result.get("goal_team", ""))).is_empty():
					scripted.reset()
				if bool(step_result.get("terminated", false)):
					break
			environment.dispose()
	return samples


static func _teach_contextual_ability(player, action: Dictionary, step_index: int) -> void:
	if player.selected_ability <= 0 or step_index > 0:
		return
	if player.server_ability_active or player.server_ability_cooldown_ends_at > 0.0:
		return
	action["ability_trigger"] = true


static func _promote_attacking_finish(environment, player, action: Dictionary, team: StringName, scenario_index: int) -> void:
	if int(action.get("kick_mode", Schema.KICK_NONE)) == Schema.KICK_NONE:
		return
	# Keep one third of the team samples as real passes, while explicitly teaching
	# the missing terminal action in the other situations. The previous corpus was
	# almost entirely passes because mirrored defenders blocked the centre lane.
	if environment.team_size > 1 and scenario_index % 3 == 0:
		return
	var goal_position := Vector2(environment.field_rect.end.x, environment.field_rect.get_center().y)
	if team == &"red":
		goal_position.x = environment.field_rect.position.x
	var opening_offset: float = float((scenario_index % 3) - 1) * environment.field_rect.size.y * 0.08
	goal_position.y += opening_offset
	action["kick_mode"] = Schema.KICK_SHOT
	action["aim"] = environment.ball.global_position.direction_to(goal_position)
	action["kick_strength"] = 0.84
	action["receiver_slot"] = 0


static func _configure_scenario(environment, scenario_index: int) -> void:
	var center: Vector2 = environment.field_rect.get_center()
	var vertical_offset: float = float((scenario_index % 7) - 3) * 170.0
	environment.ball.global_position = center + Vector2(float((scenario_index % 5) - 2) * 260.0, vertical_offset)
	environment.ball.linear_velocity = Vector2.ZERO
	for team_players in [environment.blue_players, environment.red_players]:
		for player in team_players:
			var attack_sign: float = 1.0 if player.team == &"blue" else -1.0
			var distance: float = 420.0 + float((scenario_index + player.team_slot * 3) % 5) * 180.0
			player.global_position = environment.ball.global_position - Vector2(attack_sign * distance, float(player.team_slot) * 310.0 - 160.0)
			player.linear_velocity = Vector2.ZERO


static func _sample(observation: PackedFloat32Array, action: Dictionary, team: StringName) -> Dictionary:
	var safe: Dictionary = ActionCodec.sanitize(action)
	var move: Vector2 = safe.get("move", Vector2.ZERO) as Vector2
	var aim: Vector2 = safe.get("aim", Vector2.RIGHT) as Vector2
	var kick_mode: int = int(safe.get("kick_mode", Schema.KICK_NONE))
	var mask: PackedFloat32Array = LegalActionMask.from_observation(observation)
	if kick_mode < 0 or kick_mode >= 3 or mask[kick_mode] <= 0.5:
		# A one-player curriculum has no pass receiver. Teach the intended forward
		# finish instead of asking the masked policy to imitate an illegal pass.
		kick_mode = Schema.KICK_SHOT if mask[Schema.KICK_SHOT] > 0.5 else Schema.KICK_NONE
	var mirror_x: float = -1.0 if team == &"red" else 1.0
	var canonical_move := Vector2(move.x * mirror_x, move.y)
	var canonical_aim := Vector2(aim.x * mirror_x, aim.y)
	var raw_continuous := PackedFloat32Array([
		_inverse_tanh(canonical_move.x),
		_inverse_tanh(canonical_move.y),
		_inverse_tanh(canonical_aim.x),
		_inverse_tanh(canonical_aim.y),
		_logit(float(safe.get("kick_strength", 0.5))) if kick_mode != Schema.KICK_NONE else 0.0
	])
	var continuous_weights := PackedFloat32Array([1.0, 1.0, 1.0, 1.0, 0.0])
	var discrete_weights := PackedFloat32Array([1.0, 1.0, 1.0, 1.0, 0.0])
	if kick_mode == Schema.KICK_PASS:
		discrete_weights[0] = 4.0
		discrete_weights[4] = 4.0
		continuous_weights[2] = 4.0
		continuous_weights[3] = 4.0
		continuous_weights[4] = 4.0
	elif kick_mode == Schema.KICK_SHOT:
		discrete_weights[0] = 3.0
		continuous_weights[2] = 3.0
		continuous_weights[3] = 3.0
		continuous_weights[4] = 3.0
	if bool(safe.get("ability_trigger", false)):
		discrete_weights[1] = 5.0
	return {
		"observation": observation.duplicate(),
		"raw_continuous": raw_continuous,
		"continuous_mask": PackedFloat32Array([1.0, 1.0, 1.0, 1.0, 1.0 if kick_mode != Schema.KICK_NONE else 0.0]),
		"discrete": PackedInt32Array([
			kick_mode,
			1 if bool(safe.get("ability_trigger", false)) else 0,
			1 if bool(safe.get("pass_request", false)) else 0,
			int(safe.get("receive_mode", Schema.RECEIVE_NONE)),
			int(safe.get("receiver_slot", 0))
		]),
		"discrete_mask": mask,
		"continuous_weights": continuous_weights,
		"discrete_weights": discrete_weights,
		"weight": 1.0
	}


static func _inverse_tanh(value: float) -> float:
	var safe: float = clampf(value, -0.999, 0.999)
	return 0.5 * log((1.0 + safe) / (1.0 - safe))


static func _logit(value: float) -> float:
	var safe: float = clampf(value, 0.001, 0.999)
	return log(safe / (1.0 - safe))
