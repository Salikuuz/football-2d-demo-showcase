class_name HybridObservationBuilder
extends RefCounted


const Schema := preload("res://ai/hybrid/tactical_schema.gd")
const BallPredictor := preload("res://ai/hybrid/ball_trajectory_predictor.gd")
const AbilityThreatModel = preload("res://ai/ability/ability_threat_model.gd")

# Runtime-only per-physics-frame cache. 4v4 can ask eight brains to evaluate
# the same ball trajectory / team ability state in one frame. Those values are
# identical for every relevant controller, so rebuilding them per CPU wastes a
# large amount of CPU time and can create frame spikes on weaker machines.
# Training/gameplay semantics stay identical because the cache is cleared on
# every physics frame.
static var _shared_cache_physics_frame: int = -1
static var _shared_trajectory_cache: Dictionary = {}
static var _shared_sorted_ball_race_cache: Dictionary = {}
static var _shared_ability_state_cache: Dictionary = {}


static func _prepare_shared_runtime_cache() -> void:
	var physics_frame: int = Engine.get_physics_frames()
	if physics_frame == _shared_cache_physics_frame:
		return
	_shared_cache_physics_frame = physics_frame
	_shared_trajectory_cache.clear()
	_shared_sorted_ball_race_cache.clear()
	_shared_ability_state_cache.clear()


static func _shared_ball_trajectory(
	ball: Node,
	ball_position: Vector2,
	ball_velocity: Vector2,
	bounds: Rect2,
	seconds: float,
	step_seconds: float,
	linear_damp: float,
	bounce: float
) -> PackedVector2Array:
	_prepare_shared_runtime_cache()
	var ball_id: int = ball.get_instance_id() if ball != null else 0
	var key: String = "%d|%.4f|%.4f|%.4f" % [
		ball_id,
		seconds,
		step_seconds,
		bounce
	]
	if _shared_trajectory_cache.has(key):
		return _shared_trajectory_cache[key] as PackedVector2Array
	var trajectory: PackedVector2Array = BallPredictor.predict(
		ball_position,
		ball_velocity,
		bounds,
		seconds,
		step_seconds,
		linear_damp,
		bounce
	)
	_shared_trajectory_cache[key] = trajectory
	return trajectory


static func _shared_sorted_players_by_ball_race(
	manager: Node,
	team_key: StringName,
	players: Array,
	ball_position: Vector2
) -> Array:
	_prepare_shared_runtime_cache()
	var manager_id: int = manager.get_instance_id() if manager != null else 0
	var key: String = "%d|%s" % [manager_id, str(team_key)]
	if _shared_sorted_ball_race_cache.has(key):
		return _shared_sorted_ball_race_cache[key] as Array
	var sorted_players: Array = _sort_players_by_ball_race(players, ball_position)
	_shared_sorted_ball_race_cache[key] = sorted_players
	return sorted_players


static func _shared_team_ability_state(
	manager: Node,
	cache_key: String,
	players: Array,
	ball_position: Vector2,
	goal_position: Vector2,
	field_width: float,
	server_now: float,
	ball_velocity: Vector2
) -> Dictionary:
	_prepare_shared_runtime_cache()
	var manager_id: int = manager.get_instance_id() if manager != null else 0
	var key: String = "%d|%s" % [manager_id, cache_key]
	if _shared_ability_state_cache.has(key):
		return _shared_ability_state_cache[key] as Dictionary
	var result: Dictionary = AbilityThreatModel.analyze_team(
		players,
		ball_position,
		goal_position,
		field_width,
		server_now,
		ball_velocity
	) as Dictionary
	_shared_ability_state_cache[key] = result
	return result


