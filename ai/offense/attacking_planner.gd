class_name CPUAttackingPlanner
extends RefCounted

const ACTION_DIRECT_SHOT: StringName = &"direct_shot"
const ACTION_WALL_SHOT: StringName = &"wall_shot"
const ACTION_SELF_PASS: StringName = &"self_pass"
const ACTION_CARRY: StringName = &"carry"
const ACTION_ONE_TWO: StringName = &"one_two"
const ACTION_REBOUND: StringName = &"rebound_setup"
const ACTION_RESET: StringName = &"reset_possession"
const ACTION_PASS: StringName = &"pass"

var _controller: Node


func setup(controller: Node) -> void:
	_controller = controller


func evaluate(opponent_goal: Node) -> Dictionary:
	if not _is_ready() or opponent_goal == null:
		return {}
	var player: Node = _controller.get("controlled_player")
	var ball: Node = _controller.get("ball")
	if player == null or ball == null:
		return {}
	var ball_position: Vector2 = ball.get("global_position")
	var pressure_distance: float = float(
		_controller.call("_nearest_opponent_distance", ball_position)
	)
	var pressure_radius: float = maxf(
		1.0,
		float(_controller.get("pass_pressure_radius"))
	)
	var pressure: float = clampf(
		1.0 - pressure_distance / (pressure_radius * 1.35),
		0.0,
		1.0
	)
	var candidates: Array[Dictionary] = []
	var rejected: PackedStringArray = PackedStringArray()
	var planning_depth := 1.0
	if _controller.has_method("_get_personality_planning_depth"):
		planning_depth = clampf(
			float(_controller.call("_get_personality_planning_depth")),
			0.2,
			1.0
		)
	_append_direct_shot(candidates, rejected, opponent_goal, pressure)
	if planning_depth >= 0.42:
		_append_wall_shot(candidates, rejected, opponent_goal, pressure)
	else:
		rejected.append("wall shot: planning depth too low")
	_append_pass_candidates(
		candidates,
		rejected,
		opponent_goal,
		pressure,
		planning_depth >= 0.58
	)
	if planning_depth >= 0.42:
		_append_self_pass(candidates, rejected, opponent_goal, pressure)
	_append_carry(candidates, rejected, opponent_goal, pressure)
	if planning_depth >= 0.70:
		_append_rebound(candidates, rejected, opponent_goal, pressure)
	if planning_depth >= 0.50:
		_append_reset(candidates, rejected, opponent_goal, pressure)
	if candidates.is_empty():
		return {
			"action": ACTION_CARRY,
			"score": 0.0,
			"target": ball_position,
			"destination": ball_position,
			"shot_quality": 0.0,
			"pass_quality": 0.0,
			"pressure": pressure,
			"reason": "no_legal_candidate",
			"rejected": rejected,
			"candidate_scores": {}
		}
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("score", -INF)) > float(b.get("score", -INF))
	)
	var best: Dictionary = candidates[0].duplicate(true)
	var scores: Dictionary = {}
	for candidate in candidates:
		var action_key: String = str(candidate.get("action", "unknown"))
		if not scores.has(action_key):
			scores[action_key] = float(candidate.get("score", 0.0))
	best["candidate_scores"] = scores
	best["rejected"] = rejected
	best["pressure"] = pressure
	if not best.has("shot_quality"):
		best["shot_quality"] = _best_metric(candidates, "shot_quality")
	if not best.has("pass_quality"):
		best["pass_quality"] = _best_metric(candidates, "pass_quality")
	return best


