extends RefCounted


const ACTION_NONE: StringName = &"none"
const ACTION_PASS: StringName = &"pass"
const ACTION_WALL_PASS: StringName = &"wall_pass"
const ACTION_ONE_TWO: StringName = &"one_two"
const ACTION_THIRD_MAN: StringName = &"third_man"
const ACTION_SHOT: StringName = &"shot"
const ACTION_CARRY: StringName = &"carry"
const ACTION_RECOVER: StringName = &"recover"

const ROLE_ACTOR: StringName = &"actor"
const ROLE_RECEIVER: StringName = &"receiver"
const ROLE_RETURN_RUNNER: StringName = &"return_runner"
const ROLE_RUNNER: StringName = &"runner"
const ROLE_CONNECTOR: StringName = &"connector"
const ROLE_SAFETY: StringName = &"safety"
const ROLE_COLLECTOR: StringName = &"collector"

const ABILITY_BURST_DRIBBLE: int = 1
const ABILITY_QUICK_TRIGGER: int = 2
const ABILITY_POWER_STRIKE: int = 3
const ABILITY_OVERDRIVE: int = 4
const ABILITY_TIME_SKIP_PASS: int = 8
const ABILITY_DIRECT_FINISH: int = 9
const ABILITY_ELASTIC_STEP: int = 10
const ABILITY_BLIND_SPOT: int = 15
const ABILITY_RETURN_TAG: int = 18
const ABILITY_BREAKAWAY: int = 19
const ABILITY_SIDE_SWIPE: int = 21
const ABILITY_NUTMEG: int = 22

const DEFAULT_PASS_SPEED: float = 2450.0
const MINIMUM_PASS_DISTANCE: float = 360.0
const MAXIMUM_PASS_DISTANCE: float = 4550.0
const MINIMUM_LANE_CLEARANCE: float = 105.0
const FORCE_LANE_CLEARANCE: float = 175.0
const FORCE_ARRIVAL_MARGIN: float = 0.10
const FORCE_CONFIDENCE: float = 0.78


func run_async_job(
	snapshot: Dictionary,
	previous_plan: Dictionary,
	result_box: Array
) -> void:
	# Worker entry point. build_plan() only reads the copied snapshot/previous
	# plan and performs pure Dictionary/Vector math; it never touches Nodes or
	# SceneTree state. Each asynchronous request owns a fresh planner instance.
	result_box[0] = build_plan(snapshot, previous_plan)


func build_plan(
	snapshot: Dictionary,
	previous_plan: Dictionary = {}
) -> Dictionary:
	var team := StringName(snapshot.get("team", &""))
	var own_players := snapshot.get("own_players", []) as Array
	var opponents := snapshot.get("opponents", []) as Array
	var ball_position := snapshot.get("ball_position", Vector2.ZERO) as Vector2
	var ball_velocity := snapshot.get("ball_velocity", Vector2.ZERO) as Vector2
	var now_msec := int(snapshot.get("now_msec", 0))
	if team == &"" or own_players.is_empty():
		return {}

	var possession_team := StringName(snapshot.get("possession_team", &""))
	var carrier_peer_id := int(snapshot.get("carrier_peer_id", 0))
	var carrier := _find_player(own_players, carrier_peer_id)
	if possession_team == team and carrier.is_empty():
		carrier = _find_kickable_player(own_players)
		carrier_peer_id = int(carrier.get("peer_id", 0))

	if possession_team == team and not carrier.is_empty():
		return _build_attack_plan(
			snapshot,
			carrier,
			own_players,
			opponents,
			previous_plan
		)
	if possession_team == &"" or possession_team == &"none":
		return _build_loose_ball_plan(
			snapshot,
			own_players,
			opponents
		)

	return {
		"version": 1,
		"plan_id": "%s_defense_%d" % [str(team), now_msec],
		"team": team,
		"phase": &"defense",
		"action": ACTION_NONE,
		"confidence": 0.0,
		"force_execute": false,
		"actor_peer_id": 0,
		"receiver_peer_id": 0,
		"next_peer_id": 0,
		"assignments": {},
		"ball_anchor": ball_position,
		"ball_velocity_anchor": ball_velocity,
		"expires_msec": now_msec + 220
	}