## Builds only the live state used by commitment validation and the two
## emergency overrides.  A complete observation also creates normalized
## entity slots, ability-threat summaries, pass previews and team-sequence
## data; none of those values are read while an existing decision is merely
## being validated between policy refreshes.
static func build_safety(
	controller: Node,
	include_elite_finish_preview: bool = true
) -> Dictionary:
	if controller == null:
		return {}
	var player: Node = controller.get("controlled_player")
	var manager: Node = controller.get("match_manager")
	var ball: Node = controller.get("ball")
	if player == null or manager == null or ball == null:
		return {}
	var minimum_x: float = float(controller.get("minimum_field_x"))
	var maximum_x: float = float(controller.get("maximum_field_x"))
	var minimum_y: float = float(controller.get("minimum_field_y"))
	var maximum_y: float = float(controller.get("maximum_field_y"))
	var field_width: float = maxf(1.0, maximum_x - minimum_x)
	var field_height: float = maxf(1.0, maximum_y - minimum_y)
	var teammates: Array = controller.call("_get_teammates") as Array
	var opponents: Array = controller.call("_get_opponents") as Array
	var own_goal: Node = controller.call("_get_own_goal")
	var opponent_goal: Node = controller.call("_get_opponent_goal")
	var own_goal_position: Vector2 = _goal_center(controller, own_goal)
	var opponent_goal_position: Vector2 = _goal_center(
		controller,
		opponent_goal
	)
	var player_position: Vector2 = player.get("global_position")
	var player_velocity: Vector2 = player.get("linear_velocity")
	var ball_position: Vector2 = ball.get("global_position")
	var ball_velocity: Vector2 = ball.get("linear_velocity")
	var player_has_kickable_ball: bool = bool(
		player.call("cpu_has_kickable_ball")
	)
	var teammate_has_physical_control := false
	for teammate_variant in teammates:
		var teammate := teammate_variant as Node
		if (
			teammate == null
			or not is_instance_valid(teammate)
			or teammate == player
			or not bool(teammate.get("controls_enabled"))
		):
			continue
		if (
			teammate.has_method("cpu_has_kickable_ball")
			and bool(teammate.call("cpu_has_kickable_ball"))
		):
			teammate_has_physical_control = true
			break
	var opponent_has_physical_control := false
	for opponent_variant in opponents:
		var opponent := opponent_variant as Node
		if (
			opponent == null
			or not is_instance_valid(opponent)
			or not bool(opponent.get("controls_enabled"))
		):
			continue
		if bool(controller.call("_opponent_controls_ball", opponent)):
			opponent_has_physical_control = true
			break
	var possession := "loose"
	if player_has_kickable_ball:
		possession = "self"
	elif teammate_has_physical_control:
		possession = "team"
	elif opponent_has_physical_control:
		possession = "opponent"

	var sorted_teammates: Array = _stable_players(
		teammates,
		int(player.get("owner_peer_id"))
	)
	var sorted_opponents: Array = _shared_sorted_players_by_ball_race(
		manager,
		StringName(player.get("team")),
		_stable_players(opponents, -1),
		ball_position
	)
	var own_goal_danger: bool = bool(
		controller.call("_ball_is_in_own_goal_danger")
	)
	var prediction_step: float = 1.0 / 30.0
	var self_ball_arrival_seconds: float = 3.0
	# A moving-ball trajectory is only meaningful while the ball is actually
	# loose. While somebody physically controls it, the next trajectory is set
	# by that player's input, so simulating 38 bounce/damping steps per CPU is
	# both expensive and less representative than a direct arrival estimate.
	if possession == "loose":
		var trajectory: PackedVector2Array = _shared_ball_trajectory(
			ball,
			ball_position,
			ball_velocity,
			Rect2(minimum_x, minimum_y, field_width, field_height),
			1.25,
			prediction_step,
			float(ball.get("linear_damp")),
			0.8
		)
		var intercept: Dictionary = BallPredictor.earliest_intercept(
			player_position,
			player_velocity,
			float(player.get("max_speed")),
			float(player.get("acceleration")),
			trajectory,
			prediction_step
		)
		self_ball_arrival_seconds = (
			float(intercept.get("ball_time", 3.0))
			if bool(intercept.get("available", false))
			else 3.0
		)
	elif possession == "self":
		self_ball_arrival_seconds = 0.0
	else:
		self_ball_arrival_seconds = _estimate_player_ball_arrival(
			player,
			ball_position
		)
	var nearest_opponent: Node = (
		sorted_opponents[0] as Node
		if not sorted_opponents.is_empty()
		else null
	)
	var nearest_opponent_ball_arrival_seconds := 3.0
	var opponent_kick_ready := false
	if nearest_opponent != null:
		nearest_opponent_ball_arrival_seconds = _estimate_player_ball_arrival(
			nearest_opponent,
			ball_position
		)
		opponent_kick_ready = (
			nearest_opponent.has_method("cpu_has_kickable_ball")
			and bool(nearest_opponent.call("cpu_has_kickable_ball"))
		)
	var ball_race_advantage_seconds: float = (
		nearest_opponent_ball_arrival_seconds
		- self_ball_arrival_seconds
	)
	var opponent_first_touch: bool = (
		opponent_kick_ready
		or ball_race_advantage_seconds < -0.10
	)
	var goal_cover_available: bool = _has_goal_cover_teammate(
		sorted_teammates,
		ball_position,
		own_goal_position
	)
	var opponent_shot_threat: float = _calculate_opponent_shot_threat(
		nearest_opponent,
		ball_position,
		ball_velocity,
		own_goal_position,
		field_width,
		possession,
		own_goal_danger,
		nearest_opponent_ball_arrival_seconds,
		opponent_has_physical_control
	)
	var self_clearly_first_to_loose_ball: bool = (
		possession == "loose"
		and not opponent_has_physical_control
		and ball_race_advantage_seconds >= 0.14
	)
	var player_goal_distance: float = player_position.distance_to(
		own_goal_position
	)
	var opponent_goal_distance: float = (
		(nearest_opponent.get("global_position") as Vector2).distance_to(
			own_goal_position
		)
		if nearest_opponent != null
		else player_goal_distance
	)
	var breakaway_goal_side_margin: float = maxf(
		player_goal_distance
		- ball_position.distance_to(own_goal_position),
		player_goal_distance - opponent_goal_distance
	)
	var attacker_behind_defender: bool = (
		not goal_cover_available
		and (opponent_has_physical_control or opponent_first_touch)
		and breakaway_goal_side_margin >= 120.0
	)
	var breakaway_recovery_urgency: float = clampf(
		(breakaway_goal_side_margin - 80.0) / 1200.0
		+ opponent_shot_threat * 0.55,
		0.0,
		1.0
	)
	var open_net_risk := 0.0
	if not goal_cover_available:
		if opponent_has_physical_control or opponent_first_touch:
			open_net_risk += clampf(
				self_ball_arrival_seconds
				- nearest_opponent_ball_arrival_seconds,
				0.0,
				0.65
			) / 0.65
			open_net_risk += opponent_shot_threat * 0.75
			if opponent_first_touch:
				open_net_risk += 0.35
		if own_goal_danger and not self_clearly_first_to_loose_ball:
			open_net_risk += 0.35
	if self_clearly_first_to_loose_ball:
		open_net_risk *= 0.12
	if attacker_behind_defender:
		open_net_risk = maxf(
			open_net_risk,
			0.72 + breakaway_recovery_urgency * 0.28
		)
	open_net_risk = clampf(open_net_risk, 0.0, 1.0)

	var elite_goal_probability := 0.0
	if (
		include_elite_finish_preview
		and possession == "self"
		and opponent_goal != null
		and controller.has_method("_get_elite_finish_preview")
	):
		var elite_finish: Dictionary = controller.call(
			"_get_elite_finish_preview",
			opponent_goal
		) as Dictionary
		elite_goal_probability = clampf(
			float(elite_finish.get("goal_probability", 0.0)),
			0.0,
			1.0
		)
	return {
		"possession": possession,
		"goal_distance": clampf(
			ball_position.distance_to(opponent_goal_position) / field_width,
			0.0,
			1.5
		),
		"own_goal_distance": clampf(
			ball_position.distance_to(own_goal_position) / field_width,
			0.0,
			1.5
		),
		"self_ball_arrival_seconds": self_ball_arrival_seconds,
		"nearest_opponent_ball_arrival_seconds": nearest_opponent_ball_arrival_seconds,
		"opponent_first_touch": opponent_first_touch,
		"self_clearly_first_to_loose_ball": self_clearly_first_to_loose_ball,
		"opponent_has_physical_control": opponent_has_physical_control,
		"attacker_behind_defender": attacker_behind_defender,
		"breakaway_goal_side_margin": breakaway_goal_side_margin,
		"breakaway_recovery_urgency": breakaway_recovery_urgency,
		"opponent_shot_threat": opponent_shot_threat,
		"goal_cover_available": goal_cover_available,
		"open_net_risk": open_net_risk,
		"own_goal_danger": own_goal_danger,
		"elite_goal_probability": elite_goal_probability,
	}


