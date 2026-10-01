class_name TheodoreRLV2HeadlessEnvironment
extends RefCounted

const Schema := preload("res://ai_v2/rl_schema.gd")
const Interface := preload("res://ai_v2/rl_interface.gd")
const ActionCodec := preload("res://ai_v2/rl_action_codec.gd")

const DEFAULT_FIELD_RECT := Rect2(360.0, 680.0, 6610.0, 3640.0)
const FIXED_STEP_SECONDS: float = 1.0 / 60.0
const PLAYER_RADIUS: float = 119.0
const BALL_RADIUS: float = 36.0
const GOAL_HALF_HEIGHT: float = 475.0
const BALL_BOUNCE: float = 0.8
const PLAYER_LINEAR_DAMP: float = 5.0
const BALL_CONTROL_DISTANCE: float = 260.0
const MINIMUM_KICK_SPEED: float = 1450.0
const MAXIMUM_KICK_SPEED: float = 6500.0
const ABILITY_ACTIVE_SECONDS: float = 2.5
const ABILITY_COOLDOWN_SECONDS: float = 8.0
const KICK_EXECUTION_COOLDOWN_SECONDS: float = 0.14
const MAX_CONTROL_RELATIVE_SPEED: float = 3200.0


class TrainingBall extends Node2D:
	var linear_velocity: Vector2 = Vector2.ZERO
	var linear_damp: float = 0.55


class TrainingGoal extends Node2D:
	pass


class TrainingPlayer extends Node2D:
	var display_name: String = "Training CPU"
	var team: StringName = &"blue"
	var team_slot: int = 0
	var owner_peer_id: int = 0
	var cpu_controlled: bool = true
	var controls_enabled: bool = true
	var linear_velocity: Vector2 = Vector2.ZERO
	var server_direction: Vector2 = Vector2.ZERO
	var selected_ability: int = 0
	var server_active_ability_id: int = 0
	var server_ability_active: bool = false
	var server_ability_cooldown_ends_at: float = 0.0
	var server_ability_ends_at: float = 0.0
	var server_ability_timers_paused: bool = false
	var server_permanent_overdrive_enabled: bool = false
	var server_permanent_power_strike_enabled: bool = false
	var server_ability_strength_scale: float = 1.0
	var server_is_charging: bool = false
	var server_charge_started_at: float = 0.0
	var server_next_kick_is_pass: bool = false
	var server_pass_request_ends_at: float = 0.0
	var server_human_first_touch_mode: StringName = &"none"
	var server_direct_finish_volley_requested: bool = false
	var server_next_kick_allowed_at: float = 0.0
	var max_speed: float = 5550.0
	var acceleration: float = 5900.0
	var burst_speed_multiplier: float = 1.6
	var burst_acceleration_multiplier: float = 4.4
	var elastic_step_speed_multiplier: float = 1.4
	var elastic_step_acceleration_multiplier: float = 3.0
	var goalkeeper_reach_speed_multiplier: float = 2.0
	var overdrive_speed_multiplier: float = 1.65
	var overdrive_acceleration_multiplier: float = 1.65

	func _get_selected_ability_cooldown() -> float:
		return ABILITY_COOLDOWN_SECONDS

	func cpu_get_maximum_shot_charge_seconds() -> float:
		return 0.5

	func is_satoru_gojo() -> bool:
		return false


class TrainingMatchState extends Node:
	var ball: Node = null
	var blue_players: Array = []
	var red_players: Array = []
	var blue_goal: Node = null
	var red_goal: Node = null
	var blue_score: int = 0
	var red_score: int = 0
	var regulation_time_remaining: float = 60.0
	var is_overtime: bool = false
	var _match_clock_waiting_for_kickoff: bool = false
	var round_resetting: bool = false
	var game_has_started: bool = true
	var freeplay_active: bool = false
	var current_field_variant: int = 0