func _append_direct_shot(
	candidates: Array[Dictionary],
	rejected: PackedStringArray,
	opponent_goal: Node,
	pressure: float
) -> void:
	var ball: Node = _controller.get("ball")
	var ball_position: Vector2 = ball.get("global_position")
	var target: Vector2 = _controller.call(
		"_get_best_live_direct_shot_target",
		opponent_goal
	) as Vector2
	if target.is_zero_approx():
		target = _controller.call("_get_shot_target", opponent_goal) as Vector2
	var distance: float = ball_position.distance_to(target)
	var clearance: float = float(_controller.call(
		"_minimum_segment_clearance",
		ball_position,
		target
	))
	var required_lane: float = maxf(
		90.0,
		float(_controller.call("_required_direct_shot_lane", distance))
	)
	var lane_quality: float = clampf(clearance / required_lane, 0.0, 1.35) / 1.35
	var distance_quality: float = 1.0 - clampf((distance - 700.0) / 3900.0, 0.0, 1.0)
	var target_space: float = float(_controller.call("_nearest_opponent_distance", target))
	var space_quality: float = clampf(target_space / 950.0, 0.0, 1.0)
	var shot_quality: float = clampf(
		lane_quality * 0.52
		+ distance_quality * 0.34
		+ space_quality * 0.14,
		0.0,
		1.0
	)
	var player: Node = _controller.get("controlled_player")
	var is_gojo: bool = (
		player != null
		and player.has_method("is_satoru_gojo")
		and bool(player.call("is_satoru_gojo"))
	)
	var is_dictator: bool = (
		_controller.has_method("_is_dictator_mbappe_cpu")
		and bool(_controller.call("_is_dictator_mbappe_cpu"))
	)
	var power_strike_ready: bool = (
		player != null
		and int(player.get("selected_ability")) == FootballPlayer.ABILITY_POWER_STRIKE
		and _controller.has_method("_cpu_ability_is_ready")
		and bool(_controller.call("_cpu_ability_is_ready"))
	)
	var curve_shot_ready: bool = (
		player != null
		and int(player.get("selected_ability")) == FootballPlayer.ABILITY_QUICK_TRIGGER
		and _controller.has_method("_cpu_ability_is_ready")
		and bool(_controller.call("_cpu_ability_is_ready"))
	)
	var second_ball_value: float = _best_second_ball_team_value(
		_controller.call("_get_goal_center", opponent_goal) as Vector2
	)
	var minimum_lane_ratio: float = 0.48
	if power_strike_ready and second_ball_value >= 0.62:
		minimum_lane_ratio = 0.30
	elif curve_shot_ready:
		minimum_lane_ratio = 0.36
	if clearance < required_lane * minimum_lane_ratio:
		rejected.append("direct shot: blocked lane")
		return
	var maximum_direct_distance: float = 5400.0 if is_dictator else 5000.0
	if power_strike_ready:
		maximum_direct_distance = 6500.0
	elif curve_shot_ready:
		maximum_direct_distance = maxf(maximum_direct_distance, 5800.0)
	if distance > maximum_direct_distance:
		rejected.append("direct shot: too far")
		return
	var minimum_direct_quality: float = 0.39 if is_dictator else 0.44
	if power_strike_ready and second_ball_value >= 0.62:
		minimum_direct_quality = minf(minimum_direct_quality, 0.28)
	elif curve_shot_ready:
		minimum_direct_quality = minf(minimum_direct_quality, 0.35)
	if shot_quality < minimum_direct_quality:
		rejected.append("direct shot: conversion/chance-creation quality too low")
		return
	var team_strategy: StringName = StringName(_controller.call("_get_team_strategy"))
	var counter_style: bool = team_strategy == &"counter"
	var long_range_minimum_quality: float = 0.60
	if counter_style:
		long_range_minimum_quality = 0.50
	if is_gojo:
		long_range_minimum_quality = 0.45
	if is_dictator:
		long_range_minimum_quality = minf(long_range_minimum_quality, 0.44)
	# A long Power Strike / Curve Shot does not need to be a clean conversion
	# attempt when teammates are already positioned to attack the second ball.
	# Keep a minimum route quality, but let strong teams intentionally create
	# saves, deflections and rotation chaos from distance.
	if power_strike_ready:
		# Power Strike is allowed to test long, imperfect lanes. Teammates attacking
		# the second ball improve the value, but are no longer required before the
		# CPU is allowed to try something dangerous from range.
		long_range_minimum_quality = minf(
			long_range_minimum_quality,
			0.26 if second_ball_value >= 0.62 else 0.34
		)
	elif curve_shot_ready and second_ball_value >= 0.58:
		long_range_minimum_quality = minf(long_range_minimum_quality, 0.34)
	if distance > 3200.0 and shot_quality < long_range_minimum_quality:
		rejected.append("direct shot: long-range chance not worth possession")
		return
	var score: float = pow(shot_quality, 1.55) * 1080.0
	score += maxf(0.0, 2700.0 - distance) * 0.10
	score -= pressure * 75.0 if distance > 2300.0 else 0.0
	if counter_style:
		# Reward converting open transition space into an early shot instead of
		# always carrying until the standard committed-shot distance.
		var range_pressure: float = clampf((distance - 1900.0) / 2600.0, 0.0, 1.0)
		score += lerpf(70.0, 145.0, range_pressure)
	if is_dictator:
		# Permanent Overdrive otherwise makes open carrying lanes score too well.
		# Dictator should cash in a credible angle instead of oscillating forever.
		score += 165.0
	if power_strike_ready:
		# Power Strike can score OR create the next action through a forced save,
		# deflection or loose second ball. Team structure therefore contributes to
		# its value instead of requiring every attempt to be a clean solo finish.
		score += 320.0 + second_ball_value * 430.0
		if is_gojo:
			score += 160.0
	elif curve_shot_ready:
		score += 150.0 + second_ball_value * 180.0
	score += _role_action_bias(ACTION_DIRECT_SHOT)
	candidates.append({
		"action": ACTION_DIRECT_SHOT,
		"score": score,
		"target": target,
		"destination": target,
		"shot_quality": shot_quality,
		"pass_quality": 0.0,
		"reason": "best direct goal route",
		"uses_wall": false,
		"receiver_peer_id": 0
	})