static func build(controller: Node) -> Dictionary:
	if controller == null:
		return {}
	var player: Node = controller.get("controlled_player")
	var manager: Node = controller.get("match_manager")
	var ball: Node = controller.get("ball")
	if player == null or manager == null or ball == null:
		return {}
	var minimum_x := float(controller.get("minimum_field_x"))
	var maximum_x := float(controller.get("maximum_field_x"))
	var minimum_y := float(controller.get("minimum_field_y"))
	var maximum_y := float(controller.get("maximum_field_y"))
	var field_width := maxf(1.0, maximum_x - minimum_x)
	var field_height := maxf(1.0, maximum_y - minimum_y)
	var attack_sign := float(controller.call("_get_attack_sign"))
	var team: StringName = StringName(player.get("team"))
	var teammates: Array = controller.call("_get_teammates") as Array
	var opponents: Array = controller.call("_get_opponents") as Array
	var own_goal: Node = controller.call("_get_own_goal")
	var opponent_goal: Node = controller.call("_get_opponent_goal")
	var own_goal_position := _goal_center(controller, own_goal)
	var opponent_goal_position := _goal_center(controller, opponent_goal)
	var player_position: Vector2 = player.get("global_position")
	var player_velocity: Vector2 = player.get("linear_velocity")
	var ball_position: Vector2 = ball.get("global_position")
	var ball_velocity: Vector2 = ball.get("linear_velocity")
	var possession_team: StringName = StringName(manager.call("get_cpu_possession_team"))
	var possession := "loose"
	var player_has_kickable_ball := bool(player.call("cpu_has_kickable_ball"))
	var active_other_teammates := 0
	var teammate_has_physical_control := false
	for teammate_variant in teammates:
		var teammate := teammate_variant as Node
		if (
			teammate == null
			or not is_instance_valid(teammate)
			or teammate == player
			or not bool(teammate.get("controls_enabled"))
		):
			continue
		active_other_teammates += 1
		if (
			teammate.has_method("cpu_has_kickable_ball")
			and bool(teammate.call("cpu_has_kickable_ball"))
		):
			teammate_has_physical_control = true

	var opponent_has_physical_control := false
	for opponent_variant in opponents:
		var opponent := opponent_variant as Node
		if (
			opponent == null
			or not is_instance_valid(opponent)
			or not bool(opponent.get("controls_enabled"))
		):
			continue
		if bool(controller.call("_opponent_controls_ball", opponent)):
			opponent_has_physical_control = true
			break

	# Last touch is historical information, not possession. A ball remains loose
	# when the previous toucher is far away. This prevents a defender from
	# marking that player while an unclaimed ball sits behind it.
	if player_has_kickable_ball:
		possession = "self"
	elif teammate_has_physical_control:
		possession = "team"
	elif opponent_has_physical_control:
		possession = "opponent"
	else:
		possession = "loose"
	var normalized_player := _normalize_position(
		player_position,
		attack_sign,
		minimum_x,
		maximum_x,
		minimum_y,
		maximum_y
	)
	var normalized_ball := _normalize_position(
		ball_position,
		attack_sign,
		minimum_x,
		maximum_x,
		minimum_y,
		maximum_y
	)
	var sorted_teammates := _stable_players(teammates, int(player.get("owner_peer_id")))
	var sorted_opponents := _shared_sorted_players_by_ball_race(
		manager,
		team,
		_stable_players(opponents, -1),
		ball_position
	)
	var teammate_slots := _build_entity_slots(
		sorted_teammates,
		Schema.MAX_TEAM_SIZE - 1,
		attack_sign,
		minimum_x,
		maximum_x,
		minimum_y,
		maximum_y,
		player_position,
		ball_position
	)
	var opponent_slots := _build_entity_slots(
		sorted_opponents,
		Schema.MAX_TEAM_SIZE,
		attack_sign,
		minimum_x,
		maximum_x,
		minimum_y,
		maximum_y,
		player_position,
		ball_position
	)
	var goal_distance := ball_position.distance_to(opponent_goal_position)
	var own_goal_distance := ball_position.distance_to(own_goal_position)
	var shot_lane := float(controller.call("_minimum_segment_clearance", ball_position, opponent_goal_position))
	var own_goal_danger := bool(controller.call("_ball_is_in_own_goal_danger"))
	var primary_chaser := bool(controller.call("_is_primary_ball_chaser"))
	var team_possession := possession == "self" or possession == "team"
	var local_duel: Node = controller.call("_get_relevant_duel_opponent")
	var nearest_opponent_distance := float(controller.call("_nearest_opponent_distance", ball_position))
	# A pass plan is only actionable for the player that physically owns the
	# ball. Building the full advanced pass search for the other 7 CPUs in a 4v4
	# was pure work and one of the largest avoidable observation costs.
	var best_pass: Dictionary = {"available": false}
	if possession == "self":
		best_pass = _best_pass_summary(controller, opponent_goal)
	var score_blue := int(manager.get("blue_score"))
	var score_red := int(manager.get("red_score"))
	var score_for := score_blue if team == &"blue" else score_red
	var score_against := score_red if team == &"blue" else score_blue
	var regulation_seconds := maxf(1.0, float(manager.get("regulation_seconds")))
	var remaining := maxf(0.0, float(manager.get("regulation_time_remaining")))
	var server_now := float(controller.call("_server_time_seconds"))
	var cooldown_remaining := maxf(
		0.0,
		float(player.get("server_ability_cooldown_ends_at")) - server_now
	)
	var opponent_ability_state: Dictionary = _shared_team_ability_state(
		manager,
		"%s|opponents" % str(team),
		sorted_opponents,
		ball_position,
		own_goal_position,
		field_width,
		server_now,
		ball_velocity
	)
	var own_team_players: Array = sorted_teammates.duplicate()
	own_team_players.append(player)
	var team_ability_state: Dictionary = _shared_team_ability_state(
		manager,
		"%s|own" % str(team),
		own_team_players,
		ball_position,
		opponent_goal_position,
		field_width,
		server_now,
		ball_velocity
	)
	var prediction_step := 1.0 / 30.0
	var trajectory := _shared_ball_trajectory(
		ball,
		ball_position,
		ball_velocity,
		Rect2(minimum_x, minimum_y, field_width, field_height),
		1.25,
		prediction_step,
		float(ball.get("linear_damp")),
		0.8
	)
	var intercept := BallPredictor.earliest_intercept(
		player_position,
		player_velocity,
		float(player.get("max_speed")),
		float(player.get("acceleration")),
		trajectory,
		prediction_step
	)
	var self_ball_arrival_seconds := (
		float(intercept.get("ball_time", 3.0))
		if bool(intercept.get("available", false))
		else 3.0
	)
	var nearest_opponent: Node = (
		sorted_opponents[0] as Node
		if not sorted_opponents.is_empty()
		else null
	)
	var nearest_opponent_ball_arrival_seconds := 3.0
	var opponent_kick_ready := false
	var opponent_charging := false
	if nearest_opponent != null:
		nearest_opponent_ball_arrival_seconds = _estimate_player_ball_arrival(
			nearest_opponent,
			ball_position
		)
		opponent_kick_ready = (
			nearest_opponent.has_method("cpu_has_kickable_ball")
			and bool(nearest_opponent.call("cpu_has_kickable_ball"))
		)
		opponent_charging = bool(nearest_opponent.get("server_is_charging"))
	var ball_race_advantage_seconds := (
		nearest_opponent_ball_arrival_seconds
		- self_ball_arrival_seconds
	)
	var opponent_first_touch := (
		opponent_kick_ready
		or ball_race_advantage_seconds < -0.10
	)
	var goal_cover_available := _has_goal_cover_teammate(
		sorted_teammates,
		ball_position,
		own_goal_position
	)
	var opponent_shot_threat := _calculate_opponent_shot_threat(
		nearest_opponent,
		ball_position,
		ball_velocity,
		own_goal_position,
		field_width,
		possession,
		own_goal_danger,
		nearest_opponent_ball_arrival_seconds,
		opponent_has_physical_control
	)
	var self_clearly_first_to_loose_ball := (
		possession == "loose"
		and not opponent_has_physical_control
		and ball_race_advantage_seconds >= 0.14
	)
	var player_goal_distance := player_position.distance_to(
		own_goal_position
	)
	var opponent_goal_distance := (
		(nearest_opponent.get("global_position") as Vector2).distance_to(
			own_goal_position
		)
		if nearest_opponent != null
		else player_goal_distance
	)
	var ball_goal_side_margin := (
		player_goal_distance
		- ball_position.distance_to(own_goal_position)
	)
	var opponent_goal_side_margin := (
		player_goal_distance
		- opponent_goal_distance
	)
	var breakaway_goal_side_margin := maxf(
		ball_goal_side_margin,
		opponent_goal_side_margin
	)
	var one_vs_one: bool = (
		sorted_teammates.is_empty()
		and sorted_opponents.size() == 1
	)
	var offensive_bypass_margin: float = 0.0
	var offensive_defender_beaten: bool = false
	if nearest_opponent != null:
		offensive_bypass_margin = (
			ball_position.x
			- (nearest_opponent.get("global_position") as Vector2).x
		) * attack_sign
		offensive_defender_beaten = (
			possession == "self"
			and offensive_bypass_margin >= 180.0
		)
	var shot_followup_ready: bool = true
	if (
		one_vs_one
		and controller.has_method(
			"_one_vs_one_shot_has_finish_or_followup"
		)
	):
		shot_followup_ready = bool(
			controller.call(
				"_one_vs_one_shot_has_finish_or_followup",
				opponent_goal_position
			)
		)

	var elite_finish: Dictionary = {}
	if (
		possession == "self"
		and opponent_goal != null
		and controller.has_method("_get_elite_finish_preview")
	):
		elite_finish = controller.call(
			"_get_elite_finish_preview",
			opponent_goal
		) as Dictionary
	var elite_goal_probability: float = clampf(
		float(elite_finish.get("goal_probability", 0.0)),
		0.0,
		1.0
	)

	var space_play: Dictionary = {}
	if (
		one_vs_one
		and possession == "self"
		and opponent_goal != null
		and controller.has_method(
			"_get_one_vs_one_space_play_preview"
		)
	):
		space_play = controller.call(
			"_get_one_vs_one_space_play_preview",
			opponent_goal
		) as Dictionary
	var space_play_available: bool = (
		not space_play.is_empty()
	)
	var space_play_destination: Vector2 = (
		space_play.get(
			"destination",
			ball_position
		) as Vector2
	)
	var space_play_quality: float = clampf(
		float(
			space_play.get(
				"shooting_area_quality",
				0.0
			)
		) / 1.7,
		0.0,
		1.0
	)

	var attacker_behind_defender := (
		not goal_cover_available
		and (
			opponent_has_physical_control
			or opponent_first_touch
		)
		and breakaway_goal_side_margin >= 120.0
	)
	var breakaway_recovery_urgency := clampf(
		(breakaway_goal_side_margin - 80.0) / 1200.0
		+ opponent_shot_threat * 0.55,
		0.0,
		1.0
	)
	var open_net_risk := 0.0
	if not goal_cover_available:
		# Open-net risk only applies when the opponent can realistically use the
		# ball. Ball location by itself must not make a 1v1 defender abandon a
		# free ball that it reaches first.
		if opponent_has_physical_control or opponent_first_touch:
			open_net_risk += clampf(
				self_ball_arrival_seconds
				- nearest_opponent_ball_arrival_seconds,
				0.0,
				0.65
			) / 0.65
			open_net_risk += opponent_shot_threat * 0.75
			if opponent_first_touch:
				open_net_risk += 0.35
		if own_goal_danger and not self_clearly_first_to_loose_ball:
			open_net_risk += 0.35
	if self_clearly_first_to_loose_ball:
		open_net_risk *= 0.12
	if attacker_behind_defender:
		open_net_risk = maxf(
			open_net_risk,
			0.72 + breakaway_recovery_urgency * 0.28
		)
	open_net_risk = clampf(open_net_risk, 0.0, 1.0)
	var team_sequence_plan: Dictionary = {}
	var team_sequence_assignment: Dictionary = {}
	if manager.has_method("get_cpu_team_sequence_plan"):
		var sequence_variant: Variant = manager.call(
			"get_cpu_team_sequence_plan",
			team
		)
		if sequence_variant is Dictionary:
			team_sequence_plan = sequence_variant as Dictionary
	if not team_sequence_plan.is_empty():
		team_sequence_assignment = (
			team_sequence_plan.get("assignments", {}) as Dictionary
		).get(int(player.get("owner_peer_id")), {}) as Dictionary
	return {
		"observation_version": Schema.OBSERVATION_VERSION,
		"team": team,
		"attack_sign": attack_sign,
		"player_peer_id": int(player.get("owner_peer_id")),
		"player": normalized_player,
		"player_velocity": _normalize_velocity(player_velocity, attack_sign, 6000.0),
		"ball": normalized_ball,
		"ball_velocity": _normalize_velocity(ball_velocity, attack_sign, 12000.0),
		"ball_angular_velocity": clampf(float(ball.get("angular_velocity")) / 30.0, -1.5, 1.5),
		"predicted_ball": _normalize_position(
			trajectory[mini(trajectory.size() - 1, 5)] if not trajectory.is_empty() else ball_position,
			attack_sign,
			minimum_x,
			maximum_x,
			minimum_y,
			maximum_y
		),
		"intercept_available": bool(intercept.get("available", false)),
		"self_ball_arrival_seconds": self_ball_arrival_seconds,
		"nearest_opponent_ball_arrival_seconds": nearest_opponent_ball_arrival_seconds,
		"ball_race_advantage": clampf(ball_race_advantage_seconds / 1.2, -1.5, 1.5),
		"opponent_first_touch": opponent_first_touch,
		"self_clearly_first_to_loose_ball": self_clearly_first_to_loose_ball,
		"opponent_has_physical_control": opponent_has_physical_control,
		"attacker_behind_defender": attacker_behind_defender,
		"breakaway_goal_side_margin": breakaway_goal_side_margin,
		"breakaway_recovery_urgency": breakaway_recovery_urgency,
		"opponent_kick_ready": opponent_kick_ready,
		"opponent_charging": opponent_charging,
		"opponent_shot_threat": opponent_shot_threat,
		"goal_cover_available": goal_cover_available,
		"open_net_risk": open_net_risk,
		"intercept_time": clampf(float(intercept.get("ball_time", 2.0)) / 2.0, 0.0, 1.0),
		"intercept_position": _normalize_position(
			intercept.get("position", ball_position),
			attack_sign, minimum_x, maximum_x, minimum_y, maximum_y
		),
		"own_goal": _normalize_position(own_goal_position, attack_sign, minimum_x, maximum_x, minimum_y, maximum_y),
		"opponent_goal": _normalize_position(opponent_goal_position, attack_sign, minimum_x, maximum_x, minimum_y, maximum_y),
		"own_goal_relative": _normalize_velocity(own_goal_position - player_position, attack_sign, maxf(field_width, field_height)),
		"opponent_goal_relative": _normalize_velocity(opponent_goal_position - player_position, attack_sign, maxf(field_width, field_height)),
		"teammates": teammate_slots,
		"opponents": opponent_slots,
		"possession": possession,
		"last_touch_peer_id": int(ball.get("last_touch_peer_id")),
		"last_touch_team": StringName(manager.get("_cpu_last_touch_team")),
		"team_has_possession": team_possession,
		"primary_chaser": primary_chaser,
		"local_duel": local_duel != null,
		"one_vs_one": one_vs_one,
		"offensive_bypass_margin": offensive_bypass_margin,
		"offensive_defender_beaten": offensive_defender_beaten,
		"shot_followup_ready": shot_followup_ready,
		"elite_goal_probability": elite_goal_probability,
		"elite_finish_available": not elite_finish.is_empty(),
		"elite_finish_force_ratio": clampf(
			float(elite_finish.get("force_ratio", 0.0)),
			0.0,
			1.0
		),
		"elite_finish_uses_wall": bool(elite_finish.get("uses_wall", false)),
		"elite_finish_timing_margin": clampf(
			float(elite_finish.get("timing_margin", 0.0)),
			-1.0,
			2.0
		),
		"space_play_available": space_play_available,
		"space_play_uses_wall": bool(
			space_play.get("uses_wall", false)
		),
		"space_play_destination": space_play_destination,
		"space_play_quality": space_play_quality,
		"space_play_recovery_margin": clampf(
			float(
				space_play.get(
					"recovery_margin",
					0.0
				)
			),
			-1.0,
			2.0
		),
		"space_play_shooting_lane": clampf(
			float(
				space_play.get(
					"shooting_lane",
					0.0
				)
			) / 900.0,
			0.0,
			1.5
		),
		"space_play_force_ratio": clampf(
			float(
				space_play.get(
					"force_ratio",
					0.0
				)
			),
			0.0,
			1.0
		),
		"ball_distance": clampf(player_position.distance_to(ball_position) / maxf(field_width, field_height), 0.0, 1.5),
		"ball_speed": clampf(ball_velocity.length() / 12000.0, 0.0, 1.5),
		"goal_distance": clampf(goal_distance / field_width, 0.0, 1.5),
		"own_goal_distance": clampf(own_goal_distance / field_width, 0.0, 1.5),
		"shot_lane": clampf(shot_lane / 1400.0, -1.0, 1.0),
		"nearest_opponent_ball_distance": clampf(nearest_opponent_distance / 1800.0, 0.0, 2.0),
		"own_goal_danger": own_goal_danger,
		"best_pass": best_pass,
		"score_difference": clampf(float(score_for - score_against) / 5.0, -1.0, 1.0),
		"time_remaining": clampf(remaining / regulation_seconds, 0.0, 1.0),
		"overtime": bool(manager.get("is_overtime")),
		"team_size": clampf(float(sorted_teammates.size() + 1) / float(Schema.MAX_TEAM_SIZE), 0.0, 1.0),
		"opponent_size": clampf(float(sorted_opponents.size()) / float(Schema.MAX_TEAM_SIZE), 0.0, 1.0),
		"kick_ready": player_has_kickable_ball,
		"charging": bool(player.get("server_is_charging")),
		"ability_ready": cooldown_remaining <= 0.0,
		"ability_id": int(player.get("selected_ability")),
		"ability_cooldown": clampf(cooldown_remaining / 20.0, 0.0, 1.0),
		"opponent_ability_state": opponent_ability_state,
		"team_ability_state": team_ability_state,
		"team_sequence_plan": team_sequence_plan,
		"team_sequence_assignment": team_sequence_assignment,
		"field_width": field_width,
		"field_height": field_height
	}


