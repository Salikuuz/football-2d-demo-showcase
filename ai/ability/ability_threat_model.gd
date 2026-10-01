extends RefCounted


# Parser-safe, dependency-free ability threat model.
# Keep these IDs synchronized with FootballPlayer's public ability IDs.
const ABILITY_NONE = 0
const ABILITY_BURST_DRIBBLE = 1
const ABILITY_QUICK_TRIGGER = 2
const ABILITY_POWER_STRIKE = 3
const ABILITY_OVERDRIVE = 4
const ABILITY_HEEL_TURN = 5
const ABILITY_ENFORCER = 6
const ABILITY_GOALKEEPER_REACH = 7
const ABILITY_TIME_SKIP_PASS = 8
const ABILITY_DIRECT_FINISH = 9
const ABILITY_ELASTIC_STEP = 10
const ABILITY_META_VISION = 11
const ABILITY_COPYCAT = 12
const ABILITY_REFLEX_BLOCK = 13
const ABILITY_IRON_ANCHOR = 14
const ABILITY_BLIND_SPOT = 15
const ABILITY_BOOGIE_WOOGIE = 16
const ABILITY_ECHO = 17
const ABILITY_RETURN_TAG = 18
const ABILITY_BREAKAWAY = 19
const ABILITY_SNAPBACK = 20
const ABILITY_SIDE_SWIPE = 21
const ABILITY_NUTMEG = 22
const ABILITY_DECOY_RUN = 23

const THREAT_NONE = &"none"
const THREAT_POWER_SHOT = &"power_shot"
const THREAT_CURVE_SHOT = &"curve_shot"
const THREAT_SPEED_BREAK = &"speed_break"
const THREAT_BYPASS = &"bypass"
const THREAT_COMBINATION = &"combination"
const THREAT_FIRST_TIME_FINISH = &"first_time_finish"
const THREAT_DISPLACEMENT = &"displacement"
const THREAT_DEFENSIVE_STOP = &"defensive_stop"


static func analyze_team(
	players,
	ball_position,
	own_goal_position,
	field_width,
	server_now,
	ball_velocity = Vector2.ZERO
) -> Dictionary:
	var has = {}
	var ready = {}
	var active = {}
	var details = []
	var aggregate = _empty_team_result(has, ready, active, details)

	if not players is Array:
		return aggregate

	for player_value in players:
		if not player_value is Node:
			continue
		var player = player_value
		if not is_instance_valid(player):
			continue
		if not bool(player.get("controls_enabled")):
			continue

		var detail = analyze_player(
			player,
			_safe_vector2(ball_position),
			_safe_vector2(own_goal_position),
			float(field_width),
			float(server_now),
			_safe_vector2(ball_velocity)
		)
		if detail.is_empty():
			continue

		details.append(detail)
		var ability_id = int(detail.get("ability_id", ABILITY_NONE))
		if ability_id > ABILITY_NONE:
			has[ability_id] = true
			if bool(detail.get("ready", false)):
				ready[ability_id] = true
			if bool(detail.get("active", false)):
				active[ability_id] = true

		_merge_maximum(aggregate, detail, "goal_threat")
		_merge_maximum(aggregate, detail, "counter_threat")
		_merge_maximum(aggregate, detail, "power_shot_threat")
		_merge_maximum(aggregate, detail, "curve_shot_threat")
		_merge_maximum(aggregate, detail, "speed_break_threat")
		_merge_maximum(aggregate, detail, "bypass_threat")
		_merge_maximum(aggregate, detail, "combination_threat")
		_merge_maximum(aggregate, detail, "first_time_finish_threat")
		_merge_maximum(aggregate, detail, "displacement_threat")
		_merge_maximum(aggregate, detail, "defensive_stop_threat")
		_merge_maximum(aggregate, detail, "uncertainty")

		var score = float(detail.get("primary_score", 0.0))
		if score > float(aggregate.get("primary_score", 0.0)):
			aggregate["primary_score"] = score
			aggregate["primary_threat"] = detail.get(
				"primary_threat",
				THREAT_NONE
			)
			aggregate["primary_peer_id"] = int(
				detail.get("peer_id", 0)
			)
			aggregate["primary_ability_id"] = ability_id
			aggregate["primary_position"] = _safe_vector2(
				detail.get("position", Vector2.ZERO)
			)
			aggregate["primary_ball_arrival"] = float(
				detail.get("ball_arrival", 3.0)
			)

	return aggregate


