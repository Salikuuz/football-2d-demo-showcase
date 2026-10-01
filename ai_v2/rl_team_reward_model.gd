class_name TheodoreRLV2TeamRewardModel
extends RefCounted

const BaseReward := preload("res://ai_v2/rl_reward_model.gd")
const Schema := preload("res://ai_v2/rl_schema.gd")

const FIELD_PROGRESS_WEIGHT: float = 0.22
const TEAM_POSSESSION_STEP_REWARD: float = 0.0025
const DANGER_WEIGHT: float = 0.10
const GOAL_REWARD: float = 10.0
const WIN_REWARD: float = 20.0
const POSSESSION_GAIN_REWARD: float = 0.10
const POSSESSION_LOSS_PENALTY: float = 0.12
const COMPLETED_PASS_REWARD: float = 0.24
const INTENDED_PASS_BONUS: float = 0.08
const INTERCEPTED_PASS_PENALTY: float = 0.12
const FORWARD_SHOT_REWARD: float = 0.05
const KICKOFF_CONTACT_REWARD: float = 0.08
const DOUBLE_COMMIT_STEP_PENALTY: float = 0.004
const DOUBLE_COMMIT_DISTANCE: float = 430.0


static func capture(environment, team: StringName) -> Dictionary:
	var own_players: Array = environment.blue_players if team == &"blue" else environment.red_players
	var opponents: Array = environment.red_players if team == &"blue" else environment.blue_players
	var attack_sign: float = 1.0 if team == &"blue" else -1.0
	var field_width: float = maxf(1.0, environment.field_rect.size.x)
	var team_distance: float = _nearest_distance(own_players, environment.ball.global_position)
	var opponent_distance: float = _nearest_distance(opponents, environment.ball.global_position)
	var owner_team: StringName = &""
	if team_distance <= environment.BALL_CONTROL_DISTANCE or opponent_distance <= environment.BALL_CONTROL_DISTANCE:
		owner_team = team if team_distance <= opponent_distance else (&"red" if team == &"blue" else &"blue")
	return {
		"ball_progress": (environment.ball.global_position.x - environment.field_rect.get_center().x) * attack_sign / field_width,
		"team_controls": team_distance <= environment.BALL_CONTROL_DISTANCE,
		"opponent_controls": opponent_distance <= environment.BALL_CONTROL_DISTANCE,
		"owner_team": owner_team,
		"close_teammates": _players_near_ball(own_players, environment.ball.global_position, DOUBLE_COMMIT_DISTANCE),
		"own_goal_danger": BaseReward._goal_danger(environment, team),
		"blue_score": environment.manager.blue_score,
		"red_score": environment.manager.red_score
	}


static func transition_reward(environment, team: StringName, before: Dictionary, step_result: Dictionary) -> float:
	var components: Dictionary = transition_reward_components(environment, team, before, step_result)
	return float(components.get("shared", 0.0)) + float(components.get("aggregate_execution", 0.0))


static func transition_reward_components(environment, team: StringName, before: Dictionary, step_result: Dictionary) -> Dictionary:
	var after: Dictionary = capture(environment, team)
	var shared_reward: float = (float(after.get("ball_progress", 0.0)) - float(before.get("ball_progress", 0.0))) * FIELD_PROGRESS_WEIGHT
	if bool(after.get("team_controls", false)):
		shared_reward += TEAM_POSSESSION_STEP_REWARD
	elif bool(after.get("opponent_controls", false)):
		shared_reward -= TEAM_POSSESSION_STEP_REWARD
	shared_reward += (float(before.get("own_goal_danger", 0.0)) - float(after.get("own_goal_danger", 0.0))) * DANGER_WEIGHT
	var before_owner := StringName(str(before.get("owner_team", "")))
	var after_owner := StringName(str(after.get("owner_team", "")))
	if before_owner != team and after_owner == team:
		shared_reward += POSSESSION_GAIN_REWARD
	elif before_owner == team and after_owner != team and not after_owner.is_empty():
		shared_reward -= POSSESSION_LOSS_PENALTY
	var close_teammates: int = int(after.get("close_teammates", 0))
	if close_teammates > 1:
		shared_reward -= float(close_teammates - 1) * DOUBLE_COMMIT_STEP_PENALTY
	var execution_by_slot: Dictionary = {}
	for event_value in step_result.get("events", []) as Array:
		var event: Dictionary = event_value as Dictionary
		if StringName(str(event.get("team", ""))) != team:
			continue
		var event_type: String = str(event.get("type", ""))
		if event_type == "pass_completed":
			_add_slot_reward(execution_by_slot, int(event.get("passer_slot", -1)), COMPLETED_PASS_REWARD)
			if bool(event.get("intended", false)):
				_add_slot_reward(execution_by_slot, int(event.get("receiver_slot", -1)), INTENDED_PASS_BONUS)
		elif event_type == "pass_intercepted":
			_add_slot_reward(execution_by_slot, int(event.get("passer_slot", -1)), -INTERCEPTED_PASS_PENALTY)
		elif event_type == "kick":
			var event_slot: int = int(event.get("slot", -1))
			if _is_viable_scoring_shot(environment, team, event):
				_add_slot_reward(execution_by_slot, event_slot, FORWARD_SHOT_REWARD)
			if environment.elapsed_seconds <= 2.0:
				_add_slot_reward(execution_by_slot, event_slot, KICKOFF_CONTACT_REWARD)
	var goal_team := StringName(step_result.get("goal_team", &""))
	if not goal_team.is_empty():
		shared_reward += GOAL_REWARD if goal_team == team else -GOAL_REWARD
	if bool(step_result.get("terminated", false)):
		var own_score: int = int(step_result.get("blue_score", 0)) if team == &"blue" else int(step_result.get("red_score", 0))
		var opponent_score: int = int(step_result.get("red_score", 0)) if team == &"blue" else int(step_result.get("blue_score", 0))
		if own_score > opponent_score:
			shared_reward += WIN_REWARD
		elif own_score < opponent_score:
			shared_reward -= WIN_REWARD
	var aggregate_execution: float = 0.0
	for slot_reward_value in execution_by_slot.values():
		aggregate_execution += float(slot_reward_value)
	return {
		"shared": shared_reward,
		"execution_by_slot": execution_by_slot,
		"aggregate_execution": aggregate_execution
	}


static func reward_for_slot(components: Dictionary, slot: int) -> float:
	var execution_by_slot: Dictionary = components.get("execution_by_slot", {}) as Dictionary
	return float(components.get("shared", 0.0)) + float(execution_by_slot.get(slot, 0.0))


static func _add_slot_reward(rewards: Dictionary, slot: int, amount: float) -> void:
	if slot < 0 or is_zero_approx(amount):
		return
	rewards[slot] = float(rewards.get(slot, 0.0)) + amount


static func _is_viable_scoring_shot(environment, team: StringName, event: Dictionary) -> bool:
	return BaseReward._is_viable_scoring_shot(environment, team, event)


static func _nearest_distance(players: Array, ball_position: Vector2) -> float:
	var result: float = INF
	for player in players:
		result = minf(result, (player.global_position as Vector2).distance_to(ball_position))
	return result


static func _players_near_ball(players: Array, ball_position: Vector2, radius: float) -> int:
	var result: int = 0
	for player in players:
		if (player.global_position as Vector2).distance_to(ball_position) <= radius:
			result += 1
	return result