var field_rect: Rect2 = DEFAULT_FIELD_RECT
var team_size: int = 1
var episode_seconds: float = 60.0
var goals_to_win: int = 3
var fixed_step_seconds: float = FIXED_STEP_SECONDS
var manager: TrainingMatchState = null
var ball: TrainingBall = null
var blue_players: Array[TrainingPlayer] = []
var red_players: Array[TrainingPlayer] = []
var players: Array[TrainingPlayer] = []
var elapsed_seconds: float = 0.0
var episode_steps: int = 0
var completed_episodes: int = 0
var total_goals: int = 0
var last_goal_team: StringName = &""
var seed_value: int = 1
var last_step_events: Array[Dictionary] = []

var _rng := RandomNumberGenerator.new()
var _disposed: bool = false
var _pending_passes: Dictionary = {}


func _init(
	requested_team_size: int = 1,
	requested_seed: int = 1,
	requested_episode_seconds: float = 60.0,
	requested_goals_to_win: int = 3
) -> void:
	team_size = clampi(requested_team_size, 1, Schema.MAX_TEAM_SIZE)
	seed_value = requested_seed
	episode_seconds = maxf(FIXED_STEP_SECONDS, requested_episode_seconds)
	goals_to_win = maxi(1, requested_goals_to_win)
	_create_minimal_match_state()
	reset(seed_value)


func reset(requested_seed: int = -1) -> Array[PackedFloat32Array]:
	if requested_seed >= 0:
		seed_value = requested_seed
	_rng.seed = seed_value
	elapsed_seconds = 0.0
	episode_steps = 0
	last_goal_team = &""
	last_step_events.clear()
	_pending_passes.clear()
	manager.blue_score = 0
	manager.red_score = 0
	manager.regulation_time_remaining = episode_seconds
	manager._match_clock_waiting_for_kickoff = false
	manager.round_resetting = false
	manager.game_has_started = true
	_reset_positions()
	return observe_all()


func configure_human_slots(team: StringName, slots: PackedInt32Array) -> void:
	var team_players: Array[TrainingPlayer] = blue_players if team == &"blue" else red_players
	for player in team_players:
		player.cpu_controlled = not slots.has(player.team_slot)


func configure_evaluation_scenario(scenario: Dictionary) -> void:
	manager.current_field_variant = maxi(0, int(scenario.get("field_variant", 0)))
	manager.blue_score = maxi(0, int(scenario.get("blue_score", 0)))
	manager.red_score = maxi(0, int(scenario.get("red_score", 0)))
	var elapsed_fraction: float = clampf(float(scenario.get("elapsed_fraction", 0.0)), 0.0, 0.95)
	elapsed_seconds = episode_seconds * elapsed_fraction
	manager.regulation_time_remaining = maxf(0.0, episode_seconds - elapsed_seconds)
	_apply_team_scenario(blue_players, scenario.get("blue_positions", []) as Array, scenario.get("blue_abilities", []) as Array, scenario.get("blue_profiles", []) as Array)
	_apply_team_scenario(red_players, scenario.get("red_positions", []) as Array, scenario.get("red_abilities", []) as Array, scenario.get("red_profiles", []) as Array)
	ball.global_position = _normalized_field_point(scenario.get("ball_position", Vector2(0.5, 0.5)) as Vector2, BALL_RADIUS)
	ball.linear_velocity = scenario.get("ball_velocity", Vector2.ZERO) as Vector2
	last_step_events.clear()


