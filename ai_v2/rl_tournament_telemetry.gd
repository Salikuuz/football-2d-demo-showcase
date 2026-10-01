class_name TheodoreRLV2TournamentTelemetry
extends RefCounted

const Schema := preload("res://ai_v2/rl_schema.gd")

const CONTROL_DISTANCE: float = 260.0
const DOUBLE_COMMIT_DISTANCE: float = 430.0
const PASS_TIMEOUT_SECONDS: float = 2.2
const REBOUND_TIMEOUT_SECONDS: float = 1.2

var _stats: Dictionary = {}
var _pending_passes: Dictionary = {}
var _pending_rebounds: Dictionary = {}
var _last_owner: Dictionary = {}
var _last_kicker_team: StringName = &""
var _kickoff_resolved: bool = false
var _previous_ball_position: Vector2 = Vector2.ZERO
var _previous_ball_velocity: Vector2 = Vector2.ZERO


func begin(environment) -> void:
	_stats = {"blue": _empty_stats(), "red": _empty_stats()}
	_pending_passes.clear()
	_pending_rebounds.clear()
	_last_owner = _owner(environment)
	_last_kicker_team = &""
	_kickoff_resolved = false
	_previous_ball_position = environment.ball.global_position
	_previous_ball_velocity = environment.ball.linear_velocity


func before_step(environment, actions_by_team: Dictionary) -> void:
	for team in [&"blue", &"red"]:
		var team_key: String = String(team)
		var stats: Dictionary = _stats[team_key] as Dictionary
		var actions: Array = actions_by_team.get(team_key, []) as Array
		for action_value in actions:
			var action: Dictionary = action_value as Dictionary
			if int(action.get("kick_mode", Schema.KICK_NONE)) != Schema.KICK_NONE:
				stats["kick_requests"] = int(stats["kick_requests"]) + 1
			if bool(action.get("ability_trigger", false)):
				stats["ability_requests"] = int(stats["ability_requests"]) + 1
		_sample_shape(environment, team, stats)
	_previous_ball_position = environment.ball.global_position
	_previous_ball_velocity = environment.ball.linear_velocity


func after_step(environment, step_result: Dictionary) -> void:
	for event_value in step_result.get("events", []) as Array:
		var event: Dictionary = event_value as Dictionary
		var event_type: String = str(event.get("type", ""))
		var team: StringName = StringName(str(event.get("team", "")))
		if event_type == "kick" and not team.is_empty():
			_record_kick(environment, team, event)
		elif event_type == "ability_activated" and not team.is_empty():
			var stats: Dictionary = _stats[String(team)] as Dictionary
			stats["ability_uses"] = int(stats["ability_uses"]) + 1
			var ability_id: int = int(event.get("ability_id", 0))
			var usage: Dictionary = stats["ability_usage"] as Dictionary
			usage[ability_id] = int(usage.get(ability_id, 0)) + 1
		elif event_type == "goal" and not team.is_empty():
			_record_goal(environment, team, event)
	var owner: Dictionary = _owner(environment)
	_record_possession(owner)
	_resolve_passes(environment, owner)
	_resolve_rebounds(environment, owner)
	if not _kickoff_resolved and environment.elapsed_seconds >= 2.0:
		for team_key in ["blue", "red"]:
			var stats: Dictionary = _stats[team_key] as Dictionary
			stats["kickoff_mistakes"] = int(stats["kickoff_mistakes"]) + 1
		_kickoff_resolved = true
	_last_owner = owner


func result(candidate_team: StringName) -> Dictionary:
	var opponent_team: StringName = &"red" if candidate_team == &"blue" else &"blue"
	return {
		"candidate": (_stats[String(candidate_team)] as Dictionary).duplicate(true),
		"current_ai": (_stats[String(opponent_team)] as Dictionary).duplicate(true),
		"blue": (_stats["blue"] as Dictionary).duplicate(true),
		"red": (_stats["red"] as Dictionary).duplicate(true)
	}


func _empty_stats() -> Dictionary:
	return {
		"steps": 0,
		"possession_steps": 0,
		"possession_gains": 0,
		"possession_losses": 0,
		"kick_requests": 0,
		"successful_kicks": 0,
		"shots": 0,
		"passes_attempted": 0,
		"passes_completed": 0,
		"line_breaks": 0,
		"ability_requests": 0,
		"ability_uses": 0,
		"ability_usage": {},
		"double_commit_steps": 0,
		"rebound_opportunities": 0,
		"rebound_collections": 0,
		"goalkeeper_mistakes": 0,
		"kickoff_mistakes": 0,
		"own_goals": 0
	}


func _sample_shape(environment, team: StringName, stats: Dictionary) -> void:
	stats["steps"] = int(stats["steps"]) + 1
	var team_players: Array = environment.blue_players if team == &"blue" else environment.red_players
	var close_players: int = 0
	for player in team_players:
		if player.global_position.distance_to(environment.ball.global_position) <= DOUBLE_COMMIT_DISTANCE:
			close_players += 1
	if close_players >= 2 and environment.elapsed_seconds > 0.75:
		stats["double_commit_steps"] = int(stats["double_commit_steps"]) + 1
	var owner: Dictionary = _owner(environment)
	if StringName(str(owner.get("team", ""))) == team:
		stats["possession_steps"] = int(stats["possession_steps"]) + 1


