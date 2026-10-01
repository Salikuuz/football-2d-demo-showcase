class_name FootballDecoyRunAfterimage
extends Node2D

var velocity: Vector2 = Vector2.ZERO
var duration: float = 1.0
var elapsed: float = 0.0
var team_color: Color = Color.WHITE


func setup(
	start_position: Vector2,
	movement_velocity: Vector2,
	lifetime: float,
	color: Color
) -> void:
	top_level = true
	global_position = start_position
	velocity = movement_velocity
	duration = maxf(0.1, lifetime)
	team_color = color
	queue_redraw()


func _process(delta: float) -> void:
	elapsed += delta
	global_position += velocity * delta
	var ratio: float = clampf(elapsed / duration, 0.0, 1.0)
	velocity *= pow(0.22, delta / duration)
	modulate.a = 1.0 - ratio
	queue_redraw()
	if elapsed >= duration:
		queue_free()


func _draw() -> void:
	var fade: float = 1.0 - clampf(elapsed / duration, 0.0, 1.0)
	var ghost_fill := Color(team_color, 0.22 * fade)
	var ghost_rim := Color(team_color.lightened(0.35), 0.72 * fade)
	draw_circle(Vector2.ZERO, 72.0, ghost_fill)
	draw_arc(Vector2.ZERO, 78.0, 0.0, TAU, 48, ghost_rim, 9.0, true)
	draw_arc(Vector2.ZERO, 57.0, 0.0, TAU, 40, Color.WHITE * Color(1, 1, 1, 0.30 * fade), 3.0, true)
	var trail_direction: Vector2 = -velocity.normalized()
	if not trail_direction.is_zero_approx():
		for index: int in range(3):
			var distance: float = 95.0 + float(index) * 52.0
			var radius: float = 34.0 - float(index) * 7.0
			draw_circle(
				trail_direction * distance,
				radius,
				Color(team_color, (0.14 - float(index) * 0.025) * fade)
			)