func step(actions: Array[Dictionary]) -> Dictionary:
	if _disposed:
		return {"error": "environment_disposed", "terminated": true}
	last_step_events.clear()
	var safe_actions: Array[Dictionary] = []
	for player_index in range(players.size()):
		var supplied: Dictionary = actions[player_index] if player_index < actions.size() else ActionCodec.neutral_action()
		safe_actions.append(ActionCodec.sanitize(supplied))
	var now: float = elapsed_seconds
	for player_index in range(players.size()):
		_apply_player_action(players[player_index], safe_actions[player_index], now)
	_resolve_player_contacts()
	_integrate_ball()
	_update_pending_passes()
	var scored_team: StringName = _detect_goal()
	if not scored_team.is_empty():
		_record_goal(scored_team)
	elapsed_seconds += fixed_step_seconds
	episode_steps += 1
	manager.regulation_time_remaining = maxf(0.0, episode_seconds - elapsed_seconds)
	var terminated: bool = (
		elapsed_seconds >= episode_seconds
		or manager.blue_score >= goals_to_win
		or manager.red_score >= goals_to_win
	)
	return {
		"observations": observe_all(),
		"terminated": terminated,
		"goal_team": scored_team,
		"blue_score": manager.blue_score,
		"red_score": manager.red_score,
		"episode_steps": episode_steps,
		"events": last_step_events.duplicate(true)
	}


func finish_and_reset_if_needed(step_result: Dictionary) -> bool:
	if not bool(step_result.get("terminated", false)):
		return false
	completed_episodes += 1
	seed_value += 1
	reset(seed_value)
	return true


func observe_all() -> Array[PackedFloat32Array]:
	var result: Array[PackedFloat32Array] = []
	for player in players:
		var packet: Dictionary = Interface.observe(manager, player, field_rect, elapsed_seconds)
		if not bool(packet.get("valid", false)):
			return []
		var flat: PackedFloat32Array = packet.get("flat", PackedFloat32Array())
		result.append(flat)
	return result


func benchmark_actions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for player in players:
		var attack_sign: float = 1.0 if player.team == &"blue" else -1.0
		var to_ball: Vector2 = player.global_position.direction_to(ball.global_position)
		var goal_direction := Vector2(attack_sign, 0.0)
		var can_kick: bool = player.global_position.distance_to(ball.global_position) <= BALL_CONTROL_DISTANCE
		result.append({
			"move": to_ball,
			"aim": goal_direction,
			"kick_strength": 0.72,
			"kick_mode": Schema.KICK_SHOT if can_kick else Schema.KICK_NONE,
			"ability_trigger": episode_steps % 240 == player.team_slot * 7,
			"pass_request": false,
			"receive_mode": Schema.RECEIVE_NONE,
			"receiver_slot": 0
		})
	return result


func receiver_action_slot(passer: TrainingPlayer, receiver: TrainingPlayer) -> int:
	if passer == null or receiver == null or passer.team != receiver.team or passer == receiver:
		return 0
	var teammates: Array[TrainingPlayer] = []
	var team_players: Array[TrainingPlayer] = blue_players if passer.team == &"blue" else red_players
	for candidate in team_players:
		if candidate != passer:
			teammates.append(candidate)
	teammates.sort_custom(func(first: TrainingPlayer, second: TrainingPlayer) -> bool:
		return first.team_slot < second.team_slot
	)
	var relative_index: int = teammates.find(receiver)
	return relative_index + 1 if relative_index >= 0 else 0


func receiver_team_slot(passer: TrainingPlayer, action_slot: int) -> int:
	if passer == null or action_slot <= 0:
		return -1
	var teammates: Array[TrainingPlayer] = []
	var team_players: Array[TrainingPlayer] = blue_players if passer.team == &"blue" else red_players
	for candidate in team_players:
		if candidate != passer:
			teammates.append(candidate)
	teammates.sort_custom(func(first: TrainingPlayer, second: TrainingPlayer) -> bool:
		return first.team_slot < second.team_slot
	)
	var relative_index: int = action_slot - 1
	return teammates[relative_index].team_slot if relative_index >= 0 and relative_index < teammates.size() else -1


func state_checksum() -> int:
	var values := PackedFloat64Array([
		ball.global_position.x,
		ball.global_position.y,
		ball.linear_velocity.x,
		ball.linear_velocity.y,
		float(manager.blue_score),
		float(manager.red_score),
		elapsed_seconds
	])
	for player in players:
		values.append(player.global_position.x)
		values.append(player.global_position.y)
		values.append(player.linear_velocity.x)
		values.append(player.linear_velocity.y)
	return hash(values)


