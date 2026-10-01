class_name TheodoreRLV2RewardModel
extends RefCounted

const Schema := preload("res://ai_v2/rl_schema.gd")

const FIELD_PROGRESS_WEIGHT: float = 0.22
const POSSESSION_STEP_REWARD: float = 0.0025
const DANGER_WEIGHT: float = 0.10
const GOAL_REWARD: float = 10.0
const WIN_REWARD: float = 20.0
const POSSESSION_GAIN_REWARD: float = 0.10
const POSSESSION_LOSS_PENALTY: float = 0.12
const FORWARD_SHOT_REWARD: float = 0.05
const KICKOFF_CONTACT_REWARD: float = 0.08


static func capture(environment, team: StringName) -> Dictionary:
	var own_player = environment.blue_players[0] if team == &"blue" else environment.red_players[0]
	var opponent = environment.red_players[0] if team == &"blue" else environment.blue_players[0]
	var attack_sign: float = 1.0 if team == &"blue" else -1.0
	var field_width: float = maxf(1.0, environment.field_rect.size.x)
	var ball_progress: float = (
		(environment.ball.global_position.x - environment.field_rect.get_center().x)
		* attack_sign
		/ field_width
	)
	var self_distance: float = own_player.global_position.distance_to(environment.ball.global_position)
	var opponent_distance: float = opponent.global_position.distance_to(environment.ball.global_position)
	return {
		"ball_progress": ball_progress,
		"self_controls": self_distance <= environment.BALL_CONTROL_DISTANCE,
		"opponent_controls": opponent_distance <= environment.BALL_CONTROL_DISTANCE,
		"owner_team": (
			team if self_distance <= opponent_distance and self_distance <= environment.BALL_CONTROL_DISTANCE
			else ((&"red" if team == &"blue" else &"blue") if opponent_distance <= environment.BALL_CONTROL_DISTANCE else &"")
		),
		"own_goal_danger": _goal_danger(environment, team),
		"blue_score": environment.manager.blue_score,
		"red_score": environment.manager.red_score
	}


static func transition_reward(
	environment,
	team: StringName,
	before: Dictionary,
	step_result: Dictionary
) -> float:
	var after: Dictionary = capture(environment, team)
	var reward: float = (
		float(after.get("ball_progress", 0.0))
		- float(before.get("ball_progress", 0.0))
	) * FIELD_PROGRESS_WEIGHT
	if bool(after.get("self_controls", false)):
		reward += POSSESSION_STEP_REWARD
	elif bool(after.get("opponent_controls", false)):
		reward -= POSSESSION_STEP_REWARD
	reward += (
		float(before.get("own_goal_danger", 0.0))
		- float(after.get("own_goal_danger", 0.0))
	) * DANGER_WEIGHT
	var before_owner := StringName(str(before.get("owner_team", "")))
	var after_owner := StringName(str(after.get("owner_team", "")))
	if before_owner != team and after_owner == team:
		reward += POSSESSION_GAIN_REWARD
	elif before_owner == team and after_owner != team and not after_owner.is_empty():
		reward -= POSSESSION_LOSS_PENALTY
	for event_value in step_result.get("events", []) as Array:
		var event: Dictionary = event_value as Dictionary
		if StringName(str(event.get("team", ""))) != team:
			continue
		var event_type: String = str(event.get("type", ""))
		if event_type == "kick":
			if _is_viable_scoring_shot(environment, team, event):
				reward += FORWARD_SHOT_REWARD
			if environment.elapsed_seconds <= 2.0:
				reward += KICKOFF_CONTACT_REWARD
	var goal_team := StringName(step_result.get("goal_team", &""))
	if not goal_team.is_empty():
		reward += GOAL_REWARD if goal_team == team else -GOAL_REWARD
	if bool(step_result.get("terminated", false)):
		var own_score: int = int(step_result.get("blue_score", 0)) if team == &"blue" else int(step_result.get("red_score", 0))
		var opponent_score: int = int(step_result.get("red_score", 0)) if team == &"blue" else int(step_result.get("blue_score", 0))
		if own_score > opponent_score:
			reward += WIN_REWARD
		elif own_score < opponent_score:
			reward -= WIN_REWARD
	return reward


static func _is_viable_scoring_shot(environment, team: StringName, event: Dictionary) -> bool:
	if int(event.get("kick_mode", Schema.KICK_NONE)) != Schema.KICK_SHOT:
		return false
	var aim: Vector2 = event.get("aim", Vector2.ZERO) as Vector2
	if aim.length_squared() <= 0.000001:
		return false
	aim = aim.normalized()
	var attack_sign: float = 1.0 if team == &"blue" else -1.0
	if aim.x * attack_sign <= 0.05:
		return false
	var ball_position: Vector2 = event.get("ball_position_before", environment.ball.global_position) as Vector2
	var goal_x: float = environment.field_rect.end.x if team == &"blue" else environment.field_rect.position.x
	var horizontal_distance: float = (goal_x - ball_position.x) * attack_sign
	if horizontal_distance <= 0.0:
		return false
	var path_length: float = horizontal_distance / maxf(0.0001, aim.x * attack_sign)
	var goal_intersection_y: float = ball_position.y + aim.y * path_length
	var ball_radius: float = float(environment.BALL_RADIUS)
	var open_half_height: float = maxf(0.0, float(environment.GOAL_HALF_HEIGHT) - ball_radius)
	if absf(goal_intersection_y - environment.field_rect.get_center().y) > open_half_height:
		return false
	var shot_velocity: Vector2 = event.get("ball_velocity_after", Vector2.ZERO) as Vector2
	var remaining_speed: float = shot_velocity.length() - maxf(0.0, float(environment.ball.linear_damp)) * path_length
	if remaining_speed < float(environment.MINIMUM_KICK_SPEED) * 0.18:
		return false
	var goal_point := Vector2(goal_x, goal_intersection_y)
	var opponents: Array = environment.red_players if team == &"blue" else environment.blue_players
	var blocking_radius: float = float(environment.PLAYER_RADIUS) + ball_radius
	for opponent in opponents:
		var opponent_position: Vector2 = opponent.global_position as Vector2
		var closest_point: Vector2 = Geometry2D.get_closest_point_to_segment(opponent_position, ball_position, goal_point)
		if (closest_point - ball_position).dot(goal_point - ball_position) <= 0.0:
			continue
		if closest_point.distance_to(goal_point) <= ball_radius:
			continue
		if opponent_position.distance_to(closest_point) <= blocking_radius:
			return false
	return true


static func _goal_danger(environment, team: StringName) -> float:
	var own_goal_x: float = environment.field_rect.position.x if team == &"blue" else environment.field_rect.end.x
	var distance: float = absf(environment.ball.global_position.x - own_goal_x)
	var normalized_distance: float = clampf(distance / maxf(1.0, environment.field_rect.size.x), 0.0, 1.0)
	var center_delta: float = absf(environment.ball.global_position.y - environment.field_rect.get_center().y)
	var mouth_factor: float = 1.0 - clampf(center_delta / maxf(1.0, environment.GOAL_HALF_HEIGHT * 2.0), 0.0, 1.0)
	return (1.0 - normalized_distance) * mouth_factor