func _build_attack_plan(
	snapshot: Dictionary,
	carrier: Dictionary,
	own_players: Array,
	opponents: Array,
	previous_plan: Dictionary
) -> Dictionary:
	var team := StringName(snapshot.get("team", &""))
	var now_msec := int(snapshot.get("now_msec", 0))
	var ball_position := snapshot.get("ball_position", Vector2.ZERO) as Vector2
	var ball_velocity := snapshot.get("ball_velocity", Vector2.ZERO) as Vector2
	var own_goal := snapshot.get("own_goal", Vector2.ZERO) as Vector2
	var opponent_goal := snapshot.get("opponent_goal", Vector2.ZERO) as Vector2
	var goal_mouth := snapshot.get(
		"opponent_goal_mouth",
		Vector2(opponent_goal.y - 772.5, opponent_goal.y + 772.5)
	) as Vector2
	var bounds := snapshot.get("field_bounds", Rect2()) as Rect2
	var attack_sign := float(snapshot.get("attack_sign", 1.0))
	var candidates: Array[Dictionary] = []

	var shot := _build_shot_candidate(
		ball_position,
		opponent_goal,
		goal_mouth,
		opponents
	)
	if not shot.is_empty():
		candidates.append(shot)

	for teammate_variant in own_players:
		if not teammate_variant is Dictionary:
			continue
		var teammate := teammate_variant as Dictionary
		if int(teammate.get("peer_id", 0)) == int(carrier.get("peer_id", 0)):
			continue
		_append_pass_candidates(
			candidates,
			snapshot,
			carrier,
			teammate,
			own_players,
			opponents,
			previous_plan
		)

	var carry := _build_carry_candidate(
		ball_position,
		carrier,
		own_players,
		opponents,
		opponent_goal,
		bounds,
		attack_sign
	)
	if not carry.is_empty():
		candidates.append(carry)

	if candidates.is_empty():
		return _empty_attack_plan(
			team,
			now_msec,
			int(carrier.get("peer_id", 0)),
			ball_position,
			ball_velocity
		)

	candidates.sort_custom(
		func(first: Dictionary, second: Dictionary) -> bool:
			return float(first.get("score", -INF)) > float(second.get("score", -INF))
	)
	var best := candidates[0].duplicate(true)
	var second_score := (
		float(candidates[1].get("score", -INF))
		if candidates.size() > 1
		else float(best.get("score", 0.0)) - 520.0
	)
	var best_score := float(best.get("score", 0.0))
	var score_gap := maxf(0.0, best_score - second_score)
	var confidence := clampf(
		0.42
		+ score_gap / 2100.0
		+ maxf(0.0, float(best.get("arrival_margin", 0.0))) * 0.24
		+ minf(float(best.get("route_clearance", 0.0)), 900.0) / 5200.0
		+ float(best.get("continuation_value", 0.0)) * 0.12
		- float(best.get("counter_risk", 0.0)) * 0.18,
		0.0,
		0.98
	)
	best["confidence"] = confidence
	best["score_gap"] = score_gap
	best["force_execute"] = _should_force_execute(best, confidence)
	best["version"] = 1
	best["plan_id"] = "%s_%d_%d" % [
		str(team),
		now_msec,
		int(carrier.get("peer_id", 0))
	]
	best["team"] = team
	best["phase"] = &"attack"
	best["actor_peer_id"] = int(carrier.get("peer_id", 0))
	best["ball_anchor"] = ball_position
	best["ball_velocity_anchor"] = ball_velocity
	best["assignments"] = _build_attack_assignments(
		best,
		carrier,
		own_players,
		own_goal,
		opponent_goal,
		bounds,
		attack_sign
	)
	best["expires_msec"] = now_msec + 440
	return best


func _append_pass_candidates(
	candidates: Array[Dictionary],
	snapshot: Dictionary,
	carrier: Dictionary,
	receiver: Dictionary,
	own_players: Array,
	opponents: Array,
	previous_plan: Dictionary
) -> void:
	var ball_position := snapshot.get("ball_position", Vector2.ZERO) as Vector2
	var opponent_goal := snapshot.get("opponent_goal", Vector2.ZERO) as Vector2
	var bounds := snapshot.get("field_bounds", Rect2()) as Rect2
	var attack_sign := float(snapshot.get("attack_sign", 1.0))
	var receiver_position := receiver.get("position", Vector2.ZERO) as Vector2
	var receiver_velocity := receiver.get("velocity", Vector2.ZERO) as Vector2
	var center_y := bounds.get_center().y
	var lane_side := -1.0 if receiver_position.y > center_y else 1.0
	var targets: Array[Dictionary] = [
		{
			"kind": &"feet",
			"target": receiver_position
		},
		{
			"kind": &"lead",
			"target": receiver_position + receiver_velocity * 0.16
			+ Vector2(attack_sign * 240.0, 0.0)
		},
		{
			"kind": &"through",
			"target": receiver_position + receiver_velocity * 0.12
			+ Vector2(attack_sign * 620.0, lane_side * 120.0)
		},
		{
			"kind": &"wide_switch",
			"target": Vector2(
				receiver_position.x + attack_sign * 300.0,
				lerpf(receiver_position.y, center_y + lane_side * 1120.0, 0.58)
			)
		}
	]

	for target_variant in targets:
		var target_data := target_variant as Dictionary
		var target := _clamp_point(
			target_data.get("target", receiver_position) as Vector2,
			bounds,
			120.0
		)
		var candidate := _score_pass_route(
			ball_position,
			target,
			StringName(target_data.get("kind", &"lead")),
			carrier,
			receiver,
			own_players,
			opponents,
			opponent_goal,
			attack_sign,
			false,
			Vector2.ZERO,
			previous_plan
		)
		if not candidate.is_empty():
			candidates.append(candidate)

	var direct_clearance := _segment_clearance(
		ball_position,
		receiver_position,
		opponents
	)
	if direct_clearance >= 270.0:
		return
	for wall_y in [bounds.position.y + 38.0, bounds.end.y - 38.0]:
		var wall_route := _build_wall_route(
			ball_position,
			receiver_position,
			float(wall_y),
			bounds,
			opponents
		)
		if wall_route.is_empty():
			continue
		if float(wall_route.get("clearance", 0.0)) < direct_clearance + 95.0:
			continue
		var wall_candidate := _score_pass_route(
			ball_position,
			receiver_position,
			&"wall_bank",
			carrier,
			receiver,
			own_players,
			opponents,
			opponent_goal,
			attack_sign,
			true,
			wall_route.get("bounce", Vector2.ZERO) as Vector2,
			previous_plan
		)
		if wall_candidate.is_empty():
			continue
		wall_candidate["route_distance"] = float(
			wall_route.get("distance", 0.0)
		)
		wall_candidate["route_clearance"] = float(
			wall_route.get("clearance", 0.0)
		)
		wall_candidate["direct_clearance"] = direct_clearance
		wall_candidate["score"] = float(wall_candidate.get("score", 0.0)) + 95.0
		candidates.append(wall_candidate)


