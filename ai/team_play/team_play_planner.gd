class_name TeamPlayPlanner
extends RefCounted


const PASS_TO_FEET: StringName = &"to_feet"
const PASS_LEAD: StringName = &"lead"
const PASS_THROUGH: StringName = &"through"
const PASS_DIAGONAL_SPLIT: StringName = &"diagonal_split"
const PASS_BLINDSIDE: StringName = &"blindside"
const PASS_SQUARE: StringName = &"square"
const PASS_WIDE_SWITCH: StringName = &"wide_switch"
const PASS_CUTBACK: StringName = &"cutback"
const PASS_LAYOFF: StringName = &"layoff"
const PASS_PRESSURE_ESCAPE: StringName = &"pressure_escape"
const PASS_WALL_BANK: StringName = &"wall_bank"
const PASS_ONE_TWO: StringName = &"one_two"
const PASS_THIRD_MAN: StringName = &"third_man"
const PASS_OVERLAP: StringName = &"overlap"
const PASS_UNDERLAP: StringName = &"underlap"
const PASS_RECYCLE: StringName = &"recycle"

const INTENT_RECEIVE: StringName = &"receive"
const INTENT_FORWARD_RUN: StringName = &"forward_run"
const INTENT_WIDE_SUPPORT: StringName = &"wide_support"
const INTENT_COVER: StringName = &"cover"

const SUPPORT_RUN_BEHIND: StringName = &"run_behind"
const SUPPORT_RETURN_LANE: StringName = &"return_lane"
const SUPPORT_WIDTH: StringName = &"width"
const SUPPORT_DECOY: StringName = &"decoy"
const SUPPORT_COVER: StringName = &"cover"
const SUPPORT_FAR_POST: StringName = &"far_post"
const SUPPORT_REBOUND: StringName = &"rebound"

# Large-team pass planning is one of the heaviest pure-math workloads in a
# 5v5/6v6 match. Keep SceneTree reads on the main thread, then fan the copied
# route/actor snapshots out over Godot's existing worker pool. Smaller modes
# stay on the original sequential path so thread dispatch never adds overhead.
const PARALLEL_PASS_MINIMUM_TEAM_SIZE: int = 5
const PARALLEL_PASS_MINIMUM_CANDIDATES: int = 12
const PARALLEL_PASS_MAX_WORKERS: int = 8

var _controller: Node
var _cached_pass_plan: Dictionary = {}
var _cached_ranked_pass_plans: Array[Dictionary] = []
var _cached_pass_at: float = -INF
var _cached_pass_ball_position: Vector2 = Vector2.ZERO
var _cached_pass_carrier_position: Vector2 = Vector2.ZERO
var _cached_support_assignments: Dictionary = {}
var _cached_support_at: float = -INF
var _cached_support_ball_position: Vector2 = Vector2.ZERO
var _cached_support_carrier_peer_id: int = 0
var _cached_support_active_team_count: int = 0

# These arrays are resized before dispatch and never resized by worker threads.
# Each worker owns one index, which follows Godot's documented safe pattern for
# parallel Array element access. The jobs contain only plain Variant data.
var _parallel_route_jobs: Array[Dictionary] = []
var _parallel_route_results: Array[Dictionary] = []


func setup(controller: Node) -> void:
	_controller = controller
	reset()


func reset() -> void:
	_cached_pass_plan.clear()
	_cached_ranked_pass_plans.clear()
	_cached_pass_at = -INF
	_cached_pass_ball_position = Vector2.ZERO
	_cached_pass_carrier_position = Vector2.ZERO
	_cached_support_assignments.clear()
	_cached_support_at = -INF
	_cached_support_ball_position = Vector2.ZERO
	_cached_support_carrier_peer_id = 0
	_cached_support_active_team_count = 0


func get_best_pass_plan(
	opponent_goal: Node,
	force_refresh: bool = false
) -> Dictionary:
	var ranked := get_ranked_pass_plans(
		opponent_goal,
		1,
		force_refresh
	)
	return ranked[0].duplicate(true) if not ranked.is_empty() else {}


func get_ranked_pass_plans(
	opponent_goal: Node,
	maximum_plans: int = 6,
	force_refresh: bool = false
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not _is_ready() or opponent_goal == null or maximum_plans <= 0:
		return result
	var now := _now()
	var ball: Node = _controller.get("ball")
	var carrier: Node = _controller.get("controlled_player")
	var ball_position: Vector2 = ball.get("global_position")
	var carrier_position: Vector2 = carrier.get("global_position")
	var cache_valid := (
		not force_refresh
		and now - _cached_pass_at <= 0.09
		and ball_position.distance_to(_cached_pass_ball_position) <= 85.0
		and carrier_position.distance_to(_cached_pass_carrier_position) <= 95.0
	)
	if not cache_valid:
		_cached_pass_at = now
		_cached_pass_ball_position = ball_position
		_cached_pass_carrier_position = carrier_position
		_cached_ranked_pass_plans = _calculate_ranked_pass_plans(
			opponent_goal
		)
		_cached_pass_plan = (
			_cached_ranked_pass_plans[0].duplicate(true)
			if not _cached_ranked_pass_plans.is_empty()
			else {}
		)
	for index in range(mini(maximum_plans, _cached_ranked_pass_plans.size())):
		result.append(_cached_ranked_pass_plans[index].duplicate(true))
	return result


func get_support_assignments(carrier: Node) -> Dictionary:
	if not _is_ready() or carrier == null or not is_instance_valid(carrier):
		return {}
	var now := _now()
	var ball: Node = _controller.get("ball")
	var ball_position: Vector2 = ball.get("global_position")
	var carrier_peer_id := int(carrier.get("owner_peer_id"))
	var active_team_count := int(
		_controller.call("_get_active_team_player_count")
	)
	if (
		now - _cached_support_at > 0.42
		or ball_position.distance_to(_cached_support_ball_position) > 210.0
		or carrier_peer_id != _cached_support_carrier_peer_id
		or active_team_count != _cached_support_active_team_count
		or _cached_support_assignments.is_empty()
	):
		_cached_support_at = now
		_cached_support_ball_position = ball_position
		_cached_support_carrier_peer_id = carrier_peer_id
		_cached_support_active_team_count = active_team_count
		_cached_support_assignments = _calculate_support_assignments(carrier)
	return _cached_support_assignments.duplicate(true)


func get_support_assignment(carrier: Node) -> Dictionary:
	var assignments := get_support_assignments(carrier)
	if assignments.is_empty():
		return {}
	var player: Node = _controller.get("controlled_player")
	return (
		assignments.get(
			str(int(player.get("owner_peer_id"))),
			{}
		) as Dictionary
	).duplicate(true)


func get_cached_pass_plan_for_receiver(peer_id: int) -> Dictionary:
	if peer_id <= 0 or _now() - _cached_pass_at > 0.55:
		return {}
	for plan in _cached_ranked_pass_plans:
		if int(plan.get("receiver_peer_id", 0)) == peer_id:
			return plan.duplicate(true)
	return {}


func _calculate_ranked_pass_plans(
	opponent_goal: Node
) -> Array[Dictionary]:
	var player: Node = _controller.get("controlled_player")
	var ball: Node = _controller.get("ball")
	var teammates: Array = _controller.call("_get_teammates") as Array
	var opponents: Array = _controller.call("_get_opponents") as Array
	var ball_position: Vector2 = ball.get("global_position")
	var goal_center: Vector2 = _controller.call("_get_goal_center", opponent_goal)
	var attack_sign := float(_controller.call("_get_attack_sign"))
	var pressure := _nearest_active_distance(opponents, ball_position)
	var pressure_radius := float(_controller.get("pass_pressure_radius"))
	var under_pressure := pressure <= pressure_radius
	var defensive_shape := _analyze_defensive_shape(
		opponents,
		ball_position,
		goal_center,
		attack_sign
	)
	var active_team_count := int(
		_controller.call("_get_active_team_player_count")
	)
	var candidates: Array[Dictionary] = []
	for teammate_variant in teammates:
		var receiver := teammate_variant as Node
		if not _valid_actor(receiver) or receiver == player:
			continue
		if bool(_controller.call("_is_designated_goalkeeper", receiver)):
			_append_goalkeeper_recycle_candidate(
				candidates,
				receiver,
				ball_position,
				goal_center,
				attack_sign,
				under_pressure
			)
			continue
		if active_team_count <= 2:
			_append_two_player_receiver_candidates(
				candidates,
				receiver,
				ball_position,
				attack_sign,
				under_pressure
			)
		else:
			_append_receiver_candidates(
				candidates,
				receiver,
				ball_position,
				goal_center,
				attack_sign,
				under_pressure,
				defensive_shape
			)

	var parallel_route_results: Array[Dictionary] = (
		_precompute_parallel_route_safety(
			candidates,
			ball_position,
			opponents,
			active_team_count
		)
	)
	var evaluated_plans: Array[Dictionary] = []
	for candidate_index in range(candidates.size()):
		var candidate := candidates[candidate_index]
		var precomputed_route: Dictionary = {}
		if candidate_index < parallel_route_results.size():
			precomputed_route = parallel_route_results[candidate_index]
		var evaluated := _evaluate_pass_candidate(
			candidate,
			ball_position,
			goal_center,
			attack_sign,
			opponents,
			under_pressure,
			defensive_shape,
			precomputed_route
		)
		if evaluated.is_empty():
			continue
		var score := float(evaluated.get("score", -INF))
		var quality := clampf((score + 360.0) / 1850.0, 0.0, 1.0)
		evaluated["quality"] = quality
		evaluated["available"] = quality >= 0.28
		evaluated["defensive_shape"] = defensive_shape
		evaluated_plans.append(evaluated)

	evaluated_plans.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var score_a := float(a.get("score", -INF))
		var score_b := float(b.get("score", -INF))
		if not is_equal_approx(score_a, score_b):
			return score_a > score_b
		var receiver_a := int(a.get("receiver_peer_id", 2147483647))
		var receiver_b := int(b.get("receiver_peer_id", 2147483647))
		if receiver_a != receiver_b:
			return receiver_a < receiver_b
		return str(a.get("kind", "")) < str(b.get("kind", ""))
	)

	# Keep several genuinely different options. Without this, tiny score
	# differences can fill the list with variants to the same receiver and the
	# learned policy never gets a meaningful choice between a switch, a split
	# pass, a pressure escape and a combination.
	var result: Array[Dictionary] = []
	var kind_counts: Dictionary = {}
	var receiver_counts: Dictionary = {}
	for plan in evaluated_plans:
		var kind_key := str(plan.get("kind", ""))
		var receiver_key := str(int(plan.get("receiver_peer_id", 0)))
		if int(kind_counts.get(kind_key, 0)) >= 2:
			continue
		if int(receiver_counts.get(receiver_key, 0)) >= 3:
			continue
		result.append(plan)
		kind_counts[kind_key] = int(kind_counts.get(kind_key, 0)) + 1
		receiver_counts[receiver_key] = int(receiver_counts.get(receiver_key, 0)) + 1
		if result.size() >= 10:
			break
	return result


