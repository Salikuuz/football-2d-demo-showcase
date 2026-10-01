class_name LargeTeamParallelSnapshotBrain
extends RefCounted

# Pure-data large-team tactical prepass. The MatchManager builds one immutable
# snapshot on the main physics thread. Each CPU agent then evaluates its own
# high-level movement/reception state on Godot worker threads. No Node,
# SceneTree, physics-server, rendering, audio or networking API is touched here.

const TEAM_BLUE: StringName = &"blue"
const TEAM_RED: StringName = &"red"
const NO_TEAM: StringName = &""

const ROLE_DEFENDER: StringName = &"defender"
const ROLE_MIDFIELDER: StringName = &"midfielder"
const ROLE_WINGER: StringName = &"winger"
const ROLE_STRIKER: StringName = &"striker"

const INTENT_CHASE: StringName = &"chase_ball"
const INTENT_COVER: StringName = &"cover"
const INTENT_MARK: StringName = &"mark"
const INTENT_RECEIVE: StringName = &"receive"
const INTENT_FORWARD_RUN: StringName = &"forward_run"
const INTENT_WIDE_SUPPORT: StringName = &"wide_support"

var _tasks: Array[Dictionary] = []
var _snapshot: Dictionary = {}
var _single_agent: Dictionary = {}
var _serial: int = 0
var _submitted_frame: int = -1


func has_pending() -> bool:
	return not _tasks.is_empty()


func submit(snapshot: Dictionary) -> bool:
	# The mobile Web preset is intentionally single-threaded for iPhone/Safari
	# compatibility. MatchManager already avoids this path there; keep the worker
	# object safe as well in case another caller is added later.
	if OS.has_feature("web"):
		return false
	if has_pending() or snapshot.is_empty():
		return false
	var agents: Array = snapshot.get("agents", []) as Array
	if agents.is_empty():
		return false
	_serial += 1
	_submitted_frame = int(snapshot.get("physics_frame", -1))
	# The manager creates a fresh snapshot exclusively for this submission and
	# never mutates it afterwards. Share that immutable snapshot directly across
	# workers instead of deep-copying the full 12-player world on the physics
	# thread every 30 Hz. Read-only container access is all these jobs perform.
	var immutable_snapshot := snapshot
	for agent_variant in agents:
		var agent := agent_variant as Dictionary
		if not bool(agent.get("cpu_controlled", false)) or not bool(agent.get("enabled", false)):
			continue
		var runner = get_script().new()
		runner._snapshot = immutable_snapshot
		runner._single_agent = agent
		var result_box: Array = [{}]
		var task_id := WorkerThreadPool.add_task(
			runner._run_single_agent.bind(result_box),
			bool(agent.get("part4_worker_high_priority", false)),
			"large-team CPU %d snapshot" % int(agent.get("peer_id", 0))
		)
		if task_id >= 0:
			_tasks.append({
				"id": task_id,
				"runner": runner,
				"box": result_box,
				"frame": _submitted_frame
			})
	return not _tasks.is_empty()


func poll() -> Dictionary:
	if _tasks.is_empty():
		return {}
	var completed_plans: Dictionary = {}
	var remaining: Array[Dictionary] = []
	var newest_frame := -1
	for task: Dictionary in _tasks:
		var task_id := int(task.get("id", -1))
		if task_id < 0 or not WorkerThreadPool.is_task_completed(task_id):
			remaining.append(task)
			continue
		# This wait is only called after is_task_completed() returned true, so the
		# physics thread never waits for AI computation to finish.
		WorkerThreadPool.wait_for_task_completion(task_id)
		var box := task.get("box", []) as Array
		if not box.is_empty() and box[0] is Dictionary:
			var plan := box[0] as Dictionary
			var peer_id := int(plan.get("peer_id", 0))
			if peer_id > 0:
				completed_plans[peer_id] = plan
				newest_frame = maxi(newest_frame, int(plan.get("snapshot_frame", -1)))
	_tasks = remaining
	if completed_plans.is_empty():
		return {}
	return {
		"serial": _serial,
		"physics_frame": newest_frame,
		"plans": completed_plans
	}


func wait_for_result() -> Dictionary:
	# Intentionally non-blocking. Kept for compatibility with older callers.
	return poll()


func shutdown() -> void:
	# Never block the gameplay/main thread during teardown. Worker callables keep
	# their runner/result storage alive until their short pure-data task exits.
	_tasks.clear()