func _append_wall_shot(
	candidates: Array[Dictionary],
	rejected: PackedStringArray,
	opponent_goal: Node,
	pressure: float
) -> void:
	var ball: Node = _controller.get("ball")
	var ball_position: Vector2 = ball.get("global_position")
	var goal_target: Vector2 = _controller.call("_get_shot_target", opponent_goal) as Vector2
	var route: Dictionary = _controller.call("_get_best_wall_route", goal_target) as Dictionary
	if route.is_empty():
		rejected.append("wall shot: no safe bank route")
		return
	var bounce: Vector2 = route.get("bounce", Vector2.ZERO) as Vector2
	if bounce.is_zero_approx():
		rejected.append("wall shot: missing bounce point")
		return
	var wall_clearance: float = float(route.get("clearance", 0.0))
	var direct_clearance: float = float(_controller.call(
		"_minimum_segment_clearance",
		ball_position,
		goal_target
	))
	var route_distance: float = float(route.get(
		"distance",
		ball_position.distance_to(bounce) + bounce.distance_to(goal_target)
	))
	var advantage: float = wall_clearance - direct_clearance
	var team_strategy: StringName = StringName(_controller.call("_get_team_strategy"))
	var counter_style: bool = team_strategy == &"counter"
	var player: Node = _controller.get("controlled_player")
	var is_gojo: bool = (
		player != null
		and player.has_method("is_satoru_gojo")
		and bool(player.call("is_satoru_gojo"))
	)
	var is_dictator: bool = (
		_controller.has_method("_is_dictator_mbappe_cpu")
		and bool(_controller.call("_is_dictator_mbappe_cpu"))
	)
	# Normal personalities still bank only when the wall clearly improves the
	# lane. Counterattackers may use a comparably safe bank on purpose, giving
	# them genuine shooting-angle variety instead of only straight attempts.
	var minimum_advantage: float = 80.0
	if counter_style:
		minimum_advantage = -35.0
	if is_gojo:
		minimum_advantage = -75.0
	if is_dictator:
		minimum_advantage = minf(minimum_advantage, -45.0)
	if wall_clearance < 125.0 or advantage < minimum_advantage:
		rejected.append("wall shot: route is not valuable enough")
		return
	var distance_quality: float = 1.0 - clampf((route_distance - 1100.0) / 5200.0, 0.0, 1.0)
	var route_quality: float = clampf(wall_clearance / 620.0, 0.0, 1.0)
	var advantage_quality: float = clampf(advantage / 620.0, 0.0, 1.0)
	var shot_quality: float = clampf(
		route_quality * 0.42 + advantage_quality * 0.34 + distance_quality * 0.24,
		0.0,
		1.0
	)
	var minimum_wall_quality: float = 0.38
	if counter_style:
		minimum_wall_quality = 0.34
	if is_gojo:
		minimum_wall_quality = 0.31
	if is_dictator:
		minimum_wall_quality = minf(minimum_wall_quality, 0.33)
	if shot_quality < minimum_wall_quality:
		rejected.append("wall shot: conversion quality too low")
		return
	var score: float = pow(shot_quality, 1.45) * 930.0 - pressure * 40.0
	if counter_style:
		# A good bank is itself pressure in transition, not merely an emergency
		# fallback for a completely blocked direct lane.
		score += 115.0
	if is_dictator:
		score += 85.0
	score += _role_action_bias(ACTION_WALL_SHOT)
	candidates.append({
		"action": ACTION_WALL_SHOT,
		"score": score,
		"target": bounce,
		"destination": goal_target,
		"route_distance": route_distance,
		"shot_quality": shot_quality,
		"pass_quality": 0.0,
		"reason": "bank route beats blocked direct lane",
		"uses_wall": true,
		"receiver_peer_id": 0
	})