func _append_goalkeeper_recycle_candidate(
	candidates: Array[Dictionary],
	receiver: Node,
	ball_position: Vector2,
	goal_center: Vector2,
	attack_sign: float,
	under_pressure: bool
) -> void:
	var player: Node = _controller.get("controlled_player")
	if (
		player == null
		or bool(_controller.call("_is_designated_goalkeeper", player))
		or not _valid_actor(receiver)
	):
		return
	var own_goal: Node = _controller.call("_get_own_goal")
	if own_goal == null:
		return
	var own_goal_center: Vector2 = _controller.call(
		"_get_goal_center",
		own_goal
	)
	var field_length := absf(goal_center.x - own_goal_center.x)
	var attack_progress := (
		(ball_position.x - own_goal_center.x) * attack_sign
		/ maxf(1.0, field_length)
	)
	# A goalkeeper recycle is a pressure-release/build-up option, never a
	# default 2v2 action. In the previous planner the goalkeeper was often the
	# only legal receiver, so a timed safety escape repeatedly became a bizarre
	# backpass even when the carrier had a clear forward lane.
	if not under_pressure and attack_progress > 0.48:
		return
	var active_team_count := int(
		_controller.call("_get_active_team_player_count")
	)
	if active_team_count <= 2 and not under_pressure:
		var forward_target := _clamp(
			ball_position + Vector2(attack_sign * 900.0, 0.0)
		)
		var forward_clearance := float(_controller.call(
			"_minimum_segment_clearance",
			ball_position,
			forward_target
		))
		var minimum_lane := float(_controller.get("pass_lane_clearance"))
		if forward_clearance >= minimum_lane * 0.82:
			return
	var receiver_position: Vector2 = receiver.get("global_position")
	var receiver_velocity: Vector2 = receiver.get("linear_velocity")
	var target := _clamp(
		receiver_position
		+ receiver_velocity * 0.08
		+ Vector2(attack_sign * 90.0, 0.0)
	)
	var pressure_at_keeper := _nearest_active_distance(
		_controller.call("_get_opponents") as Array,
		target
	)
	if pressure_at_keeper < 650.0:
		return
	_append_candidate(
		candidates,
		receiver,
		PASS_RECYCLE,
		target,
		false,
		245.0 if under_pressure else 95.0
	)


func _append_two_player_receiver_candidates(
	candidates: Array[Dictionary],
	receiver: Node,
	ball_position: Vector2,
	attack_sign: float,
	under_pressure: bool
) -> void:
	# In the current 2v2 format one player is the designated goalkeeper. A
	# keeper carrying the ball needs a few clear distribution choices, not the
	# full 3v3 combination catalogue (third-man, overlap, blindside, wall bank,
	# and one-two variants all aimed at the same lone teammate).
	var base_position: Vector2 = receiver.get("global_position")
	var velocity: Vector2 = receiver.get("linear_velocity")
	var lead_target := _basic_lead_target(receiver)
	_append_candidate(
		candidates,
		receiver,
		PASS_TO_FEET,
		base_position + velocity * 0.08,
		false,
		35.0
	)
	_append_candidate(
		candidates,
		receiver,
		PASS_LEAD,
		lead_target,
		false,
		95.0
	)
	var receiver_progress := (
		base_position.x - ball_position.x
	) * attack_sign
	if receiver_progress >= -180.0:
		var through_target := _clamp(
			base_position
			+ velocity * 0.14
			+ Vector2(attack_sign * 620.0, 0.0)
		)
		_append_candidate(
			candidates,
			receiver,
			PASS_THROUGH,
			through_target,
			false,
			155.0
		)
	if under_pressure and receiver_progress < 520.0:
		var lateral_sign := signf(base_position.y - ball_position.y)
		if is_zero_approx(lateral_sign):
			lateral_sign = 1.0
		var escape_target := _clamp(
			base_position
			+ velocity * 0.08
			+ Vector2(attack_sign * 120.0, lateral_sign * 210.0)
		)
		_append_candidate(
			candidates,
			receiver,
			PASS_PRESSURE_ESCAPE,
			escape_target,
			false,
			175.0
		)


func _append_receiver_candidates(
	candidates: Array[Dictionary],
	receiver: Node,
	ball_position: Vector2,
	goal_center: Vector2,
	attack_sign: float,
	under_pressure: bool,
	defensive_shape: Dictionary
) -> void:
	var base_position: Vector2 = receiver.get("global_position")
	var velocity: Vector2 = receiver.get("linear_velocity")
	var field_center_y := (
		float(_controller.get("minimum_field_y"))
		+ float(_controller.get("maximum_field_y"))
	) * 0.5
	var basic_lead := _basic_lead_target(receiver)
	var receiver_intention := _controller.call(
		"_get_effective_player_intention",
		receiver
	) as Dictionary
	var receiver_action := StringName(receiver_intention.get("action", &""))
	var intended_target: Vector2 = receiver_intention.get(
		"target_position",
		basic_lead
	)
	var forward_progress := (
		base_position.x - ball_position.x
	) * attack_sign
	var lateral_sign := signf(base_position.y - ball_position.y)
	if is_zero_approx(lateral_sign):
		lateral_sign = -1.0 if base_position.y <= field_center_y else 1.0

	_append_candidate(
		candidates,
		receiver,
		PASS_TO_FEET,
		base_position + velocity * 0.08,
		false,
		0.0
	)
	_append_candidate(
		candidates,
		receiver,
		PASS_LEAD,
		basic_lead,
		false,
		65.0
	)

	var through_distance := clampf(
		520.0 + velocity.length() * 0.16,
		520.0,
		1180.0
	)
	if receiver_action == INTENT_FORWARD_RUN:
		through_distance += 260.0
	var through_target := _clamp(
		base_position
		+ velocity * 0.16
		+ Vector2(attack_sign * through_distance, 0.0)
	)
	_append_candidate(
		candidates,
		receiver,
		PASS_THROUGH,
		through_target,
		false,
		150.0
	)

	var diagonal_target := _clamp(
		base_position
		+ Vector2(
			attack_sign * 680.0,
			lateral_sign * 480.0
		)
	)
	_append_candidate(
		candidates,
		receiver,
		PASS_DIAGONAL_SPLIT,
		diagonal_target,
		false,
		120.0
	)

	var blindside_target := _get_blindside_target(
		receiver,
		ball_position,
		attack_sign
	)
	if not blindside_target.is_zero_approx():
		_append_candidate(
			candidates,
			receiver,
			PASS_BLINDSIDE,
			blindside_target,
			false,
			205.0
		)

	var square_separation := absf(base_position.y - ball_position.y)
	if square_separation >= 520.0 and absf(forward_progress) <= 720.0:
		var square_target := _clamp(
			base_position + velocity * 0.12
		)
		_append_candidate(
			candidates,
			receiver,
			PASS_SQUARE,
			square_target,
			false,
			145.0
		)

	var receiver_near_wall := absf(base_position.y - field_center_y) > 920.0
	var far_side_y := (
		float(_controller.get("minimum_field_y")) + 410.0
		if ball_position.y > field_center_y
		else float(_controller.get("maximum_field_y")) - 410.0
	)
	var switch_target := _clamp(Vector2(
		maxf(base_position.x, ball_position.x + attack_sign * 260.0)
		if attack_sign > 0.0
		else minf(base_position.x, ball_position.x + attack_sign * 260.0),
		far_side_y
	))
	if receiver_near_wall or bool(defensive_shape.get("far_side_open", false)):
		_append_candidate(
			candidates,
			receiver,
			PASS_WIDE_SWITCH,
			switch_target,
			false,
			180.0
		)

	var advanced_ball := (
		(goal_center.x - ball_position.x) * attack_sign <= 2050.0
	)
	if advanced_ball and forward_progress < 180.0:
		var cutback_target := _clamp(
			base_position
			+ velocity * 0.10
			+ Vector2(-attack_sign * 110.0, -lateral_sign * 90.0)
		)
		_append_candidate(
			candidates,
			receiver,
			PASS_CUTBACK,
			cutback_target,
			false,
			255.0
		)

	if under_pressure and forward_progress < 500.0:
		var escape_target := _clamp(
			base_position
			+ velocity * 0.08
			+ Vector2(-attack_sign * 170.0, lateral_sign * 240.0)
		)
		_append_candidate(
			candidates,
			receiver,
			PASS_PRESSURE_ESCAPE,
			escape_target,
			false,
			230.0
		)
		_append_candidate(
			candidates,
			receiver,
			PASS_LAYOFF,
			base_position + Vector2(-attack_sign * 120.0, 0.0),
			false,
			165.0
		)

	if receiver_action in [INTENT_FORWARD_RUN, INTENT_WIDE_SUPPORT]:
		var intention_target := _clamp(
			base_position
			+ (intended_target - base_position).limit_length(1450.0)
		)
		_append_candidate(
			candidates,
			receiver,
			PASS_OVERLAP if absf(intention_target.y - ball_position.y) > 430.0 else PASS_UNDERLAP,
			intention_target,
			false,
			210.0
		)

	var wall_destination := basic_lead
	var wall_route := _controller.call(
		"_get_best_wall_route",
		wall_destination
	) as Dictionary
	if not wall_route.is_empty():
		_append_candidate(
			candidates,
			receiver,
			PASS_WALL_BANK,
			wall_destination,
			true,
			140.0,
			wall_route
		)

	var player: Node = _controller.get("controlled_player")
	if not bool(_controller.call("_is_designated_goalkeeper", player)):
		var one_two_target := _clamp(
			player.get("global_position")
			+ Vector2(
				attack_sign * float(_controller.get("elite_one_two_run_distance")),
				-lateral_sign * 340.0
			)
		)
		_append_candidate(
			candidates,
			receiver,
			PASS_ONE_TWO,
			basic_lead,
			false,
			185.0,
			{},
			int(player.get("owner_peer_id")),
			one_two_target
		)

	var third_man := _best_third_man(receiver, basic_lead, goal_center, attack_sign)
	if not third_man.is_empty():
		_append_candidate(
			candidates,
			receiver,
			PASS_THIRD_MAN,
			basic_lead,
			false,
			225.0,
			{},
			int(third_man.get("peer_id", 0)),
			third_man.get("target", Vector2.ZERO)
		)


func _get_blindside_target(
	receiver: Node,
	ball_position: Vector2,
	attack_sign: float
) -> Vector2:
	var receiver_position: Vector2 = receiver.get("global_position")
	var nearest_marker: Node
	var nearest_distance := INF
	for opponent_variant in _controller.call("_get_opponents") as Array:
		var opponent := opponent_variant as Node
		if not _valid_actor(opponent):
			continue
		var distance := (
			(opponent.get("global_position") as Vector2)
			.distance_to(receiver_position)
		)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_marker = opponent
	if nearest_marker == null or nearest_distance > 1250.0:
		return Vector2.ZERO
	var marker_position: Vector2 = nearest_marker.get("global_position")
	var marker_is_goal_side := (
		(marker_position.x - receiver_position.x) * attack_sign > -120.0
	)
	if not marker_is_goal_side:
		return Vector2.ZERO
	var lateral_escape := signf(receiver_position.y - marker_position.y)
	if is_zero_approx(lateral_escape):
		lateral_escape = (
			-1.0
			if receiver_position.y <= ball_position.y
			else 1.0
		)
	return _clamp(
		receiver_position
		+ (receiver.get("linear_velocity") as Vector2) * 0.12
		+ Vector2(attack_sign * 590.0, lateral_escape * 330.0)
	)


func _append_candidate(
	candidates: Array[Dictionary],
	receiver: Node,
	kind: StringName,
	target: Vector2,
	uses_wall: bool,
	kind_bonus: float,
	wall_route: Dictionary = {},
	follow_up_peer_id: int = 0,
	follow_up_target: Vector2 = Vector2.ZERO
) -> void:
	candidates.append({
		"receiver": receiver,
		"receiver_peer_id": int(receiver.get("owner_peer_id")),
		"kind": kind,
		"target": _clamp(target),
		"uses_wall": uses_wall,
		"kind_bonus": kind_bonus,
		"wall_route": wall_route,
		"follow_up_peer_id": follow_up_peer_id,
		"follow_up_target": follow_up_target
	})