func _run_single_agent(result_box: Array) -> void:
	result_box[0] = _plan_agent_result(_single_agent)


func _plan_agent_result(agent: Dictionary) -> Dictionary:
	if not bool(agent.get("cpu_controlled", false)) or not bool(agent.get("enabled", false)):
		return {}
	var team := StringName(agent.get("team", NO_TEAM))
	var own_players: Array = (
		_snapshot.get("blue_players", []) as Array
		if team == TEAM_BLUE
		else _snapshot.get("red_players", []) as Array
	)
	var opponents: Array = (
		_snapshot.get("red_players", []) as Array
		if team == TEAM_BLUE
		else _snapshot.get("blue_players", []) as Array
	)
	var ball_position: Vector2 = _snapshot.get("ball_position", Vector2.ZERO)
	var ball_velocity: Vector2 = _snapshot.get("ball_velocity", Vector2.ZERO)
	var possession_team := StringName(_snapshot.get("possession_team", NO_TEAM))
	var peer_id := int(agent.get("peer_id", 0))
	var is_goalkeeper := bool(agent.get("goalkeeper", false))
	var carrier_peer_id := _find_team_carrier_peer(own_players, ball_position, possession_team == team)
	var committed_chaser := int(
		_snapshot.get("blue_chaser_peer_id", 0)
		if team == TEAM_BLUE
		else _snapshot.get("red_chaser_peer_id", 0)
	)
	var primary_chaser := false
	if committed_chaser > 0:
		primary_chaser = committed_chaser == peer_id
	elif possession_team != team:
		primary_chaser = _find_best_chaser_peer(own_players, ball_position) == peer_id

	var plan := {
		"peer_id": peer_id,
		"team": team,
		"snapshot_frame": int(_snapshot.get("physics_frame", -1)),
		"team_has_possession": possession_team == team,
		"possession_team": possession_team,
		"ball_actor_peer_id": carrier_peer_id,
		"ball_chaser_peer_id": committed_chaser,
		"primary_ball_chaser": primary_chaser,
		"reception_evaluated": false,
		"reception": {},
		"shape_valid": false,
		"shape_phase": &"",
		"shape_target": Vector2.ZERO,
		"shape_intent": INTENT_COVER,
		"shape_target_peer_id": 0
	}

	if not is_goalkeeper:
		plan["reception_evaluated"] = true
		plan["reception"] = _build_detected_reception(
			agent,
			own_players,
			ball_position,
			ball_velocity
		)
		if possession_team == team and carrier_peer_id > 0 and carrier_peer_id != peer_id:
			var carrier := _find_actor(own_players, carrier_peer_id)
			if not carrier.is_empty():
				var support_target := _build_attack_shape(agent, carrier, ball_position)
				plan["shape_valid"] = true
				plan["shape_phase"] = &"attack"
				plan["shape_target"] = support_target
				plan["shape_intent"] = _support_intent_for_role(StringName(agent.get("role", ROLE_MIDFIELDER)))
				plan["shape_target_peer_id"] = carrier_peer_id
		elif possession_team in [TEAM_BLUE, TEAM_RED] and possession_team != team and not primary_chaser:
			var defense_plan := _build_defensive_shape(agent, opponents, ball_position)
			if not defense_plan.is_empty():
				plan["shape_valid"] = true
				plan["shape_phase"] = &"defense"
				plan["shape_target"] = defense_plan.get("target", Vector2.ZERO)
				plan["shape_intent"] = defense_plan.get("intent", INTENT_COVER)
				plan["shape_target_peer_id"] = int(defense_plan.get("target_peer_id", 0))
		elif possession_team == NO_TEAM and not primary_chaser:
			plan["shape_valid"] = true
			plan["shape_phase"] = &"loose"
			plan["shape_target"] = _build_loose_shape(agent, ball_position)
			plan["shape_intent"] = INTENT_COVER

	return plan


func _find_actor(players: Array, peer_id: int) -> Dictionary:
	for player_variant in players:
		var player := player_variant as Dictionary
		if int(player.get("peer_id", 0)) == peer_id:
			return player
	return {}