func _count_bypassed_defenders(
	start: Vector2,
	target: Vector2,
	opponents: Array,
	attack_sign: float
) -> int:
	var forward_distance: float = (target.x - start.x) * attack_sign
	if forward_distance <= 220.0:
		return 0
	var route: Vector2 = target - start
	var route_length: float = route.length()
	if route_length <= 0.001:
		return 0
	var route_direction: Vector2 = route / route_length
	var bypassed: int = 0
	for opponent_variant in opponents:
		if not opponent_variant is Dictionary:
			continue
		var opponent := opponent_variant as Dictionary
		var position := opponent.get("position", Vector2.ZERO) as Vector2
		var defender_progress: float = (position.x - start.x) * attack_sign
		if defender_progress <= 100.0 or defender_progress >= forward_distance - 80.0:
			continue
		var along: float = (position - start).dot(route_direction)
		if along <= 0.0 or along >= route_length:
			continue
		var nearest_point: Vector2 = start + route_direction * along
		# Tactical line-break channel is intentionally wider than collision
		# clearance: a split pass can bypass a defender without touching them.
		if position.distance_to(nearest_point) <= 1200.0:
			bypassed += 1
	return bypassed


func _score_pass_route(
	start: Vector2,
	target: Vector2,
	kind: StringName,
	carrier: Dictionary,
	receiver: Dictionary,
	own_players: Array,
	opponents: Array,
	opponent_goal: Vector2,
	attack_sign: float,
	uses_wall: bool,
	bounce: Vector2,
	previous_plan: Dictionary
) -> Dictionary:
	var distance := start.distance_to(target)
	if distance < MINIMUM_PASS_DISTANCE or distance > MAXIMUM_PASS_DISTANCE:
		return {}
	var route_clearance := _segment_clearance(start, target, opponents)
	var route_distance := distance
	if uses_wall:
		route_clearance = minf(
			_segment_clearance(start, bounce, opponents),
			_segment_clearance(bounce, target, opponents)
		)
		route_distance = start.distance_to(bounce) + bounce.distance_to(target)
	if route_clearance < MINIMUM_LANE_CLEARANCE:
		return {}
	var receiver_arrival := _arrival_seconds(receiver, target)
	var opponent_arrival := _minimum_arrival_seconds(opponents, target)
	var ball_arrival := _ball_travel_seconds(route_distance, uses_wall)
	var arrival_margin := opponent_arrival - maxf(ball_arrival, receiver_arrival)
	if arrival_margin < -0.10:
		return {}
	var openness := _nearest_distance(opponents, target)
	var forward_progress := (target.x - start.x) * attack_sign
	var goal_gain := start.distance_to(opponent_goal) - target.distance_to(opponent_goal)
	var line_breaks: int = _count_bypassed_defenders(
		start,
		target,
		opponents,
		attack_sign
	)
	var team_size: int = maxi(1, own_players.size())
	var continuation := _evaluate_continuation(
		target,
		carrier,
		receiver,
		own_players,
		opponents,
		opponent_goal,
		attack_sign
	)
	var continuation_value := float(continuation.get("value", 0.0))
	var counter_risk := _estimate_counter_risk(
		target,
		carrier,
		own_players,
		opponents,
		attack_sign
	)
	var score := (
		minf(route_clearance, 1250.0) * 0.54
		+ minf(openness, 1500.0) * 0.31
		+ clampf(arrival_margin, -0.1, 0.9) * 650.0
		+ forward_progress * 0.24
		+ goal_gain * 0.13
		+ continuation_value * 520.0
		+ float(line_breaks) * (230.0 if team_size >= 3 else 170.0)
		- counter_risk * 420.0
	)
	if kind == &"through":
		score += maxf(0.0, forward_progress - 300.0) * 0.17
		score += float(line_breaks) * 115.0
	if kind == &"wide_switch":
		score += minf(openness, 900.0) * 0.12
	if kind == &"wall_bank":
		score += 75.0
	var receiver_ability := int(receiver.get("ability_id", 0))
	if bool(receiver.get("ability_ready", false)):
		if receiver_ability == ABILITY_DIRECT_FINISH:
			score += 230.0 + continuation_value * 150.0
		elif receiver_ability == ABILITY_POWER_STRIKE and distance >= 1200.0:
			score += 185.0 + float(line_breaks) * 45.0
		elif receiver_ability == ABILITY_QUICK_TRIGGER:
			score += 165.0 + continuation_value * 85.0
		elif receiver_ability == ABILITY_TIME_SKIP_PASS:
			score += 135.0 + continuation_value * 110.0
		elif receiver_ability in [
			ABILITY_RETURN_TAG,
			ABILITY_SIDE_SWIPE
		]:
			score += 125.0 + continuation_value * 80.0
		elif receiver_ability in [
			ABILITY_BURST_DRIBBLE,
			ABILITY_OVERDRIVE,
			ABILITY_ELASTIC_STEP,
			ABILITY_BLIND_SPOT,
			ABILITY_BREAKAWAY,
			ABILITY_NUTMEG
		]:
			score += 120.0 if forward_progress > 300.0 else 45.0
	if (
		int(carrier.get("ability_id", 0)) == ABILITY_TIME_SKIP_PASS
		and bool(carrier.get("ability_ready", false))
	):
		score += 115.0
	var previous_receiver := int(previous_plan.get("receiver_peer_id", 0))
	var previous_actor := int(previous_plan.get("actor_peer_id", 0))
	if (
		previous_receiver == int(carrier.get("peer_id", 0))
		and previous_actor == int(receiver.get("peer_id", 0))
	):
		score += 245.0
		continuation["sequence_kind"] = &"one_two"

	var sequence_kind := StringName(continuation.get("sequence_kind", &""))
	var action := ACTION_PASS
	if uses_wall:
		action = ACTION_WALL_PASS
	elif sequence_kind == &"one_two":
		action = ACTION_ONE_TWO
	elif sequence_kind == &"third_man":
		action = ACTION_THIRD_MAN
	return {
		"action": action,
		"kind": kind,
		"receiver_peer_id": int(receiver.get("peer_id", 0)),
		"next_peer_id": int(continuation.get("next_peer_id", 0)),
		"destination": target,
		"route_target": target,
		"bounce": bounce,
		"uses_wall": uses_wall,
		"route_distance": route_distance,
		"route_clearance": route_clearance,
		"direct_clearance": _segment_clearance(start, target, opponents),
		"arrival_margin": arrival_margin,
		"interception_margin": arrival_margin,
		"receiver_margin": opponent_arrival - receiver_arrival,
		"openness": openness,
		"forward_progress": forward_progress,
		"goal_gain": goal_gain,
		"line_breaks": line_breaks,
		"continuation_value": continuation_value,
		"chain_value": continuation_value * 900.0,
		"counter_risk": counter_risk,
		"defensive_error_value": maxf(0.0, forward_progress) * 0.18
		+ maxf(0.0, openness - 340.0) * 0.22,
		"actor_run_target": continuation.get("actor_run_target", Vector2.ZERO),
		"next_run_target": continuation.get("next_run_target", Vector2.ZERO),
		"score": score,
		"reason": "shared_sequence_%s" % str(kind),
		"available": true,
		"sequence_plan": true
	}