func _append_pass_candidates(
	candidates: Array[Dictionary],
	rejected: PackedStringArray,
	opponent_goal: Node,
	pressure: float,
	allow_one_two: bool = true
) -> void:
	var planner: Variant = _controller.get("_team_play_planner")
	if planner == null or not planner.has_method("get_ranked_pass_plans"):
		rejected.append("pass: team planner unavailable")
		return
	var ranked_variant: Variant = planner.call(
		"get_ranked_pass_plans",
		opponent_goal,
		8,
		true
	)
	if not ranked_variant is Array:
		rejected.append("pass: no ranked plans")
		return
	var ranked: Array = ranked_variant as Array
	var best_normal: Dictionary = {}
	var best_one_two: Dictionary = {}
	for plan_variant in ranked:
		if not plan_variant is Dictionary:
			continue
		var plan: Dictionary = plan_variant as Dictionary
		if not bool(plan.get("available", false)):
			continue
		var kind: StringName = StringName(plan.get("kind", &""))
		if kind == &"one_two":
			if best_one_two.is_empty():
				best_one_two = plan
		elif best_normal.is_empty():
			best_normal = plan
	if not best_normal.is_empty():
		_append_pass_plan_candidate(
			candidates,
			best_normal,
			ACTION_PASS,
			pressure,
			"highest-value teammate route"
		)
	else:
		rejected.append("pass: no safe ordinary receiver")
	if allow_one_two and not best_one_two.is_empty():
		_append_pass_plan_candidate(
			candidates,
			best_one_two,
			ACTION_ONE_TWO,
			pressure,
			"return lane remains open after the first pass"
		)
	elif not allow_one_two:
		rejected.append("one-two: planning depth too low")
	else:
		rejected.append("one-two: no safe return lane")


func _append_pass_plan_candidate(
	candidates: Array[Dictionary],
	plan: Dictionary,
	action: StringName,
	pressure: float,
	reason: String
) -> void:
	var quality: float = clampf(float(plan.get("quality", 0.0)), 0.0, 1.0)
	var margin: float = float(plan.get("interception_margin", -0.2))
	var progress: float = float(plan.get("forward_progress", 0.0))
	var counter_risk: float = clampf(float(plan.get("counter_risk", 0.0)), 0.0, 1.0)
	var score: float = quality * 920.0
	score += clampf(margin, -0.4, 1.5) * 150.0
	score += clampf(progress, -900.0, 1800.0) * 0.08
	score -= counter_risk * 260.0
	score += pressure * (165.0 if action == ACTION_PASS else 95.0)
	score += _role_action_bias(action)
	candidates.append({
		"action": action,
		"score": score,
		"target": plan.get("route_target", plan.get("destination", Vector2.ZERO)),
		"destination": plan.get("destination", Vector2.ZERO),
		"receiver_peer_id": int(plan.get("receiver_peer_id", 0)),
		"pass_plan": plan.duplicate(true),
		"uses_wall": bool(plan.get("uses_wall", false)),
		"shot_quality": 0.0,
		"pass_quality": quality,
		"reason": reason
	})