func _find_team_carrier_peer(players: Array, ball_position: Vector2, has_possession: bool) -> int:
	if not has_possession:
		return 0
	var best_peer := 0
	var best_score := INF
	for player_variant in players:
		var player := player_variant as Dictionary
		if not bool(player.get("enabled", false)):
			continue
		var peer_id := int(player.get("peer_id", 0))
		if bool(player.get("has_ball", false)):
			return peer_id
		var distance := (player.get("position", Vector2.ZERO) as Vector2).distance_to(ball_position)
		if peer_id == int(_snapshot.get("last_touch_peer_id", 0)):
			distance -= 180.0
		if distance < best_score:
			best_score = distance
			best_peer = peer_id
	return best_peer


func _find_best_chaser_peer(players: Array, ball_position: Vector2) -> int:
	var best_peer := 0
	var best_eta := INF
	for player_variant in players:
		var player := player_variant as Dictionary
		if not bool(player.get("enabled", false)):
			continue
		if bool(player.get("goalkeeper", false)) and players.size() > 1:
			continue
		var position: Vector2 = player.get("position", Vector2.ZERO)
		var speed := maxf(450.0, float(player.get("max_speed", 900.0)))
		var velocity: Vector2 = player.get("velocity", Vector2.ZERO)
		var toward := position.direction_to(ball_position)
		var closing_speed := maxf(120.0, speed + velocity.dot(toward) * 0.28)
		var eta := position.distance_to(ball_position) / closing_speed
		if eta < best_eta:
			best_eta = eta
			best_peer = int(player.get("peer_id", 0))
	return best_peer


func _build_detected_reception(
	agent: Dictionary,
	own_players: Array,
	ball_position: Vector2,
	ball_velocity: Vector2
) -> Dictionary:
	var last_touch_peer_id := int(_snapshot.get("last_touch_peer_id", 0))
	var last_touch_team := StringName(_snapshot.get("last_touch_team", NO_TEAM))
	var team := StringName(agent.get("team", NO_TEAM))
	var peer_id := int(agent.get("peer_id", 0))
	var minimum_speed := float(_snapshot.get("incoming_pass_minimum_speed", 520.0))
	if (
		ball_velocity.length() < minimum_speed
		or last_touch_peer_id <= 0
		or last_touch_peer_id == peer_id
		or last_touch_team != team
	):
		return {}
	var own_candidate := _reception_candidate(agent, ball_position, ball_velocity)
	if own_candidate.is_empty():
		return {}
	var own_score := float(own_candidate.get("score", INF))
	var receiver_advantage := float(_snapshot.get("incoming_pass_receiver_advantage", 70.0))
	for teammate_variant in own_players:
		var teammate := teammate_variant as Dictionary
		var teammate_peer := int(teammate.get("peer_id", 0))
		if (
			teammate_peer == peer_id
			or teammate_peer == last_touch_peer_id
			or not bool(teammate.get("enabled", false))
		):
			continue
		var candidate := _reception_candidate(teammate, ball_position, ball_velocity)
		if candidate.is_empty():
			continue
		var teammate_score := float(candidate.get("score", INF))
		if (
			teammate_score + receiver_advantage < own_score
			or (
				absf(teammate_score - own_score) <= receiver_advantage
				and teammate_peer < peer_id
			)
		):
			return {}
	return {
		"position": own_candidate.get("position", agent.get("position", Vector2.ZERO)),
		"score": own_score,
		"time": float(own_candidate.get("time", 0.0)),
		"passer_peer_id": last_touch_peer_id,
		"detected": true,
		"parallel_snapshot": true
	}