func live_node_count() -> int:
	if manager == null or not is_instance_valid(manager):
		return 0
	return 1 + manager.get_child_count()


func dispose() -> void:
	if _disposed:
		return
	_disposed = true
	players.clear()
	blue_players.clear()
	red_players.clear()
	ball = null
	if manager != null and is_instance_valid(manager):
		manager.free()
	manager = null


func _create_minimal_match_state() -> void:
	manager = TrainingMatchState.new()
	manager.name = "RLTrainingMatch"
	ball = TrainingBall.new()
	ball.name = "Ball"
	manager.add_child(ball)
	manager.ball = ball
	var blue_goal := TrainingGoal.new()
	blue_goal.name = "BlueGoal"
	manager.add_child(blue_goal)
	blue_goal.global_position = Vector2(field_rect.position.x, field_rect.get_center().y)
	manager.blue_goal = blue_goal
	var red_goal := TrainingGoal.new()
	red_goal.name = "RedGoal"
	manager.add_child(red_goal)
	red_goal.global_position = Vector2(field_rect.end.x, field_rect.get_center().y)
	manager.red_goal = red_goal
	for team in [&"blue", &"red"]:
		for slot in range(team_size):
			var player := TrainingPlayer.new()
			player.name = "%s_%d" % [String(team), slot]
			player.display_name = "Training %s %d" % [String(team).capitalize(), slot + 1]
			player.team = team
			player.team_slot = slot
			player.owner_peer_id = (100 if team == &"blue" else 200) + slot
			player.selected_ability = 1 + ((slot + (0 if team == &"blue" else team_size)) % (Schema.ABILITY_COUNT_WITH_NONE - 1))
			manager.add_child(player)
			players.append(player)
			if team == &"blue":
				blue_players.append(player)
			else:
				red_players.append(player)
	manager.blue_players = blue_players
	manager.red_players = red_players


func _reset_positions() -> void:
	ball.global_position = field_rect.get_center()
	ball.linear_velocity = Vector2.ZERO
	var center_y: float = field_rect.get_center().y
	var slot_spacing: float = minf(720.0, field_rect.size.y / float(team_size + 1))
	for player in players:
		var attack_sign: float = 1.0 if player.team == &"blue" else -1.0
		var x_offset: float = 900.0 + float(player.team_slot % 2) * 360.0
		var centered_slot: float = float(player.team_slot) - float(team_size - 1) * 0.5
		var seeded_y_jitter: float = _rng.randf_range(-18.0, 18.0)
		player.global_position = Vector2(
			field_rect.get_center().x - attack_sign * x_offset,
			center_y + centered_slot * slot_spacing + seeded_y_jitter
		)
		player.linear_velocity = Vector2.ZERO
		player.server_direction = Vector2.ZERO
		player.server_is_charging = false
		player.server_next_kick_is_pass = false
		player.server_pass_request_ends_at = 0.0
		player.server_human_first_touch_mode = &"none"
		player.server_direct_finish_volley_requested = false
		player.server_next_kick_allowed_at = 0.0
		player.server_ability_active = false
		player.server_active_ability_id = 0
		player.server_ability_ends_at = 0.0
		player.server_ability_cooldown_ends_at = 0.0


