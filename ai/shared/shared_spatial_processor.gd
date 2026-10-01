class_name SharedAISpatialProcessor
extends RefCounted

# Part 2 shared spatial processor. It operates exclusively on the immutable
# plain-data world snapshot built by MatchManager, so the same distances,
# pressure queries, ball trajectory and arrival estimates can be reused by all
# CPU agents during one physics frame instead of being recomputed bot-by-bot.

const TEAM_BLUE: StringName = &"blue"
const TEAM_RED: StringName = &"red"
const DEFAULT_DUEL_STEP_SECONDS: float = 0.08
const DEFAULT_DUEL_HORIZON_SECONDS: float = 1.25
const DEFAULT_WALL_TOP_Y: float = 806.0
const DEFAULT_WALL_BOTTOM_Y: float = 4194.0
const DEFAULT_FIELD_BOUNDS := Rect2(360.0, 680.0, 6610.0, 3640.0)


static func build(world: Dictionary) -> Dictionary:
	if world.is_empty():
		return {}
	var blue_players := world.get("blue_snapshots", []) as Array
	var red_players := world.get("red_snapshots", []) as Array
	var all_players: Array = []
	all_players.append_array(blue_players)
	all_players.append_array(red_players)
	var positions_by_peer: Dictionary = {}
	var actors_by_peer: Dictionary = {}
	var pair_distance_sq: Dictionary = {}
	var nearest_opponent_by_peer: Dictionary = {}
	var nearest_teammate_by_peer: Dictionary = {}

	for actor_variant in all_players:
		var actor := actor_variant as Dictionary
		var peer_id := int(actor.get("peer_id", 0))
		if peer_id <= 0 or not bool(actor.get("enabled", false)):
			continue
		positions_by_peer[peer_id] = actor.get("position", Vector2.ZERO)
		actors_by_peer[peer_id] = actor

	# O(n²) once for the whole 12-player frame is much cheaper than dozens of
	# individual O(n) scans in every bot. The matrix also feeds marking/pressure
	# queries without touching Nodes or the SceneTree.
	for actor_variant in all_players:
		var actor := actor_variant as Dictionary
		var peer_id := int(actor.get("peer_id", 0))
		if peer_id <= 0 or not bool(actor.get("enabled", false)):
			continue
		var actor_team := StringName(actor.get("team", &""))
		var actor_position: Vector2 = actor.get("position", Vector2.ZERO)
		var row: Dictionary = {}
		var nearest_opponent_peer := 0
		var nearest_opponent_distance_sq := INF
		var nearest_teammate_peer := 0
		var nearest_teammate_distance_sq := INF
		for other_variant in all_players:
			var other := other_variant as Dictionary
			var other_peer := int(other.get("peer_id", 0))
			if (
				other_peer <= 0
				or other_peer == peer_id
				or not bool(other.get("enabled", false))
			):
				continue
			var distance_sq := actor_position.distance_squared_to(
				other.get("position", Vector2.ZERO) as Vector2
			)
			row[other_peer] = distance_sq
			if StringName(other.get("team", &"")) == actor_team:
				if distance_sq < nearest_teammate_distance_sq:
					nearest_teammate_distance_sq = distance_sq
					nearest_teammate_peer = other_peer
			else:
				if distance_sq < nearest_opponent_distance_sq:
					nearest_opponent_distance_sq = distance_sq
					nearest_opponent_peer = other_peer
		pair_distance_sq[peer_id] = row
		nearest_opponent_by_peer[peer_id] = {
			"peer_id": nearest_opponent_peer,
			"distance": sqrt(nearest_opponent_distance_sq)
				if is_finite(nearest_opponent_distance_sq)
				else INF,
		}
		nearest_teammate_by_peer[peer_id] = {
			"peer_id": nearest_teammate_peer,
			"distance": sqrt(nearest_teammate_distance_sq)
				if is_finite(nearest_teammate_distance_sq)
				else INF,
		}

	var spatial := {
		"physics_frame": int(world.get("physics_frame", -1)),
		"actors_by_peer": actors_by_peer,
		"positions_by_peer": positions_by_peer,
		"blue_players": blue_players,
		"red_players": red_players,
		"pair_distance_sq": pair_distance_sq,
		"nearest_opponent_by_peer": nearest_opponent_by_peer,
		"nearest_teammate_by_peer": nearest_teammate_by_peer,
		# Exact Vector2 query caches. These preserve gameplay semantics; no grid
		# approximation is used. Common targets such as the ball, pass receiver and
		# support points are consequently scanned once and then shared by all bots.
		"blue_pressure_cache": {},
		"red_pressure_cache": {},
		"blue_nearest_peer_cache": {},
		"red_nearest_peer_cache": {},
		"arrival_cache": {},
		"duel_cache": {},
		"field_bounds": world.get("ai_field_bounds", DEFAULT_FIELD_BOUNDS),
		"wall_top_y": float(world.get("ball_wall_top_y", DEFAULT_WALL_TOP_Y)),
		"wall_bottom_y": float(world.get("ball_wall_bottom_y", DEFAULT_WALL_BOTTOM_Y)),
		"duel_step_seconds": DEFAULT_DUEL_STEP_SECONDS,
		"duel_horizon_seconds": DEFAULT_DUEL_HORIZON_SECONDS,
	}
	# Trajectory geometry itself is cheap and universally shared. Arrival-time
	# solving is deliberately lazy: eagerly solving 12 players x every trajectory
	# sample each 60 Hz frame costs more than the duplicated work it replaces.
	# The exact arrival queries below are cached only when a tactical branch needs
	# them, then reused by the rest of the team for the current frame.
	spatial["ball_trajectory"] = _build_ball_trajectory(world, spatial)

	# Prime the most common pressure query immediately.
	var ball_position: Vector2 = world.get("ball_position", Vector2.ZERO)
	query_nearest_opponent(spatial, TEAM_BLUE, ball_position)
	query_nearest_opponent(spatial, TEAM_RED, ball_position)
	return spatial


