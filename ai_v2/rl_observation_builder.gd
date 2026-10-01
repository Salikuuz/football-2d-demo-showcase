class_name TheodoreRLV2ObservationBuilder
extends RefCounted

const Schema := preload("res://ai_v2/rl_schema.gd")
const BallPredictor := preload("res://ai/hybrid/ball_trajectory_predictor.gd")
const PlayerScript := preload("res://Characters/player.gd")


static func build(
	manager: Node,
	perspective_player: Node,
	field_rect: Rect2,
	server_now: float = -1.0
) -> Dictionary:
	if manager == null or perspective_player == null:
		return _empty_packet("missing_manager_or_player")
	var ball: Node = manager.get("ball") as Node
	if ball == null:
		return _empty_packet("missing_ball")
	var safe_rect := _safe_field_rect(field_rect)
	var now := server_now
	if now < 0.0:
		now = float(Time.get_ticks_msec()) / 1000.0
	var perspective_team := StringName(perspective_player.get("team"))
	if perspective_team not in [&"blue", &"red"]:
		return _empty_packet("invalid_perspective_team")
	var attack_sign := 1.0 if perspective_team == &"blue" else -1.0
	var own_players: Array = _team_players(manager, perspective_team)
	var opponent_team := &"red" if perspective_team == &"blue" else &"blue"
	var opponent_players: Array = _team_players(manager, opponent_team)
	var teammates: Array = []
	for player in own_players:
		if player != perspective_player:
			teammates.append(player)
	teammates = _stable_players(teammates)
	opponent_players = _stable_players(opponent_players)

	var own_goal_position := _goal_position(manager, perspective_team, safe_rect)
	var opponent_goal_position := _goal_position(manager, opponent_team, safe_rect)
	var ball_position: Vector2 = ball.get("global_position")
	var ball_velocity: Vector2 = ball.get("linear_velocity")
	var ball_damp := float(ball.get("linear_damp"))
	var trajectory := BallPredictor.predict(
		ball_position,
		ball_velocity,
		safe_rect,
		1.0,
		0.25,
		ball_damp,
		0.8
	)

	var global_values := _build_global_values(
		manager,
		perspective_player,
		own_players,
		opponent_players,
		ball_position,
		ball_velocity,
		trajectory,
		safe_rect,
		attack_sign
	)
	var flat := PackedFloat32Array(global_values)
	var structured_entities: Dictionary = {}

	var self_values := _build_entity_values(
		perspective_player,
		perspective_player,
		ball_position,
		own_goal_position,
		opponent_goal_position,
		safe_rect,
		attack_sign,
		now,
		&"self"
	)
	flat.append_array(self_values)
	structured_entities["self"] = _entity_debug_dictionary(self_values)

	for teammate_index in range(Schema.MAX_TEAMMATES):
		var teammate: Node = teammates[teammate_index] if teammate_index < teammates.size() else null
		var teammate_values := _build_entity_values(
			teammate,
			perspective_player,
			ball_position,
			own_goal_position,
			opponent_goal_position,
			safe_rect,
			attack_sign,
			now,
			&"teammate"
		)
		flat.append_array(teammate_values)
		structured_entities["teammate_%d" % teammate_index] = _entity_debug_dictionary(teammate_values)

	for opponent_index in range(Schema.MAX_OPPONENTS):
		var opponent: Node = opponent_players[opponent_index] if opponent_index < opponent_players.size() else null
		var opponent_values := _build_entity_values(
			opponent,
			perspective_player,
			ball_position,
			own_goal_position,
			opponent_goal_position,
			safe_rect,
			attack_sign,
			now,
			&"opponent"
		)
		flat.append_array(opponent_values)
		structured_entities["opponent_%d" % opponent_index] = _entity_debug_dictionary(opponent_values)

	var valid := flat.size() == Schema.observation_size() and _all_finite(flat)
	return {
		"protocol": Schema.PROTOCOL_NAME,
		"observation_version": Schema.OBSERVATION_VERSION,
		"schema_fingerprint": Schema.schema_fingerprint(),
		"valid": valid,
		"error": "" if valid else "invalid_observation_vector",
		"flat": flat,
		"structured": {
			"global": _global_debug_dictionary(global_values),
			"entities": structured_entities
		}
	}