static func analyze_player(
	player,
	ball_position,
	own_goal_position,
	field_width,
	server_now,
	ball_velocity = Vector2.ZERO
) -> Dictionary:
	if not player is Node:
		return {}
	if not is_instance_valid(player):
		return {}

	var ability_id = int(player.get("selected_ability"))
	var active_id = int(player.get("server_active_ability_id"))
	var ability_active = bool(player.get("server_ability_active"))
	var active = false
	if ability_active:
		active = active_id == ability_id or ability_id == ABILITY_COPYCAT

	var cooldown_ends = float(
		player.get("server_ability_cooldown_ends_at")
	)
	var timers_paused = bool(player.get("server_ability_timers_paused"))
	var ready = false
	if ability_id > ABILITY_NONE and not timers_paused:
		ready = cooldown_ends <= float(server_now) + 0.02

	var kick_ready = false
	if player.has_method("cpu_has_kickable_ball"):
		kick_ready = bool(player.call("cpu_has_kickable_ball"))

	var position = _safe_vector2(player.get("global_position"))
	var velocity = _safe_vector2(player.get("linear_velocity"))
	var safe_ball_position = _safe_vector2(ball_position)
	var safe_goal_position = _safe_vector2(own_goal_position)
	var safe_ball_velocity = _safe_vector2(ball_velocity)
	var safe_field_width = maxf(1.0, float(field_width))
	var max_speed = maxf(1.0, float(player.get("max_speed")))
	var ball_distance = position.distance_to(safe_ball_position)
	var direction_to_ball = position.direction_to(safe_ball_position)
	var closing_speed = maxf(
		max_speed * 0.42,
		max_speed + velocity.dot(direction_to_ball) * 0.35
	)
	var ball_arrival = ball_distance / closing_speed
	if kick_ready:
		ball_arrival = 0.0

	var access = clampf(1.0 - ball_arrival / 1.65, 0.0, 1.0)
	if kick_ready:
		access = 1.0

	var incoming_pass_access = _incoming_pass_access(
		position,
		safe_ball_position,
		safe_ball_velocity
	)
	var projected_access = maxf(access, incoming_pass_access)

	var goal_distance = safe_ball_position.distance_to(safe_goal_position)
	var goal_closeness = 1.0 - clampf(
		goal_distance / maxf(1.0, safe_field_width * 0.82),
		0.0,
		1.0
	)
	var player_goal_closeness = 1.0 - clampf(
		position.distance_to(safe_goal_position)
		/ maxf(1.0, safe_field_width * 0.92),
		0.0,
		1.0
	)

	var readiness = 0.16
	if ready:
		readiness = 0.82
	if active:
		readiness = 1.0

	var charging = bool(player.get("server_is_charging"))
	var commitment = clampf(
		projected_access * 0.58
		+ maxf(goal_closeness, player_goal_closeness) * 0.30
		+ _charging_bonus(charging),
		0.0,
		1.0
	)

	var result = _empty_player_result(
		player,
		ability_id,
		active_id,
		ready,
		active,
		kick_ready,
		charging,
		position,
		velocity,
		ball_arrival,
		projected_access,
		access,
		incoming_pass_access,
		goal_closeness
	)

	_apply_ability_threat(
		result,
		player,
		ability_id,
		readiness,
		commitment,
		projected_access,
		access,
		goal_closeness,
		player_goal_closeness
	)
	return result


