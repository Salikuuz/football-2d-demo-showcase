extends Node2D

@export var lifetime_seconds: float = 0.18
@export var minimum_radius: float = 34.0
@export var maximum_radius: float = 78.0

var _color: Color = Color.WHITE
var _direction: Vector2 = Vector2.RIGHT
var _strength: float = 0.5
var _elapsed: float = 0.0


func setup(
	color: Color,
	direction: Vector2,
	strength: float
) -> void:
	_color = color
	_direction = (
		direction.normalized()
		if direction.length_squared() > 0.001
		else Vector2.RIGHT
	)
	_strength = clampf(strength, 0.0, 1.0)
	queue_redraw()


func _process(delta: float) -> void:
	_elapsed += maxf(0.0, delta)
	if _elapsed >= maxf(0.01, lifetime_seconds):
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var duration: float = maxf(0.01, lifetime_seconds)
	var progress: float = clampf(_elapsed / duration, 0.0, 1.0)
	var fade: float = 1.0 - progress
	var eased: float = 1.0 - pow(1.0 - progress, 2.0)
	var radius: float = lerpf(
		minimum_radius,
		maximum_radius,
		_strength
	) * lerpf(0.66, 1.12, eased)
	var direction_angle: float = _direction.angle()
	var tangent: Vector2 = _direction.orthogonal()

	# Tight crescents read as a precise impact without covering the pitch.
	var arc_color: Color = _color
	arc_color.a = 0.82 * fade
	draw_arc(
		Vector2.ZERO,
		radius,
		direction_angle - 0.74,
		direction_angle + 0.74,
		14,
		arc_color,
		lerpf(3.0, 6.5, _strength),
		true
	)
	var inner_color: Color = Color.WHITE
	inner_color.a = 0.72 * fade
	draw_arc(
		Vector2.ZERO,
		radius * 0.72,
		direction_angle - 0.42,
		direction_angle + 0.42,
		9,
		inner_color,
		lerpf(1.5, 3.2, _strength),
		true
	)

	# Deterministic shards keep the effect crisp and replay-safe.
	var shard_color: Color = _color.lightened(0.24)
	shard_color.a = 0.9 * fade
	for index: int in range(5):
		var lateral: float = float(index - 2) * radius * 0.18
		var start: Vector2 = _direction * radius * 0.42 + tangent * lateral
		var end: Vector2 = (
			_direction * radius * (0.78 + float(index % 2) * 0.16)
			+ tangent * lateral * 1.22
		)
		draw_line(
			start,
			end,
			shard_color,
			lerpf(1.5, 3.2, _strength),
			true
		)

	var core_color: Color = Color.WHITE
	core_color.a = 0.85 * fade
	draw_circle(
		_direction * radius * 0.24,
		lerpf(3.0, 7.0, _strength) * fade,
		core_color
	)