func _apply_player_action(player: TrainingPlayer, action: Dictionary, now: float) -> void:
	if player.server_ability_active and now >= player.server_ability_ends_at:
		player.server_ability_active = false
		player.server_active_ability_id = 0
	var move: Vector2 = action.get("move", Vector2.ZERO)
	player.server_direction = move
	var speed_multiplier: float = 1.0
	var acceleration_multiplier: float = 1.0
	if player.server_ability_active and player.server_active_ability_id == 4:
		speed_multiplier = player.overdrive_speed_multiplier
		acceleration_multiplier = player.overdrive_acceleration_multiplier
	var target_velocity: Vector2 = move * player.max_speed * speed_multiplier
	player.linear_velocity = player.linear_velocity.move_toward(
		target_velocity,
		player.acceleration * acceleration_multiplier * fixed_step_seconds
	)
	player.linear_velocity *= maxf(0.0, 1.0 - PLAYER_LINEAR_DAMP * fixed_step_seconds)
	player.global_position += player.linear_velocity * fixed_step_seconds
	player.global_position = Vector2(
		clampf(player.global_position.x, field_rect.position.x + PLAYER_RADIUS, field_rect.end.x - PLAYER_RADIUS),
		clampf(player.global_position.y, field_rect.position.y + PLAYER_RADIUS, field_rect.end.y - PLAYER_RADIUS)
	)
	if bool(action.get("ability_trigger", false)) and now >= player.server_ability_cooldown_ends_at:
		player.server_ability_active = player.selected_ability > 0
		player.server_active_ability_id = player.selected_ability if player.server_ability_active else 0
		player.server_ability_ends_at = now + ABILITY_ACTIVE_SECONDS
		player.server_ability_cooldown_ends_at = now + ABILITY_COOLDOWN_SECONDS
		if player.server_ability_active:
			last_step_events.append({
				"type": "ability_activated",
				"team": String(player.team),
				"slot": player.team_slot,
				"ability_id": player.selected_ability
			})
	var kick_mode: int = int(action.get("kick_mode", Schema.KICK_NONE))
	player.server_next_kick_is_pass = kick_mode == Schema.KICK_PASS
	if bool(action.get("pass_request", false)):
		player.server_pass_request_ends_at = now + 0.65
	elif now >= player.server_pass_request_ends_at:
		player.server_pass_request_ends_at = 0.0
	var receive_mode: int = int(action.get("receive_mode", Schema.RECEIVE_NONE))
	player.server_human_first_touch_mode = (
		&"trap" if receive_mode == Schema.RECEIVE_TRAP
		else (&"dummy" if receive_mode == Schema.RECEIVE_DUMMY else &"none")
	)
	player.server_direct_finish_volley_requested = receive_mode == Schema.RECEIVE_VOLLEY
	if kick_mode != Schema.KICK_NONE and now >= player.server_next_kick_allowed_at:
		if _try_kick_ball(player, action):
			player.server_next_kick_allowed_at = now + KICK_EXECUTION_COOLDOWN_SECONDS


func _try_kick_ball(player: TrainingPlayer, action: Dictionary) -> bool:
	if player.global_position.distance_to(ball.global_position) > BALL_CONTROL_DISTANCE:
		return false
	var aim: Vector2 = action.get("aim", Vector2.RIGHT)
	if aim.length_squared() <= 0.000001:
		return false
	var strength: float = clampf(float(action.get("kick_strength", 0.0)), 0.0, 1.0)
	var kick_speed: float = lerpf(MINIMUM_KICK_SPEED, MAXIMUM_KICK_SPEED, strength)
	var before_position: Vector2 = ball.global_position
	var before_velocity: Vector2 = ball.linear_velocity
	ball.linear_velocity = aim.normalized() * kick_speed
	ball.global_position = player.global_position + aim.normalized() * (PLAYER_RADIUS + BALL_RADIUS + 2.0)
	var action_receiver_slot: int = int(action.get("receiver_slot", 0))
	var intended_team_slot: int = receiver_team_slot(player, action_receiver_slot)
	last_step_events.append({
		"type": "kick",
		"team": String(player.team),
		"slot": player.team_slot,
		"kick_mode": int(action.get("kick_mode", Schema.KICK_NONE)),
		"receiver_slot": intended_team_slot,
		"strength": strength,
		"aim": aim.normalized(),
		"ball_position_before": before_position,
		"ball_velocity_before": before_velocity,
		"ball_velocity_after": ball.linear_velocity,
		"ability_id": player.server_active_ability_id
	})
	if int(action.get("kick_mode", Schema.KICK_NONE)) == Schema.KICK_PASS:
		_pending_passes[String(player.team)] = {
			"passer_slot": player.team_slot,
			"receiver_slot": intended_team_slot,
			"started_step": episode_steps,
			"expires_at": elapsed_seconds + 2.2
		}
	return true