func _reception_candidate(
	player: Dictionary,
	ball_position: Vector2,
	ball_velocity: Vector2
) -> Dictionary:
	var step_seconds := 0.08
	var prediction_seconds := maxf(0.2, float(_snapshot.get("incoming_pass_maximum_seconds", 1.6)))
	var predicted_position := ball_position
	var predicted_velocity := ball_velocity
	var elapsed := 0.0
	var best_distance := INF
	var best_position := predicted_position
	var best_time := 0.0
	var damping := maxf(0.0, float(_snapshot.get("ball_linear_damp", 0.0)))
	var top_y := float(_snapshot.get("ball_wall_top_y", 780.0))
	var bottom_y := float(_snapshot.get("ball_wall_bottom_y", 4220.0))
	var player_position: Vector2 = player.get("position", Vector2.ZERO)
	var player_velocity: Vector2 = player.get("velocity", Vector2.ZERO)
	while elapsed < prediction_seconds:
		var current_step := minf(step_seconds, prediction_seconds - elapsed)
		if damping > 0.001:
			predicted_velocity *= exp(-damping * current_step)
		predicted_position += predicted_velocity * current_step
		if predicted_position.y < top_y:
			predicted_position.y = top_y + (top_y - predicted_position.y)
			predicted_velocity.y = absf(predicted_velocity.y) * 0.8
		elif predicted_position.y > bottom_y:
			predicted_position.y = bottom_y - (predicted_position.y - bottom_y)
			predicted_velocity.y = -absf(predicted_velocity.y) * 0.8
		elapsed += current_step
		var player_prediction := player_position + player_velocity * elapsed * 0.35
		var distance := player_prediction.distance_to(predicted_position)
		if distance < best_distance:
			best_distance = distance
			best_position = predicted_position
			best_time = elapsed
		if predicted_velocity.length() < float(_snapshot.get("incoming_pass_minimum_speed", 520.0)) * 0.45:
			break
	if best_distance > float(_snapshot.get("incoming_pass_lane_width", 620.0)):
		return {}
	return {
		"position": _clamp(best_position),
		"score": best_distance + best_time * 34.0,
		"time": best_time
	}


func _build_attack_shape(agent: Dictionary, carrier: Dictionary, ball_position: Vector2) -> Vector2:
	var team := StringName(agent.get("team", NO_TEAM))
	var attack_sign := 1.0 if team == TEAM_BLUE else -1.0
	var role := StringName(agent.get("role", ROLE_MIDFIELDER))
	var center_y := (float(_snapshot.get("minimum_y", 800.0)) + float(_snapshot.get("maximum_y", 4200.0))) * 0.5
	var lane_y := center_y + _lane_offset(agent, role)
	var depth := -520.0
	match role:
		ROLE_DEFENDER: depth = -1250.0
		ROLE_MIDFIELDER: depth = -520.0
		ROLE_WINGER: depth = 260.0
		ROLE_STRIKER: depth = 980.0
	var carrier_position: Vector2 = carrier.get("position", ball_position)
	var target := Vector2(carrier_position.x + attack_sign * depth, lane_y)
	return _push_away_from_ball(_clamp(target), ball_position, 680.0, attack_sign, agent)


func _build_defensive_shape(agent: Dictionary, opponents: Array, ball_position: Vector2) -> Dictionary:
	var team := StringName(agent.get("team", NO_TEAM))
	var assignment_root: Dictionary = (
		_snapshot.get("blue_defensive_assignments", {}) as Dictionary
		if team == TEAM_BLUE
		else _snapshot.get("red_defensive_assignments", {}) as Dictionary
	)
	var peer_id := int(agent.get("peer_id", 0))
	var assignment := assignment_root.get(peer_id, {}) as Dictionary
	if assignment.is_empty():
		return {"target": _build_defensive_zone(agent, ball_position), "intent": INTENT_COVER, "target_peer_id": 0}
	var role := StringName(assignment.get("role", &"cover"))
	var target: Vector2 = assignment.get("target_position", Vector2.ZERO)
	var target_peer_id := int(assignment.get("target_peer_id", 0))
	if role == &"mark" and target_peer_id > 0:
		var marked := _find_actor(opponents, target_peer_id)
		if not marked.is_empty():
			var own_goal := _own_goal(team)
			var marked_position: Vector2 = marked.get("position", ball_position)
			target = marked_position.lerp(own_goal, 0.28)
	if target.is_zero_approx():
		target = _build_defensive_zone(agent, ball_position)
	var zone := _build_defensive_zone(agent, ball_position)
	if not zone.is_zero_approx() and role != &"press":
		var blend := float(_snapshot.get("large_team_defensive_zone_blend", 0.42))
		if role == &"final": blend *= 0.30
		elif role == &"cover": blend *= 0.72
		target = target.lerp(zone, clampf(blend, 0.0, 0.9))
	return {
		"target": _clamp(target),
		"intent": INTENT_MARK if role == &"mark" else INTENT_COVER,
		"target_peer_id": target_peer_id
	}


func _build_loose_shape(agent: Dictionary, ball_position: Vector2) -> Vector2:
	var zone := _build_defensive_zone(agent, ball_position)
	var team := StringName(agent.get("team", NO_TEAM))
	var attack_sign := 1.0 if team == TEAM_BLUE else -1.0
	return _push_away_from_ball(zone, ball_position, 700.0, attack_sign, agent)