func _evaluate_continuation(
	reception: Vector2,
	carrier: Dictionary,
	receiver: Dictionary,
	own_players: Array,
	opponents: Array,
	opponent_goal: Vector2,
	attack_sign: float
) -> Dictionary:
	var shot_lane := _segment_clearance(reception, opponent_goal, opponents)
	var goal_distance := reception.distance_to(opponent_goal)
	var value := clampf(shot_lane / 900.0, 0.0, 1.0) * 0.52
	value += clampf((4300.0 - goal_distance) / 4300.0, 0.0, 1.0) * 0.34
	var carrier_position := carrier.get("position", Vector2.ZERO) as Vector2
	var side := -1.0 if carrier_position.y >= reception.y else 1.0
	var actor_run_target := reception + Vector2(
		attack_sign * 720.0,
		side * 480.0
	)
	var actor_openness := _nearest_distance(opponents, actor_run_target)
	var next_peer_id := int(carrier.get("peer_id", 0))
	var sequence_kind: StringName = &"one_two"
	var next_run_target := actor_run_target
	if own_players.size() >= 3:
		var third_best: Dictionary = {}
		var third_score := -INF
		for player_variant in own_players:
			if not player_variant is Dictionary:
				continue
			var player := player_variant as Dictionary
			var peer_id := int(player.get("peer_id", 0))
			if peer_id in [
				int(carrier.get("peer_id", 0)),
				int(receiver.get("peer_id", 0))
			]:
				continue
			var player_position := player.get("position", Vector2.ZERO) as Vector2
			var run_target := player_position + Vector2(attack_sign * 560.0, 0.0)
			var open := _nearest_distance(opponents, run_target)
			var progress := (run_target.x - reception.x) * attack_sign
			var candidate_score := open + progress * 0.36
			if candidate_score > third_score:
				third_score = candidate_score
				third_best = {
					"peer_id": peer_id,
					"target": run_target,
					"openness": open
				}
		if not third_best.is_empty() and float(third_best.get("openness", 0.0)) > actor_openness + 90.0:
			next_peer_id = int(third_best.get("peer_id", 0))
			next_run_target = third_best.get("target", actor_run_target) as Vector2
			sequence_kind = &"third_man"
			actor_openness = float(third_best.get("openness", actor_openness))
	value += clampf((actor_openness - 240.0) / 1100.0, 0.0, 1.0) * 0.28
	return {
		"value": clampf(value, 0.0, 1.25),
		"next_peer_id": next_peer_id,
		"actor_run_target": actor_run_target,
		"next_run_target": next_run_target,
		"sequence_kind": sequence_kind
	}