static func flatten(observation: Dictionary) -> Dictionary:
	if observation.is_empty():
		return {}
	var features := {
		"bias": 1.0,
		"possession_self": 1.0 if str(observation.get("possession", "")) == "self" else 0.0,
		"possession_team": 1.0 if bool(observation.get("team_has_possession", false)) else 0.0,
		"possession_opponent": 1.0 if str(observation.get("possession", "")) == "opponent" else 0.0,
		"possession_loose": 1.0 if str(observation.get("possession", "")) == "loose" else 0.0,
		"primary_chaser": 1.0 if bool(observation.get("primary_chaser", false)) else 0.0,
		"local_duel": 1.0 if bool(observation.get("local_duel", false)) else 0.0,
		"one_vs_one": 1.0 if bool(observation.get("one_vs_one", false)) else 0.0,
		"offensive_bypass_margin": clampf(
			float(observation.get("offensive_bypass_margin", 0.0))
			/ 1200.0,
			-1.5,
			1.5
		),
		"offensive_defender_beaten": 1.0 if bool(
			observation.get("offensive_defender_beaten", false)
		) else 0.0,
		"shot_followup_ready": 1.0 if bool(
			observation.get("shot_followup_ready", true)
		) else 0.0,
		"elite_goal_probability": float(observation.get("elite_goal_probability", 0.0)),
		"elite_finish_available": 1.0 if bool(observation.get("elite_finish_available", false)) else 0.0,
		"elite_finish_force_ratio": float(observation.get("elite_finish_force_ratio", 0.0)),
		"elite_finish_uses_wall": 1.0 if bool(observation.get("elite_finish_uses_wall", false)) else 0.0,
		"elite_finish_timing_margin": clampf(
			float(observation.get("elite_finish_timing_margin", 0.0)),
			-1.0,
			1.5
		),
		"space_play_available": 1.0 if bool(
			observation.get(
				"space_play_available",
				false
			)
		) else 0.0,
		"space_play_uses_wall": 1.0 if bool(
			observation.get(
				"space_play_uses_wall",
				false
			)
		) else 0.0,
		"space_play_quality": float(
			observation.get(
				"space_play_quality",
				0.0
			)
		),
		"space_play_recovery_margin": clampf(
			float(
				observation.get(
					"space_play_recovery_margin",
					0.0
				)
			),
			-1.0,
			1.5
		),
		"space_play_shooting_lane": float(
			observation.get(
				"space_play_shooting_lane",
				0.0
			)
		),
		"space_play_force_ratio": float(
			observation.get(
				"space_play_force_ratio",
				0.0
			)
		),
		"own_goal_danger": 1.0 if bool(observation.get("own_goal_danger", false)) else 0.0,
		"kick_ready": 1.0 if bool(observation.get("kick_ready", false)) else 0.0,
		"charging": 1.0 if bool(observation.get("charging", false)) else 0.0,
		"ability_ready": 1.0 if bool(observation.get("ability_ready", false)) else 0.0,
		"overtime": 1.0 if bool(observation.get("overtime", false)) else 0.0,
		"intercept_available": 1.0 if bool(observation.get("intercept_available", false)) else 0.0,
		"ball_spin": float(observation.get("ball_angular_velocity", 0.0)),
		"ball_distance": float(observation.get("ball_distance", 1.0)),
		"ball_speed": float(observation.get("ball_speed", 0.0)),
		"goal_distance": float(observation.get("goal_distance", 1.0)),
		"goal_closeness": 1.0 - clampf(float(observation.get("goal_distance", 1.0)), 0.0, 1.0),
		"own_goal_distance": float(observation.get("own_goal_distance", 1.0)),
		"shot_lane": float(observation.get("shot_lane", 0.0)),
		"opponent_pressure": 1.0 - clampf(float(observation.get("nearest_opponent_ball_distance", 1.0)), 0.0, 1.0),
		"score_difference": float(observation.get("score_difference", 0.0)),
		"time_remaining": float(observation.get("time_remaining", 1.0)),
		"team_size": float(observation.get("team_size", 0.25)),
		"opponent_size": float(observation.get("opponent_size", 0.25)),
		"ability_cooldown": float(observation.get("ability_cooldown", 0.0)),
		"intercept_time": float(observation.get("intercept_time", 1.0)),
		"ball_race_advantage": float(observation.get("ball_race_advantage", 0.0)),
		"opponent_first_touch": 1.0 if bool(observation.get("opponent_first_touch", false)) else 0.0,
		"self_clearly_first_to_loose_ball": 1.0 if bool(observation.get("self_clearly_first_to_loose_ball", false)) else 0.0,
		"opponent_has_physical_control": 1.0 if bool(observation.get("opponent_has_physical_control", false)) else 0.0,
		"opponent_stall": 1.0 if bool(observation.get("opponent_stall", false)) else 0.0,
		"opponent_stall_strength": clampf(float(observation.get("opponent_stall_strength", 0.0)), 0.0, 1.0),
		"opponent_stall_duration": clampf(float(observation.get("opponent_stall_seconds", 0.0)) / 2.0, 0.0, 1.5),
		"opponent_idle_input": clampf(float(observation.get("opponent_idle_input", 0.0)), 0.0, 1.0),
		"opponent_commit_signal": clampf(float(observation.get("opponent_commit_signal", 0.0)), 0.0, 1.0),
		"defensive_goal_proximity": clampf(float(observation.get("defensive_goal_proximity", 0.0)), 0.0, 1.0),
		"attacking_goal_proximity": clampf(float(observation.get("attacking_goal_proximity", 0.0)), 0.0, 1.0),
		"attacker_behind_defender": 1.0 if bool(observation.get("attacker_behind_defender", false)) else 0.0,
		"breakaway_goal_side_margin": clampf(float(observation.get("breakaway_goal_side_margin", 0.0)) / 1800.0, -1.5, 1.5),
		"breakaway_recovery_urgency": float(observation.get("breakaway_recovery_urgency", 0.0)),
		"opponent_kick_ready": 1.0 if bool(observation.get("opponent_kick_ready", false)) else 0.0,
		"opponent_charging": 1.0 if bool(observation.get("opponent_charging", false)) else 0.0,
		"opponent_shot_threat": float(observation.get("opponent_shot_threat", 0.0)),
		"goal_cover_available": 1.0 if bool(observation.get("goal_cover_available", false)) else 0.0,
		"open_net_risk": float(observation.get("open_net_risk", 0.0)),
		"opponent_ability_goal_threat": 0.0,
		"opponent_ability_counter_threat": 0.0,
		"opponent_power_strike_threat": 0.0,
		"opponent_curve_shot_threat": 0.0,
		"opponent_speed_break_threat": 0.0,
		"opponent_bypass_threat": 0.0,
		"opponent_combination_threat": 0.0,
		"opponent_first_time_finish_threat": 0.0,
		"opponent_displacement_threat": 0.0,
		"opponent_defensive_stop_threat": 0.0,
		"opponent_ability_uncertainty": 0.0,
		"team_sequence_available": 0.0,
		"team_sequence_confidence": 0.0,
		"team_sequence_actor": 0.0,
		"team_sequence_receiver": 0.0,
		"team_sequence_runner": 0.0,
		"team_sequence_safety": 0.0,
		"team_sequence_pass": 0.0,
		"team_sequence_wall_pass": 0.0,
		"team_sequence_combination": 0.0,
		"team_sequence_shot": 0.0,
		"team_sequence_carry": 0.0,
		"team_sequence_arrival_margin": 0.0,
		"team_sequence_lane": 0.0,
		"team_sequence_continuation": 0.0,
		"team_sequence_counter_risk": 0.0
	}
	var opponent_ability_state := observation.get(
		"opponent_ability_state",
		{}
	) as Dictionary
	features["opponent_ability_goal_threat"] = float(
		opponent_ability_state.get("goal_threat", 0.0)
	)
	features["opponent_ability_counter_threat"] = float(
		opponent_ability_state.get("counter_threat", 0.0)
	)
	features["opponent_power_strike_threat"] = float(
		opponent_ability_state.get("power_shot_threat", 0.0)
	)
	features["opponent_curve_shot_threat"] = float(
		opponent_ability_state.get("curve_shot_threat", 0.0)
	)
	features["opponent_speed_break_threat"] = float(
		opponent_ability_state.get("speed_break_threat", 0.0)
	)
	features["opponent_bypass_threat"] = float(
		opponent_ability_state.get("bypass_threat", 0.0)
	)
	features["opponent_combination_threat"] = float(
		opponent_ability_state.get("combination_threat", 0.0)
	)
	features["opponent_first_time_finish_threat"] = float(
		opponent_ability_state.get("first_time_finish_threat", 0.0)
	)
	features["opponent_displacement_threat"] = float(
		opponent_ability_state.get("displacement_threat", 0.0)
	)
	features["opponent_defensive_stop_threat"] = float(
		opponent_ability_state.get("defensive_stop_threat", 0.0)
	)
	features["opponent_ability_uncertainty"] = float(
		opponent_ability_state.get("uncertainty", 0.0)
	)
	var team_ability_state := observation.get(
		"team_ability_state",
		{}
	) as Dictionary
	var opponent_has := opponent_ability_state.get("has", {}) as Dictionary
	var opponent_ready := opponent_ability_state.get("ready", {}) as Dictionary
	var opponent_active := opponent_ability_state.get("active", {}) as Dictionary
	var team_has := team_ability_state.get("has", {}) as Dictionary
	var team_ready := team_ability_state.get("ready", {}) as Dictionary
	var team_active := team_ability_state.get("active", {}) as Dictionary
	for ability_id in range(1, FootballPlayer.ABILITY_COUNT + 1):
		features["opponent_ability_%d_has" % ability_id] = (
			1.0 if bool(opponent_has.get(ability_id, false)) else 0.0
		)
		features["opponent_ability_%d_ready" % ability_id] = (
			1.0 if bool(opponent_ready.get(ability_id, false)) else 0.0
		)
		features["opponent_ability_%d_active" % ability_id] = (
			1.0 if bool(opponent_active.get(ability_id, false)) else 0.0
		)
		features["team_ability_%d_has" % ability_id] = (
			1.0 if bool(team_has.get(ability_id, false)) else 0.0
		)
		features["team_ability_%d_ready" % ability_id] = (
			1.0 if bool(team_ready.get(ability_id, false)) else 0.0
		)
		features["team_ability_%d_active" % ability_id] = (
			1.0 if bool(team_active.get(ability_id, false)) else 0.0
		)
	var team_sequence_plan := observation.get(
		"team_sequence_plan",
		{}
	) as Dictionary
	var team_sequence_assignment := observation.get(
		"team_sequence_assignment",
		{}
	) as Dictionary
	if not team_sequence_plan.is_empty():
		features["team_sequence_available"] = 1.0
		features["team_sequence_confidence"] = clampf(
			float(team_sequence_plan.get("confidence", 0.0)),
			0.0,
			1.0
		)
		features["team_sequence_actor"] = 1.0 if (
			int(team_sequence_plan.get("actor_peer_id", 0))
			== int(observation.get("player_peer_id", 0))
		) else 0.0
		features["team_sequence_receiver"] = 1.0 if (
			int(team_sequence_plan.get("receiver_peer_id", 0))
			== int(observation.get("player_peer_id", 0))
		) else 0.0
		var sequence_action := StringName(
			team_sequence_plan.get("action", &"none")
		)
		features["team_sequence_pass"] = 1.0 if sequence_action in [
			&"pass", &"one_two", &"third_man"
		] else 0.0
		features["team_sequence_wall_pass"] = 1.0 if (
			sequence_action == &"wall_pass"
		) else 0.0
		features["team_sequence_combination"] = 1.0 if sequence_action in [
			&"one_two", &"third_man"
		] else 0.0
		features["team_sequence_shot"] = 1.0 if (
			sequence_action == &"shot"
		) else 0.0
		features["team_sequence_carry"] = 1.0 if (
			sequence_action == &"carry"
		) else 0.0
		features["team_sequence_arrival_margin"] = clampf(
			float(team_sequence_plan.get("arrival_margin", 0.0)),
			-1.0,
			1.5
		)
		features["team_sequence_lane"] = clampf(
			float(team_sequence_plan.get("route_clearance", 0.0)) / 1200.0,
			0.0,
			1.5
		)
		features["team_sequence_continuation"] = clampf(
			float(team_sequence_plan.get("continuation_value", 0.0)),
			0.0,
			1.5
		)
		features["team_sequence_counter_risk"] = clampf(
			float(team_sequence_plan.get("counter_risk", 0.0)),
			0.0,
			1.0
		)
	var sequence_role := StringName(
		team_sequence_assignment.get("role", &"")
	)
	features["team_sequence_runner"] = 1.0 if sequence_role in [
		&"runner", &"return_runner", &"connector"
	] else 0.0
	features["team_sequence_safety"] = 1.0 if sequence_role == &"safety" else 0.0
	var player_value: Variant = observation.get("player", Vector2.ZERO)
	var ball_value: Variant = observation.get("ball", Vector2.ZERO)
	var player_position := player_value as Vector2 if player_value is Vector2 else Vector2.ZERO
	var ball_position := ball_value as Vector2 if ball_value is Vector2 else Vector2.ZERO
	features["player_x"] = player_position.x
	features["player_y"] = player_position.y
	features["ball_x"] = ball_position.x
	features["ball_y"] = ball_position.y
	features["ball_ahead"] = clampf(ball_position.x - player_position.x, -1.0, 1.0)
	var own_goal_value: Variant = observation.get("own_goal_relative", Vector2.ZERO)
	var opponent_goal_value: Variant = observation.get("opponent_goal_relative", Vector2.ZERO)
	var own_goal_relative := own_goal_value as Vector2 if own_goal_value is Vector2 else Vector2.ZERO
	var opponent_goal_relative := opponent_goal_value as Vector2 if opponent_goal_value is Vector2 else Vector2.ZERO
	features["own_goal_relative_x"] = own_goal_relative.x
	features["own_goal_relative_y"] = own_goal_relative.y
	features["opponent_goal_relative_x"] = opponent_goal_relative.x
	features["opponent_goal_relative_y"] = opponent_goal_relative.y
	var best_pass := observation.get("best_pass", {}) as Dictionary
	features["pass_available"] = 1.0 if bool(best_pass.get("available", false)) else 0.0
	features["pass_lane"] = float(best_pass.get("lane", 0.0))
	features["pass_progress"] = float(best_pass.get("progress", 0.0))
	features["pass_receiver_open"] = float(best_pass.get("openness", 0.0))
	features["pass_quality"] = float(best_pass.get("quality", 0.0))
	features["pass_interception_margin"] = clampf(
		float(best_pass.get("interception_margin", 0.0)),
		-1.0,
		1.5
	)
	features["pass_receiver_margin"] = clampf(
		float(best_pass.get("receiver_margin", 0.0)),
		-1.0,
		1.5
	)
	features["pass_chain_value"] = clampf(
		float(best_pass.get("chain_value", 0.0)),
		0.0,
		1.5
	)
	features["pass_counter_risk"] = clampf(
		float(best_pass.get("counter_risk", 0.0)),
		0.0,
		1.0
	)
	features["pass_defensive_error"] = clampf(
		float(best_pass.get("defensive_error_value", 0.0)),
		0.0,
		1.5
	)
	var pass_kind := StringName(best_pass.get("kind", &""))
	features["pass_is_through"] = 1.0 if pass_kind in [
		&"through",
		&"diagonal_split",
		&"blindside",
		&"overlap",
		&"underlap"
	] else 0.0
	features["pass_is_switch"] = 1.0 if pass_kind == &"wide_switch" else 0.0
	features["pass_is_cutback"] = 1.0 if pass_kind == &"cutback" else 0.0
	features["pass_is_wall"] = 1.0 if pass_kind == &"wall_bank" else 0.0
	features["pass_is_combination"] = 1.0 if pass_kind in [
		&"one_two", &"third_man", &"overlap", &"underlap"
	] else 0.0
	features["pass_is_pressure_escape"] = 1.0 if pass_kind in [
		&"pressure_escape", &"layoff", &"recycle"
	] else 0.0
	features["pass_is_blindside"] = 1.0 if pass_kind == &"blindside" else 0.0
	features["pass_is_square"] = 1.0 if pass_kind == &"square" else 0.0
	features["pass_is_recycle"] = 1.0 if pass_kind == &"recycle" else 0.0
	var opponents := observation.get("opponents", []) as Array
	if not opponents.is_empty():
		var nearest := opponents[0] as Dictionary
		features["nearest_opponent_distance"] = float(nearest.get("actor_distance", 1.0))
		features["nearest_opponent_ball_distance"] = float(nearest.get("ball_distance", 1.0))
		features["nearest_opponent_goal_side"] = float(nearest.get("goal_side", 0.0))
		features["nearest_opponent_arrival_time"] = float(nearest.get("ball_arrival_time", 1.0))
	else:
		features["nearest_opponent_distance"] = 1.0
		features["nearest_opponent_ball_distance"] = 1.0
		features["nearest_opponent_goal_side"] = 0.0
		features["nearest_opponent_arrival_time"] = 1.0
	return features