func _append_self_pass(
	candidates: Array[Dictionary],
	rejected: PackedStringArray,
	opponent_goal: Node,
	pressure: float
) -> void:
	var player: Node = _controller.get("controlled_player")
	var ball: Node = _controller.get("ball")
	var ball_position: Vector2 = ball.get("global_position")
	var attack_sign: float = float(_controller.call("_get_attack_sign"))
	var forward: Vector2 = Vector2(attack_sign, 0.0)
	var nearest_opponent: Node = _nearest_opponent(ball_position)
	var lateral_sign: float = -1.0
	if nearest_opponent != null:
		var opponent_position: Vector2 = nearest_opponent.get("global_position")
		lateral_sign = -1.0 if opponent_position.y >= ball_position.y else 1.0
	var target: Vector2 = _controller.call(
		"_clamp_to_field",
		ball_position + forward * 930.0 + Vector2(0.0, lateral_sign * 520.0)
	) as Vector2
	var route_clearance: float = float(_controller.call(
		"_minimum_segment_clearance",
		ball_position,
		target
	))
	var target_space: float = float(_controller.call("_nearest_opponent_distance", target))
	var progress: float = (target.x - ball_position.x) * attack_sign
	if progress < 360.0 or route_clearance < 150.0 or target_space < 390.0:
		rejected.append("self-pass: recovery space is not safe")
		return
	var player_distance: float = (player.get("global_position") as Vector2).distance_to(target)
	var control_quality: float = clampf(target_space / 1050.0, 0.0, 1.0)
	var route_quality: float = clampf(route_clearance / 650.0, 0.0, 1.0)
	var score: float = (
		control_quality * 330.0
		+ route_quality * 290.0
		+ clampf(progress / 1200.0, 0.0, 1.0) * 230.0
		+ pressure * 135.0
		- clampf(player_distance - 1200.0, 0.0, 1800.0) * 0.06
	)
	score += _role_action_bias(ACTION_SELF_PASS)
	candidates.append({
		"action": ACTION_SELF_PASS,
		"score": score,
		"target": target,
		"destination": target,
		"shot_quality": 0.0,
		"pass_quality": 0.0,
		"reason": "push beyond pressure and recover in open space",
		"uses_wall": false,
		"receiver_peer_id": 0
	})