static func to_wire_packet(packet: Dictionary) -> Dictionary:
	return {
		"protocol": str(packet.get("protocol", Schema.PROTOCOL_NAME)),
		"observation_version": int(packet.get("observation_version", Schema.OBSERVATION_VERSION)),
		"schema_fingerprint": str(packet.get("schema_fingerprint", Schema.schema_fingerprint())),
		"valid": bool(packet.get("valid", false)),
		"error": str(packet.get("error", "")),
		"observation": Array(packet.get("flat", PackedFloat32Array()))
	}


static func feature_index(feature_name: String) -> int:
	return Schema.observation_feature_names().find(feature_name)


static func _build_global_values(
	manager: Node,
	perspective_player: Node,
	own_players: Array,
	opponent_players: Array,
	ball_position: Vector2,
	ball_velocity: Vector2,
	trajectory: PackedVector2Array,
	field_rect: Rect2,
	attack_sign: float
) -> PackedFloat32Array:
	var own_team := StringName(perspective_player.get("team"))
	var own_score := int(manager.get("blue_score")) if own_team == &"blue" else int(manager.get("red_score"))
	var opponent_score := int(manager.get("red_score")) if own_team == &"blue" else int(manager.get("blue_score"))
	var team_size := maxi(1, own_players.size())
	var human_teammates := 0
	for player in own_players:
		if player != perspective_player and not bool(player.get("cpu_controlled")):
			human_teammates += 1
	var human_opponents := 0
	for player in opponent_players:
		if not bool(player.get("cpu_controlled")):
			human_opponents += 1
	var future_025 := _trajectory_sample(trajectory, 1)
	var future_050 := _trajectory_sample(trajectory, 2)
	var future_100 := _trajectory_sample(trajectory, 4)
	var possession := _estimate_possession(perspective_player, own_players, opponent_players, ball_position)
	var canonical_ball_position := _canonical_position(ball_position, field_rect, attack_sign)
	var canonical_ball_velocity := _canonical_velocity(ball_velocity, attack_sign)
	var canonical_025 := _canonical_position(future_025, field_rect, attack_sign)
	var canonical_050 := _canonical_position(future_050, field_rect, attack_sign)
	var canonical_100 := _canonical_position(future_100, field_rect, attack_sign)
	var values := PackedFloat32Array([
		clampf(float(team_size) / float(Schema.MAX_TEAM_SIZE), 0.0, 1.0),
		clampf(float(own_score) / 10.0, 0.0, 1.0),
		clampf(float(opponent_score) / 10.0, 0.0, 1.0),
		clampf(float(own_score - opponent_score) / 10.0, -1.0, 1.0),
		clampf(float(manager.get("regulation_time_remaining")) / Schema.MAX_MATCH_SECONDS, 0.0, 1.0),
		1.0 if bool(manager.get("is_overtime")) else 0.0,
		1.0 if bool(manager.get("_match_clock_waiting_for_kickoff")) else 0.0,
		1.0 if bool(manager.get("round_resetting")) else 0.0,
		1.0 if bool(manager.get("game_has_started")) else 0.0,
		1.0 if bool(manager.get("freeplay_active")) else 0.0,
		clampf(float(manager.get("current_field_variant")) / 16.0, 0.0, 1.0),
		clampf(float(human_teammates) / float(Schema.MAX_TEAMMATES), 0.0, 1.0),
		clampf(float(human_opponents) / float(Schema.MAX_OPPONENTS), 0.0, 1.0),
		canonical_ball_position.x,
		canonical_ball_position.y,
		canonical_ball_velocity.x,
		canonical_ball_velocity.y,
		clampf(ball_velocity.length() / Schema.VELOCITY_SCALE, 0.0, 2.0),
		canonical_025.x,
		canonical_025.y,
		canonical_050.x,
		canonical_050.y,
		canonical_100.x,
		canonical_100.y,
		1.0 if possession == &"self" else 0.0,
		1.0 if possession == &"team" else 0.0,
		1.0 if possession == &"opponent" else 0.0,
		1.0 if possession == &"loose" else 0.0
	])
	return values