static func _best_pass_summary(controller: Node, opponent_goal: Node) -> Dictionary:
	if opponent_goal == null:
		return {"available": false}
	if controller.has_method("_get_best_team_pass_plan"):
		var team_plan := controller.call(
			"_get_best_team_pass_plan",
			opponent_goal,
			false
		) as Dictionary
		var acceptable := (
			not team_plan.is_empty()
			and controller.has_method("_team_pass_plan_is_acceptable")
			and bool(controller.call(
				"_team_pass_plan_is_acceptable",
				team_plan
			))
		)
		if acceptable:
			var ball: Node = controller.get("ball")
			var player: Node = controller.get("controlled_player")
			var target: Vector2 = team_plan.get(
				"destination",
				Vector2.ZERO
			)
			var lane := float(team_plan.get("route_clearance", 0.0))
			var attack_sign := float(controller.call("_get_attack_sign"))
			var progress := (
				target.x - (ball.get("global_position") as Vector2).x
			) * attack_sign
			return {
				"available": true,
				"peer_id": int(team_plan.get("receiver_peer_id", 0)),
				"target": target,
				"lane": clampf(lane / 1000.0, -1.0, 1.5),
				"progress": clampf(progress / 2200.0, -1.0, 1.0),
				"openness": clampf(
					float(team_plan.get("openness", 0.0)) / 1500.0,
					0.0,
					1.5
				),
				"distance": clampf(
					(player.get("global_position") as Vector2).distance_to(target)
					/ 4200.0,
					0.0,
					1.5
				),
				"quality": float(team_plan.get("quality", 0.0)),
				"interception_margin": float(
					team_plan.get("interception_margin", 0.0)
				),
				"receiver_margin": float(
					team_plan.get("receiver_margin", 0.0)
				),
				"chain_value": clampf(
					float(team_plan.get("chain_value", 0.0)) / 900.0,
					0.0,
					1.5
				),
				"counter_risk": float(
					team_plan.get("counter_risk", 0.0)
				),
				"defensive_error_value": clampf(
					float(team_plan.get("defensive_error_value", 0.0))
					/ 520.0,
					0.0,
					1.5
				),
				"kind": StringName(team_plan.get("kind", &""))
			}
	var receiver: Node = controller.call("_select_pass_target", opponent_goal)
	if receiver == null:
		return {"available": false}
	var ball: Node = controller.get("ball")
	var player: Node = controller.get("controlled_player")
	var target: Vector2 = controller.call("_get_lead_pass_target", receiver)
	var lane := float(controller.call("_minimum_pass_lane_clearance", target))
	var attack_sign := float(controller.call("_get_attack_sign"))
	var progress := (target.x - (ball.get("global_position") as Vector2).x) * attack_sign
	var openness := float(controller.call("_nearest_opponent_distance", target))
	return {
		"available": true,
		"peer_id": int(receiver.get("owner_peer_id")),
		"target": target,
		"lane": clampf(lane / 1000.0, -1.0, 1.5),
		"progress": clampf(progress / 2200.0, -1.0, 1.0),
		"openness": clampf(openness / 1500.0, 0.0, 1.5),
		"distance": clampf((player.get("global_position") as Vector2).distance_to(target) / 4200.0, 0.0, 1.5),
		"quality": 0.35,
		"kind": &"legacy"
	}