func _evaluate_pass_candidate(
	candidate: Dictionary,
	ball_position: Vector2,
	goal_center: Vector2,
	attack_sign: float,
	opponents: Array,
	under_pressure: bool,
	defensive_shape: Dictionary,
	precomputed_route: Dictionary = {}
) -> Dictionary:
	var receiver: Node = candidate.get("receiver") as Node
	var player: Node = _controller.get("controlled_player") as Node
	var kind := StringName(candidate.get("kind", PASS_LEAD))
	if not _valid_actor(receiver) or receiver == player:
		return {}
	if (
		bool(_controller.call("_is_designated_goalkeeper", receiver))
		and kind != PASS_RECYCLE
	):
		return {}
	var target: Vector2 = candidate.get("target", Vector2.ZERO)
	if target.is_zero_approx():
		return {}
	var distance := ball_position.distance_to(target)
	var minimum_distance := float(_controller.get("minimum_pass_distance"))
	var maximum_distance := float(_controller.get("maximum_pass_distance"))
	if distance < minimum_distance * 0.72 or distance > maximum_distance * 1.04:
		return {}

	var direct_clearance := (
		float(precomputed_route.get("direct_clearance", INF))
		if not precomputed_route.is_empty()
		else float(_controller.call(
			"_minimum_segment_clearance",
			ball_position,
			target
		))
	)
	var uses_wall := bool(candidate.get("uses_wall", false))
	var wall_route := candidate.get("wall_route", {}) as Dictionary
	var route_clearance := direct_clearance
	var route_distance := distance
	var bounce := Vector2.ZERO
	if uses_wall:
		if wall_route.is_empty():
			return {}
		route_clearance = float(wall_route.get("clearance", 0.0))
		route_distance = float(wall_route.get("distance", distance))
		bounce = wall_route.get("bounce", Vector2.ZERO)
		if bounce.is_zero_approx():
			return {}
	var minimum_lane := float(_controller.get("pass_lane_clearance"))
	var safety_ratio := 0.62 if kind in [PASS_PRESSURE_ESCAPE, PASS_LAYOFF, PASS_RECYCLE] else 0.74
	if route_clearance < minimum_lane * safety_ratio:
		return {}

	var route_safety: Dictionary = precomputed_route
	if route_safety.is_empty():
		route_safety = _route_interception_safety(
			ball_position,
			target,
			bounce,
			route_distance,
			opponents,
			receiver
		)
	var interception_margin := float(route_safety.get("margin", -2.0))
	if interception_margin < -0.13:
		return {}
	var receiver_margin := float(route_safety.get("receiver_margin", -2.0))
	if receiver_margin < -0.18 and kind not in [PASS_TO_FEET, PASS_LAYOFF]:
		return {}

	var openness := (
		float(precomputed_route.get("openness", INF))
		if not precomputed_route.is_empty()
		else float(_controller.call("_nearest_opponent_distance", target))
	)
	var forward_progress := (target.x - ball_position.x) * attack_sign
	var goal_gain := (
		ball_position.distance_to(goal_center)
		- target.distance_to(goal_center)
	)
	var chain_value := _follow_up_value(
		receiver,
		target,
		goal_center,
		attack_sign,
		int(candidate.get("follow_up_peer_id", 0)),
		candidate.get("follow_up_target", Vector2.ZERO)
	)
	var defensive_error_value := _defensive_error_value(
		kind,
		target,
		ball_position,
		defensive_shape,
		attack_sign
	)
	var counter_risk := _counter_risk_after_pass(
		receiver,
		target,
		ball_position,
		goal_center,
		attack_sign
	)
	var kind_bonus := float(candidate.get("kind_bonus", 0.0))
	var score := (
		forward_progress * 0.34
		+ goal_gain * 0.27
		+ minf(openness, 1500.0) * 0.31
		+ minf(route_clearance, 1300.0) * 0.38
		+ clampf(interception_margin, -0.2, 1.2) * 520.0
		+ clampf(receiver_margin, -0.2, 1.2) * 330.0
		+ chain_value * 0.72
		+ defensive_error_value
		+ kind_bonus
		- route_distance * 0.085
		- counter_risk * 620.0
	)
	if _controller.has_method("_get_tactical_role"):
		var receiver_role := StringName(_controller.call("_get_tactical_role", receiver))
		match receiver_role:
			&"striker":
				if kind in [PASS_THROUGH, PASS_BLINDSIDE, PASS_CUTBACK, PASS_LEAD]:
					score += 180.0
				if forward_progress > 420.0:
					score += 95.0
			&"playmaker":
				if kind in [PASS_ONE_TWO, PASS_LAYOFF, PASS_SQUARE, PASS_WIDE_SWITCH, PASS_TO_FEET]:
					score += 165.0
				if under_pressure:
					score += 75.0
			&"defender":
				if kind in [PASS_RECYCLE, PASS_PRESSURE_ESCAPE, PASS_TO_FEET]:
					score += 135.0
				elif forward_progress > 850.0:
					score -= 120.0
	# A safe human teammate must remain a real option even when the learned
	# policy was trained mostly against CPU receivers. An explicit pass request
	# is stronger still, but neither bonus can rescue an unsafe route because
	# interception and receiver-arrival gates were already enforced above.
	if not bool(receiver.get("cpu_controlled")):
		score += 95.0
	if float(receiver.get("server_pass_request_ends_at")) > _now():
		score += 720.0
	if under_pressure:
		if kind in [PASS_PRESSURE_ESCAPE, PASS_LAYOFF, PASS_WIDE_SWITCH, PASS_WALL_BANK]:
			score += 240.0
		else:
			score += clampf(interception_margin, 0.0, 1.0) * 85.0
	if kind == PASS_CUTBACK:
		score += maxf(0.0, goal_gain) * 0.22
	if kind == PASS_THROUGH and receiver_margin > 0.12:
		score += 190.0
	if kind == PASS_BLINDSIDE and receiver_margin > 0.08:
		score += 175.0
	if kind == PASS_SQUARE and under_pressure:
		score += 135.0
	if kind == PASS_RECYCLE:
		score += 175.0 if under_pressure else 25.0
	if kind == PASS_THIRD_MAN and chain_value > 380.0:
		score += 170.0
	if kind == PASS_ONE_TWO and chain_value > 300.0:
		score += 130.0
	if kind == PASS_WALL_BANK:
		score -= maxf(0.0, route_distance - distance) * 0.07

	var result := candidate.duplicate(true)
	result.erase("receiver")
	result["score"] = score
	result["destination"] = target
	result["route_target"] = bounce if uses_wall else target
	result["bounce"] = bounce
	result["route_distance"] = route_distance
	result["route_clearance"] = route_clearance
	result["direct_clearance"] = direct_clearance
	result["interception_margin"] = interception_margin
	result["receiver_margin"] = receiver_margin
	result["openness"] = openness
	result["forward_progress"] = forward_progress
	result["goal_gain"] = goal_gain
	result["chain_value"] = chain_value
	result["counter_risk"] = counter_risk
	result["defensive_error_value"] = defensive_error_value
	result["under_pressure"] = under_pressure
	result["reason"] = _pass_reason(kind, defensive_shape, under_pressure)
	return result


func _precompute_parallel_route_safety(
	candidates: Array[Dictionary],
	ball_position: Vector2,
	opponents: Array,
	active_team_count: int
) -> Array[Dictionary]:
	# The iPhone-friendly Web preset deliberately uses Godot's single-threaded
	# Web template. Returning no precompute here makes the existing evaluator use
	# its serial route-safety path instead of touching WorkerThreadPool.
	if OS.has_feature("web"):
		return []
	if (
		active_team_count < PARALLEL_PASS_MINIMUM_TEAM_SIZE
		or candidates.size() < PARALLEL_PASS_MINIMUM_CANDIDATES
	):
		return []
	var player: Node = _controller.get("controlled_player")
	var ball: Node = _controller.get("ball")
	if player == null or ball == null:
		return []

	var opponent_snapshots: Array[Dictionary] = []
	for opponent_variant in opponents:
		var opponent := opponent_variant as Node
		if not _valid_actor(opponent):
			continue
		var interception_bonus := float(
			_controller.call("_get_ability_interception_bonus", opponent)
		)
		opponent_snapshots.append(
			_make_parallel_actor_snapshot(opponent, interception_bonus)
		)
	if opponent_snapshots.is_empty():
		return []

	var damping := maxf(0.0, float(ball.get("linear_damp")))
	var ball_mass := maxf(0.05, float(ball.get("mass")))
	var maximum_distance := maxf(
		1.0,
		float(_controller.get("maximum_pass_distance"))
	)
	var minimum_force := float(player.get("minimum_shot_force"))
	var maximum_force := float(player.get("maximum_shot_force"))
	var wall_restitution := 0.8
	if _controller.has_method("_get_double_bank_wall_restitution"):
		wall_restitution = clampf(
			float(_controller.call("_get_double_bank_wall_restitution")),
			0.45,
			1.0
		)

	_parallel_route_jobs.clear()
	_parallel_route_jobs.resize(candidates.size())
	_parallel_route_results.clear()
	_parallel_route_results.resize(candidates.size())
	for index in range(candidates.size()):
		var candidate := candidates[index]
		var receiver: Node = candidate.get("receiver") as Node
		if not _valid_actor(receiver):
			_parallel_route_jobs[index] = {}
			continue
		var target: Vector2 = candidate.get("target", Vector2.ZERO)
		var uses_wall := bool(candidate.get("uses_wall", false))
		var wall_route := candidate.get("wall_route", {}) as Dictionary
		var bounce := Vector2.ZERO
		var route_distance := ball_position.distance_to(target)
		if uses_wall and not wall_route.is_empty():
			bounce = wall_route.get("bounce", Vector2.ZERO) as Vector2
			route_distance = float(
				wall_route.get("distance", route_distance)
			)
		var distance_ratio := clampf(
			route_distance / maximum_distance,
			0.0,
			1.0
		)
		var force_ratio := lerpf(0.28, 0.78, distance_ratio)
		var force := lerpf(minimum_force, maximum_force, force_ratio)
		var launch_speed := maxf(520.0, force / ball_mass)
		_parallel_route_jobs[index] = {
			"start": ball_position,
			"destination": target,
			"bounce": bounce,
			"route_distance": route_distance,
			"launch_speed": launch_speed,
			"damping": damping,
			"wall_restitution": wall_restitution,
			"receiver": _make_parallel_actor_snapshot(receiver, 0.0),
			"opponents": opponent_snapshots
		}

	var worker_count := clampi(
		OS.get_processor_count() - 2,
		2,
		PARALLEL_PASS_MAX_WORKERS
	)
	worker_count = mini(worker_count, candidates.size())
	var group_id := WorkerThreadPool.add_group_task(
		_parallel_route_safety_worker,
		candidates.size(),
		worker_count,
		true,
		"large-team pass route safety"
	)
	WorkerThreadPool.wait_for_group_task_completion(group_id)
	return _parallel_route_results


func _make_parallel_actor_snapshot(
	actor: Node,
	interception_bonus: float
) -> Dictionary:
	return {
		"position": actor.get("global_position") as Vector2,
		"velocity": actor.get("linear_velocity") as Vector2,
		"max_speed": maxf(500.0, float(actor.get("max_speed"))),
		"acceleration": maxf(800.0, float(actor.get("acceleration"))),
		"interception_bonus": maxf(0.0, interception_bonus)
	}


func _parallel_route_safety_worker(index: int) -> void:
	var job := _parallel_route_jobs[index]
	if job.is_empty():
		_parallel_route_results[index] = {}
		return
	_parallel_route_results[index] = _route_safety_from_snapshot(job)


