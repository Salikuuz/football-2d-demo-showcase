class_name HybridBallTrajectoryPredictor
extends RefCounted


static func predict(
	position: Vector2,
	velocity: Vector2,
	bounds: Rect2,
	seconds: float,
	step_seconds: float = 1.0 / 60.0,
	linear_damp: float = 0.55,
	bounce: float = 0.8
) -> PackedVector2Array:
	var points := PackedVector2Array([position])
	var simulated_position := position
	var simulated_velocity := velocity
	var duration := maxf(0.0, seconds)
	var step := clampf(step_seconds, 1.0 / 240.0, 1.0 / 20.0)
	var steps := ceili(duration / step)
	for index in range(steps):
		var actual_step := minf(step, duration - float(index) * step)
		if actual_step <= 0.0:
			break
		# Godot's linear damping is exponential in continuous time. This keeps
		# prediction consistent when the fixed physics rate changes.
		var damping_factor := exp(-maxf(0.0, linear_damp) * actual_step)
		simulated_velocity *= damping_factor
		simulated_position += simulated_velocity * actual_step
		if simulated_position.x < bounds.position.x:
			simulated_position.x = bounds.position.x + (bounds.position.x - simulated_position.x)
			simulated_velocity.x = absf(simulated_velocity.x) * bounce
		elif simulated_position.x > bounds.end.x:
			simulated_position.x = bounds.end.x - (simulated_position.x - bounds.end.x)
			simulated_velocity.x = -absf(simulated_velocity.x) * bounce
		if simulated_position.y < bounds.position.y:
			simulated_position.y = bounds.position.y + (bounds.position.y - simulated_position.y)
			simulated_velocity.y = absf(simulated_velocity.y) * bounce
		elif simulated_position.y > bounds.end.y:
			simulated_position.y = bounds.end.y - (simulated_position.y - bounds.end.y)
			simulated_velocity.y = -absf(simulated_velocity.y) * bounce
		points.append(simulated_position)
	return points


static func estimate_arrival_time(
	actor_position: Vector2,
	actor_velocity: Vector2,
	target_position: Vector2,
	maximum_speed: float,
	acceleration: float
) -> float:
	var displacement := actor_position.distance_to(target_position)
	if displacement <= 1.0:
		return 0.0
	var speed_toward := maxf(
		0.0,
		actor_velocity.dot(actor_position.direction_to(target_position))
	)
	var safe_acceleration := maxf(1.0, acceleration)
	var safe_maximum_speed := maxf(1.0, maximum_speed)
	var acceleration_time := maxf(0.0, (safe_maximum_speed - speed_toward) / safe_acceleration)
	var acceleration_distance := (
		speed_toward * acceleration_time
		+ 0.5 * safe_acceleration * acceleration_time * acceleration_time
	)
	if displacement <= acceleration_distance:
		return (
			-speed_toward
			+ sqrt(maxf(0.0, speed_toward * speed_toward + 2.0 * safe_acceleration * displacement))
		) / safe_acceleration
	return acceleration_time + (displacement - acceleration_distance) / safe_maximum_speed


static func earliest_intercept(
	actor_position: Vector2,
	actor_velocity: Vector2,
	maximum_speed: float,
	acceleration: float,
	trajectory: PackedVector2Array,
	step_seconds: float
) -> Dictionary:
	for index in range(trajectory.size()):
		var target := trajectory[index]
		var ball_time := float(index) * step_seconds
		var actor_time := estimate_arrival_time(
			actor_position,
			actor_velocity,
			target,
			maximum_speed,
			acceleration
		)
		if actor_time <= ball_time + 0.08:
			return {
				"available": true,
				"position": target,
				"ball_time": ball_time,
				"actor_time": actor_time,
				"index": index
			}
	return {"available": false}