static func _sort_players_by_ball_race(
	players: Array,
	ball_position: Vector2
) -> Array:
	var result := players.duplicate()
	for index in range(1, result.size()):
		var current: Node = result[index] as Node
		var current_arrival := _estimate_player_ball_arrival(
			current,
			ball_position
		)
		var cursor := index - 1
		while cursor >= 0:
			var previous: Node = result[cursor] as Node
			var previous_arrival := _estimate_player_ball_arrival(
				previous,
				ball_position
			)
			var previous_peer := int(previous.get("owner_peer_id"))
			var current_peer := int(current.get("owner_peer_id"))
			if previous_arrival < current_arrival - 0.001:
				break
			if (
				is_equal_approx(previous_arrival, current_arrival)
				and previous_peer <= current_peer
			):
				break
			result[cursor + 1] = previous
			cursor -= 1
		result[cursor + 1] = current
	return result


static func _estimate_player_ball_arrival(
	player: Node,
	ball_position: Vector2
) -> float:
	if player == null or not is_instance_valid(player):
		return 3.0
	if (
		player.has_method("cpu_has_kickable_ball")
		and bool(player.call("cpu_has_kickable_ball"))
	):
		return 0.0
	return BallPredictor.estimate_arrival_time(
		player.get("global_position") as Vector2,
		player.get("linear_velocity") as Vector2,
		ball_position,
		float(player.get("max_speed")),
		float(player.get("acceleration"))
	)