func _build_shot_candidate(
	start: Vector2,
	goal_center: Vector2,
	goal_mouth: Vector2,
	opponents: Array
) -> Dictionary:
	var best: Dictionary = {}
	var best_score := -INF
	for y in [
		goal_center.y,
		lerpf(goal_center.y, goal_mouth.x, 0.58),
		lerpf(goal_center.y, goal_mouth.y, 0.58)
	]:
		var target := Vector2(goal_center.x, float(y))
		var lane := _segment_clearance(start, target, opponents)
		var distance := start.distance_to(target)
		var opponent_arrival := _minimum_arrival_to_segment(
			opponents,
			start,
			target
		)
		var ball_time := _ball_travel_seconds(distance, false) * 0.72
		var timing_margin := opponent_arrival - ball_time
		if lane < 120.0 or timing_margin < -0.06:
			continue
		var score := (
			lane * 0.76
			+ maxf(0.0, 4400.0 - distance) * 0.20
			+ clampf(timing_margin, -0.1, 0.8) * 580.0
		)
		if score > best_score:
			best_score = score
			best = {
				"action": ACTION_SHOT,
				"kind": &"direct_shot",
				"destination": target,
				"route_target": target,
				"receiver_peer_id": 0,
				"next_peer_id": 0,
				"uses_wall": false,
				"route_distance": distance,
				"route_clearance": lane,
				"direct_clearance": lane,
				"arrival_margin": timing_margin,
				"interception_margin": timing_margin,
				"receiver_margin": timing_margin,
				"openness": lane,
				"forward_progress": 0.0,
				"goal_gain": 0.0,
				"continuation_value": 0.0,
				"counter_risk": 0.20,
				"score": score,
				"available": true,
				"reason": "shared_sequence_open_shot"
			}
	return best


func _build_carry_candidate(
	ball_position: Vector2,
	carrier: Dictionary,
	own_players: Array,
	opponents: Array,
	opponent_goal: Vector2,
	bounds: Rect2,
	attack_sign: float
) -> Dictionary:
	var nearest := _nearest_player(opponents, ball_position)
	var lateral := 0.0
	if not nearest.is_empty():
		var opponent_position := nearest.get("position", Vector2.ZERO) as Vector2
		lateral = -1.0 if opponent_position.y >= ball_position.y else 1.0
	var target := _clamp_point(
		ball_position + Vector2(attack_sign * 820.0, lateral * 520.0),
		bounds,
		150.0
	)
	var lane := _segment_clearance(ball_position, target, opponents)
	var openness := _nearest_distance(opponents, target)
	var progress := (target.x - ball_position.x) * attack_sign
	var score := lane * 0.44 + openness * 0.36 + progress * 0.31
	var carrier_ability: int = int(carrier.get("ability_id", 0))
	var ability_ready: bool = bool(carrier.get("ability_ready", false))
	var team_size: int = maxi(1, own_players.size())
	var dribble_specialist: bool = (
		ability_ready
		and carrier_ability in [
			ABILITY_BURST_DRIBBLE,
			ABILITY_OVERDRIVE,
			ABILITY_ELASTIC_STEP,
			ABILITY_BLIND_SPOT,
			ABILITY_BREAKAWAY,
			ABILITY_NUTMEG
		]
	)
	if dribble_specialist:
		score += 160.0
	# In crowded team modes, an ordinary carry is a fallback rather than the
	# default answer to every open patch of grass. Creator abilities make that
	# even more important: search for a line break/switch/combination first.
	if team_size >= 3:
		score *= 0.70 if team_size == 3 else 0.52
		if dribble_specialist:
			score *= 1.18
		elif (
			ability_ready
			and carrier_ability in [
				ABILITY_POWER_STRIKE,
				ABILITY_QUICK_TRIGGER,
				ABILITY_TIME_SKIP_PASS,
				ABILITY_RETURN_TAG,
				ABILITY_SIDE_SWIPE
			]
		):
			score *= 0.58
	return {
		"action": ACTION_CARRY,
		"kind": &"carry",
		"destination": target,
		"route_target": target,
		"receiver_peer_id": 0,
		"next_peer_id": 0,
		"uses_wall": false,
		"route_distance": ball_position.distance_to(target),
		"route_clearance": lane,
		"direct_clearance": lane,
		"arrival_margin": 0.0,
		"interception_margin": 0.0,
		"receiver_margin": 0.0,
		"openness": openness,
		"forward_progress": progress,
		"goal_gain": ball_position.distance_to(opponent_goal) - target.distance_to(opponent_goal),
		"continuation_value": 0.18,
		"counter_risk": 0.34,
		"score": score,
		"available": true,
		"reason": "shared_sequence_carry"
	}