static func _build_entity_values(
	player: Node,
	perspective_player: Node,
	ball_position: Vector2,
	own_goal_position: Vector2,
	opponent_goal_position: Vector2,
	field_rect: Rect2,
	attack_sign: float,
	server_now: float,
	relation: StringName
) -> PackedFloat32Array:
	var total_size := Schema.entity_feature_size()
	if player == null or not is_instance_valid(player):
		var empty := PackedFloat32Array()
		empty.resize(total_size)
		return empty
	var position: Vector2 = player.get("global_position")
	var velocity: Vector2 = player.get("linear_velocity")
	var move_intent: Vector2 = player.get("server_direction")
	var selected_ability := clampi(int(player.get("selected_ability")), 0, Schema.ABILITY_COUNT_WITH_NONE - 1)
	var active_ability := clampi(int(player.get("server_active_ability_id")), 0, Schema.ABILITY_COUNT_WITH_NONE - 1)
	var ability_active := bool(player.get("server_ability_active"))
	var cooldown_remaining := maxf(0.0, float(player.get("server_ability_cooldown_ends_at")) - server_now)
	var cooldown_total := _selected_ability_cooldown(player)
	var active_remaining := 0.0
	if ability_active:
		active_remaining = maxf(0.0, float(player.get("server_ability_ends_at")) - server_now)
		if active_remaining > 1000.0:
			active_remaining = Schema.ABILITY_TIME_SCALE
	var ability_ready := (
		selected_ability > 0
		and cooldown_remaining <= 0.02
		and not bool(player.get("server_ability_timers_paused"))
	)
	if bool(player.get("server_permanent_overdrive_enabled")) or bool(player.get("server_permanent_power_strike_enabled")):
		ability_ready = true
	var speed_multipliers := _effective_mobility_multipliers(player)
	var max_speed := maxf(1.0, float(player.get("max_speed")))
	var acceleration := maxf(1.0, float(player.get("acceleration")))
	var effective_speed := max_speed * speed_multipliers.x
	var effective_acceleration := acceleration * speed_multipliers.y
	var arrival_time := BallPredictor.estimate_arrival_time(
		position,
		velocity,
		ball_position,
		effective_speed,
		effective_acceleration
	)
	var max_charge_seconds := _maximum_charge_seconds(player)
	var charge_seconds := 0.0
	if bool(player.get("server_is_charging")):
		charge_seconds = maxf(0.0, server_now - float(player.get("server_charge_started_at")))
	var pass_request_active := float(player.get("server_pass_request_ends_at")) > server_now
	var first_touch_mode := StringName(player.get("server_human_first_touch_mode"))
	var direct_finish_volley := bool(player.get("server_direct_finish_volley_requested"))
	var has_ball_control := _player_has_ball_control(player, ball_position)
	var role := PlayerScript.get_ability_role(selected_ability)
	var canonical_position := _canonical_position(position, field_rect, attack_sign)
	var canonical_velocity := _canonical_velocity(velocity, attack_sign)
	var canonical_move := Vector2(move_intent.x * attack_sign, move_intent.y).limit_length(1.0)
	var field_diagonal := maxf(1.0, field_rect.size.length())
	var own_goal_distance := position.distance_to(own_goal_position) / field_diagonal
	var opponent_goal_distance := position.distance_to(opponent_goal_position) / field_diagonal
	var is_self := player == perspective_player
	var is_teammate := relation == &"teammate"
	var is_opponent := relation == &"opponent"
	var team_slot := int(player.get("team_slot"))
	var base := PackedFloat32Array([
		1.0,
		1.0 if is_self else 0.0,
		1.0 if is_teammate else 0.0,
		1.0 if is_opponent else 0.0,
		0.0 if bool(player.get("cpu_controlled")) else 1.0,
		1.0 if bool(player.get("cpu_controlled")) else 0.0,
		1.0 if bool(player.get("controls_enabled")) else 0.0,
		clampf(float(maxi(0, team_slot)) / float(Schema.MAX_TEAM_SIZE - 1), 0.0, 1.0),
		canonical_position.x,
		canonical_position.y,
		canonical_velocity.x,
		canonical_velocity.y,
		canonical_move.x,
		canonical_move.y,
		clampf(position.distance_to(ball_position) / field_diagonal, 0.0, 1.5),
		clampf(arrival_time / Schema.ARRIVAL_TIME_SCALE, 0.0, 2.0),
		clampf(own_goal_distance, 0.0, 1.5),
		clampf(opponent_goal_distance, 0.0, 1.5),
		clampf(canonical_position.x, 0.0, 1.0),
		clampf(max_speed / Schema.MAX_SPEED_SCALE, 0.0, 2.0),
		clampf(acceleration / Schema.ACCELERATION_SCALE, 0.0, 2.0),
		clampf(speed_multipliers.x / 3.0, 0.0, 1.5),
		clampf(speed_multipliers.y / 4.0, 0.0, 1.5),
		1.0 if bool(player.get("server_is_charging")) else 0.0,
		clampf(charge_seconds / maxf(0.01, max_charge_seconds), 0.0, 1.0),
		1.0 if bool(player.get("server_next_kick_is_pass")) else 0.0,
		1.0 if pass_request_active else 0.0,
		1.0 if has_ball_control else 0.0,
		1.0 if ability_ready else 0.0,
		1.0 if ability_active else 0.0,
		clampf(cooldown_remaining / maxf(0.01, cooldown_total), 0.0, 1.0) if cooldown_total > 0.0 else 0.0,
		clampf(active_remaining / Schema.ABILITY_TIME_SCALE, 0.0, 1.0),
		clampf(float(player.get("server_ability_strength_scale")), 0.0, 1.5),
		1.0 if bool(player.get("server_permanent_overdrive_enabled")) else 0.0,
		1.0 if bool(player.get("server_permanent_power_strike_enabled")) else 0.0,
		1.0 if role == PlayerScript.ABILITY_ROLE_ATTACK else 0.0,
		1.0 if role == PlayerScript.ABILITY_ROLE_PLAYMAKER else 0.0,
		1.0 if role == PlayerScript.ABILITY_ROLE_FLEXIBLE else 0.0,
		1.0 if role == PlayerScript.ABILITY_ROLE_DEFENSE else 0.0,
		1.0 if first_touch_mode == PlayerScript.HUMAN_FIRST_TOUCH_NONE and not direct_finish_volley else 0.0,
		1.0 if first_touch_mode == PlayerScript.HUMAN_FIRST_TOUCH_TRAP else 0.0,
		1.0 if direct_finish_volley else 0.0,
		1.0 if first_touch_mode == PlayerScript.HUMAN_FIRST_TOUCH_DUMMY else 0.0
	])
	for ability_id in range(Schema.ABILITY_COUNT_WITH_NONE):
		base.append(1.0 if selected_ability == ability_id else 0.0)
	for ability_id in range(Schema.ABILITY_COUNT_WITH_NONE):
		base.append(1.0 if ability_active and active_ability == ability_id else 0.0)
	if base.size() != total_size:
		push_error("Theodore RL V2 entity vector size mismatch: %d != %d" % [base.size(), total_size])
	return base