static func _has_goal_cover_teammate(
	teammates: Array,
	ball_position: Vector2,
	own_goal_position: Vector2
) -> bool:
	var ball_goal_distance := ball_position.distance_to(own_goal_position)
	for teammate_variant in teammates:
		var teammate := teammate_variant as Node
		if teammate == null or not is_instance_valid(teammate):
			continue
		var teammate_position: Vector2 = teammate.get("global_position")
		if teammate_position.distance_to(own_goal_position) >= ball_goal_distance:
			continue
		if (
			_distance_to_segment(
				teammate_position,
				own_goal_position,
				ball_position
			)
			<= 850.0
		):
			return true
	return false


static func _calculate_opponent_shot_threat(
	opponent: Node,
	ball_position: Vector2,
	ball_velocity: Vector2,
	own_goal_position: Vector2,
	field_width: float,
	possession: String,
	own_goal_danger: bool,
	opponent_arrival_seconds: float,
	opponent_has_control: bool
) -> float:
	if opponent == null or not is_instance_valid(opponent):
		return 0.0
	var threat := 0.0
	var opponent_kick_ready := (
		opponent.has_method("cpu_has_kickable_ball")
		and bool(opponent.call("cpu_has_kickable_ball"))
	)
	var opponent_charging := bool(opponent.get("server_is_charging"))
	var access_factor := (
		1.0
		if opponent_has_control
		else clampf(
			1.0 - opponent_arrival_seconds / 1.25,
			0.0,
			1.0
		)
	)
	if possession == "opponent":
		threat += 0.20
	if opponent_kick_ready:
		threat += 0.30
	if opponent_charging:
		threat += 0.35
	var goal_distance := ball_position.distance_to(own_goal_position)
	threat += (
		1.0
		- clampf(
			goal_distance / maxf(1.0, field_width * 0.72),
			0.0,
			1.0
		)
	) * 0.45 * access_factor
	var direction_to_goal := ball_position.direction_to(own_goal_position)
	var ball_is_actual_goal_threat := (
		not direction_to_goal.is_zero_approx()
		and ball_velocity.dot(direction_to_goal) >= 420.0
	)
	if ball_is_actual_goal_threat:
		threat += 0.30
	if own_goal_danger:
		threat += 0.25 * maxf(access_factor, 0.35 if ball_is_actual_goal_threat else 0.0)
	return clampf(threat, 0.0, 1.0)