static func _apply_ability_threat(
	result,
	player,
	ability_id,
	readiness,
	commitment,
	projected_access,
	access,
	goal_closeness,
	player_goal_closeness
):
	if ability_id == ABILITY_POWER_STRIKE:
		var power = clampf(
			readiness
			* (0.42 + projected_access * 0.58)
			* (0.54 + maxf(goal_closeness, 0.30) * 0.46),
			0.0,
			1.0
		)
		result["power_shot_threat"] = power
		result["goal_threat"] = power
		result["counter_threat"] = power * (0.72 + access * 0.28)
		_set_primary(result, THREAT_POWER_SHOT, power)
		return

	if ability_id == ABILITY_QUICK_TRIGGER:
		var curve = readiness * commitment
		result["curve_shot_threat"] = curve
		result["goal_threat"] = curve * 0.86
		_set_primary(result, THREAT_CURVE_SHOT, curve)
		return

	if ability_id == ABILITY_OVERDRIVE:
		var speed = readiness * clampf(
			0.35 + projected_access * 0.65,
			0.0,
			1.0
		)
		result["speed_break_threat"] = speed
		result["counter_threat"] = speed
		result["bypass_threat"] = speed * 0.72
		_set_primary(result, THREAT_SPEED_BREAK, speed)
		return

	if ability_id == ABILITY_BREAKAWAY:
		# Breakaway is both a speed break and a defender-bypass threat. Feed it
		# into the same tactical features used by Overdrive/Burst so defenders
		# preserve goal-side depth instead of stepping directly into the self-pass.
		var breakaway = readiness * clampf(
			0.30 + projected_access * 0.70,
			0.0,
			1.0
		)
		result["speed_break_threat"] = breakaway
		result["bypass_threat"] = breakaway * 0.92
		result["counter_threat"] = breakaway * 0.94
		_set_primary(result, THREAT_SPEED_BREAK, breakaway)
		return

	if ability_id == ABILITY_SNAPBACK:
		# Snapback creates a delayed second action rather than a raw shot buff.
		# Combination threat makes cover players respect the return lane, while
		# uncertainty prevents the policy from treating the first touch as final.
		var snapback = readiness * clampf(
			0.24 + projected_access * 0.76,
			0.0,
			1.0
		)
		result["combination_threat"] = snapback
		result["counter_threat"] = snapback * 0.64
		result["goal_threat"] = snapback * (0.42 + goal_closeness * 0.34)
		result["uncertainty"] = maxf(
			float(result.get("uncertainty", 0.0)),
			snapback * 0.52
		)
		_set_primary(result, THREAT_COMBINATION, snapback)
		return

	if ability_id == ABILITY_SIDE_SWIPE:
		# Side Swipe changes the launch angle for both shots and passes. Reuse the
		# curve-shot feature for non-straight finishing pressure and combination
		# threat for its lateral passing route; no gameplay curve values change.
		var side_swipe = readiness * clampf(
			0.28 + projected_access * 0.72,
			0.0,
			1.0
		)
		result["curve_shot_threat"] = side_swipe * 0.86
		result["combination_threat"] = side_swipe * 0.78
		result["bypass_threat"] = side_swipe * 0.58
		result["goal_threat"] = side_swipe * (0.58 + goal_closeness * 0.34)
		_set_primary(result, THREAT_CURVE_SHOT, side_swipe * 0.86)
		return

	if ability_id == ABILITY_NUTMEG:
		var nutmeg = readiness * clampf(
			0.30 + projected_access * 0.70,
			0.0,
			1.0
		)
		result["bypass_threat"] = nutmeg
		result["counter_threat"] = nutmeg * 0.74
		_set_primary(result, THREAT_BYPASS, nutmeg)
		return

	if ability_id == ABILITY_DECOY_RUN:
		# The current ability is primarily a deception tool. The tactical layer
		# should at least know that an apparent run carries extra uncertainty and
		# some bypass potential instead of treating it as ABILITY_NONE.
		var decoy = readiness * clampf(
			0.26 + projected_access * 0.74,
			0.0,
			1.0
		)
		result["uncertainty"] = decoy
		result["bypass_threat"] = decoy * 0.48
		result["counter_threat"] = decoy * 0.42
		_set_primary(result, THREAT_BYPASS, decoy * 0.48)
		return

	if _is_bypass_ability(ability_id):
		var bypass = readiness * clampf(
			0.30 + projected_access * 0.70,
			0.0,
			1.0
		)
		result["bypass_threat"] = bypass
		result["counter_threat"] = bypass * 0.76
		_set_primary(result, THREAT_BYPASS, bypass)
		return

	if ability_id == ABILITY_TIME_SKIP_PASS or ability_id == ABILITY_RETURN_TAG:
		var combo = readiness * clampf(
			0.22 + projected_access * 0.78,
			0.0,
			1.0
		)
		result["combination_threat"] = combo
		result["counter_threat"] = combo * 0.68
		_set_primary(result, THREAT_COMBINATION, combo)
		return

	if ability_id == ABILITY_DIRECT_FINISH:
		var finish = readiness * clampf(
			0.28 + maxf(projected_access, player_goal_closeness) * 0.72,
			0.0,
			1.0
		)
		result["first_time_finish_threat"] = finish
		result["goal_threat"] = finish * 0.94
		result["combination_threat"] = finish * 0.72
		_set_primary(result, THREAT_FIRST_TIME_FINISH, finish)
		return

	if ability_id == ABILITY_HEEL_TURN:
		var heel = readiness * projected_access
		result["bypass_threat"] = heel * 0.78
		result["combination_threat"] = heel * 0.42
		_set_primary(result, THREAT_BYPASS, heel * 0.78)
		return

	if _is_displacement_ability(ability_id):
		var displacement = readiness * clampf(
			0.25 + projected_access * 0.75,
			0.0,
			1.0
		)
		result["displacement_threat"] = displacement
		result["bypass_threat"] = displacement * 0.58
		_set_primary(result, THREAT_DISPLACEMENT, displacement)
		return

	if _is_defensive_stop_ability(ability_id):
		var stop = readiness * clampf(
			0.35 + player_goal_closeness * 0.65,
			0.0,
			1.0
		)
		result["defensive_stop_threat"] = stop
		_set_primary(result, THREAT_DEFENSIVE_STOP, stop)
		return

	if ability_id == ABILITY_META_VISION:
		result["uncertainty"] = readiness * 0.38
		return

	if ability_id == ABILITY_COPYCAT:
		var copied_id = int(player.get("server_last_used_ability_id"))
		result["uncertainty"] = readiness * 0.72
		if copied_id > ABILITY_NONE and copied_id != ABILITY_COPYCAT:
			result["active_ability_id"] = copied_id
			result["uncertainty"] = readiness * 0.42
			_apply_ability_threat(
				result,
				player,
				copied_id,
				readiness * 0.88,
				commitment,
				projected_access,
				access,
				goal_closeness,
				player_goal_closeness
			)