func _route_safety_from_snapshot(job: Dictionary) -> Dictionary:
	# Worker-thread function: only copied dictionaries, arrays, floats and vectors.
	# Never touch _controller, Nodes, SceneTree, physics or rendering from here.
	var start: Vector2 = job.get("start", Vector2.ZERO)
	var destination: Vector2 = job.get("destination", Vector2.ZERO)
	var bounce: Vector2 = job.get("bounce", Vector2.ZERO)
	var launch_speed := maxf(1.0, float(job.get("launch_speed", 520.0)))
	var damping := maxf(0.0, float(job.get("damping", 0.0)))
	var restitution := clampf(
		float(job.get("wall_restitution", 0.8)),
		0.0,
		1.0
	)
	var receiver := job.get("receiver", {}) as Dictionary
	var opponents := job.get("opponents", []) as Array
	var direct_clearance := INF
	var openness := INF
	for opponent_variant in opponents:
		var opponent := opponent_variant as Dictionary
		var opponent_position: Vector2 = opponent.get(
			"position",
			Vector2.ZERO
		) as Vector2
		direct_clearance = minf(
			direct_clearance,
			_parallel_distance_to_segment(
				opponent_position,
				start,
				destination
			) - float(opponent.get("interception_bonus", 0.0))
		)
		openness = minf(
			openness,
			opponent_position.distance_to(destination)
		)

	var minimum_margin := INF
	var elapsed_time := 0.0
	var segment_start_speed := launch_speed
	var segment_count := 1 if bounce.is_zero_approx() else 2
	for segment_index in range(segment_count):
		var a := start if segment_index == 0 else bounce
		var b := destination if segment_count == 1 or segment_index == 1 else bounce
		var segment_distance := a.distance_to(b)
		for sample_index in range(1, 7):
			var ratio := float(sample_index) / 6.0
			var point := a.lerp(b, ratio)
			var local_distance := segment_distance * ratio
			var ball_time := elapsed_time + _parallel_ball_travel_seconds(
				local_distance,
				segment_start_speed,
				damping
			)
			for opponent_variant in opponents:
				var opponent := opponent_variant as Dictionary
				var opponent_time := maxf(
					0.0,
					_parallel_actor_arrival_seconds(opponent, point) - 0.06
				)
				minimum_margin = minf(
					minimum_margin,
					opponent_time - ball_time
				)
		var segment_time := _parallel_ball_travel_seconds(
			segment_distance,
			segment_start_speed,
			damping
		)
		elapsed_time += segment_time
		segment_start_speed = maxf(
			0.0,
			segment_start_speed * exp(-damping * segment_time)
		)
		if segment_index < segment_count - 1:
			segment_start_speed *= restitution
	if is_inf(minimum_margin):
		minimum_margin = 2.0
	var receiver_arrival := _parallel_actor_arrival_seconds(
		receiver,
		destination
	)
	return {
		"margin": minimum_margin,
		"receiver_margin": elapsed_time - receiver_arrival,
		"ball_time": elapsed_time,
		"receiver_time": receiver_arrival,
		"arrival_speed": segment_start_speed,
		"direct_clearance": direct_clearance,
		"openness": openness
	}


func _parallel_actor_arrival_seconds(
	actor: Dictionary,
	point: Vector2
) -> float:
	if actor.is_empty():
		return 3.5
	var position: Vector2 = actor.get("position", Vector2.ZERO) as Vector2
	var velocity: Vector2 = actor.get("velocity", Vector2.ZERO) as Vector2
	var displacement := point - position
	var distance := displacement.length()
	if distance <= 1.0:
		return 0.0
	var direction := displacement / distance
	var velocity_alignment := (
		velocity.normalized().dot(direction)
		if velocity.length() > 60.0
		else 1.0
	)
	var turn_penalty := lerpf(
		0.0,
		0.16,
		clampf((0.35 - velocity_alignment) / 1.35, 0.0, 1.0)
	)
	var initial_speed := maxf(0.0, velocity.dot(direction))
	var maximum_speed := maxf(500.0, float(actor.get("max_speed", 500.0)))
	var acceleration := maxf(800.0, float(actor.get("acceleration", 800.0)))
	var accelerate_time := maxf(
		0.0,
		(maximum_speed - initial_speed) / acceleration
	)
	var accelerate_distance := (
		initial_speed * accelerate_time
		+ 0.5 * acceleration * accelerate_time * accelerate_time
	)
	if distance <= accelerate_distance:
		return turn_penalty + (
			-sqrt(maxf(
				0.0,
				initial_speed * initial_speed + 2.0 * acceleration * distance
			)) + initial_speed
		) / -acceleration
	return (
		turn_penalty
		+ accelerate_time
		+ (distance - accelerate_distance) / maximum_speed
	)


func _parallel_ball_travel_seconds(
	distance: float,
	initial_speed: float,
	damping: float
) -> float:
	var safe_distance := maxf(0.0, distance)
	var safe_speed := maxf(1.0, initial_speed)
	if damping <= 0.001:
		return safe_distance / safe_speed
	var distance_fraction := damping * safe_distance / safe_speed
	if distance_fraction >= 0.96:
		return safe_distance / maxf(120.0, safe_speed * 0.24)
	return -log(maxf(0.04, 1.0 - distance_fraction)) / damping


func _parallel_distance_to_segment(
	point: Vector2,
	segment_start: Vector2,
	segment_end: Vector2
) -> float:
	var segment := segment_end - segment_start
	var length_squared := segment.length_squared()
	if length_squared <= 0.0001:
		return point.distance_to(segment_start)
	var ratio := clampf(
		(point - segment_start).dot(segment) / length_squared,
		0.0,
		1.0
	)
	return point.distance_to(segment_start + segment * ratio)


func _route_interception_safety(
	start: Vector2,
	destination: Vector2,
	bounce: Vector2,
	route_distance: float,
	opponents: Array,
	receiver: Node
) -> Dictionary:
	var launch_speed := _estimated_pass_speed(route_distance)
	var restitution := 1.0
	if not bounce.is_zero_approx():
		restitution = 0.8
		if _controller.has_method("_get_double_bank_wall_restitution"):
			restitution = clampf(
				float(_controller.call("_get_double_bank_wall_restitution")),
				0.45,
				1.0
			)
	var segments: Array[Dictionary] = []
	if bounce.is_zero_approx():
		segments.append({"a": start, "b": destination})
	else:
		segments.append({"a": start, "b": bounce})
		segments.append({"a": bounce, "b": destination})
	var minimum_margin := INF
	var elapsed_time := 0.0
	var segment_start_speed := launch_speed
	for segment_index in range(segments.size()):
		var segment := segments[segment_index] as Dictionary
		var a: Vector2 = segment.get("a", Vector2.ZERO)
		var b: Vector2 = segment.get("b", Vector2.ZERO)
		var segment_distance := a.distance_to(b)
		for sample_index in range(1, 7):
			var ratio := float(sample_index) / 6.0
			var point := a.lerp(b, ratio)
			var local_distance := segment_distance * ratio
			var ball_time := elapsed_time + _estimated_ball_travel_seconds(
				local_distance,
				segment_start_speed
			)
			for opponent_variant in opponents:
				var opponent := opponent_variant as Node
				if not _valid_actor(opponent):
					continue
				# The small reaction allowance deliberately favors the defender. A
				# plan that remains safe here is far less likely to become an easy
				# interception when physics/collisions differ slightly.
				var opponent_time := maxf(
					0.0,
					_estimate_arrival_seconds(opponent, point) - 0.06
				)
				minimum_margin = minf(
					minimum_margin,
					opponent_time - ball_time
				)
		var segment_time := _estimated_ball_travel_seconds(
			segment_distance,
			segment_start_speed
		)
		elapsed_time += segment_time
		segment_start_speed = _remaining_ball_speed(
			segment_start_speed,
			segment_time
		)
		if segment_index < segments.size() - 1:
			segment_start_speed *= restitution
	if is_inf(minimum_margin):
		minimum_margin = 2.0
	var receiver_arrival := _estimate_arrival_seconds(receiver, destination)
	return {
		"margin": minimum_margin,
		"receiver_margin": elapsed_time - receiver_arrival,
		"ball_time": elapsed_time,
		"receiver_time": receiver_arrival,
		"arrival_speed": segment_start_speed
	}


func _estimated_ball_travel_seconds(
	distance: float,
	initial_speed: float
) -> float:
	var safe_distance := maxf(0.0, distance)
	var safe_speed := maxf(1.0, initial_speed)
	var ball: Node = _controller.get("ball")
	var damping := (
		maxf(0.0, float(ball.get("linear_damp")))
		if ball != null
		else 0.0
	)
	if damping <= 0.001:
		return safe_distance / safe_speed
	var distance_fraction := damping * safe_distance / safe_speed
	if distance_fraction >= 0.96:
		# The pass would be crawling by arrival. Treat it as much slower rather
		# than granting a false safe margin from constant-speed geometry.
		return safe_distance / maxf(120.0, safe_speed * 0.24)
	return -log(maxf(0.04, 1.0 - distance_fraction)) / damping


func _remaining_ball_speed(
	initial_speed: float,
	travel_seconds: float
) -> float:
	var ball: Node = _controller.get("ball")
	var damping := (
		maxf(0.0, float(ball.get("linear_damp")))
		if ball != null
		else 0.0
	)
	return maxf(0.0, initial_speed * exp(-damping * travel_seconds))


func _estimated_pass_speed(route_distance: float) -> float:
	var player: Node = _controller.get("controlled_player")
	var ball: Node = _controller.get("ball")
	var maximum_distance := maxf(1.0, float(_controller.get("maximum_pass_distance")))
	var distance_ratio := clampf(route_distance / maximum_distance, 0.0, 1.0)
	var minimum_force := float(player.get("minimum_shot_force"))
	var maximum_force := float(player.get("maximum_shot_force"))
	var force_ratio := lerpf(0.28, 0.78, distance_ratio)
	var force := lerpf(minimum_force, maximum_force, force_ratio)
	return maxf(520.0, force / maxf(0.05, float(ball.get("mass"))))


func _estimate_arrival_seconds(actor: Node, point: Vector2) -> float:
	if not _valid_actor(actor):
		return 3.5
	var position: Vector2 = actor.get("global_position")
	var velocity: Vector2 = actor.get("linear_velocity")
	var displacement := point - position
	var distance := displacement.length()
	if distance <= 1.0:
		return 0.0
	var direction := displacement / distance
	var velocity_alignment := (
		velocity.normalized().dot(direction)
		if velocity.length() > 60.0
		else 1.0
	)
	var turn_penalty := lerpf(
		0.0,
		0.16,
		clampf((0.35 - velocity_alignment) / 1.35, 0.0, 1.0)
	)
	var initial_speed := maxf(0.0, velocity.dot(direction))
	var maximum_speed := maxf(500.0, float(actor.get("max_speed")))
	var acceleration := maxf(800.0, float(actor.get("acceleration")))
	var accelerate_time := maxf(0.0, (maximum_speed - initial_speed) / acceleration)
	var accelerate_distance := (
		initial_speed * accelerate_time
		+ 0.5 * acceleration * accelerate_time * accelerate_time
	)
	if distance <= accelerate_distance:
		return turn_penalty + (
			-sqrt(maxf(0.0, initial_speed * initial_speed + 2.0 * acceleration * distance))
			+ initial_speed
		) / -acceleration
	return (
		turn_penalty
		+ accelerate_time
		+ (distance - accelerate_distance) / maximum_speed
	)