func _build_attack_assignments(
	plan: Dictionary,
	carrier: Dictionary,
	own_players: Array,
	own_goal: Vector2,
	opponent_goal: Vector2,
	bounds: Rect2,
	attack_sign: float
) -> Dictionary:
	var assignments: Dictionary = {}
	var actor_peer_id := int(carrier.get("peer_id", 0))
	var receiver_peer_id := int(plan.get("receiver_peer_id", 0))
	var next_peer_id := int(plan.get("next_peer_id", 0))
	var destination := plan.get("destination", Vector2.ZERO) as Vector2
	var actor_run_target := _clamp_point(
		plan.get("actor_run_target", Vector2.ZERO) as Vector2,
		bounds,
		140.0
	)
	var next_run_target := _clamp_point(
		plan.get("next_run_target", Vector2.ZERO) as Vector2,
		bounds,
		140.0
	)
	assignments[actor_peer_id] = {
		"role": ROLE_ACTOR,
		"intent": StringName(plan.get("action", ACTION_NONE)),
		"target_position": destination,
		"target_peer_id": receiver_peer_id
	}
	if receiver_peer_id > 0:
		assignments[receiver_peer_id] = {
			"role": ROLE_RECEIVER,
			"intent": &"receive",
			"target_position": destination,
			"target_peer_id": actor_peer_id
		}
	var extras: Array[Dictionary] = []
	for player_variant in own_players:
		if not player_variant is Dictionary:
			continue
		var player := player_variant as Dictionary
		var peer_id := int(player.get("peer_id", 0))
		if peer_id in [actor_peer_id, receiver_peer_id]:
			continue
		extras.append(player)
	if next_peer_id == actor_peer_id and not actor_run_target.is_zero_approx():
		assignments[actor_peer_id]["post_action_role"] = ROLE_RETURN_RUNNER
		assignments[actor_peer_id]["post_action_target"] = actor_run_target
	elif next_peer_id > 0 and next_peer_id != receiver_peer_id:
		assignments[next_peer_id] = {
			"role": ROLE_RUNNER,
			"intent": &"forward_run",
			"target_position": next_run_target,
			"target_peer_id": receiver_peer_id
		}
	for index in range(extras.size()):
		var extra := extras[index]
		var peer_id := int(extra.get("peer_id", 0))
		if assignments.has(peer_id):
			continue
		var extra_position := extra.get("position", Vector2.ZERO) as Vector2
		var target := own_goal.lerp(destination, 0.58)
		var role := ROLE_SAFETY
		var intent: StringName = &"cover"
		if index == 0 and own_players.size() >= 3:
			role = ROLE_CONNECTOR
			intent = &"wide_support"
			var side := -1.0 if destination.y > bounds.get_center().y else 1.0
			target = destination + Vector2(attack_sign * 260.0, side * 760.0)
		else:
			target.y = lerpf(target.y, extra_position.y, 0.28)
		assignments[peer_id] = {
			"role": role,
			"intent": intent,
			"target_position": _clamp_point(target, bounds, 160.0),
			"target_peer_id": receiver_peer_id
		}
	return assignments