static func _empty_team_result(has, ready, active, details) -> Dictionary:
	return {
		"goal_threat": 0.0,
		"counter_threat": 0.0,
		"power_shot_threat": 0.0,
		"curve_shot_threat": 0.0,
		"speed_break_threat": 0.0,
		"bypass_threat": 0.0,
		"combination_threat": 0.0,
		"first_time_finish_threat": 0.0,
		"displacement_threat": 0.0,
		"defensive_stop_threat": 0.0,
		"uncertainty": 0.0,
		"primary_threat": THREAT_NONE,
		"primary_peer_id": 0,
		"primary_ability_id": ABILITY_NONE,
		"primary_score": 0.0,
		"primary_position": Vector2.ZERO,
		"primary_ball_arrival": 3.0,
		"has": has,
		"ready": ready,
		"active": active,
		"players": details
	}


static func _empty_player_result(
	player,
	ability_id,
	active_id,
	ready,
	active,
	kick_ready,
	charging,
	position,
	velocity,
	ball_arrival,
	projected_access,
	direct_access,
	incoming_pass_access,
	goal_closeness
) -> Dictionary:
	return {
		"peer_id": int(player.get("owner_peer_id")),
		"ability_id": ability_id,
		"active_ability_id": active_id,
		"ready": ready,
		"active": active,
		"kick_ready": kick_ready,
		"charging": charging,
		"position": position,
		"velocity": velocity,
		"ball_arrival": clampf(float(ball_arrival), 0.0, 3.0),
		"access": projected_access,
		"direct_access": direct_access,
		"incoming_pass_access": incoming_pass_access,
		"goal_closeness": goal_closeness,
		"goal_threat": 0.0,
		"counter_threat": 0.0,
		"power_shot_threat": 0.0,
		"curve_shot_threat": 0.0,
		"speed_break_threat": 0.0,
		"bypass_threat": 0.0,
		"combination_threat": 0.0,
		"first_time_finish_threat": 0.0,
		"displacement_threat": 0.0,
		"defensive_stop_threat": 0.0,
		"uncertainty": 0.0,
		"primary_threat": THREAT_NONE,
		"primary_score": 0.0
	}


static func _incoming_pass_access(position, ball_position, ball_velocity):
	var incoming_speed = ball_velocity.length()
	var ball_distance = position.distance_to(ball_position)
	if incoming_speed < 420.0 or ball_distance <= 1.0:
		return 0.0
	var alignment = ball_velocity.normalized().dot(
		ball_position.direction_to(position)
	)
	if alignment < 0.55:
		return 0.0
	var travel_seconds = ball_distance / incoming_speed
	return clampf(
		1.0 - travel_seconds / 1.55,
		0.0,
		1.0
	) * clampf(
		(alignment - 0.45) / 0.55,
		0.0,
		1.0
	)


static func _merge_maximum(target, source, key):
	target[key] = maxf(
		float(target.get(key, 0.0)),
		float(source.get(key, 0.0))
	)


static func _set_primary(result, threat, score):
	if float(score) <= float(result.get("primary_score", 0.0)):
		return
	result["primary_score"] = clampf(float(score), 0.0, 1.0)
	result["primary_threat"] = threat


static func _safe_vector2(value):
	if value is Vector2:
		return value
	return Vector2.ZERO


static func _charging_bonus(charging):
	if bool(charging):
		return 0.12
	return 0.0


static func _is_bypass_ability(ability_id):
	return (
		ability_id == ABILITY_BURST_DRIBBLE
		or ability_id == ABILITY_ELASTIC_STEP
		or ability_id == ABILITY_BLIND_SPOT
	)


static func _is_displacement_ability(ability_id):
	return (
		ability_id == ABILITY_ENFORCER
		or ability_id == ABILITY_BOOGIE_WOOGIE
	)


static func _is_defensive_stop_ability(ability_id):
	return (
		ability_id == ABILITY_GOALKEEPER_REACH
		or ability_id == ABILITY_REFLEX_BLOCK
		or ability_id == ABILITY_IRON_ANCHOR
		or ability_id == ABILITY_ECHO
	)