static func query_pair_distance(
	spatial: Dictionary,
	first_peer_id: int,
	second_peer_id: int
) -> float:
	if first_peer_id <= 0 or second_peer_id <= 0:
		return INF
	if first_peer_id == second_peer_id:
		return 0.0
	var rows := spatial.get("pair_distance_sq", {}) as Dictionary
	var row := rows.get(first_peer_id, {}) as Dictionary
	var distance_sq := float(row.get(second_peer_id, INF))
	return sqrt(distance_sq) if is_finite(distance_sq) else INF


static func query_nearest_opponent(
	spatial: Dictionary,
	team: StringName,
	position: Vector2
) -> Dictionary:
	if spatial.is_empty() or team not in [TEAM_BLUE, TEAM_RED]:
		return {"peer_id": 0, "distance": INF}
	var cache_key := "blue_pressure_cache" if team == TEAM_BLUE else "red_pressure_cache"
	var peer_cache_key := "blue_nearest_peer_cache" if team == TEAM_BLUE else "red_nearest_peer_cache"
	var distance_cache := spatial.get(cache_key, {}) as Dictionary
	var peer_cache := spatial.get(peer_cache_key, {}) as Dictionary
	if distance_cache.has(position):
		return {
			"peer_id": int(peer_cache.get(position, 0)),
			"distance": float(distance_cache.get(position, INF)),
		}
	var opponents := (
		spatial.get("red_players", []) as Array
		if team == TEAM_BLUE
		else spatial.get("blue_players", []) as Array
	)
	var nearest_peer := 0
	var nearest_distance_sq := INF
	for opponent_variant in opponents:
		var opponent := opponent_variant as Dictionary
		if not bool(opponent.get("enabled", false)):
			continue
		var distance_sq := position.distance_squared_to(
			opponent.get("position", Vector2.ZERO) as Vector2
		)
		if distance_sq < nearest_distance_sq:
			nearest_distance_sq = distance_sq
			nearest_peer = int(opponent.get("peer_id", 0))
	var nearest_distance := (
		sqrt(nearest_distance_sq) if is_finite(nearest_distance_sq) else INF
	)
	distance_cache[position] = nearest_distance
	peer_cache[position] = nearest_peer
	return {"peer_id": nearest_peer, "distance": nearest_distance}