func _append_carry(
	candidates: Array[Dictionary],
	rejected: PackedStringArray,
	opponent_goal: Node,
	pressure: float
) -> void:
	var ball: Node = _controller.get("ball")
	var ball_position: Vector2 = ball.get("global_position")
	var goal_center: Vector2 = _controller.call("_get_goal_center", opponent_goal) as Vector2
	var attack_sign: float = float(_controller.call("_get_attack_sign"))
	var center_y: float = (
		float(_controller.get("minimum_field_y"))
		+ float(_controller.get("maximum_field_y"))
	) * 0.5
	var side: float = -1.0 if ball_position.y > center_y else 1.0
	var targets: Array[Vector2] = [
		_controller.call("_clamp_to_field", ball_position + Vector2(attack_sign * 700.0, 0.0)) as Vector2,
		_controller.call("_clamp_to_field", ball_position + Vector2(attack_sign * 620.0, side * 480.0)) as Vector2,
		_controller.call("_clamp_to_field", ball_position + Vector2(attack_sign * 520.0, -side * 480.0)) as Vector2
	]
	var best_target: Vector2 = Vector2.ZERO
	var best_value: float = -INF
	for target in targets:
		var clearance: float = float(_controller.call(
			"_minimum_segment_clearance",
			ball_position,
			target
		))
		var openness: float = float(_controller.call("_nearest_opponent_distance", target))
		var goal_gain: float = ball_position.distance_to(goal_center) - target.distance_to(goal_center)
		var value: float = minf(clearance, 850.0) * 0.28 + minf(openness, 1200.0) * 0.36 + goal_gain * 0.22
		if value > best_value:
			best_value = value
			best_target = target
	if best_target.is_zero_approx() or best_value < 230.0:
		rejected.append("carry: no open control lane")
		return
	var score: float = best_value * 0.72
	score += (1.0 - pressure) * 150.0
	var team_size: int = 1
	if _controller.has_method("_get_checkpoint_team_player_count"):
		team_size = maxi(1, int(_controller.call("_get_checkpoint_team_player_count")))
	var player: Node = _controller.get("controlled_player")
	if team_size >= 3:
		# A carry remains a tool, not the default answer to every open patch of
		# grass in a crowded match. Re-evaluate passes/shots much more often.
		score *= 0.72 if team_size == 3 else 0.54
		if player != null:
			var ability_id: int = int(player.get("selected_ability"))
			if ability_id in [
				FootballPlayer.ABILITY_BURST_DRIBBLE,
				FootballPlayer.ABILITY_ELASTIC_STEP,
				FootballPlayer.ABILITY_BLIND_SPOT,
				FootballPlayer.ABILITY_BREAKAWAY,
				FootballPlayer.ABILITY_NUTMEG
			]:
				score *= 1.16
			elif (
				ability_id in [
					FootballPlayer.ABILITY_POWER_STRIKE,
					FootballPlayer.ABILITY_QUICK_TRIGGER,
					FootballPlayer.ABILITY_TIME_SKIP_PASS
				]
				and _controller.has_method("_cpu_ability_is_ready")
				and bool(_controller.call("_cpu_ability_is_ready"))
			):
				score *= 0.58
	if (
		_controller.has_method("_is_dictator_mbappe_cpu")
		and bool(_controller.call("_is_dictator_mbappe_cpu"))
	):
		score -= 170.0
	score += _role_action_bias(ACTION_CARRY)
	candidates.append({
		"action": ACTION_CARRY,
		"score": score,
		"target": best_target,
		"destination": best_target,
		"shot_quality": 0.0,
		"pass_quality": 0.0,
		"reason": "retain control while improving the next decision",
		"uses_wall": false,
		"receiver_peer_id": 0
	})


func _best_second_ball_team_value(goal_center: Vector2) -> float:
	if not _controller.has_method("_get_best_team_second_ball_value"):
		return 0.0
	return clampf(
		float(_controller.call("_get_best_team_second_ball_value", goal_center)),
		0.0,
		1.35
	)


