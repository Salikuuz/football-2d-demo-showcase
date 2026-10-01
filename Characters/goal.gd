class_name FootballGoal
extends Area2D

@export_enum("red", "blue")
var defending_team: String = "red"
@export_category("Meta Vision Warning")
@export var meta_vision_danger_color: Color = Color(
	1.0, 0.08, 0.12, 1.0
)
@export var meta_vision_danger_outline_width: float = 22.0
@export var meta_vision_danger_outline_padding: float = 34.0

signal goal_scored(scoring_team: String)

@onready var meta_vision_danger_outline: Line2D = (
	$MetaVisionDangerOutline
)
@onready var goal_frame: Sprite2D = $GoalFrame
@onready var top_post_glow: Sprite2D = $TopPostGlow
@onready var bottom_post_glow: Sprite2D = $BottomPostGlow

var _default_collision_size: Vector2 = Vector2.ZERO


func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	_apply_goal_visuals()
	_capture_default_collision_size()
	_prepare_meta_vision_danger_outline()


func _capture_default_collision_size() -> void:
	var collision_shape := get_node_or_null(
		"CollisionShape2D"
	) as CollisionShape2D
	if collision_shape != null and collision_shape.shape is RectangleShape2D:
		_default_collision_size = (collision_shape.shape as RectangleShape2D).size


func set_mouth_scale(scale_factor: float) -> void:
	var collision_shape := get_node_or_null(
		"CollisionShape2D"
	) as CollisionShape2D
	if collision_shape == null or collision_shape.shape is not RectangleShape2D:
		return
	if _default_collision_size == Vector2.ZERO:
		_capture_default_collision_size()
	if _default_collision_size == Vector2.ZERO:
		return
	collision_shape.shape = collision_shape.shape.duplicate(true)
	var rectangle := collision_shape.shape as RectangleShape2D
	rectangle.size = Vector2(
		_default_collision_size.x,
		_default_collision_size.y * clampf(scale_factor, 0.4, 1.0)
	)
	_prepare_meta_vision_danger_outline()


func _apply_goal_visuals() -> void:
	var team_color := (
		Color(0.12, 0.5, 1.0, 0.72)
		if defending_team == "blue"
		else Color(1.0, 0.12, 0.18, 0.72)
	)
	goal_frame.flip_h = defending_team == "red"
	top_post_glow.modulate = team_color
	bottom_post_glow.modulate = team_color


func _on_body_entered(body: Node2D) -> void:
	print(name, " detected: ", body.name)

	if body is not FootballBall:
		return

	var scoring_team := "blue" if defending_team == "red" else "red"

	print("GOAL FOR ", scoring_team)
	goal_scored.emit(scoring_team)


func get_goal_plane_x() -> float:
	var collision_shape := get_node_or_null(
		"CollisionShape2D"
	) as CollisionShape2D
	if collision_shape == null:
		return global_position.x
	return collision_shape.global_position.x


func get_mouth_y_range() -> Vector2:
	var collision_shape := get_node_or_null(
		"CollisionShape2D"
	) as CollisionShape2D
	if (
		collision_shape == null
		or collision_shape.shape is not RectangleShape2D
	):
		return Vector2(
			global_position.y - 772.5,
			global_position.y + 772.5
		)

	var rectangle := collision_shape.shape as RectangleShape2D
	var half_height := (
		rectangle.size.y
		* absf(collision_shape.global_scale.y)
		* 0.5
	)
	return Vector2(
		collision_shape.global_position.y - half_height,
		collision_shape.global_position.y + half_height
	)


func _prepare_meta_vision_danger_outline() -> void:
	if meta_vision_danger_outline == null:
		return
	var collision_shape := get_node_or_null(
		"CollisionShape2D"
	) as CollisionShape2D
	if (
		collision_shape == null
		or collision_shape.shape is not RectangleShape2D
	):
		meta_vision_danger_outline.hide()
		return

	var rectangle := collision_shape.shape as RectangleShape2D
	var padding := maxf(0.0, meta_vision_danger_outline_padding)
	var half_size := rectangle.size * 0.5 + Vector2.ONE * padding
	var center := collision_shape.position
	meta_vision_danger_outline.clear_points()
	for point in [
		center + Vector2(-half_size.x, -half_size.y),
		center + Vector2(half_size.x, -half_size.y),
		center + Vector2(half_size.x, half_size.y),
		center + Vector2(-half_size.x, half_size.y),
		center + Vector2(-half_size.x, -half_size.y)
	]:
		meta_vision_danger_outline.add_point(point)
	meta_vision_danger_outline.width = maxf(
		1.0,
		meta_vision_danger_outline_width
	)
	meta_vision_danger_outline.default_color = (
		meta_vision_danger_color
	)
	meta_vision_danger_outline.hide()


func set_meta_vision_danger_visible(enabled: bool) -> void:
	if meta_vision_danger_outline == null:
		return
	meta_vision_danger_outline.visible = enabled
	if not enabled:
		return
	var pulse := (
		sin(float(Time.get_ticks_msec()) * 0.018) * 0.5 + 0.5
	)
	meta_vision_danger_outline.modulate.a = lerpf(
		0.35,
		1.0,
		pulse
	)