static func query_player_arrival_seconds(
	spatial: Dictionary,
	peer_id: int,
	target: Vector2,
	high_seconds: float = 2.05
) -> float:
	if spatial.is_empty() or peer_id <= 0:
		return INF
	var actor := (spatial.get("actors_by_peer", {}) as Dictionary).get(peer_id, {}) as Dictionary
	if actor.is_empty():
		return INF
	var cache := spatial.get("arrival_cache", {}) as Dictionary
	var peer_cache := cache.get(peer_id, {}) as Dictionary
	# Vector3 preserves the exact target coordinates plus the search horizon, so
	# this cache does not change arrival math or quantize gameplay positions.
	var key := Vector3(target.x, target.y, high_seconds)
	if peer_cache.has(key):
		return float(peer_cache.get(key, INF))
	var result := _estimate_actor_arrival_seconds(actor, target, high_seconds)
	peer_cache[key] = result
	cache[peer_id] = peer_cache
	return result


static func query_duel_interception(
	spatial: Dictionary,
	own_peer_id: int,
	opponent_peer_id: int
) -> Dictionary:
	if spatial.is_empty() or own_peer_id <= 0 or opponent_peer_id <= 0:
		return {}
	var cache := spatial.get("duel_cache", {}) as Dictionary
	var cache_key := Vector2i(own_peer_id, opponent_peer_id)
	if cache.has(cache_key):
		return cache.get(cache_key, {}) as Dictionary
	var trajectory := spatial.get("ball_trajectory", []) as Array
	if trajectory.is_empty():
		return {}
	var high_seconds := maxf(1.8, DEFAULT_DUEL_HORIZON_SECONDS + 0.8)
	var best: Dictionary = {}
	for index in range(trajectory.size()):
		var sample := trajectory[index] as Dictionary
		var sample_position: Vector2 = sample.get("position", Vector2.ZERO)
		var own_arrival := query_player_arrival_seconds(
			spatial, own_peer_id, sample_position, high_seconds
		)
		var opponent_arrival := query_player_arrival_seconds(
			spatial, opponent_peer_id, sample_position, high_seconds
		)
		best = {
			"position": sample_position,
			"ball_arrival": float(sample.get("seconds", 0.0)),
			"own_arrival": own_arrival,
			"opponent_arrival": opponent_arrival,
		}
		if index == 0:
			continue
		var elapsed := float(sample.get("seconds", 0.0))
		if minf(own_arrival, opponent_arrival) <= elapsed + 0.08:
			break
		if float(sample.get("speed", 0.0)) < 45.0:
			break
	cache[cache_key] = best
	return best