func _follow_up_value(
	receiver: Node,
	receiver_target: Vector2,
	goal_center: Vector2,
	attack_sign: float,
	preferred_peer_id: int,
	preferred_target: Vector2
) -> float:
	var best_value := 0.0
	var teammates: Array = _controller.call("_get_teammates") as Array
	for teammate_variant in teammates:
		var teammate := teammate_variant as Node
		if (
			not _valid_actor(teammate)
			or teammate == receiver
			or teammate == _controller.get("controlled_player")
			or bool(_controller.call("_is_designated_goalkeeper", teammate))
		):
			continue
		var target := _basic_lead_target(teammate)
		if int(teammate.get("owner_peer_id")) == preferred_peer_id and not preferred_target.is_zero_approx():
			target = preferred_target
		var distance := receiver_target.distance_to(target)
		if distance < 300.0 or distance > float(_controller.get("maximum_pass_distance")):
			continue
		var clearance := float(_controller.call(
			"_minimum_segment_clearance",
			receiver_target,
			target
		))
		if clearance < float(_controller.get("pass_lane_clearance")) * 0.62:
			continue
		var progress := (target.x - receiver_target.x) * attack_sign
		var openness := float(_controller.call("_nearest_opponent_distance", target))
		var goal_gain := receiver_target.distance_to(goal_center) - target.distance_to(goal_center)
		best_value = maxf(
			best_value,
			progress * 0.28
			+ goal_gain * 0.22
			+ minf(clearance, 1200.0) * 0.31
			+ minf(openness, 1400.0) * 0.29
			- distance * 0.06
		)
	var shot_lane := float(_controller.call(
		"_minimum_segment_clearance",
		receiver_target,
		goal_center
	))
	var shot_gain := (
		minf(shot_lane, 1200.0) * 0.36
		+ maxf(0.0, 2600.0 - receiver_target.distance_to(goal_center)) * 0.18
	)
	return maxf(best_value, shot_gain)


func _best_third_man(
	receiver: Node,
	receiver_target: Vector2,
	goal_center: Vector2,
	attack_sign: float
) -> Dictionary:
	var best: Dictionary = {}
	var best_score := -INF
	for teammate_variant in _controller.call("_get_teammates") as Array:
		var teammate := teammate_variant as Node
		if (
			not _valid_actor(teammate)
			or teammate == receiver
			or teammate == _controller.get("controlled_player")
			or bool(_controller.call("_is_designated_goalkeeper", teammate))
		):
			continue
		var target := _clamp(
			_basic_lead_target(teammate)
			+ Vector2(attack_sign * 420.0, 0.0)
		)
		var clearance := float(_controller.call(
			"_minimum_segment_clearance",
			receiver_target,
			target
		))
		if clearance < float(_controller.get("pass_lane_clearance")) * 0.66:
			continue
		var score := (
			(target.x - receiver_target.x) * attack_sign * 0.42
			+ minf(clearance, 1200.0) * 0.34
			+ minf(float(_controller.call("_nearest_opponent_distance", target)), 1400.0) * 0.35
			+ (receiver_target.distance_to(goal_center) - target.distance_to(goal_center)) * 0.24
		)
		if score > best_score:
			best_score = score
			best = {
				"peer_id": int(teammate.get("owner_peer_id")),
				"target": target,
				"score": score
			}
	return best if best_score >= 330.0 else {}


func _counter_risk_after_pass(
	receiver: Node,
	target: Vector2,
	ball_position: Vector2,
	goal_center: Vector2,
	attack_sign: float
) -> float:
	var own_goal: Node = _controller.call("_get_own_goal")
	if own_goal == null:
		return 0.0
	var own_goal_center: Vector2 = _controller.call("_get_goal_center", own_goal)
	var outfield_behind := 0
	var closest_cover := INF
	for teammate_variant in _controller.call("_get_teammates") as Array:
		var teammate := teammate_variant as Node
		if not _valid_actor(teammate) or teammate == receiver:
			continue
		if bool(_controller.call("_is_designated_goalkeeper", teammate)):
			continue
		var position: Vector2 = teammate.get("global_position")
		var behind_ball := (position.x - target.x) * attack_sign < -260.0
		if behind_ball:
			outfield_behind += 1
		closest_cover = minf(closest_cover, position.distance_to(
			target.lerp(own_goal_center, 0.42)
		))
	var progress := (target.x - ball_position.x) * attack_sign
	var risk := 0.0
	if outfield_behind <= 0 and progress > 420.0:
		risk += 0.62
	if closest_cover > 1500.0:
		risk += clampf((closest_cover - 1500.0) / 1700.0, 0.0, 0.55)
	if target.distance_to(goal_center) < 1300.0:
		risk *= 0.72
	return clampf(risk, 0.0, 1.0)


func _defensive_error_value(
	kind: StringName,
	target: Vector2,
	ball_position: Vector2,
	shape: Dictionary,
	attack_sign: float
) -> float:
	var value := 0.0
	if bool(shape.get("overcommitted_to_ball", false)):
		if kind in [
			PASS_WIDE_SWITCH,
			PASS_CUTBACK,
			PASS_PRESSURE_ESCAPE,
			PASS_WALL_BANK,
			PASS_SQUARE,
			PASS_RECYCLE
		]:
			value += 260.0
	if bool(shape.get("far_side_open", false)) and kind == PASS_WIDE_SWITCH:
		value += 330.0
	if bool(shape.get("central_gap_open", false)) and kind in [
		PASS_THROUGH,
		PASS_DIAGONAL_SPLIT,
		PASS_BLINDSIDE,
		PASS_THIRD_MAN
	]:
		value += 310.0
	if bool(shape.get("line_broken", false)) and (target.x - ball_position.x) * attack_sign > 420.0:
		value += 220.0
	var target_side := signf(target.y - float(shape.get("center_y", target.y)))
	var defense_side := signf(float(shape.get("average_y", target.y)) - float(shape.get("center_y", target.y)))
	if target_side != 0.0 and defense_side != 0.0 and target_side != defense_side:
		value += float(shape.get("side_shift", 0.0)) * 190.0
	return value


func _analyze_defensive_shape(
	opponents: Array,
	ball_position: Vector2,
	goal_center: Vector2,
	attack_sign: float
) -> Dictionary:
	var active: Array[Node] = []
	var center_y := (
		float(_controller.get("minimum_field_y"))
		+ float(_controller.get("maximum_field_y"))
	) * 0.5
	var average_y := center_y
	var close_to_ball := 0
	var min_y := INF
	var max_y := -INF
	var defenders_ahead := 0
	for opponent_variant in opponents:
		var opponent := opponent_variant as Node
		if not _valid_actor(opponent):
			continue
		active.append(opponent)
		var position: Vector2 = opponent.get("global_position")
		average_y += position.y - center_y
		min_y = minf(min_y, position.y)
		max_y = maxf(max_y, position.y)
		if position.distance_to(ball_position) <= 930.0:
			close_to_ball += 1
		if (position.x - ball_position.x) * attack_sign > 80.0:
			defenders_ahead += 1
	if not active.is_empty():
		average_y = center_y + (average_y - center_y) / float(active.size())
	else:
		min_y = center_y
		max_y = center_y
	var width := maxf(0.0, max_y - min_y)
	var side_shift := clampf(absf(average_y - center_y) / 1150.0, 0.0, 1.0)
	var far_side_open := side_shift >= 0.34 or width < 1050.0
	var overcommitted := close_to_ball >= mini(2, active.size())
	var central_gap_open := false
	if active.size() >= 2:
		var ys: Array[float] = []
		for opponent in active:
			ys.append((opponent.get("global_position") as Vector2).y)
		ys.sort()
		var largest_gap := 0.0
		for index in range(1, ys.size()):
			largest_gap = maxf(largest_gap, ys[index] - ys[index - 1])
		central_gap_open = largest_gap >= 720.0
	return {
		"center_y": center_y,
		"average_y": average_y,
		"width": width,
		"side_shift": side_shift,
		"far_side_open": far_side_open,
		"overcommitted_to_ball": overcommitted,
		"central_gap_open": central_gap_open,
		"line_broken": defenders_ahead <= maxi(0, active.size() - 2),
		"close_to_ball": close_to_ball,
		"defender_count": active.size(),
		"goal_distance": ball_position.distance_to(goal_center)
	}


func _calculate_support_assignments(carrier: Node) -> Dictionary:
	var assignments: Dictionary = {}
	var support_players: Array[Node] = []
	var active_team_count := int(
		_controller.call("_get_active_team_player_count")
	)
	for teammate_variant in _controller.call("_get_teammates") as Array:
		var teammate := teammate_variant as Node
		if (
			not _valid_actor(teammate)
			or teammate == carrier
			or not bool(teammate.get("cpu_controlled"))
		):
			continue
		var designated_goalkeeper := bool(
			_controller.call("_is_designated_goalkeeper", teammate)
		)
		if designated_goalkeeper and active_team_count > 2:
			continue
		support_players.append(teammate)
	if support_players.is_empty():
		return assignments
	support_players.sort_custom(func(a: Node, b: Node) -> bool:
		return int(a.get("owner_peer_id")) < int(b.get("owner_peer_id"))
	)
	var targets := _build_support_targets(carrier, support_players.size())
	var role_order := _preferred_support_role_order(
		carrier,
		support_players.size()
	)
	var used_indices: Dictionary = {}

	# In 2v2 there is only one supporting outfielder. Do not force that player
	# to sit behind the ball every possession: choose the single role that best
	# fits the pressure, space and counter-risk state.
	if support_players.size() == 1:
		var player := support_players[0]
		var fallback := _best_unused_support_target(
			player,
			targets,
			used_indices,
			carrier
		)
		if not fallback.is_empty():
			assignments[str(int(player.get("owner_peer_id")))] = (
				fallback.get("target_data", {})
			)
		return assignments

	for role_variant in role_order:
		var role_order_name := str(role_variant)
		var best_player: Node
		var best_target_index := -1
		var best_score := -INF
		for player in support_players:
			var peer_key := str(int(player.get("owner_peer_id")))
			if assignments.has(peer_key):
				continue
			for target_index in range(targets.size()):
				if used_indices.has(target_index):
					continue
				var target_data := targets[target_index] as Dictionary
				if str(target_data.get("role", "")) != role_order_name:
					continue
				var score := _support_fit_score(player, target_data, carrier)
				if score > best_score:
					best_score = score
					best_player = player
					best_target_index = target_index
		if best_player != null and best_target_index >= 0:
			var selected := targets[best_target_index] as Dictionary
			assignments[str(int(best_player.get("owner_peer_id")))] = selected
			used_indices[best_target_index] = true
		if assignments.size() >= support_players.size():
			break

	for player in support_players:
		var peer_key := str(int(player.get("owner_peer_id")))
		if assignments.has(peer_key):
			continue
		var fallback := _best_unused_support_target(
			player,
			targets,
			used_indices,
			carrier
		)
		if not fallback.is_empty():
			assignments[peer_key] = fallback.get("target_data", {})
			used_indices[int(fallback.get("index", -1))] = true
	return assignments


