class_name HybridCurriculumManager
extends RefCounted


const STAGES: Array[Dictionary] = [
	{"id": "reach_stationary_ball", "team_size": 1, "duration": 16.0, "success": "ball_touch", "threshold": 0.85},
	{"id": "empty_goal_shot", "team_size": 1, "duration": 18.0, "success": "goal", "threshold": 0.8},
	{"id": "moving_ball_shot", "team_size": 1, "duration": 22.0, "success": "on_target", "threshold": 0.75},
	{"id": "save_predetermined_shot", "team_size": 1, "duration": 18.0, "success": "save", "threshold": 0.72},
	{"id": "clear_goal_danger", "team_size": 1, "duration": 18.0, "success": "clear", "threshold": 0.75},
	{"id": "score_stationary_defender", "team_size": 1, "duration": 28.0, "success": "goal", "threshold": 0.65},
	{"id": "score_moving_defender", "team_size": 1, "duration": 32.0, "success": "goal", "threshold": 0.58},
	{"id": "defend_direct_shot", "team_size": 1, "duration": 28.0, "success": "no_concede", "threshold": 0.7},
	{"id": "defend_wall_shot", "team_size": 1, "duration": 30.0, "success": "no_concede", "threshold": 0.62},
	{"id": "learn_wall_bank", "team_size": 1, "duration": 30.0, "success": "wall_chance", "threshold": 0.6},
	{"id": "learn_delayed_touch", "team_size": 1, "duration": 30.0, "success": "possession_quality", "threshold": 0.62},
	{"id": "learn_fake_challenge", "team_size": 1, "duration": 30.0, "success": "containment", "threshold": 0.6},
	{"id": "basic_passing", "team_size": 2, "duration": 36.0, "success": "pass_completion", "threshold": 0.7},
	{"id": "pass_one_defender", "team_size": 2, "duration": 42.0, "success": "chance_created", "threshold": 0.58},
	{"id": "supporting_runs", "team_size": 2, "duration": 42.0, "success": "support_quality", "threshold": 0.62},
	{"id": "full_1v1", "team_size": 1, "duration": 50.0, "success": "win_rate", "threshold": 0.58},
	{"id": "full_2v2", "team_size": 2, "duration": 55.0, "success": "win_rate", "threshold": 0.56},
	{"id": "full_3v3", "team_size": 3, "duration": 60.0, "success": "win_rate", "threshold": 0.54},
	{"id": "full_4v4", "team_size": 4, "duration": 65.0, "success": "win_rate", "threshold": 0.53},
	{"id": "score_dependent", "team_size": 3, "duration": 55.0, "success": "situational_result", "threshold": 0.58},
	{"id": "overtime", "team_size": 3, "duration": 45.0, "success": "overtime_result", "threshold": 0.56}
]

var _stage_index: int = 0
var _history: Dictionary = {}
var _rng := RandomNumberGenerator.new()


func _init(seed_value: int = 104729) -> void:
	_rng.seed = seed_value


func set_stage(stage_id: String) -> bool:
	for index in range(STAGES.size()):
		if str(STAGES[index].get("id", "")) == stage_id:
			_stage_index = index
			return true
	return false


func set_stage_index(index: int) -> void:
	_stage_index = clampi(index, 0, STAGES.size() - 1)


func get_stage() -> Dictionary:
	return STAGES[_stage_index].duplicate(true)


func get_stage_index() -> int:
	return _stage_index


func record_result(success_value: float) -> bool:
	var stage := get_stage()
	var stage_id := str(stage.get("id", "full_match"))
	var samples := _history.get(stage_id, []) as Array
	samples.append(clampf(success_value, 0.0, 1.0))
	while samples.size() > 20:
		samples.pop_front()
	_history[stage_id] = samples
	if samples.size() < 8:
		return false
	var average := 0.0
	for value in samples:
		average += float(value)
	average /= float(samples.size())
	if average >= float(stage.get("threshold", 1.0)) and _stage_index < STAGES.size() - 1:
		_stage_index += 1
		return true
	return false


func revisit_weakest_stage(stage_scores: Dictionary) -> bool:
	var weakest_id := ""
	var weakest_margin := INF
	for stage in STAGES:
		var stage_id := str(stage.get("id", ""))
		if not stage_scores.has(stage_id):
			continue
		var margin := float(stage_scores[stage_id]) - float(stage.get("threshold", 1.0))
		if margin < weakest_margin:
			weakest_margin = margin
			weakest_id = stage_id
	if weakest_id.is_empty() or weakest_margin >= 0.0:
		return false
	return set_stage(weakest_id)