func _update_pending_passes() -> void:
	for team_key_value in _pending_passes.keys():
		var team_key: String = str(team_key_value)
		var pending: Dictionary = _pending_passes[team_key_value] as Dictionary
		if elapsed_seconds > float(pending.get("expires_at", 0.0)):
			last_step_events.append({
				"type": "pass_expired",
				"team": team_key,
				"passer_slot": int(pending.get("passer_slot", -1)),
				"intended_receiver": int(pending.get("receiver_slot", -1))
			})
			_pending_passes.erase(team_key_value)
			continue
		if episode_steps <= int(pending.get("started_step", -1)):
			continue
		var owner: Dictionary = _closest_ball_owner()
		var owner_team: String = str(owner.get("team", ""))
		if owner_team.is_empty():
			continue
		if owner_team != team_key:
			last_step_events.append({
				"type": "pass_intercepted",
				"team": team_key,
				"passer_slot": int(pending.get("passer_slot", -1)),
				"intended_receiver": int(pending.get("receiver_slot", -1))
			})
			_pending_passes.erase(team_key_value)
			continue
		var owner_slot: int = int(owner.get("slot", -1))
		if owner_slot == int(pending.get("passer_slot", -1)):
			continue
		var intended_slot: int = int(pending.get("receiver_slot", -1))
		last_step_events.append({
			"type": "pass_completed",
			"team": team_key,
			"passer_slot": int(pending.get("passer_slot", -1)),
			"receiver_slot": owner_slot,
			"intended_receiver": intended_slot,
			"intended": intended_slot < 0 or intended_slot == owner_slot
		})
		_pending_passes.erase(team_key_value)


func _closest_ball_owner() -> Dictionary:
	var closest_distance: float = BALL_CONTROL_DISTANCE
	var result: Dictionary = {}
	for player in players:
		var distance: float = player.global_position.distance_to(ball.global_position)
		var relative_speed: float = (ball.linear_velocity - player.linear_velocity).length()
		if distance <= closest_distance and relative_speed <= MAX_CONTROL_RELATIVE_SPEED:
			closest_distance = distance
			result = {
				"team": String(player.team),
				"slot": player.team_slot,
				"relative_speed": relative_speed
			}
	return result


func _resolve_player_contacts() -> void:
	var minimum_distance: float = PLAYER_RADIUS * 2.0
	for first_index in range(players.size()):
		for second_index in range(first_index + 1, players.size()):
			var first: TrainingPlayer = players[first_index]
			var second: TrainingPlayer = players[second_index]
			var difference: Vector2 = second.global_position - first.global_position
			var distance: float = difference.length()
			if distance >= minimum_distance:
				continue
			var normal := difference / distance if distance > 0.001 else Vector2.RIGHT
			var correction: Vector2 = normal * (minimum_distance - distance) * 0.5
			first.global_position -= correction
			second.global_position += correction
			var first_normal_speed: float = first.linear_velocity.dot(normal)
			var second_normal_speed: float = second.linear_velocity.dot(normal)
			if first_normal_speed > second_normal_speed:
				var average: float = (first_normal_speed + second_normal_speed) * 0.5
				first.linear_velocity += normal * (average - first_normal_speed)
				second.linear_velocity += normal * (average - second_normal_speed)