func _build_loose_ball_plan(
	snapshot: Dictionary,
	own_players: Array,
	opponents: Array
) -> Dictionary:
	var team := StringName(snapshot.get("team", &""))
	var now_msec := int(snapshot.get("now_msec", 0))
	var ball_position := snapshot.get("ball_position", Vector2.ZERO) as Vector2
	var ball_velocity := snapshot.get("ball_velocity", Vector2.ZERO) as Vector2
	var bounds := snapshot.get("field_bounds", Rect2()) as Rect2
	var predicted_ball := _clamp_point(
		ball_position + ball_velocity * 0.18,
		bounds,
		100.0
	)
	var collector: Dictionary = {}
	var best_arrival := INF
	for player_variant in own_players:
		if not player_variant is Dictionary:
			continue
		var player := player_variant as Dictionary
		var arrival := _arrival_seconds(player, predicted_ball)
		if arrival < best_arrival:
			best_arrival = arrival
			collector = player
	var opponent_arrival := _minimum_arrival_seconds(opponents, predicted_ball)
	var confidence := clampf(
		0.48 + (opponent_arrival - best_arrival) * 0.34,
		0.0,
		0.94
	)
	var assignments: Dictionary = {}
	var collector_peer_id := int(collector.get("peer_id", 0))
	for player_variant in own_players:
		if not player_variant is Dictionary:
			continue
		var player := player_variant as Dictionary
		var peer_id := int(player.get("peer_id", 0))
		if peer_id == collector_peer_id:
			assignments[peer_id] = {
				"role": ROLE_COLLECTOR,
				"intent": &"chase_ball",
				"target_position": predicted_ball,
				"target_peer_id": 0
			}
		else:
			var own_goal := snapshot.get("own_goal", Vector2.ZERO) as Vector2
			var support := own_goal.lerp(predicted_ball, 0.54)
			assignments[peer_id] = {
				"role": ROLE_SAFETY,
				"intent": &"cover",
				"target_position": _clamp_point(support, bounds, 160.0),
				"target_peer_id": 0
			}
	return {
		"version": 1,
		"plan_id": "%s_loose_%d" % [str(team), now_msec],
		"team": team,
		"phase": &"loose",
		"action": ACTION_RECOVER,
		"confidence": confidence,
		"force_execute": false,
		"actor_peer_id": collector_peer_id,
		"receiver_peer_id": 0,
		"next_peer_id": 0,
		"destination": predicted_ball,
		"route_clearance": 0.0,
		"arrival_margin": opponent_arrival - best_arrival,
		"continuation_value": 0.0,
		"counter_risk": 0.0,
		"assignments": assignments,
		"ball_anchor": ball_position,
		"ball_velocity_anchor": ball_velocity,
		"expires_msec": now_msec + 260
	}


func _should_force_execute(candidate: Dictionary, confidence: float) -> bool:
	var action := StringName(candidate.get("action", ACTION_NONE))
	if action not in [ACTION_PASS, ACTION_WALL_PASS, ACTION_ONE_TWO, ACTION_THIRD_MAN]:
		return false
	return (
		confidence >= FORCE_CONFIDENCE
		and float(candidate.get("route_clearance", 0.0)) >= FORCE_LANE_CLEARANCE
		and float(candidate.get("arrival_margin", -1.0)) >= FORCE_ARRIVAL_MARGIN
		and float(candidate.get("counter_risk", 1.0)) <= 0.68
	)


func _estimate_counter_risk(
	target: Vector2,
	carrier: Dictionary,
	own_players: Array,
	opponents: Array,
	attack_sign: float
) -> float:
	var support_behind := 0
	for player_variant in own_players:
		if not player_variant is Dictionary:
			continue
		var player := player_variant as Dictionary
		if int(player.get("peer_id", 0)) == int(carrier.get("peer_id", 0)):
			continue
		var position := player.get("position", Vector2.ZERO) as Vector2
		if (target.x - position.x) * attack_sign > 250.0:
			support_behind += 1
	var nearest_opponent := _nearest_distance(opponents, target)
	return clampf(
		0.58
		- float(support_behind) * 0.17
		+ maxf(0.0, 420.0 - nearest_opponent) / 900.0,
		0.05,
		0.92
	)


func _build_wall_route(
	start: Vector2,
	target: Vector2,
	wall_y: float,
	bounds: Rect2,
	opponents: Array
) -> Dictionary:
	var reflected_target := Vector2(target.x, wall_y * 2.0 - target.y)
	var denominator := reflected_target.y - start.y
	if absf(denominator) <= 0.001:
		return {}
	var ratio := (wall_y - start.y) / denominator
	if ratio <= 0.04 or ratio >= 0.96:
		return {}
	var bounce := start.lerp(reflected_target, ratio)
	if bounce.x < bounds.position.x + 90.0 or bounce.x > bounds.end.x - 90.0:
		return {}
	var clearance := minf(
		_segment_clearance(start, bounce, opponents),
		_segment_clearance(bounce, target, opponents)
	)
	return {
		"bounce": bounce,
		"distance": start.distance_to(bounce) + bounce.distance_to(target),
		"clearance": clearance
	}


func _segment_clearance(
	start: Vector2,
	finish: Vector2,
	players: Array
) -> float:
	var minimum := 1800.0
	for player_variant in players:
		if not player_variant is Dictionary:
			continue
		var player := player_variant as Dictionary
		var position := player.get("position", Vector2.ZERO) as Vector2
		minimum = minf(minimum, _distance_to_segment(position, start, finish))
	return minimum