func apply_stage(manager: Node, challenger_team: StringName) -> void:
	if manager == null:
		return
	var stage := get_stage()
	var stage_id := str(stage.get("id", "full_1v1"))
	var blue_players := manager.get("blue_players") as Array
	var red_players := manager.get("red_players") as Array
	var ball: Node = manager.get("ball")
	if ball == null:
		return
	var attack_sign := 1.0 if challenger_team == &"blue" else -1.0
	var attack_players := blue_players if challenger_team == &"blue" else red_players
	var defend_players := red_players if challenger_team == &"blue" else blue_players
	_reset_body(ball, Vector2(3650.0, 2500.0), Vector2.ZERO)
	_enable_players(attack_players, true)
	_enable_players(defend_players, true)
	match stage_id:
		"reach_stationary_ball":
			_enable_players(defend_players, false)
			_place_first(attack_players, Vector2(1800.0 if attack_sign > 0.0 else 5500.0, 2500.0))
		"empty_goal_shot", "moving_ball_shot", "learn_wall_bank", "learn_delayed_touch":
			_enable_players(defend_players, false)
			_place_first(attack_players, Vector2(2450.0 if attack_sign > 0.0 else 4850.0, 2500.0))
			if stage_id == "moving_ball_shot":
				ball.set("linear_velocity", Vector2(attack_sign * 900.0, _rng.randf_range(-450.0, 450.0)))
		"save_predetermined_shot", "clear_goal_danger", "defend_direct_shot", "defend_wall_shot":
			_place_first(attack_players, Vector2(1200.0 if attack_sign > 0.0 else 6100.0, 2500.0))
			_place_first(defend_players, Vector2(6100.0 if attack_sign > 0.0 else 1200.0, 2500.0))
			_reset_body(ball, Vector2(5650.0 if attack_sign > 0.0 else 1650.0, 2500.0), Vector2(-attack_sign * 1600.0, _rng.randf_range(-500.0, 500.0)))
		"score_stationary_defender":
			_place_first(attack_players, Vector2(2700.0 if attack_sign > 0.0 else 4600.0, 2500.0))
			_place_first(defend_players, Vector2(3900.0 if attack_sign > 0.0 else 3400.0, 2500.0))
			_freeze_first(defend_players)
		"score_moving_defender", "learn_fake_challenge", "full_1v1":
			_place_first(attack_players, Vector2(2650.0 if attack_sign > 0.0 else 4650.0, 2500.0))
			_place_first(defend_players, Vector2(4050.0 if attack_sign > 0.0 else 3250.0, 2500.0))
		"basic_passing", "pass_one_defender", "supporting_runs":
			_place_line(attack_players, 2350.0 if attack_sign > 0.0 else 4950.0, attack_sign)
			_place_line(defend_players, 4300.0 if attack_sign > 0.0 else 3000.0, -attack_sign)
		"score_dependent":
			if challenger_team == &"blue":
				manager.set("blue_score", 1 if _rng.randf() < 0.5 else 0)
				manager.set("red_score", 2)
			else:
				manager.set("red_score", 1 if _rng.randf() < 0.5 else 0)
				manager.set("blue_score", 2)
			manager.set("regulation_time_remaining", 30.0)
		"overtime":
			manager.set("is_overtime", true)
			manager.set("overtime_elapsed", 0.0)
		_:
			pass


func get_state() -> Dictionary:
	return {
		"stage_index": _stage_index,
		"stage": get_stage(),
		"history": _history.duplicate(true)
	}


func _reset_body(body: Node, position: Vector2, velocity: Vector2) -> void:
	if body == null:
		return
	body.set("global_position", position)
	body.set("linear_velocity", velocity)
	if body.get("angular_velocity") != null:
		body.set("angular_velocity", 0.0)


func _enable_players(players: Array, enabled: bool) -> void:
	for player in players:
		if player == null or not is_instance_valid(player):
			continue
		player.set("controls_enabled", enabled)
		player.set("linear_velocity", Vector2.ZERO)


func _place_first(players: Array, position: Vector2) -> void:
	for player in players:
		if player == null or not is_instance_valid(player):
			continue
		_reset_body(player, position, Vector2.ZERO)
		return


func _freeze_first(players: Array) -> void:
	for player in players:
		if player == null or not is_instance_valid(player):
			continue
		player.set("controls_enabled", false)
		player.set("linear_velocity", Vector2.ZERO)
		return


func _place_line(players: Array, x: float, attack_sign: float) -> void:
	var active: Array = []
	for player in players:
		if player != null and is_instance_valid(player):
			active.append(player)
	for index in range(active.size()):
		var y := 2500.0 + (float(index) - float(active.size() - 1) * 0.5) * 760.0
		_reset_body(active[index], Vector2(x - attack_sign * float(index) * 260.0, y), Vector2.ZERO)


func set_stage_by_name(stage_name: String) -> bool:
	return set_stage(stage_name)


func get_current_stage() -> Dictionary:
	var stage := get_stage()
	stage["name"] = str(stage.get("id", "full_match"))
	return stage


func apply_stage_to_match(stage: Dictionary, manager: Node) -> void:
	if manager == null:
		return
	var stage_id := str(stage.get("id", stage.get("name", "")))
	if not stage_id.is_empty():
		set_stage(stage_id)
	apply_stage(manager, &"blue")