static func _distance_to_segment(
	point: Vector2,
	segment_start: Vector2,
	segment_end: Vector2
) -> float:
	var segment := segment_end - segment_start
	var length_squared := segment.length_squared()
	if length_squared <= 0.001:
		return point.distance_to(segment_start)
	var ratio := clampf(
		(point - segment_start).dot(segment) / length_squared,
		0.0,
		1.0
	)
	return point.distance_to(segment_start + segment * ratio)


static func _stable_players(players: Array, excluded_peer_id: int) -> Array:
	var result: Array = []
	for player in players:
		if player == null or not is_instance_valid(player):
			continue
		if int(player.get("owner_peer_id")) == excluded_peer_id:
			continue
		if not bool(player.get("controls_enabled")):
			continue
		result.append(player)
	result.sort_custom(func(a: Node, b: Node) -> bool:
		return int(a.get("owner_peer_id")) < int(b.get("owner_peer_id"))
	)
	return result


static func _build_entity_slots(
	players: Array,
	maximum_slots: int,
	attack_sign: float,
	minimum_x: float,
	maximum_x: float,
	minimum_y: float,
	maximum_y: float,
	actor_position: Vector2,
	ball_position: Vector2
) -> Array:
	var slots: Array = []
	for index in range(maximum_slots):
		if index >= players.size():
			slots.append({"mask": 0.0})
			continue
		var player: Node = players[index]
		var position: Vector2 = player.get("global_position")
		var velocity: Vector2 = player.get("linear_velocity")
		var arrival_time := BallPredictor.estimate_arrival_time(
			position,
			velocity,
			ball_position,
			float(player.get("max_speed")),
			float(player.get("acceleration"))
		)
		slots.append({
			"mask": 1.0,
			"peer_id": int(player.get("owner_peer_id")),
			"position": _normalize_position(position, attack_sign, minimum_x, maximum_x, minimum_y, maximum_y),
			"velocity": _normalize_velocity(velocity, attack_sign, 6000.0),
			"actor_distance": clampf(position.distance_to(actor_position) / 5000.0, 0.0, 1.5),
			"ball_distance": clampf(position.distance_to(ball_position) / 5000.0, 0.0, 1.5),
			"ball_arrival_time": clampf(arrival_time / 3.0, 0.0, 1.5),
			"goal_side": clampf((ball_position.x - position.x) * attack_sign / 2600.0, -1.0, 1.0),
			"ability_id": int(player.get("selected_ability")),
			"charging": bool(player.get("server_is_charging")),
			"kick_ready": (
				player.has_method("cpu_has_kickable_ball")
				and bool(player.call("cpu_has_kickable_ball"))
			)
		})
	return slots


static func _normalize_position(
	position: Vector2,
	attack_sign: float,
	minimum_x: float,
	maximum_x: float,
	minimum_y: float,
	maximum_y: float
) -> Vector2:
	var x := clampf((position.x - minimum_x) / maxf(1.0, maximum_x - minimum_x), 0.0, 1.0)
	if attack_sign < 0.0:
		x = 1.0 - x
	var y := clampf((position.y - minimum_y) / maxf(1.0, maximum_y - minimum_y), 0.0, 1.0)
	return Vector2(x, y)


static func _normalize_velocity(velocity: Vector2, attack_sign: float, scale: float) -> Vector2:
	return Vector2(
		clampf(velocity.x * attack_sign / maxf(1.0, scale), -1.5, 1.5),
		clampf(velocity.y / maxf(1.0, scale), -1.5, 1.5)
	)


static func _goal_center(controller: Node, goal: Node) -> Vector2:
	if goal == null:
		return Vector2.ZERO
	return controller.call("_get_goal_center", goal) as Vector2