func _preferred_support_role_order(
	carrier: Node,
	support_count: int
) -> Array[String]:
	var ball: Node = _controller.get("ball")
	var ball_position: Vector2 = ball.get("global_position")
	var opponents: Array = _controller.call("_get_opponents") as Array
	var pressure := _nearest_active_distance(opponents, ball_position)
	var pressure_radius := float(_controller.get("pass_pressure_radius"))
	var opponent_goal: Node = _controller.call("_get_opponent_goal")
	var goal_distance := INF
	if opponent_goal != null:
		goal_distance = ball_position.distance_to(
			_controller.call("_get_goal_center", opponent_goal) as Vector2
		)
	var carrier_intention := (
		_controller.call("_get_effective_player_intention", carrier)
		as Dictionary
	)
	var carrier_action := StringName(carrier_intention.get("action", &""))
	var shooting_phase := (
		bool(carrier.get("server_is_charging"))
		or carrier_action == &"shoot"
		or goal_distance
		<= float(_controller.get("off_ball_shooting_phase_goal_distance"))
	)
	var under_pressure := pressure <= pressure_radius
	var line_x := _get_last_defender_line_x(opponent_goal)
	var attack_sign := float(_controller.call("_get_attack_sign"))
	var line_is_available := (
		opponent_goal != null
		and (
			line_x - ball_position.x
		) * attack_sign
		>= float(_controller.get("off_ball_run_behind_minimum_space"))
	)

	if support_count >= 3:
		if shooting_phase:
			return [
				str(SUPPORT_REBOUND),
				str(SUPPORT_FAR_POST),
				str(SUPPORT_COVER),
				str(SUPPORT_WIDTH),
				str(SUPPORT_RETURN_LANE),
				str(SUPPORT_RUN_BEHIND),
				str(SUPPORT_DECOY)
			]
		if under_pressure:
			return [
				str(SUPPORT_RETURN_LANE),
				str(SUPPORT_COVER),
				str(SUPPORT_WIDTH),
				str(SUPPORT_RUN_BEHIND),
				str(SUPPORT_DECOY),
				str(SUPPORT_REBOUND),
				str(SUPPORT_FAR_POST)
			]
		if line_is_available:
			return [
				str(SUPPORT_RUN_BEHIND),
				str(SUPPORT_COVER),
				str(SUPPORT_WIDTH),
				str(SUPPORT_RETURN_LANE),
				str(SUPPORT_DECOY),
				str(SUPPORT_REBOUND),
				str(SUPPORT_FAR_POST)
			]
		return [
			str(SUPPORT_WIDTH),
			str(SUPPORT_RETURN_LANE),
			str(SUPPORT_COVER),
			str(SUPPORT_DECOY),
			str(SUPPORT_RUN_BEHIND),
			str(SUPPORT_REBOUND),
			str(SUPPORT_FAR_POST)
		]

	if support_count == 2:
		if shooting_phase:
			return [
				str(SUPPORT_REBOUND),
				str(SUPPORT_FAR_POST),
				str(SUPPORT_COVER),
				str(SUPPORT_RETURN_LANE),
				str(SUPPORT_WIDTH),
				str(SUPPORT_RUN_BEHIND)
			]
		if under_pressure:
			return [
				str(SUPPORT_RETURN_LANE),
				str(SUPPORT_COVER),
				str(SUPPORT_WIDTH),
				str(SUPPORT_RUN_BEHIND),
				str(SUPPORT_DECOY)
			]
		return [
			str(SUPPORT_RUN_BEHIND),
			str(SUPPORT_COVER),
			str(SUPPORT_WIDTH),
			str(SUPPORT_RETURN_LANE),
			str(SUPPORT_DECOY),
			str(SUPPORT_REBOUND)
		]

	if shooting_phase:
		return [
			str(SUPPORT_FAR_POST),
			str(SUPPORT_REBOUND),
			str(SUPPORT_RETURN_LANE),
			str(SUPPORT_COVER),
			str(SUPPORT_RUN_BEHIND),
			str(SUPPORT_WIDTH)
		]
	if under_pressure:
		return [
			str(SUPPORT_RETURN_LANE),
			str(SUPPORT_WIDTH),
			str(SUPPORT_COVER),
			str(SUPPORT_RUN_BEHIND),
			str(SUPPORT_DECOY)
		]
	return [
		str(SUPPORT_RUN_BEHIND),
		str(SUPPORT_RETURN_LANE),
		str(SUPPORT_WIDTH),
		str(SUPPORT_COVER),
		str(SUPPORT_DECOY),
		str(SUPPORT_REBOUND)
	]


func _build_large_team_support_targets(
	carrier: Node,
	support_count: int,
	team_count: int
) -> Array[Dictionary]:
	var origin: Vector2 = carrier.get("global_position")
	var velocity: Vector2 = carrier.get("linear_velocity")
	var attack_sign := float(_controller.call("_get_attack_sign"))
	var projected := origin + velocity * 0.12
	var minimum_y := float(_controller.get("minimum_field_y"))
	var maximum_y := float(_controller.get("maximum_field_y"))
	var center_y := (minimum_y + maximum_y) * 0.5
	var field_height := maxf(1200.0, maximum_y - minimum_y)
	var spread_scale := 1.0
	if team_count >= 6:
		spread_scale = 1.12
	elif team_count >= 5:
		spread_scale = 1.06
	var minimum_spacing := maxf(
		620.0,
		float(_controller.get("large_team_minimum_support_spacing"))
	)
	var wall_margin := maxf(
		300.0,
		float(_controller.get("off_ball_width_wall_margin")) * 0.88
	)
	var upper_wide_y := minimum_y + wall_margin
	var lower_wide_y := maximum_y - wall_margin
	var half_space_offset := minf(
		field_height * 0.25,
		720.0 * spread_scale
	)
	var run_offset := minf(
		field_height * 0.31,
		980.0 * spread_scale
	)
	var return_depth := maxf(
		620.0,
		float(_controller.get("off_ball_return_lane_depth")) * 1.20
	)
	var cover_depth := maxf(
		900.0,
		float(_controller.get("off_ball_cover_distance")) * 1.25
	)
	var width_advance := maxf(
		420.0,
		float(_controller.get("off_ball_width_forward_distance")) * 0.82
	)

	var opponent_goal: Node = _controller.call("_get_opponent_goal")
	var goal_center := (
		_controller.call("_get_goal_center", opponent_goal) as Vector2
		if opponent_goal != null
		else projected + Vector2(attack_sign * 3200.0, 0.0)
	)
	var last_defender_x := _get_last_defender_line_x(opponent_goal)
	var run_x := last_defender_x + (
		attack_sign * maxf(
			500.0,
			float(_controller.get("off_ball_run_behind_distance")) * 0.92
		)
	)
	var run_goal_limit := goal_center.x - (
		attack_sign * float(_controller.get("off_ball_goal_line_buffer"))
	)
	if attack_sign > 0.0:
		run_x = minf(run_x, run_goal_limit)
	else:
		run_x = maxf(run_x, run_goal_limit)

	var cover_target := _clamp(Vector2(
		projected.x - attack_sign * cover_depth,
		lerpf(projected.y, center_y, 0.76)
	))
	var return_upper := _clamp(Vector2(
		projected.x - attack_sign * return_depth,
		center_y - half_space_offset
	))
	var return_lower := _clamp(Vector2(
		projected.x - attack_sign * return_depth,
		center_y + half_space_offset
	))
	var width_upper := _clamp(Vector2(
		projected.x + attack_sign * width_advance,
		upper_wide_y
	))
	var width_lower := _clamp(Vector2(
		projected.x + attack_sign * width_advance,
		lower_wide_y
	))
	var run_upper := _clamp(Vector2(run_x, center_y - run_offset))
	var run_lower := _clamp(Vector2(run_x, center_y + run_offset))
	var decoy_side := 1.0 if projected.y < center_y else -1.0
	var decoy_target := _clamp(Vector2(
		projected.x + attack_sign * maxf(620.0, width_advance * 1.25),
		center_y + decoy_side * minf(field_height * 0.34, 1160.0 * spread_scale)
	))

	var mouth_range := _get_goal_mouth_range(opponent_goal, goal_center.y)
	var carrier_side := -1.0 if projected.y < center_y else 1.0
	var far_post_y := (
		mouth_range.y - float(_controller.get("off_ball_far_post_mouth_padding"))
		if carrier_side < 0.0
		else mouth_range.x + float(_controller.get("off_ball_far_post_mouth_padding"))
	)
	var far_post_target := _clamp(Vector2(
		goal_center.x - attack_sign * float(_controller.get("off_ball_far_post_depth")),
		far_post_y
	))
	var rebound_target := _clamp(Vector2(
		goal_center.x - attack_sign * float(_controller.get("off_ball_rebound_goal_distance")),
		goal_center.y - carrier_side * maxf(420.0, half_space_offset * 0.72)
	))

	# Never hand an off-ball player a nominal support lane that is basically on
	# top of the carrier. This is the core anti-brawl rule for 4v4-6v6.
	var candidate_positions: Array[Vector2] = [
		cover_target,
		return_upper,
		return_lower,
		width_upper,
		width_lower,
		run_upper,
		run_lower,
		decoy_target,
		far_post_target,
		rebound_target
	]
	for index in range(candidate_positions.size()):
		var target := candidate_positions[index]
		var delta := target - origin
		if delta.length() < minimum_spacing:
			if delta.is_zero_approx():
				delta = Vector2(-attack_sign, -1.0 if index % 2 == 0 else 1.0)
			candidate_positions[index] = _clamp(
				origin + delta.normalized() * minimum_spacing
			)

	cover_target = candidate_positions[0]
	return_upper = candidate_positions[1]
	return_lower = candidate_positions[2]
	width_upper = candidate_positions[3]
	width_lower = candidate_positions[4]
	run_upper = candidate_positions[5]
	run_lower = candidate_positions[6]
	decoy_target = candidate_positions[7]
	far_post_target = candidate_positions[8]
	rebound_target = candidate_positions[9]

	var pressure := _nearest_active_distance(
		_controller.call("_get_opponents") as Array,
		origin
	)
	var under_pressure := pressure <= float(_controller.get("pass_pressure_radius"))
	var cover_bias := 330.0 + (120.0 if under_pressure else 0.0)
	var return_bias := 300.0 + (180.0 if under_pressure else 0.0)
	var width_bias := 335.0
	var run_bias := 350.0 - (75.0 if under_pressure else 0.0)
	var far_post_bias := 170.0
	var rebound_bias := 155.0
	if support_count >= 4:
		cover_bias += 80.0
		width_bias += 45.0
		run_bias += 35.0

	return [
		{
			"role": str(SUPPORT_COVER),
			"intent": INTENT_COVER,
			"position": cover_target,
			"score_bias": cover_bias,
			"reason": "large_team_hold_rest_defense"
		},
		{
			"role": str(SUPPORT_RETURN_LANE),
			"intent": INTENT_RECEIVE,
			"position": return_upper,
			"score_bias": return_bias,
			"reason": "large_team_upper_midfield_triangle"
		},
		{
			"role": str(SUPPORT_RETURN_LANE),
			"intent": INTENT_RECEIVE,
			"position": return_lower,
			"score_bias": return_bias - 8.0,
			"reason": "large_team_lower_midfield_triangle"
		},
		{
			"role": str(SUPPORT_WIDTH),
			"intent": INTENT_WIDE_SUPPORT,
			"position": width_upper,
			"score_bias": width_bias,
			"reason": "large_team_stretch_upper_wing"
		},
		{
			"role": str(SUPPORT_WIDTH),
			"intent": INTENT_WIDE_SUPPORT,
			"position": width_lower,
			"score_bias": width_bias - 6.0,
			"reason": "large_team_stretch_lower_wing"
		},
		{
			"role": str(SUPPORT_RUN_BEHIND),
			"intent": INTENT_FORWARD_RUN,
			"position": run_upper,
			"score_bias": run_bias,
			"reason": "large_team_attack_upper_channel"
		},
		{
			"role": str(SUPPORT_RUN_BEHIND),
			"intent": INTENT_FORWARD_RUN,
			"position": run_lower,
			"score_bias": run_bias - 6.0,
			"reason": "large_team_attack_lower_channel"
		},
		{
			"role": str(SUPPORT_DECOY),
			"intent": INTENT_FORWARD_RUN,
			"position": decoy_target,
			"score_bias": 145.0,
			"reason": "large_team_drag_marker_from_main_lane"
		},
		{
			"role": str(SUPPORT_FAR_POST),
			"intent": INTENT_FORWARD_RUN,
			"position": far_post_target,
			"score_bias": far_post_bias,
			"reason": "large_team_occupy_far_post"
		},
		{
			"role": str(SUPPORT_REBOUND),
			"intent": INTENT_RECEIVE,
			"position": rebound_target,
			"score_bias": rebound_bias,
			"reason": "large_team_second_ball_runner"
		}
	]


