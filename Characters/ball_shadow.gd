extends Node2D


@export var shadow_offset: Vector2 = Vector2(7.0, 26.0)
@export var base_radius: float = 47.0
@export var base_scale: Vector2 = Vector2(1.25, 0.42)
@export var moving_scale_bonus: float = 0.18
@export var full_speed: float = 7000.0

var _ball: FootballBall
var _ball_sprite: Sprite2D
var _size_multiplier: float = 1.0


func _ready() -> void:
	_ball = get_parent() as FootballBall
	if _ball != null:
		_ball_sprite = _ball.get_node_or_null("Ball") as Sprite2D
	top_level = true
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	z_as_relative = false
	z_index = 0
	queue_redraw()


func _physics_process(_delta: float) -> void:
	if _ball == null or not is_instance_valid(_ball):
		queue_free()
		return

	visible = _ball_sprite == null or _ball_sprite.visible
	if not visible:
		return

	global_position = _ball.global_position + shadow_offset * _size_multiplier
	global_rotation = 0.0
	var speed_ratio := clampf(
		_ball.linear_velocity.length() / maxf(1.0, full_speed),
		0.0,
		1.0
	)
	scale = Vector2(
		base_scale.x + speed_ratio * moving_scale_bonus,
		base_scale.y - speed_ratio * 0.06
	) * _size_multiplier
	modulate.a = lerpf(0.72, 0.46, speed_ratio)


func set_ball_size_multiplier(multiplier: float) -> void:
	_size_multiplier = clampf(multiplier, 1.0, 2.0)


func _draw() -> void:
	draw_circle(
		Vector2(5.0, 4.0),
		base_radius + 10.0,
		Color(0.0, 0.015, 0.025, 0.12)
	)
	draw_circle(
		Vector2.ZERO,
		base_radius,
		Color(0.0, 0.01, 0.02, 0.32)
	)
	draw_circle(
		Vector2(-6.0, -4.0),
		base_radius * 0.62,
		Color(0.0, 0.01, 0.02, 0.2)
	)