static func _build_ball_trajectory(world: Dictionary, spatial: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var position: Vector2 = world.get("ball_position", Vector2.ZERO)
	var velocity: Vector2 = world.get("ball_velocity", Vector2.ZERO)
	var damping := maxf(0.0, float(world.get("ball_linear_damp", 0.0)))
	var wall_top := float(spatial.get("wall_top_y", DEFAULT_WALL_TOP_Y))
	var wall_bottom := float(spatial.get("wall_bottom_y", DEFAULT_WALL_BOTTOM_Y))
	var bounds: Rect2 = spatial.get("field_bounds", DEFAULT_FIELD_BOUNDS) as Rect2
	var elapsed := 0.0
	var step := DEFAULT_DUEL_STEP_SECONDS
	var horizon := DEFAULT_DUEL_HORIZON_SECONDS
	result.append({"seconds": 0.0, "position": position, "velocity": velocity, "speed": velocity.length()})
	while elapsed < horizon:
		var current_step := minf(step, horizon - elapsed)
		if damping > 0.001:
			velocity *= exp(-damping * current_step)
		position += velocity * current_step
		if position.y < wall_top:
			position.y = wall_top + (wall_top - position.y)
			velocity.y = absf(velocity.y) * 0.8
		elif position.y > wall_bottom:
			position.y = wall_bottom - (position.y - wall_bottom)
			velocity.y = -absf(velocity.y) * 0.8
		position.x = clampf(position.x, bounds.position.x, bounds.end.x)
		position.y = clampf(position.y, bounds.position.y, bounds.end.y)
		elapsed += current_step
		result.append({
			"seconds": elapsed,
			"position": position,
			"velocity": velocity,
			"speed": velocity.length(),
		})
	return result




static func estimate_arrival_seconds(
	position: Vector2,
	velocity: Vector2,
	maximum_speed: float,
	acceleration: float,
	control_radius: float,
	target: Vector2,
	high_seconds: float
) -> float:
	# Exact inverse of the constant-acceleration reach equation used by the CPU
	# duel/interception model. The old code solved this with 12 binary-search
	# iterations for every player/target pair. This produces the same answer to
	# within the old solver's ~0.5 ms quantization in O(1).
	var distance := position.distance_to(target)
	var safe_control_radius := maxf(40.0, control_radius)
	if distance <= safe_control_radius:
		return 0.0
	var remaining_distance := distance - safe_control_radius
	var direction := position.direction_to(target)
	var safe_maximum_speed := maxf(0.0, maximum_speed)
	var starting_speed := maxf(0.0, velocity.dot(direction))
	starting_speed = minf(starting_speed, safe_maximum_speed)
	var safe_acceleration := maxf(0.0, acceleration)
	var safe_high := maxf(0.0, high_seconds)
	if safe_acceleration <= 0.0001:
		if starting_speed <= 0.0001:
			return safe_high
		return minf(safe_high, remaining_distance / starting_speed)
	var acceleration_time := maxf(
		0.0,
		(safe_maximum_speed - starting_speed) / safe_acceleration
	)
	var acceleration_distance := (
		starting_speed * acceleration_time
		+ 0.5 * safe_acceleration * acceleration_time * acceleration_time
	)
	var arrival_seconds: float
	if remaining_distance <= acceleration_distance:
		var discriminant := maxf(
			0.0,
			starting_speed * starting_speed
			+ 2.0 * safe_acceleration * remaining_distance
		)
		arrival_seconds = (
			sqrt(discriminant) - starting_speed
		) / safe_acceleration
	elif safe_maximum_speed > 0.0001:
		arrival_seconds = (
			acceleration_time
			+ (remaining_distance - acceleration_distance) / safe_maximum_speed
		)
	else:
		arrival_seconds = safe_high
	return clampf(arrival_seconds, 0.0, safe_high)

static func _estimate_actor_arrival_seconds(
	actor: Dictionary,
	target: Vector2,
	high_seconds: float
) -> float:
	return estimate_arrival_seconds(
		actor.get("position", Vector2.ZERO) as Vector2,
		actor.get("velocity", Vector2.ZERO) as Vector2,
		float(actor.get("max_speed", 0.0)),
		float(actor.get("acceleration", 0.0)),
		float(actor.get("control_radius", 40.0)),
		target,
		high_seconds
	)


static func _get_actor_reachable_distance(
	actor: Dictionary,
	target: Vector2,
	seconds: float
) -> float:
	var duration := maxf(0.0, seconds)
	var position: Vector2 = actor.get("position", Vector2.ZERO)
	var velocity: Vector2 = actor.get("velocity", Vector2.ZERO)
	var direction := position.direction_to(target)
	var maximum_speed := maxf(0.0, float(actor.get("max_speed", 0.0)))
	var starting_speed := maxf(0.0, velocity.dot(direction))
	starting_speed = minf(starting_speed, maximum_speed)
	var acceleration := maxf(0.0, float(actor.get("acceleration", 0.0)))
	if acceleration <= 0.0:
		return starting_speed * duration
	var acceleration_time := maxf(0.0, (maximum_speed - starting_speed) / acceleration)
	var accelerating_seconds := minf(duration, acceleration_time)
	var reachable_distance := (
		starting_speed * accelerating_seconds
		+ 0.5 * acceleration * accelerating_seconds * accelerating_seconds
	)
	reachable_distance += maximum_speed * maxf(0.0, duration - accelerating_seconds)
	return reachable_distance