func _build_support_targets(
	carrier: Node,
	support_count: int
) -> Array[Dictionary]:
	var active_team_count := int(_controller.call("_get_active_team_player_count"))
	if (
		active_team_count >= 4
		and _controller.has_method("is_large_team_football_shape_active")
		and bool(_controller.call("is_large_team_football_shape_active"))
	):
		return _build_large_team_support_targets(
			carrier,
			support_count,
			active_team_count
		)
	var origin: Vector2 = carrier.get("global_position")
	var velocity: Vector2 = carrier.get("linear_velocity")
	var attack_sign := float(_controller.call("_get_attack_sign"))
	var projected := origin + velocity * 0.16
	var center_y := (
		float(_controller.get("minimum_field_y"))
		+ float(_controller.get("maximum_field_y"))
	) * 0.5
	var ball: Node = _controller.get("ball")
	var ball_position: Vector2 = ball.get("global_position")
	var opponent_goal: Node = _controller.call("_get_opponent_goal")
	var goal_center := (
		_controller.call("_get_goal_center", opponent_goal) as Vector2
		if opponent_goal != null
		else projected + Vector2(attack_sign * 3200.0, 0.0)
	)
	var goal_distance := ball_position.distance_to(goal_center)
	var pressure := _nearest_active_distance(
		_controller.call("_get_opponents") as Array,
		ball_position
	)
	var under_pressure := (
		pressure <= float(_controller.get("pass_pressure_radius"))
	)
	var carrier_intention := (
		_controller.call("_get_effective_player_intention", carrier)
		as Dictionary
	)
	var carrier_action := StringName(carrier_intention.get("action", &""))
	var shooting_phase := (
		bool(carrier.get("server_is_charging"))
		or carrier_action == &"shoot"
		or goal_distance
		<= float(_controller.get("off_ball_shooting_phase_goal_distance"))
	)

	var return_upper := _clamp(Vector2(
		projected.x
		- attack_sign * float(_controller.get("off_ball_return_lane_depth")),
		projected.y
		- float(_controller.get("off_ball_return_lane_width"))
	))
	var return_lower := _clamp(Vector2(
		projected.x
		- attack_sign * float(_controller.get("off_ball_return_lane_depth")),
		projected.y
		+ float(_controller.get("off_ball_return_lane_width"))
	))
	var return_target := _pick_more_useful_support_target(
		origin,
		return_upper,
		return_lower,
		true
	)

	var upper_width := _clamp(Vector2(
		projected.x
		+ attack_sign * float(_controller.get("off_ball_width_forward_distance")),
		float(_controller.get("minimum_field_y"))
		+ float(_controller.get("off_ball_width_wall_margin"))
	))
	var lower_width := _clamp(Vector2(
		projected.x
		+ attack_sign * float(_controller.get("off_ball_width_forward_distance")),
		float(_controller.get("maximum_field_y"))
		- float(_controller.get("off_ball_width_wall_margin"))
	))
	var width_target := _pick_more_useful_support_target(
		origin,
		upper_width,
		lower_width,
		false
	)

	var last_defender_x := _get_last_defender_line_x(opponent_goal)
	var run_x := last_defender_x + (
		attack_sign * float(_controller.get("off_ball_run_behind_distance"))
	)
	var run_goal_limit := goal_center.x - (
		attack_sign * float(_controller.get("off_ball_goal_line_buffer"))
	)
	if attack_sign > 0.0:
		run_x = minf(run_x, run_goal_limit)
	else:
		run_x = maxf(run_x, run_goal_limit)
	var run_upper := _clamp(Vector2(
		run_x,
		projected.y
		- float(_controller.get("off_ball_run_behind_lateral_distance"))
	))
	var run_lower := _clamp(Vector2(
		run_x,
		projected.y
		+ float(_controller.get("off_ball_run_behind_lateral_distance"))
	))
	var run_target := _pick_more_useful_support_target(
		origin,
		run_upper,
		run_lower,
		true
	)

	var carrier_side := signf(projected.y - center_y)
	if is_zero_approx(carrier_side):
		carrier_side = 1.0 if ball_position.y < center_y else -1.0
	var decoy_side := -signf(run_target.y - center_y)
	if is_zero_approx(decoy_side):
		decoy_side = -carrier_side
	var decoy_target := _clamp(Vector2(
		maxf(projected.x * attack_sign, last_defender_x * attack_sign)
		* attack_sign
		- attack_sign * float(_controller.get("off_ball_decoy_line_offset")),
		center_y
		+ decoy_side * float(_controller.get("off_ball_decoy_lateral_distance"))
	))

	var cover_target := _clamp(Vector2(
		projected.x
		- attack_sign * float(_controller.get("off_ball_cover_distance")),
		lerpf(
			projected.y,
			center_y,
			float(_controller.get("off_ball_cover_center_blend"))
		)
	))

	var mouth_range := _get_goal_mouth_range(opponent_goal, goal_center.y)
	var far_post_y := (
		mouth_range.y
		- float(_controller.get("off_ball_far_post_mouth_padding"))
		if projected.y < goal_center.y
		else mouth_range.x
		+ float(_controller.get("off_ball_far_post_mouth_padding"))
	)
	var far_post_target := _clamp(Vector2(
		goal_center.x
		- attack_sign * float(_controller.get("off_ball_far_post_depth")),
		far_post_y
	))

	var declared_attack_target: Vector2 = carrier_intention.get(
		"target_position",
		goal_center
	)
	var shot_side := signf(
		declared_attack_target.y - goal_center.y
	)
	if is_zero_approx(shot_side):
		shot_side = carrier_side
	var rebound_target := _clamp(Vector2(
		goal_center.x
		- attack_sign * float(_controller.get("off_ball_rebound_goal_distance")),
		goal_center.y
		- shot_side * float(_controller.get("off_ball_rebound_side_offset"))
	))
	if goal_distance > float(_controller.get("off_ball_shooting_phase_goal_distance")) * 1.35:
		rebound_target = _clamp(Vector2(
			projected.x
			+ attack_sign * float(_controller.get("off_ball_rebound_advance_distance")),
			projected.y
			- carrier_side * float(_controller.get("off_ball_rebound_side_offset"))
		))

	var run_bias := 255.0
	var return_bias := 210.0
	var width_bias := 190.0
	var decoy_bias := 105.0
	var cover_bias := 225.0
	var far_post_bias := 95.0
	var rebound_bias := 110.0
	if under_pressure:
		return_bias += 210.0
		width_bias += 95.0
		cover_bias += 80.0
		run_bias -= 65.0
	if shooting_phase:
		far_post_bias += 315.0
		rebound_bias += 335.0
		cover_bias += 45.0
		return_bias -= 60.0
	if support_count == 1:
		cover_bias -= 55.0
		if shooting_phase:
			far_post_bias += 90.0
			rebound_bias += 70.0
		elif under_pressure:
			return_bias += 95.0
		else:
			run_bias += 75.0
	if support_count >= 3:
		cover_bias += 100.0
		decoy_bias += 80.0

	return [
		{
			"role": str(SUPPORT_RUN_BEHIND),
			"intent": INTENT_FORWARD_RUN,
			"position": run_target,
			"score_bias": run_bias,
			"reason": "attack_space_behind_last_defender"
		},
		{
			"role": str(SUPPORT_RETURN_LANE),
			"intent": INTENT_RECEIVE,
			"position": return_target,
			"score_bias": return_bias,
			"reason": "form_safe_return_pass_triangle"
		},
		{
			"role": str(SUPPORT_WIDTH),
			"intent": INTENT_WIDE_SUPPORT,
			"position": width_target,
			"score_bias": width_bias,
			"reason": "stretch_defensive_shape_to_the_touchline"
		},
		{
			"role": str(SUPPORT_DECOY),
			"intent": INTENT_FORWARD_RUN,
			"position": decoy_target,
			"score_bias": decoy_bias,
			"reason": "drag_marker_away_from_primary_attack_lane"
		},
		{
			"role": str(SUPPORT_COVER),
			"intent": INTENT_COVER,
			"position": cover_target,
			"score_bias": cover_bias,
			"reason": "protect_counter_and_offer_recycle_pass"
		},
		{
			"role": str(SUPPORT_FAR_POST),
			"intent": INTENT_FORWARD_RUN,
			"position": far_post_target,
			"score_bias": far_post_bias,
			"reason": "occupy_far_post_for_cross_or_goal_deflection"
		},
		{
			"role": str(SUPPORT_REBOUND),
			"intent": INTENT_RECEIVE,
			"position": rebound_target,
			"score_bias": rebound_bias,
			"reason": "collect_blocked_shot_or_goalkeeper_rebound"
		}
	]


func _pick_more_useful_support_target(
	origin: Vector2,
	first: Vector2,
	second: Vector2,
	value_clear_lane: bool
) -> Vector2:
	var first_score := float(_controller.call(
		"_nearest_opponent_distance",
		first
	))
	var second_score := float(_controller.call(
		"_nearest_opponent_distance",
		second
	))
	if value_clear_lane:
		first_score += float(_controller.call(
			"_minimum_segment_clearance",
			origin,
			first
		)) * 0.45
		second_score += float(_controller.call(
			"_minimum_segment_clearance",
			origin,
			second
		)) * 0.45
	return first if first_score >= second_score else second


func _get_goal_mouth_range(
	goal: Node,
	fallback_center_y: float
) -> Vector2:
	if goal != null and goal.has_method("get_mouth_y_range"):
		return goal.call("get_mouth_y_range") as Vector2
	return Vector2(fallback_center_y - 520.0, fallback_center_y + 520.0)


func _get_last_defender_line_x(goal: Node) -> float:
	var attack_sign := float(_controller.call("_get_attack_sign"))
	var goal_center := (
		_controller.call("_get_goal_center", goal) as Vector2
		if goal != null
		else Vector2(
			float(_controller.get("maximum_field_x"))
			if attack_sign > 0.0
			else float(_controller.get("minimum_field_x")),
			0.0
		)
	)
	var goalkeeper_exclusion := float(
		_controller.get("off_ball_goalkeeper_exclusion_distance")
	)
	var best_progress := -INF
	var fallback_progress := -INF
	for opponent_variant in _controller.call("_get_opponents") as Array:
		var opponent := opponent_variant as Node
		if not _valid_actor(opponent):
			continue
		var position: Vector2 = opponent.get("global_position")
		var progress := position.x * attack_sign
		fallback_progress = maxf(fallback_progress, progress)
		if position.distance_to(goal_center) <= goalkeeper_exclusion:
			continue
		best_progress = maxf(best_progress, progress)
	if is_inf(best_progress):
		best_progress = fallback_progress
	if is_inf(best_progress):
		best_progress = (
			goal_center.x
			- attack_sign
			* float(_controller.get("off_ball_default_defender_line_depth"))
		) * attack_sign
	return best_progress * attack_sign