func _append_rebound(
	candidates: Array[Dictionary],
	rejected: PackedStringArray,
	opponent_goal: Node,
	pressure: float
) -> void:
	var ball: Node = _controller.get("ball")
	var ball_position: Vector2 = ball.get("global_position")
	var goal_center: Vector2 = _controller.call("_get_goal_center", opponent_goal) as Vector2
	var opponent_team: StringName = &"red" if StringName((_controller.get("controlled_player") as Node).get("team")) == &"blue" else &"blue"
	var manager: Node = _controller.get("match_manager")
	if manager == null or not manager.has_method("get_designated_cpu_goalkeeper"):
		rejected.append("rebound: no goalkeeper to target")
		return
	var keeper: Node = manager.call("get_designated_cpu_goalkeeper", opponent_team) as Node
	if keeper == null or not is_instance_valid(keeper):
		rejected.append("rebound: opponent keeper unavailable")
		return
	var distance: float = ball_position.distance_to(goal_center)
	var player: Node = _controller.get("controlled_player")
	var ability_id: int = int(player.get("selected_ability")) if player != null else 0
	var shot_ability_ready: bool = (
		player != null
		and ability_id in [
			FootballPlayer.ABILITY_POWER_STRIKE,
			FootballPlayer.ABILITY_QUICK_TRIGGER
		]
		and _controller.has_method("_cpu_ability_is_ready")
		and bool(_controller.call("_cpu_ability_is_ready"))
	)
	var maximum_rebound_distance: float = 3200.0
	if ability_id == FootballPlayer.ABILITY_POWER_STRIKE and shot_ability_ready:
		maximum_rebound_distance = 4700.0
	elif ability_id == FootballPlayer.ABILITY_QUICK_TRIGGER and shot_ability_ready:
		maximum_rebound_distance = 3900.0
	if distance < 950.0 or distance > maximum_rebound_distance:
		rejected.append("rebound: wrong shooting distance")
		return
	var keeper_position: Vector2 = keeper.get("global_position")
	var lane: float = float(_controller.call(
		"_minimum_segment_clearance",
		ball_position,
		keeper_position
	))
	var minimum_rebound_lane: float = 120.0
	if shot_ability_ready:
		minimum_rebound_lane = 82.0
	if lane < minimum_rebound_lane:
		rejected.append("rebound: route to keeper is blocked")
		return
	var follower_value: float = 0.0
	for teammate_variant in _controller.call("_get_teammates") as Array:
		var teammate: Node = teammate_variant as Node
		if teammate == null or teammate == _controller.get("controlled_player"):
			continue
		if not bool(teammate.get("controls_enabled")):
			continue
		var teammate_position: Vector2 = teammate.get("global_position")
		var goal_distance: float = teammate_position.distance_to(goal_center)
		if goal_distance <= 1850.0:
			follower_value = maxf(
				follower_value,
				1.0 - clampf(goal_distance / 1850.0, 0.0, 1.0)
			)
	if follower_value <= 0.0:
		rejected.append("rebound: nobody can attack the second ball")
		return
	var keeper_coverage: float = 1.0 - clampf(
		absf(keeper_position.y - goal_center.y) / 950.0,
		0.0,
		1.0
	)
	var shot_quality: float = clampf(
		0.32 + follower_value * 0.34 + keeper_coverage * 0.18 + (1.0 - pressure) * 0.08,
		0.0,
		0.82
	)
	var score: float = shot_quality * 760.0 + _role_action_bias(ACTION_REBOUND)
	if shot_ability_ready:
		score += 190.0 + _best_second_ball_team_value(goal_center) * 280.0
	candidates.append({
		"action": ACTION_REBOUND,
		"score": score,
		"target": keeper_position,
		"destination": goal_center,
		"shot_quality": shot_quality,
		"pass_quality": 0.0,
		"reason": "keeper save can create an attackable second ball",
		"uses_wall": false,
		"receiver_peer_id": 0
	})