func _integrate_ball() -> void:
	ball.linear_velocity *= exp(-maxf(0.0, ball.linear_damp) * fixed_step_seconds)
	ball.global_position += ball.linear_velocity * fixed_step_seconds
	var minimum_y: float = field_rect.position.y + BALL_RADIUS
	var maximum_y: float = field_rect.end.y - BALL_RADIUS
	if ball.global_position.y < minimum_y:
		ball.global_position.y = minimum_y + (minimum_y - ball.global_position.y)
		ball.linear_velocity.y = absf(ball.linear_velocity.y) * BALL_BOUNCE
	elif ball.global_position.y > maximum_y:
		ball.global_position.y = maximum_y - (ball.global_position.y - maximum_y)
		ball.linear_velocity.y = -absf(ball.linear_velocity.y) * BALL_BOUNCE
	var inside_goal_mouth: bool = absf(ball.global_position.y - field_rect.get_center().y) <= GOAL_HALF_HEIGHT
	if inside_goal_mouth:
		return
	var minimum_x: float = field_rect.position.x + BALL_RADIUS
	var maximum_x: float = field_rect.end.x - BALL_RADIUS
	if ball.global_position.x < minimum_x:
		ball.global_position.x = minimum_x + (minimum_x - ball.global_position.x)
		ball.linear_velocity.x = absf(ball.linear_velocity.x) * BALL_BOUNCE
	elif ball.global_position.x > maximum_x:
		ball.global_position.x = maximum_x - (ball.global_position.x - maximum_x)
		ball.linear_velocity.x = -absf(ball.linear_velocity.x) * BALL_BOUNCE


func _detect_goal() -> StringName:
	if absf(ball.global_position.y - field_rect.get_center().y) > GOAL_HALF_HEIGHT:
		return &""
	if ball.global_position.x <= field_rect.position.x - BALL_RADIUS:
		return &"red"
	if ball.global_position.x >= field_rect.end.x + BALL_RADIUS:
		return &"blue"
	return &""


func _record_goal(scoring_team: StringName) -> void:
	last_goal_team = scoring_team
	total_goals += 1
	_pending_passes.clear()
	var conceding_team: StringName = &"red" if scoring_team == &"blue" else &"blue"
	var defenders: Array[TrainingPlayer] = blue_players if conceding_team == &"blue" else red_players
	var own_goal_x: float = field_rect.position.x if conceding_team == &"blue" else field_rect.end.x
	var goalkeeper_distance: float = INF
	for defender in defenders:
		goalkeeper_distance = minf(goalkeeper_distance, absf(defender.global_position.x - own_goal_x))
	last_step_events.append({
		"type": "goal",
		"team": String(scoring_team),
		"conceding_team": String(conceding_team),
		"goalkeeper_distance": goalkeeper_distance
	})
	if scoring_team == &"blue":
		manager.blue_score += 1
	else:
		manager.red_score += 1
	_reset_positions()


func _apply_team_scenario(
	team_players: Array[TrainingPlayer],
	position_values: Array,
	ability_values: Array,
	profile_values: Array
) -> void:
	for slot in range(team_players.size()):
		var player: TrainingPlayer = team_players[slot]
		if slot < position_values.size() and position_values[slot] is Vector2:
			player.global_position = _normalized_field_point(position_values[slot] as Vector2, PLAYER_RADIUS)
		player.linear_velocity = Vector2.ZERO
		player.server_direction = Vector2.ZERO
		if slot < ability_values.size():
			player.selected_ability = clampi(int(ability_values[slot]), 0, Schema.ABILITY_COUNT_WITH_NONE - 1)
		if slot < profile_values.size() and profile_values[slot] is Dictionary:
			var profile: Dictionary = profile_values[slot] as Dictionary
			player.max_speed = 5550.0 * clampf(float(profile.get("speed_scale", 1.0)), 0.75, 1.35)
			player.acceleration = 5900.0 * clampf(float(profile.get("acceleration_scale", 1.0)), 0.75, 1.35)
			player.server_ability_strength_scale = clampf(float(profile.get("ability_strength_scale", 1.0)), 0.75, 1.35)
			player.server_permanent_overdrive_enabled = bool(profile.get("permanent_overdrive", false))
			player.server_permanent_power_strike_enabled = bool(profile.get("permanent_power_strike", false))


func _normalized_field_point(normalized_position: Vector2, radius: float) -> Vector2:
	return Vector2(
		lerpf(field_rect.position.x + radius, field_rect.end.x - radius, clampf(normalized_position.x, 0.0, 1.0)),
		lerpf(field_rect.position.y + radius, field_rect.end.y - radius, clampf(normalized_position.y, 0.0, 1.0))
	)