func _record_kick(environment, team: StringName, event: Dictionary) -> void:
	var stats: Dictionary = _stats[String(team)] as Dictionary
	stats["successful_kicks"] = int(stats["successful_kicks"]) + 1
	_last_kicker_team = team
	if not _kickoff_resolved:
		var other_team: String = "red" if team == &"blue" else "blue"
		var other_stats: Dictionary = _stats[other_team] as Dictionary
		other_stats["kickoff_mistakes"] = int(other_stats["kickoff_mistakes"]) + 1
		_kickoff_resolved = true
	var kick_mode: int = int(event.get("kick_mode", Schema.KICK_NONE))
	if kick_mode == Schema.KICK_PASS:
		stats["passes_attempted"] = int(stats["passes_attempted"]) + 1
		_pending_passes[String(team)] = {
			"passer_slot": int(event.get("slot", -1)),
			"receiver_slot": int(event.get("receiver_slot", -1)),
			"expires": environment.elapsed_seconds + PASS_TIMEOUT_SECONDS
		}
	else:
		var aim: Vector2 = event.get("aim", Vector2.ZERO) as Vector2
		var attack_sign: float = 1.0 if team == &"blue" else -1.0
		if aim.x * attack_sign > 0.42:
			stats["shots"] = int(stats["shots"]) + 1
			var ball_position: Vector2 = event.get("ball_position_before", environment.ball.global_position) as Vector2
			var goal_x: float = environment.field_rect.end.x if team == &"blue" else environment.field_rect.position.x
			if absf(goal_x - ball_position.x) < environment.field_rect.size.x * 0.3:
				_pending_rebounds[String(team)] = {"expires": environment.elapsed_seconds + REBOUND_TIMEOUT_SECONDS}
	_record_line_break(environment, team, event, stats)


func _record_line_break(environment, team: StringName, event: Dictionary, stats: Dictionary) -> void:
	var start: Vector2 = event.get("ball_position_before", environment.ball.global_position) as Vector2
	var aim: Vector2 = event.get("aim", Vector2.ZERO) as Vector2
	var attack_sign: float = 1.0 if team == &"blue" else -1.0
	if aim.x * attack_sign <= 0.2:
		return
	var opponents: Array = environment.red_players if team == &"blue" else environment.blue_players
	var broken: bool = false
	for opponent in opponents:
		var forward_distance: float = (opponent.global_position.x - start.x) * attack_sign
		if forward_distance > 0.0 and forward_distance < 1800.0:
			broken = true
			break
	if broken:
		stats["line_breaks"] = int(stats["line_breaks"]) + 1


func _record_goal(environment, scoring_team: StringName, event: Dictionary) -> void:
	var conceding_team: StringName = &"red" if scoring_team == &"blue" else &"blue"
	if _last_kicker_team == conceding_team:
		var own_stats: Dictionary = _stats[String(conceding_team)] as Dictionary
		own_stats["own_goals"] = int(own_stats["own_goals"]) + 1
	var goalkeeper_distance: float = float(event.get("goalkeeper_distance", 0.0))
	if goalkeeper_distance > environment.field_rect.size.x * 0.23:
		var conceded_stats: Dictionary = _stats[String(conceding_team)] as Dictionary
		conceded_stats["goalkeeper_mistakes"] = int(conceded_stats["goalkeeper_mistakes"]) + 1
	_pending_passes.clear()
	_pending_rebounds.clear()
	_last_owner.clear()
	_last_kicker_team = &""
	_kickoff_resolved = false


func _record_possession(owner: Dictionary) -> void:
	var old_team: String = str(_last_owner.get("team", ""))
	var new_team: String = str(owner.get("team", ""))
	if old_team == new_team or old_team.is_empty() or new_team.is_empty():
		return
	var old_stats: Dictionary = _stats[old_team] as Dictionary
	var new_stats: Dictionary = _stats[new_team] as Dictionary
	old_stats["possession_losses"] = int(old_stats["possession_losses"]) + 1
	new_stats["possession_gains"] = int(new_stats["possession_gains"]) + 1


func _resolve_passes(environment, owner: Dictionary) -> void:
	for team_key_variant in _pending_passes.keys():
		var team_key: String = str(team_key_variant)
		var pending: Dictionary = _pending_passes[team_key] as Dictionary
		if environment.elapsed_seconds > float(pending.get("expires", 0.0)):
			_pending_passes.erase(team_key_variant)
			continue
		var owner_team: String = str(owner.get("team", ""))
		if not owner_team.is_empty() and owner_team != team_key:
			_pending_passes.erase(team_key_variant)
			continue
		if owner_team == team_key and int(owner.get("slot", -1)) != int(pending.get("passer_slot", -1)):
			var stats: Dictionary = _stats[team_key] as Dictionary
			stats["passes_completed"] = int(stats["passes_completed"]) + 1
			_pending_passes.erase(team_key_variant)


func _resolve_rebounds(environment, owner: Dictionary) -> void:
	for team_key_variant in _pending_rebounds.keys():
		var team_key: String = str(team_key_variant)
		var pending: Dictionary = _pending_rebounds[team_key] as Dictionary
		if environment.elapsed_seconds > float(pending.get("expires", 0.0)):
			_pending_rebounds.erase(team_key_variant)
			continue
		var attack_sign: float = 1.0 if team_key == "blue" else -1.0
		var reversed: bool = _previous_ball_velocity.x * attack_sign > 700.0 and environment.ball.linear_velocity.x * attack_sign < -200.0
		if reversed:
			var stats: Dictionary = _stats[team_key] as Dictionary
			stats["rebound_opportunities"] = int(stats["rebound_opportunities"]) + 1
			if str(owner.get("team", "")) == team_key:
				stats["rebound_collections"] = int(stats["rebound_collections"]) + 1
			_pending_rebounds.erase(team_key_variant)


func _owner(environment) -> Dictionary:
	var closest_distance: float = CONTROL_DISTANCE
	var result: Dictionary = {}
	for player in environment.players:
		var distance: float = player.global_position.distance_to(environment.ball.global_position)
		if distance <= closest_distance:
			closest_distance = distance
			result = {"team": String(player.team), "slot": player.team_slot}
	return result