func _append_reset(
	candidates: Array[Dictionary],
	rejected: PackedStringArray,
	opponent_goal: Node,
	pressure: float
) -> void:
	var ball: Node = _controller.get("ball")
	var ball_position: Vector2 = ball.get("global_position")
	var attack_sign: float = float(_controller.call("_get_attack_sign"))
	var best_receiver: Node
	var best_target: Vector2 = Vector2.ZERO
	var best_quality: float = -INF
	for teammate_variant in _controller.call("_get_teammates") as Array:
		var teammate: Node = teammate_variant as Node
		if teammate == null or teammate == _controller.get("controlled_player"):
			continue
		if not bool(teammate.get("controls_enabled")):
			continue
		var target: Vector2 = _controller.call("_get_lead_pass_target", teammate) as Vector2
		var progress: float = (target.x - ball_position.x) * attack_sign
		if progress > 260.0:
			continue
		var clearance: float = float(_controller.call(
			"_minimum_segment_clearance",
			ball_position,
			target
		))
		var openness: float = float(_controller.call("_nearest_opponent_distance", target))
		var quality: float = minf(clearance, 1000.0) * 0.46 + minf(openness, 1300.0) * 0.44 - absf(progress) * 0.07
		if quality > best_quality:
			best_quality = quality
			best_receiver = teammate
			best_target = target
	if best_receiver != null and best_quality >= 310.0:
		var pass_quality: float = clampf(best_quality / 1000.0, 0.0, 1.0)
		var score: float = pass_quality * 620.0 + pressure * 330.0
		score += _role_action_bias(ACTION_RESET)
		candidates.append({
			"action": ACTION_RESET,
			"score": score,
			"target": best_target,
			"destination": best_target,
			"receiver_peer_id": int(best_receiver.get("owner_peer_id")),
			"pass_quality": pass_quality,
			"shot_quality": 0.0,
			"reason": "recycle away from pressure",
			"uses_wall": false
		})
		return
	if (
		_controller.has_method("_is_true_one_vs_one")
		and bool(_controller.call("_is_true_one_vs_one"))
	):
		# There is nobody to recycle possession to in a real 1v1. The old
		# fallback could be selected repeatedly and walk an elite attacker all
		# the way back toward its own goal. Use the existing carry/self-pass/
		# duel systems instead.
		rejected.append("reset: backward self-recycle disabled in 1v1")
		return
	var reset_target: Vector2 = _controller.call(
		"_clamp_to_field",
		ball_position + Vector2(-attack_sign * 520.0, 0.0)
	) as Vector2
	var reset_space: float = float(_controller.call("_nearest_opponent_distance", reset_target))
	if reset_space < 420.0:
		rejected.append("reset: no safe recycle lane")
		return
	var carry_score: float = clampf(reset_space / 1200.0, 0.0, 1.0) * 360.0 + pressure * 260.0
	carry_score += _role_action_bias(ACTION_RESET)
	candidates.append({
		"action": ACTION_RESET,
		"score": carry_score,
		"target": reset_target,
		"destination": reset_target,
		"receiver_peer_id": 0,
		"pass_quality": 0.0,
		"shot_quality": 0.0,
		"reason": "carry backward to rebuild possession",
		"uses_wall": false
	})


func _role_action_bias(action: StringName) -> float:
	if _controller == null or not _controller.has_method("_get_tactical_role"):
		return 0.0
	var player: Node = _controller.get("controlled_player")
	var role: StringName = StringName(_controller.call("_get_tactical_role", player))
	var bias := 0.0
	match role:
		&"striker":
			if action in [ACTION_DIRECT_SHOT, ACTION_REBOUND, ACTION_SELF_PASS]:
				bias += 150.0
			if action == ACTION_RESET:
				bias -= 110.0
		&"playmaker":
			if action in [ACTION_PASS, ACTION_ONE_TWO]:
				bias += 145.0
			elif action == ACTION_CARRY:
				bias += 45.0
			if action == ACTION_DIRECT_SHOT:
				bias -= 40.0
		&"defender":
			if action in [ACTION_RESET, ACTION_PASS]:
				bias += 125.0
			elif action == ACTION_CARRY:
				bias += 30.0
			if action in [ACTION_DIRECT_SHOT, ACTION_REBOUND]:
				bias -= 135.0
		&"goalkeeper":
			if action in [ACTION_RESET, ACTION_PASS]:
				bias += 220.0
			else:
				bias -= 280.0
	if _controller.has_method("_get_personality_action_bias"):
		bias += float(_controller.call("_get_personality_action_bias", action))
	return bias


func _nearest_opponent(position: Vector2) -> Node:
	var nearest: Node
	var nearest_distance: float = INF
	for opponent_variant in _controller.call("_get_opponents") as Array:
		var opponent: Node = opponent_variant as Node
		if opponent == null or not is_instance_valid(opponent):
			continue
		if not bool(opponent.get("controls_enabled")):
			continue
		var distance: float = (opponent.get("global_position") as Vector2).distance_to(position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = opponent
	return nearest


func _best_metric(candidates: Array[Dictionary], key: String) -> float:
	var best: float = 0.0
	for candidate in candidates:
		best = maxf(best, float(candidate.get(key, 0.0)))
	return best


func _is_ready() -> bool:
	return (
		_controller != null
		and is_instance_valid(_controller)
		and _controller.get("controlled_player") != null
		and _controller.get("ball") != null
	)
