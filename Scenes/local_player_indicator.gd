extends Node2D


@export var base_radius: float = 151.0
@export var pulse_radius: float = 7.0
@export var ring_width: float = 7.0
@export var chevron_offset: float = 30.0
@export var pulse_speed: float = 2.25

var _player: FootballPlayer
var _phase: float = 0.0


func _ready() -> void:
	_player = get_parent() as FootballPlayer
	show_behind_parent = true
	if _player == null or _player.cpu_controlled:
		hide()
		set_process(false)




func _physical_pixels_per_world_unit() -> float:
	if not is_inside_tree():
		return 1.0
	var transform := get_global_transform_with_canvas()
	var logical_scale := maxf(
		0.001,
		(transform.x.length() + transform.y.length()) * 0.5
	)
	var viewport := get_viewport()
	var window := get_window()
	if viewport == null or window == null:
		return logical_scale
	var logical_size := viewport.get_visible_rect().size
	var physical_size := Vector2(window.size)
	if logical_size.x <= 0.0 or logical_size.y <= 0.0:
		return logical_scale
	var presentation_scale := minf(
		physical_size.x / logical_size.x,
		physical_size.y / logical_size.y
	)
	return maxf(0.001, logical_scale * presentation_scale)


func _safe_stroke_width(world_width: float, minimum_physical_pixels: float = 1.80) -> float:
	return maxf(
		world_width,
		minimum_physical_pixels / _physical_pixels_per_world_unit()
	)

func _process(delta: float) -> void:
	if _player == null:
		hide()
		return

	var is_local := (
		not _player.cpu_controlled
		and _player.team != &""
		and multiplayer.get_unique_id() == _player.owner_peer_id
	)
	visible = is_local
	if not is_local:
		return

	_phase = fmod(_phase + delta * pulse_speed, TAU)
	queue_redraw()


func _draw() -> void:
	if _player == null:
		return

	var team_color := Color(0.7, 0.82, 1.0, 1.0)
	if _player.team == &"red":
		team_color = Color(1.0, 0.32, 0.38, 1.0)
	elif _player.team == &"blue":
		team_color = Color(0.28, 0.64, 1.0, 1.0)

	var pulse := (sin(_phase) + 1.0) * 0.5
	var radius := base_radius + pulse * pulse_radius
	var white := Color(0.96, 0.99, 1.0, 0.74 + pulse * 0.16)
	var accent := Color(team_color, 0.48 + pulse * 0.2)

	draw_arc(
		Vector2.ZERO,
		radius + 7.0,
		0.0,
		TAU,
		72,
		Color(0.0, 0.02, 0.05, 0.36),
		_safe_stroke_width(ring_width + 8.0),
		true
	)

	for segment in range(4):
		var start_angle := float(segment) * PI * 0.5 + 0.16
		var end_angle := start_angle + PI * 0.5 - 0.32
		draw_arc(
			Vector2.ZERO,
			radius,
			start_angle,
			end_angle,
			20,
			white,
			_safe_stroke_width(ring_width),
			true
		)

	draw_arc(
		Vector2.ZERO,
		radius - 10.0,
		PI * 1.06,
		PI * 1.94,
		32,
		accent,
		_safe_stroke_width(4.0),
		true
	)

	var tip_y := -radius - chevron_offset
	var chevron := PackedVector2Array([
		Vector2(0.0, tip_y + 20.0),
		Vector2(-20.0, tip_y - 7.0),
		Vector2(20.0, tip_y - 7.0)
	])
	draw_colored_polygon(chevron, white)
	draw_polyline(
		PackedVector2Array([
			Vector2(-20.0, tip_y - 7.0),
			Vector2(0.0, tip_y + 20.0),
			Vector2(20.0, tip_y - 7.0)
		]),
		accent,
		_safe_stroke_width(5.0),
		true
	)