func _minimum_arrival_to_segment(
	players: Array,
	start: Vector2,
	finish: Vector2
) -> float:
	var best := INF
	for player_variant in players:
		if not player_variant is Dictionary:
			continue
		var player := player_variant as Dictionary
		var position := player.get("position", Vector2.ZERO) as Vector2
		var segment := finish - start
		var ratio := 0.0
		if segment.length_squared() > 0.001:
			ratio = clampf(
				(position - start).dot(segment) / segment.length_squared(),
				0.0,
				1.0
			)
		var intercept := start + segment * ratio
		best = minf(best, _arrival_seconds(player, intercept))
	return best


func _minimum_arrival_seconds(players: Array, target: Vector2) -> float:
	var best := INF
	for player_variant in players:
		if not player_variant is Dictionary:
			continue
		best = minf(
			best,
			_arrival_seconds(player_variant as Dictionary, target)
		)
	return best


func _arrival_seconds(player: Dictionary, target: Vector2) -> float:
	var position := player.get("position", Vector2.ZERO) as Vector2
	var velocity := player.get("velocity", Vector2.ZERO) as Vector2
	var max_speed := maxf(300.0, float(player.get("max_speed", 5200.0)))
	var acceleration := maxf(300.0, float(player.get("acceleration", 5600.0)))
	var distance := position.distance_to(target)
	var direction := position.direction_to(target)
	var forward_speed := maxf(0.0, velocity.dot(direction))
	var acceleration_time := maxf(0.0, max_speed - forward_speed) / acceleration
	var acceleration_distance := (
		forward_speed * acceleration_time
		+ 0.5 * acceleration * acceleration_time * acceleration_time
	)
	if distance <= acceleration_distance:
		var discriminant := maxf(
			0.0,
			forward_speed * forward_speed + 2.0 * acceleration * distance
		)
		return (sqrt(discriminant) - forward_speed) / acceleration
	return acceleration_time + (distance - acceleration_distance) / max_speed


func _ball_travel_seconds(distance: float, uses_wall: bool) -> float:
	var speed := DEFAULT_PASS_SPEED * (0.86 if uses_wall else 1.0)
	return distance / maxf(1.0, speed) + distance * distance / 52000000.0


func _nearest_distance(players: Array, point: Vector2) -> float:
	var best := 1800.0
	for player_variant in players:
		if not player_variant is Dictionary:
			continue
		var player := player_variant as Dictionary
		best = minf(
			best,
			(player.get("position", Vector2.ZERO) as Vector2).distance_to(point)
		)
	return best


func _nearest_player(players: Array, point: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var best_distance := INF
	for player_variant in players:
		if not player_variant is Dictionary:
			continue
		var player := player_variant as Dictionary
		var distance := (player.get("position", Vector2.ZERO) as Vector2).distance_to(point)
		if distance < best_distance:
			best_distance = distance
			best = player
	return best


func _find_player(players: Array, peer_id: int) -> Dictionary:
	if peer_id <= 0:
		return {}
	for player_variant in players:
		if not player_variant is Dictionary:
			continue
		var player := player_variant as Dictionary
		if int(player.get("peer_id", 0)) == peer_id:
			return player
	return {}


func _find_kickable_player(players: Array) -> Dictionary:
	for player_variant in players:
		if not player_variant is Dictionary:
			continue
		var player := player_variant as Dictionary
		if bool(player.get("has_ball", false)):
			return player
	return {}


func _distance_to_segment(
	point: Vector2,
	start: Vector2,
	finish: Vector2
) -> float:
	var segment := finish - start
	var length_squared := segment.length_squared()
	if length_squared <= 0.001:
		return point.distance_to(start)
	var ratio := clampf(
		(point - start).dot(segment) / length_squared,
		0.0,
		1.0
	)
	return point.distance_to(start + segment * ratio)


func _clamp_point(point: Vector2, bounds: Rect2, padding: float) -> Vector2:
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		return point
	return Vector2(
		clampf(point.x, bounds.position.x + padding, bounds.end.x - padding),
		clampf(point.y, bounds.position.y + padding, bounds.end.y - padding)
	)


func _empty_attack_plan(
	team: StringName,
	now_msec: int,
	actor_peer_id: int,
	ball_position: Vector2,
	ball_velocity: Vector2
) -> Dictionary:
	return {
		"version": 1,
		"plan_id": "%s_empty_%d" % [str(team), now_msec],
		"team": team,
		"phase": &"attack",
		"action": ACTION_NONE,
		"confidence": 0.0,
		"force_execute": false,
		"actor_peer_id": actor_peer_id,
		"receiver_peer_id": 0,
		"next_peer_id": 0,
		"assignments": {},
		"ball_anchor": ball_position,
		"ball_velocity_anchor": ball_velocity,
		"expires_msec": now_msec + 180
	}