static func _estimate_possession(
	perspective_player: Node,
	own_players: Array,
	opponent_players: Array,
	ball_position: Vector2
) -> StringName:
	var closest: Node = null
	var closest_distance := INF
	for player in own_players + opponent_players:
		if player == null or not is_instance_valid(player) or not bool(player.get("controls_enabled")):
			continue
		var distance := (player.get("global_position") as Vector2).distance_to(ball_position)
		if distance < closest_distance:
			closest = player
			closest_distance = distance
	if closest == null or closest_distance > 260.0:
		return &"loose"
	if closest == perspective_player:
		return &"self"
	if StringName(closest.get("team")) == StringName(perspective_player.get("team")):
		return &"team"
	return &"opponent"


static func _player_has_ball_control(player: Node, ball_position: Vector2) -> bool:
	if not bool(player.get("controls_enabled")):
		return false
	return (player.get("global_position") as Vector2).distance_to(ball_position) <= 260.0


static func _selected_ability_cooldown(player: Node) -> float:
	if player.has_method("_get_selected_ability_cooldown"):
		return maxf(0.0, float(player.call("_get_selected_ability_cooldown")))
	return 0.0


static func _maximum_charge_seconds(player: Node) -> float:
	if player.has_method("cpu_get_maximum_shot_charge_seconds"):
		return maxf(0.01, float(player.call("cpu_get_maximum_shot_charge_seconds")))
	return 0.5


static func _effective_mobility_multipliers(player: Node) -> Vector2:
	var speed_multiplier := 1.0
	var acceleration_multiplier := 1.0
	var active := bool(player.get("server_ability_active"))
	var active_id := int(player.get("server_active_ability_id"))
	var strength := clampf(float(player.get("server_ability_strength_scale")), 0.0, 1.5)
	if active and active_id == PlayerScript.ABILITY_BURST_DRIBBLE:
		speed_multiplier = lerpf(1.0, float(player.get("burst_speed_multiplier")), strength)
		acceleration_multiplier = lerpf(1.0, float(player.get("burst_acceleration_multiplier")), strength)
	elif active and active_id == PlayerScript.ABILITY_ELASTIC_STEP:
		speed_multiplier = lerpf(1.0, float(player.get("elastic_step_speed_multiplier")), strength)
		acceleration_multiplier = lerpf(1.0, float(player.get("elastic_step_acceleration_multiplier")), strength)
	elif active and active_id == PlayerScript.ABILITY_GOALKEEPER_REACH:
		speed_multiplier = lerpf(1.0, float(player.get("goalkeeper_reach_speed_multiplier")), strength)
	elif active and active_id == PlayerScript.ABILITY_OVERDRIVE:
		speed_multiplier = lerpf(1.0, float(player.get("overdrive_speed_multiplier")), strength)
		acceleration_multiplier = lerpf(1.0, float(player.get("overdrive_acceleration_multiplier")), strength)
	if bool(player.get("server_permanent_overdrive_enabled")):
		speed_multiplier = maxf(speed_multiplier, float(player.get("overdrive_speed_multiplier")))
		acceleration_multiplier = maxf(acceleration_multiplier, float(player.get("overdrive_acceleration_multiplier")))
	if bool(player.get("server_permanent_power_strike_enabled")) and player.has_method("is_satoru_gojo") and bool(player.call("is_satoru_gojo")):
		speed_multiplier = maxf(speed_multiplier, 1.3)
	return Vector2(speed_multiplier, acceleration_multiplier)


