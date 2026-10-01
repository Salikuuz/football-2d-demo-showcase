class_name TheodoreRLV2ScriptedHumanTeammate
extends RefCounted

const Schema := preload("res://ai_v2/rl_schema.gd")

var _phase_by_key: Dictionary = {}


func reset() -> void:
	_phase_by_key.clear()


func action_for(environment, player, team: StringName) -> Dictionary:
	var teammates: Array = environment.blue_players if team == &"blue" else environment.red_players
	var opponents: Array = environment.red_players if team == &"blue" else environment.blue_players
	var attack_sign: float = 1.0 if team == &"blue" else -1.0
	var goal_position := Vector2(environment.field_rect.end.x, environment.field_rect.get_center().y)
	if team == &"red":
		goal_position.x = environment.field_rect.position.x
	var to_ball: Vector2 = player.global_position.direction_to(environment.ball.global_position)
	var can_kick: bool = player.global_position.distance_to(environment.ball.global_position) <= environment.BALL_CONTROL_DISTANCE
	var receiver = _best_receiver(player, teammates, opponents, attack_sign)
	var action: Dictionary = {
		"move": to_ball,
		"aim": player.global_position.direction_to(goal_position),
		"kick_strength": 0.68,
		"kick_mode": Schema.KICK_NONE,
		"ability_trigger": false,
		"pass_request": false,
		"receive_mode": Schema.RECEIVE_NONE,
		"receiver_slot": 0
	}
	if can_kick:
		var direct_lane_clear: bool = _lane_clear(environment.ball.global_position, goal_position, opponents, 250.0)
		if direct_lane_clear and absf(goal_position.x - environment.ball.global_position.x) < environment.field_rect.size.x * 0.44:
			action["kick_mode"] = Schema.KICK_SHOT
			action["kick_strength"] = 0.78
		else:
			action["kick_mode"] = Schema.KICK_PASS
			if receiver != null:
				var lead_seconds: float = 0.32
				var lead_target: Vector2 = receiver.global_position + receiver.linear_velocity * lead_seconds
				action["aim"] = environment.ball.global_position.direction_to(lead_target)
				action["receiver_slot"] = environment.receiver_action_slot(player, receiver)
				action["kick_strength"] = 0.55
	else:
		var closest: bool = true
		for teammate in teammates:
			if teammate == player:
				continue
			if teammate.global_position.distance_squared_to(environment.ball.global_position) < player.global_position.distance_squared_to(environment.ball.global_position):
				closest = false
				break
		if not closest:
			var support_target: Vector2 = environment.ball.global_position + Vector2(-attack_sign * 780.0, float(player.team_slot - 1) * 420.0)
			action["move"] = player.global_position.direction_to(support_target)
			action["pass_request"] = _request_phase(player, environment.episode_steps)
			action["receive_mode"] = Schema.RECEIVE_VOLLEY if _lane_clear(support_target, goal_position, opponents, 230.0) else Schema.RECEIVE_TRAP
	return action


func _request_phase(player, episode_steps: int) -> bool:
	var key: String = "%s:%d" % [String(player.team), player.team_slot]
	var offset: int = int(_phase_by_key.get(key, player.team_slot * 13))
	_phase_by_key[key] = offset
	return (episode_steps + offset) % 90 < 16


func _best_receiver(player, teammates: Array, opponents: Array, attack_sign: float):
	var best = null
	var best_score: float = -INF
	for teammate in teammates:
		if teammate == player:
			continue
		var forward_progress: float = (teammate.global_position.x - player.global_position.x) * attack_sign
		var nearest_pressure: float = 1800.0
		for opponent in opponents:
			nearest_pressure = minf(nearest_pressure, teammate.global_position.distance_to(opponent.global_position))
		var score: float = forward_progress * 0.65 + nearest_pressure * 0.35
		if score > best_score:
			best_score = score
			best = teammate
	return best


func _lane_clear(start: Vector2, target: Vector2, blockers: Array, clearance: float) -> bool:
	var segment: Vector2 = target - start
	var length_squared: float = segment.length_squared()
	if length_squared <= 0.0001:
		return false
	for blocker in blockers:
		var ratio: float = clampf((blocker.global_position - start).dot(segment) / length_squared, 0.0, 1.0)
		var closest: Vector2 = start + segment * ratio
		if blocker.global_position.distance_to(closest) < clearance:
			return false
	return true