func _build_defensive_zone(agent: Dictionary, ball_position: Vector2) -> Vector2:
	var team := StringName(agent.get("team", NO_TEAM))
	var attack_sign := 1.0 if team == TEAM_BLUE else -1.0
	var own_goal := _own_goal(team)
	var opponent_goal := _opponent_goal(team)
	var field_length := maxf(1.0, absf(opponent_goal.x - own_goal.x))
	var ball_progress := clampf((ball_position.x - own_goal.x) * attack_sign / field_length, 0.0, 1.0)
	var role := StringName(agent.get("role", ROLE_MIDFIELDER))
	var desired_progress := 0.44
	var maximum_ahead := -0.04
	var ball_y_blend := 0.30
	match role:
		ROLE_DEFENDER:
			desired_progress = lerpf(0.20, 0.38, ball_progress)
			maximum_ahead = -0.08
			ball_y_blend = 0.26
		ROLE_MIDFIELDER:
			desired_progress = lerpf(0.34, 0.52, ball_progress)
			maximum_ahead = -0.04
			ball_y_blend = 0.34
		ROLE_WINGER:
			desired_progress = lerpf(0.40, 0.56, ball_progress)
			maximum_ahead = 0.01
			ball_y_blend = 0.16
		ROLE_STRIKER:
			desired_progress = lerpf(0.47, 0.63, ball_progress)
			maximum_ahead = 0.08
			ball_y_blend = 0.20
	desired_progress = clampf(minf(desired_progress, ball_progress + maximum_ahead), 0.08, 0.76)
	var min_y := float(_snapshot.get("minimum_y", 800.0))
	var max_y := float(_snapshot.get("maximum_y", 4200.0))
	var center_y := (min_y + max_y) * 0.5
	var lane_y := center_y + _lane_offset(agent, role)
	lane_y = clampf(lerpf(lane_y, ball_position.y, ball_y_blend), min_y + 360.0, max_y - 360.0)
	return _clamp(Vector2(own_goal.x + attack_sign * field_length * desired_progress, lane_y))


func _lane_offset(agent: Dictionary, role: StringName) -> float:
	var slot := int(agent.get("team_slot", 0))
	var side := -1.0 if slot % 2 == 0 else 1.0
	match role:
		ROLE_WINGER: return side * 1260.0
		ROLE_MIDFIELDER: return side * 430.0
		ROLE_STRIKER: return side * 220.0
		ROLE_DEFENDER: return side * 520.0
	return 0.0


func _support_intent_for_role(role: StringName) -> StringName:
	if role in [ROLE_WINGER, ROLE_STRIKER]:
		return INTENT_FORWARD_RUN
	if role == ROLE_DEFENDER:
		return INTENT_COVER
	return INTENT_WIDE_SUPPORT


func _push_away_from_ball(
	target: Vector2,
	ball_position: Vector2,
	minimum_distance: float,
	attack_sign: float,
	agent: Dictionary
) -> Vector2:
	var offset := target - ball_position
	if offset.length() >= minimum_distance:
		return _clamp(target)
	if offset.is_zero_approx():
		var lane_sign := -1.0 if int(agent.get("team_slot", 0)) % 2 == 0 else 1.0
		offset = Vector2(-attack_sign, lane_sign)
	return _clamp(ball_position + offset.normalized() * minimum_distance)


func _own_goal(team: StringName) -> Vector2:
	return (
		_snapshot.get("blue_goal", Vector2.ZERO) as Vector2
		if team == TEAM_BLUE
		else _snapshot.get("red_goal", Vector2.ZERO) as Vector2
	)


func _opponent_goal(team: StringName) -> Vector2:
	return (
		_snapshot.get("red_goal", Vector2.ZERO) as Vector2
		if team == TEAM_BLUE
		else _snapshot.get("blue_goal", Vector2.ZERO) as Vector2
	)


func _clamp(target: Vector2) -> Vector2:
	return Vector2(
		clampf(target.x, float(_snapshot.get("minimum_x", 420.0)), float(_snapshot.get("maximum_x", 6980.0))),
		clampf(target.y, float(_snapshot.get("minimum_y", 860.0)), float(_snapshot.get("maximum_y", 4140.0)))
	)