static func _team_players(manager: Node, team: StringName) -> Array:
	var source = manager.get("blue_players") if team == &"blue" else manager.get("red_players")
	var result: Array = []
	if source is Array:
		for player in source:
			if player != null and is_instance_valid(player):
				result.append(player)
	return result


static func _stable_players(players: Array) -> Array:
	var result := players.duplicate()
	result.sort_custom(func(a, b):
		var a_slot := int(a.get("team_slot"))
		var b_slot := int(b.get("team_slot"))
		if a_slot != b_slot:
			if a_slot < 0:
				return false
			if b_slot < 0:
				return true
			return a_slot < b_slot
		return int(a.get("owner_peer_id")) < int(b.get("owner_peer_id"))
	)
	return result


static func _goal_position(manager: Node, goal_team: StringName, field_rect: Rect2) -> Vector2:
	var goal: Node = manager.get("blue_goal") as Node if goal_team == &"blue" else manager.get("red_goal") as Node
	if goal != null and is_instance_valid(goal):
		return goal.get("global_position")
	var x := field_rect.position.x if goal_team == &"blue" else field_rect.end.x
	return Vector2(x, field_rect.position.y + field_rect.size.y * 0.5)


static func _canonical_position(position: Vector2, field_rect: Rect2, attack_sign: float) -> Vector2:
	var x := (position.x - field_rect.position.x) / maxf(1.0, field_rect.size.x)
	if attack_sign < 0.0:
		x = 1.0 - x
	var y := (position.y - field_rect.position.y) / maxf(1.0, field_rect.size.y)
	return Vector2(clampf(x, -0.25, 1.25), clampf(y, -0.25, 1.25))


static func _canonical_velocity(velocity: Vector2, attack_sign: float) -> Vector2:
	return Vector2(
		clampf(velocity.x * attack_sign / Schema.VELOCITY_SCALE, -2.0, 2.0),
		clampf(velocity.y / Schema.VELOCITY_SCALE, -2.0, 2.0)
	)


static func _trajectory_sample(trajectory: PackedVector2Array, index: int) -> Vector2:
	if trajectory.is_empty():
		return Vector2.ZERO
	return trajectory[mini(index, trajectory.size() - 1)]


static func _safe_field_rect(field_rect: Rect2) -> Rect2:
	if field_rect.size.x > 100.0 and field_rect.size.y > 100.0:
		return field_rect
	return Rect2(360.0, 680.0, 6610.0, 3640.0)


static func _all_finite(values: PackedFloat32Array) -> bool:
	for value in values:
		if is_nan(value) or is_inf(value):
			return false
	return true


static func _global_debug_dictionary(values: PackedFloat32Array) -> Dictionary:
	var result: Dictionary = {}
	for index in range(mini(values.size(), Schema.GLOBAL_FEATURE_NAMES.size())):
		result[Schema.GLOBAL_FEATURE_NAMES[index]] = values[index]
	return result


static func _entity_debug_dictionary(values: PackedFloat32Array) -> Dictionary:
	var result: Dictionary = {}
	var names := Schema.entity_feature_names()
	for index in range(mini(values.size(), names.size())):
		result[names[index]] = values[index]
	return result


static func _empty_packet(error: String) -> Dictionary:
	return {
		"protocol": Schema.PROTOCOL_NAME,
		"observation_version": Schema.OBSERVATION_VERSION,
		"schema_fingerprint": Schema.schema_fingerprint(),
		"valid": false,
		"error": error,
		"flat": PackedFloat32Array(),
		"structured": {}
	}