func _largest_lateral_defensive_gap() -> Dictionary:
	var minimum_y := float(_controller.get("minimum_field_y")) + 250.0
	var maximum_y := float(_controller.get("maximum_field_y")) - 250.0
	var points: Array[float] = [minimum_y, maximum_y]
	for opponent_variant in _controller.call("_get_opponents") as Array:
		var opponent := opponent_variant as Node
		if not _valid_actor(opponent):
			continue
		points.append(clampf(
			(opponent.get("global_position") as Vector2).y,
			minimum_y,
			maximum_y
		))
	points.sort()
	var best_width := 0.0
	var best_center := (minimum_y + maximum_y) * 0.5
	for index in range(1, points.size()):
		var width := points[index] - points[index - 1]
		if width > best_width:
			best_width = width
			best_center = (points[index] + points[index - 1]) * 0.5
	return {
		"width": best_width,
		"center_y": best_center
	}


func _support_fit_score(
	player: Node,
	target_data: Dictionary,
	carrier: Node
) -> float:
	var target: Vector2 = target_data.get("position", Vector2.ZERO)
	var role := StringName(target_data.get("role", &""))
	var position: Vector2 = player.get("global_position")
	var carrier_position: Vector2 = carrier.get("global_position")
	var attack_sign := float(_controller.call("_get_attack_sign"))
	var clearance := float(_controller.call(
		"_minimum_segment_clearance",
		carrier_position,
		target
	))
	var openness := float(_controller.call("_nearest_opponent_distance", target))
	var spacing := _nearest_other_support_distance(player, target)
	var progress := (target.x - carrier_position.x) * attack_sign
	var lateral_distance := absf(target.y - carrier_position.y)
	var travel_distance := position.distance_to(target)
	var rotation_active := (
		_controller.has_method("_two_vs_two_attacking_rotation_active")
		and bool(
			_controller.call("_two_vs_two_attacking_rotation_active")
		)
	)
	var designated_goalkeeper := bool(
		_controller.call("_is_designated_goalkeeper", player)
	)
	var score := (
		float(target_data.get("score_bias", 0.0))
		+ minf(clearance, 1400.0) * 0.30
		+ minf(openness, 1650.0) * 0.38
		+ minf(spacing, 1450.0) * 0.17
		- travel_distance * 0.13
	)
	match role:
		SUPPORT_RUN_BEHIND:
			score += maxf(0.0, progress) * 0.31
			if rotation_active and _player_has_defensive_role(player):
				score += 300.0
		SUPPORT_RETURN_LANE:
			score += minf(clearance, 1200.0) * 0.17
			score += maxf(0.0, -progress) * 0.08
			if travel_distance <= 950.0:
				score += 95.0
		SUPPORT_WIDTH:
			score += lateral_distance * 0.14
			if openness >= 700.0:
				score += 110.0
		SUPPORT_DECOY:
			var marker_distance := float(_controller.call(
				"_nearest_opponent_distance",
				target
			))
			var desired_marker_distance := float(
				_controller.get("off_ball_decoy_desired_marker_distance")
			)
			score += maxf(
				0.0,
				220.0 - absf(marker_distance - desired_marker_distance) * 0.32
			)
			score += maxf(0.0, progress) * 0.13
		SUPPORT_COVER:
			score += maxf(0.0, -progress) * 0.23
			if _player_has_defensive_role(player):
				score += -70.0 if rotation_active else 285.0
		SUPPORT_FAR_POST:
			score += maxf(0.0, progress) * 0.20
			score += minf(openness, 1200.0) * 0.12
			if _player_has_defensive_role(player):
				score -= 125.0
		SUPPORT_REBOUND:
			score += minf(openness, 1200.0) * 0.15
			score += minf(clearance, 900.0) * 0.10
			if _player_has_defensive_role(player):
				score += 45.0
	if _controller.has_method("_get_tactical_role"):
		var tactical_role := StringName(_controller.call("_get_tactical_role", player))
		match tactical_role:
			&"striker":
				match role:
					SUPPORT_RUN_BEHIND, SUPPORT_FAR_POST, SUPPORT_REBOUND:
						score += 430.0
					SUPPORT_COVER:
						score -= 360.0
			&"playmaker":
				match role:
					SUPPORT_RETURN_LANE:
						score += 410.0
					SUPPORT_WIDTH:
						score += 290.0
					SUPPORT_RUN_BEHIND:
						score -= 85.0
			&"defender":
				match role:
					SUPPORT_COVER:
						score += 520.0
					SUPPORT_RETURN_LANE:
						score += 155.0
					SUPPORT_RUN_BEHIND, SUPPORT_FAR_POST, SUPPORT_REBOUND, SUPPORT_DECOY:
						score -= 420.0

	if (
		_controller.has_method("is_large_team_football_shape_active")
		and bool(_controller.call("is_large_team_football_shape_active"))
		and _controller.has_method("get_large_team_football_role")
	):
		var football_role := StringName(
			_controller.call("get_large_team_football_role", player)
		)
		match football_role:
			&"defender":
				match role:
					SUPPORT_COVER:
						score += 720.0
					SUPPORT_RETURN_LANE:
						score += 330.0
					SUPPORT_WIDTH:
						score -= 180.0
					SUPPORT_RUN_BEHIND, SUPPORT_FAR_POST, SUPPORT_REBOUND, SUPPORT_DECOY:
						score -= 680.0
			&"midfielder":
				match role:
					SUPPORT_RETURN_LANE:
						score += 610.0
					SUPPORT_COVER:
						score += 330.0
					SUPPORT_WIDTH:
						score += 190.0
					SUPPORT_RUN_BEHIND:
						score += 65.0
			&"winger":
				match role:
					SUPPORT_WIDTH:
						score += 760.0
					SUPPORT_RUN_BEHIND:
						score += 470.0
					SUPPORT_FAR_POST:
						score += 260.0
					SUPPORT_COVER:
						score -= 480.0
			&"striker":
				match role:
					SUPPORT_RUN_BEHIND:
						score += 800.0
					SUPPORT_FAR_POST:
						score += 620.0
					SUPPORT_REBOUND:
						score += 430.0
					SUPPORT_COVER:
						score -= 700.0
					SUPPORT_RETURN_LANE:
						score -= 170.0

		# Existing spacing used nearest current teammate. In large teams enforce a
		# much harder minimum so a nominal support action cannot recreate the same
		# dog-pile a few hundred pixels away from the carrier.
		var minimum_spacing := maxf(
			620.0,
			float(_controller.get("large_team_minimum_support_spacing"))
		)
		if spacing < minimum_spacing:
			score -= (minimum_spacing - spacing) * 0.92
		var carrier_spacing := target.distance_to(carrier_position)
		if carrier_spacing < minimum_spacing:
			score -= (minimum_spacing - carrier_spacing) * 1.15

	if designated_goalkeeper:
		match role:
			SUPPORT_COVER:
				score += 520.0
			SUPPORT_RETURN_LANE:
				score += 340.0
			SUPPORT_WIDTH:
				score -= 240.0
			SUPPORT_RUN_BEHIND, SUPPORT_DECOY, SUPPORT_FAR_POST, SUPPORT_REBOUND:
				score -= 1450.0
	if _controller.has_method("_get_support_role_ability_bonus"):
		score += float(_controller.call(
			"_get_support_role_ability_bonus",
			player,
			target,
			carrier
		))
	return score


func _best_unused_support_target(
	player: Node,
	targets: Array[Dictionary],
	used_indices: Dictionary,
	carrier: Node
) -> Dictionary:
	var best_index := -1
	var best_score := -INF
	for index in range(targets.size()):
		if used_indices.has(index):
			continue
		var score := _support_fit_score(player, targets[index], carrier)
		if score > best_score:
			best_score = score
			best_index = index
	return (
		{"index": best_index, "target_data": targets[best_index]}
		if best_index >= 0
		else {}
	)


func _nearest_other_support_distance(player: Node, target: Vector2) -> float:
	var nearest := INF
	for teammate_variant in _controller.call("_get_teammates") as Array:
		var teammate := teammate_variant as Node
		if not _valid_actor(teammate) or teammate == player:
			continue
		nearest = minf(nearest, (teammate.get("global_position") as Vector2).distance_to(target))
	return nearest if not is_inf(nearest) else 1600.0


func _player_has_defensive_role(player: Node) -> bool:
	if player == null or not is_instance_valid(player):
		return false
	if _controller.has_method("_is_outfield_defender"):
		return bool(_controller.call("_is_outfield_defender", player))
	return false


func _basic_lead_target(receiver: Node) -> Vector2:
	var attack_sign := float(_controller.call("_get_attack_sign"))
	var forward_lead := (
		float(_controller.get("cpu_receiver_forward_lead"))
		if bool(receiver.get("cpu_controlled"))
		else 0.0
	)
	var target := (
		receiver.get("global_position") as Vector2
		+ (receiver.get("linear_velocity") as Vector2)
		* maxf(0.0, float(_controller.get("pass_lead_seconds")))
		+ Vector2(attack_sign * forward_lead, 0.0)
	)
	return _clamp(target)


func _valid_receiver(receiver: Node, player: Node) -> bool:
	return (
		_valid_actor(receiver)
		and receiver != player
		and not bool(_controller.call("_is_designated_goalkeeper", receiver))
	)


func _valid_actor(actor: Node) -> bool:
	return (
		actor != null
		and is_instance_valid(actor)
		and bool(actor.get("controls_enabled"))
	)


func _nearest_active_distance(players: Array, position: Vector2) -> float:
	var nearest := INF
	for player_variant in players:
		var player := player_variant as Node
		if not _valid_actor(player):
			continue
		nearest = minf(nearest, (player.get("global_position") as Vector2).distance_to(position))
	return nearest


func _pass_reason(
	kind: StringName,
	defensive_shape: Dictionary,
	under_pressure: bool
) -> String:
	if under_pressure and kind in [PASS_PRESSURE_ESCAPE, PASS_LAYOFF, PASS_WALL_BANK]:
		return "escape_pressure_without_turnover"
	if kind == PASS_WIDE_SWITCH and bool(defensive_shape.get("far_side_open", false)):
		return "attack_far_side_after_defense_shift"
	if kind in [
		PASS_THROUGH,
		PASS_DIAGONAL_SPLIT,
		PASS_BLINDSIDE,
		PASS_THIRD_MAN
	] and bool(defensive_shape.get("central_gap_open", false)):
		return "exploit_gap_between_defenders"
	if kind == PASS_BLINDSIDE:
		return "release_receiver_behind_the_markers_blind_side"
	if kind == PASS_SQUARE:
		return "move_defense_sideways_before_next_attack"
	if kind == PASS_RECYCLE:
		return "recycle_through_goalkeeper_and_reset_the_press"
	if kind == PASS_CUTBACK:
		return "pull_defense_toward_goal_line_then_cut_back"
	if kind == PASS_ONE_TWO:
		return "wall_pass_and_run_beyond_marker"
	if kind == PASS_THIRD_MAN:
		return "move_ball_through_receiver_to_unmarked_third_player"
	if kind == PASS_WALL_BANK:
		return "use_wall_to_bypass_blocked_direct_lane"
	return "best_safe_progressive_team_option"


func _clamp(position: Vector2) -> Vector2:
	return _controller.call("_clamp_to_field", position) as Vector2


func _now() -> float:
	return float(_controller.call("_server_time_seconds")) if _controller != null else 0.0


func _is_ready() -> bool:
	return (
		_controller != null
		and is_instance_valid(_controller)
		and _controller.get("controlled_player") != null
		and _controller.get("ball") != null
	)
