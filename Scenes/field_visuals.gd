extends Node2D


@export var playable_bounds: Rect2 = Rect2(
	318.0,
	770.0,
	6712.0,
	3460.0
)
@export var goal_mouth_y: Vector2 = Vector2(1727.5, 3272.5)
@export var blue_goal_back_x: float = -82.0
@export var red_goal_back_x: float = 7430.0
@export var line_color: Color = Color(0.9, 0.95, 0.95, 0.78)
@export var secondary_line_color: Color = Color(0.82, 0.89, 0.9, 0.56)
@export var line_shadow_color: Color = Color(0.005, 0.012, 0.016, 0.42)
@export var line_shadow_offset: Vector2 = Vector2(8.0, 10.0)
@export_range(0.0, 12.0, 0.5)
var line_shadow_width_extra: float = 6.0
@export_category("Outer Field Rim")
@export var outer_rim_shadow_color: Color = Color(0.0, 0.0, 0.0, 0.34)
@export_range(0.0, 80.0, 1.0)
var outer_rim_shadow_size: float = 72.0
@export_range(1, 8, 1)
var outer_rim_shadow_layers: int = 6
@export var blue_goal_color: Color = Color(0.18, 0.57, 1.0, 0.82)
@export var red_goal_color: Color = Color(1.0, 0.2, 0.29, 0.82)
@export_category("Clean Marking Widths")
@export_range(6.0, 24.0, 0.5)
var boundary_line_width: float = 16.0
@export_range(6.0, 20.0, 0.5)
var primary_line_width: float = 13.0
@export_range(5.0, 18.0, 0.5)
var secondary_line_width: float = 10.0
@export_range(4.0, 18.0, 0.5)
var goal_outline_width: float = 14.0
@export_category("Surface Detail")
@export_range(0.0, 0.12, 0.001)
var stripe_alpha: float = 0.011
@export_range(0.0, 0.12, 0.001)
var grain_alpha: float = 0.008
@export_range(100, 1200, 10)
var grain_count: int = 280
@export_category("Goal Presentation")
@export_range(0.0, 0.3, 0.005)
var goal_fill_alpha: float = 0.075
@export_range(0.0, 0.4, 0.005)
var goal_net_alpha: float = 0.13
@export_range(0.0, 0.5, 0.005)
var goal_shadow_alpha: float = 0.22

var _grain_positions: Array[Vector2] = []
var _grain_directions: Array[Vector2] = []
var _grain_lengths: Array[float] = []


func _ready() -> void:
	_build_grain()
	queue_redraw()


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


func _safe_stroke_width(
	world_width: float,
	minimum_physical_pixels: float = 1.45
) -> float:
	return maxf(
		world_width,
		minimum_physical_pixels / _physical_pixels_per_world_unit()
	)


func set_goal_mouth_y(value: Vector2) -> void:
	goal_mouth_y = value
	queue_redraw()


func _build_grain() -> void:
	_grain_positions.clear()
	_grain_directions.clear()
	_grain_lengths.clear()
	var random := RandomNumberGenerator.new()
	random.seed = 20260805
	var bounds := playable_bounds.abs()
	for _index in range(maxi(0, grain_count)):
		_grain_positions.append(Vector2(
			random.randf_range(bounds.position.x, bounds.end.x),
			random.randf_range(bounds.position.y, bounds.end.y)
		))
		_grain_directions.append(
			Vector2.from_angle(random.randf_range(-0.24, 0.24))
		)
		_grain_lengths.append(random.randf_range(12.0, 42.0))


func _draw() -> void:
	var bounds := playable_bounds.abs()
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		return

	# The map background is drawn by FieldVariant across the whole arena.
	# Draw only an OUTWARD shadow around the playable field before any markings.
	# This does not place a dark rectangle over the pitch itself.
	_draw_outer_rim_shadow(bounds)
	_draw_outer_boundary(bounds)
	_draw_center_markings(bounds)
	_draw_goal_areas(bounds)
	_draw_goal_extensions(bounds)
	_draw_corner_marks(bounds)


func _draw_pitch_separation(bounds: Rect2) -> void:
	# A restrained outer lip separates the pitch from the dark arena without
	# adding another bright rectangle around the field.
	draw_rect(
		bounds.grow(50.0),
		Color(0.0, 0.006, 0.01, 0.09),
		false,
		42.0,
		true
	)
	draw_rect(
		bounds.grow(20.0),
		Color(0.0, 0.008, 0.012, 0.2),
		false,
		18.0,
		true
	)
	draw_rect(
		bounds.grow(4.0),
		Color(0.09, 0.13, 0.14, 0.42),
		false,
		4.0,
		true
	)


func _draw_outer_rim_shadow(bounds: Rect2) -> void:
	if outer_rim_shadow_size <= 0.0 or outer_rim_shadow_layers <= 0:
		return

	var layers := maxi(1, outer_rim_shadow_layers)
	for layer_index in range(layers, 0, -1):
		var t := float(layer_index) / float(layers)
		var spread := outer_rim_shadow_size * t
		var thickness := outer_rim_shadow_size / float(layers) + 3.0
		var alpha: float = outer_rim_shadow_color.a * pow(1.0 - t * 0.72, 1.35)
		var shadow_color := Color(
			outer_rim_shadow_color.r,
			outer_rim_shadow_color.g,
			outer_rim_shadow_color.b,
			alpha
		)

		# Four separate strips keep the shadow outside the playable rectangle.
		draw_rect(
			Rect2(
				Vector2(bounds.position.x - spread, bounds.position.y - spread),
				Vector2(bounds.size.x + spread * 2.0, thickness)
			),
			shadow_color,
			true
		)
		draw_rect(
			Rect2(
				Vector2(bounds.position.x - spread, bounds.end.y + spread - thickness),
				Vector2(bounds.size.x + spread * 2.0, thickness)
			),
			shadow_color,
			true
		)
		draw_rect(
			Rect2(
				Vector2(bounds.position.x - spread, bounds.position.y - spread + thickness),
				Vector2(thickness, bounds.size.y + spread * 2.0 - thickness * 2.0)
			),
			shadow_color,
			true
		)
		draw_rect(
			Rect2(
				Vector2(bounds.end.x + spread - thickness, bounds.position.y - spread + thickness),
				Vector2(thickness, bounds.size.y + spread * 2.0 - thickness * 2.0)
			),
			shadow_color,
			true
		)


func _draw_surface_texture(bounds: Rect2) -> void:
	var stripe_count := 20
	var stripe_width := bounds.size.x / float(stripe_count)
	for stripe_index in range(stripe_count):
		if stripe_index % 2 != 0:
			continue
		draw_rect(
			Rect2(
				bounds.position.x + stripe_width * stripe_index,
				bounds.position.y,
				stripe_width,
				bounds.size.y
			),
			Color(0.88, 0.94, 0.96, stripe_alpha),
			true
		)

	for index in range(_grain_positions.size()):
		var position := _grain_positions[index]
		var direction := _grain_directions[index]
		var length := _grain_lengths[index]
		var alpha := grain_alpha * (0.55 if index % 3 == 0 else 1.0)
		draw_line(
			position - direction * length * 0.5,
			position + direction * length * 0.5,
			Color(0.82, 0.9, 0.93, alpha),
			_safe_stroke_width(1.5 if index % 9 == 0 else 1.0, 0.85),
			true
		)


func _draw_outer_boundary(bounds: Rect2) -> void:
	var mouth_top := clampf(
		goal_mouth_y.x,
		bounds.position.y,
		bounds.end.y
	)
	var mouth_bottom := clampf(
		goal_mouth_y.y,
		bounds.position.y,
		bounds.end.y
	)

	_draw_line_marking(
		bounds.position,
		Vector2(bounds.end.x, bounds.position.y),
		boundary_line_width,
		line_color
	)
	_draw_line_marking(
		Vector2(bounds.position.x, bounds.end.y),
		bounds.end,
		boundary_line_width,
		line_color
	)
	for x in [bounds.position.x, bounds.end.x]:
		_draw_line_marking(
			Vector2(x, bounds.position.y),
			Vector2(x, mouth_top),
			boundary_line_width,
			line_color
		)
		_draw_line_marking(
			Vector2(x, mouth_bottom),
			Vector2(x, bounds.end.y),
			boundary_line_width,
			line_color
		)


func _draw_center_markings(bounds: Rect2) -> void:
	var center := bounds.get_center()
	_draw_line_marking(
		Vector2(center.x, bounds.position.y),
		Vector2(center.x, bounds.end.y),
		primary_line_width,
		line_color
	)
	_draw_arc_marking(
		center,
		465.0,
		0.0,
		TAU,
		line_color,
		primary_line_width,
		192
	)
	draw_circle(center + line_shadow_offset * 1.35, 24.0, Color(0.0, 0.0, 0.0, 0.20))
	draw_circle(center + line_shadow_offset, 18.0, line_shadow_color)
	draw_circle(center, 15.0, Color(line_color, 0.9))
	draw_circle(center, 7.0, Color(1.0, 1.0, 1.0, 0.92))


func _draw_goal_areas(bounds: Rect2) -> void:
	var center_y := bounds.get_center().y
	var penalty_half_height := 1025.0
	var goal_area_half_height := 535.0
	var penalty_depth := 1045.0
	var goal_area_depth := 395.0
	var penalty_spot_distance := 715.0

	_draw_open_box(
		bounds.position.x,
		bounds.position.x + penalty_depth,
		center_y - penalty_half_height,
		center_y + penalty_half_height,
		line_color,
		primary_line_width
	)
	_draw_open_box(
		bounds.end.x,
		bounds.end.x - penalty_depth,
		center_y - penalty_half_height,
		center_y + penalty_half_height,
		line_color,
		primary_line_width
	)
	_draw_open_box(
		bounds.position.x,
		bounds.position.x + goal_area_depth,
		center_y - goal_area_half_height,
		center_y + goal_area_half_height,
		secondary_line_color,
		secondary_line_width
	)
	_draw_open_box(
		bounds.end.x,
		bounds.end.x - goal_area_depth,
		center_y - goal_area_half_height,
		center_y + goal_area_half_height,
		secondary_line_color,
		secondary_line_width
	)

	var left_spot := Vector2(
		bounds.position.x + penalty_spot_distance,
		center_y
	)
	var right_spot := Vector2(
		bounds.end.x - penalty_spot_distance,
		center_y
	)
	draw_circle(left_spot + line_shadow_offset * 1.35, 18.0, Color(0.0, 0.0, 0.0, 0.20))
	draw_circle(right_spot + line_shadow_offset * 1.35, 18.0, Color(0.0, 0.0, 0.0, 0.20))
	draw_circle(left_spot + line_shadow_offset, 13.0, line_shadow_color)
	draw_circle(right_spot + line_shadow_offset, 13.0, line_shadow_color)
	draw_circle(left_spot, 10.0, Color(line_color, 0.82))
	draw_circle(right_spot, 10.0, Color(line_color, 0.82))


func _draw_goal_extensions(bounds: Rect2) -> void:
	var mouth_top := goal_mouth_y.x
	var mouth_bottom := goal_mouth_y.y
	var left_back := minf(blue_goal_back_x, bounds.position.x - 80.0)
	var right_back := maxf(red_goal_back_x, bounds.end.x + 80.0)

	_draw_goal_cage(
		bounds.position.x,
		left_back,
		mouth_top,
		mouth_bottom,
		blue_goal_color
	)
	_draw_goal_cage(
		bounds.end.x,
		right_back,
		mouth_top,
		mouth_bottom,
		red_goal_color
	)


func _draw_goal_cage(
	front_x: float,
	back_x: float,
	mouth_top: float,
	mouth_bottom: float,
	team_color: Color
) -> void:
	var back_inset := minf(36.0, (mouth_bottom - mouth_top) * 0.04)
	var front_top := Vector2(front_x, mouth_top)
	var front_bottom := Vector2(front_x, mouth_bottom)
	var back_top := Vector2(back_x, mouth_top + back_inset)
	var back_bottom := Vector2(back_x, mouth_bottom - back_inset)
	var cage := PackedVector2Array([
		front_top,
		back_top,
		back_bottom,
		front_bottom
	])
	var broad_shadow := PackedVector2Array()
	var shadow := PackedVector2Array()
	for point in cage:
		broad_shadow.append(point + Vector2(13.0, 17.0))
		shadow.append(point + Vector2(8.0, 11.0))
	draw_colored_polygon(
		broad_shadow,
		Color(0.0, 0.0, 0.0, 0.16)
	)
	draw_colored_polygon(
		shadow,
		Color(0.0, 0.005, 0.008, goal_shadow_alpha)
	)
	draw_colored_polygon(
		cage,
		Color(
			team_color.r * 0.35,
			team_color.g * 0.35,
			team_color.b * 0.35,
			goal_fill_alpha
		)
	)

	_draw_goal_net(
		front_top,
		front_bottom,
		back_top,
		back_bottom,
		team_color
	)

	var frame_color := Color(team_color, 0.78)
	var frame_highlight := Color(
		minf(team_color.r + 0.28, 1.0),
		minf(team_color.g + 0.28, 1.0),
		minf(team_color.b + 0.28, 1.0),
		0.66
	)
	for segment in [
		[front_top, back_top],
		[back_top, back_bottom],
		[back_bottom, front_bottom]
	]:
		draw_line(
			segment[0] + Vector2(11.0, 14.0),
			segment[1] + Vector2(11.0, 14.0),
			Color(0.0, 0.0, 0.0, 0.20),
			goal_outline_width + 12.0,
			true
		)
		draw_line(
			segment[0] + Vector2(7.0, 9.0),
			segment[1] + Vector2(7.0, 9.0),
			Color(0.0, 0.0, 0.0, 0.32),
			goal_outline_width + 6.0,
			true
		)
		draw_line(
			segment[0],
			segment[1],
			frame_color,
			goal_outline_width,
			true
		)
		draw_line(
			segment[0],
			segment[1],
			frame_highlight,
			_safe_stroke_width(3.0, 1.65),
			true
		)

	var cage_direction := signf(back_x - front_x)
	for post in [front_top, front_bottom]:
		draw_circle(post + Vector2(11.0, 14.0), 31.0, Color(0.0, 0.0, 0.0, 0.18))
		draw_circle(post + Vector2(7.0, 9.0), 27.0, Color(0.0, 0.0, 0.0, 0.28))
		draw_circle(post, 23.0, Color(team_color, 0.22))
		draw_circle(post, 12.0, Color(0.92, 0.97, 0.97, 0.95))
		draw_circle(post, 6.0, Color(team_color, 0.9))
		draw_line(
			post,
			post + Vector2(cage_direction * 40.0, 0.0),
			Color(0.92, 0.97, 0.97, 0.9),
			_safe_stroke_width(6.0, 1.55),
			true
		)


func _draw_goal_net(
	front_top: Vector2,
	front_bottom: Vector2,
	back_top: Vector2,
	back_bottom: Vector2,
	color: Color
) -> void:
	var net_color := Color(color, goal_net_alpha)
	var net_highlight := Color(0.82, 0.9, 0.92, goal_net_alpha * 0.52)

	for index in range(1, 8):
		var t := float(index) / 8.0
		draw_line(
			front_top.lerp(front_bottom, t),
			back_top.lerp(back_bottom, t),
			net_color,
			_safe_stroke_width(2.0, 1.25),
			true
		)

	for index in range(1, 5):
		var t := float(index) / 5.0
		draw_line(
			front_top.lerp(back_top, t),
			front_bottom.lerp(back_bottom, t),
			net_color,
			_safe_stroke_width(2.0, 1.25),
			true
		)

	# Two faint diagonals stop the net from reading as an editor/debug grid.
	draw_line(
		front_top.lerp(front_bottom, 0.2),
		back_top.lerp(back_bottom, 0.58),
		net_highlight,
		_safe_stroke_width(2.0, 1.25),
		true
	)
	draw_line(
		front_top.lerp(front_bottom, 0.8),
		back_top.lerp(back_bottom, 0.42),
		net_highlight,
		_safe_stroke_width(2.0, 1.25),
		true
	)


func _draw_corner_marks(bounds: Rect2) -> void:
	var radius := 130.0
	var width := secondary_line_width
	_draw_arc_marking(
		bounds.position,
		radius,
		0.0,
		PI * 0.5,
		secondary_line_color,
		width,
		64
	)
	_draw_arc_marking(
		Vector2(bounds.end.x, bounds.position.y),
		radius,
		PI * 0.5,
		PI,
		secondary_line_color,
		width,
		64
	)
	_draw_arc_marking(
		Vector2(bounds.position.x, bounds.end.y),
		radius,
		-PI * 0.5,
		0.0,
		secondary_line_color,
		width,
		64
	)
	_draw_arc_marking(
		bounds.end,
		radius,
		PI,
		PI * 1.5,
		secondary_line_color,
		width,
		64
	)


func _draw_open_box(
	goal_line_x: float,
	far_x: float,
	top_y: float,
	bottom_y: float,
	color: Color,
	width: float
) -> void:
	var points := PackedVector2Array([
		Vector2(goal_line_x, top_y),
		Vector2(far_x, top_y),
		Vector2(far_x, bottom_y),
		Vector2(goal_line_x, bottom_y)
	])
	_draw_polyline_marking(points, color, width)


func _draw_line_marking(
	from: Vector2,
	to: Vector2,
	width: float,
	color: Color
) -> void:
	draw_line(
		from + line_shadow_offset * 1.35,
		to + line_shadow_offset * 1.35,
		Color(0.0, 0.0, 0.0, 0.20),
		width + line_shadow_width_extra + 8.0,
		true
	)
	draw_line(
		from + line_shadow_offset,
		to + line_shadow_offset,
		line_shadow_color,
		width + line_shadow_width_extra,
		true
	)
	draw_line(from, to, color, width, true)


func _draw_polyline_marking(
	points: PackedVector2Array,
	color: Color,
	width: float
) -> void:
	var broad_shadow_points := PackedVector2Array()
	var close_shadow_points := PackedVector2Array()
	for point in points:
		broad_shadow_points.append(point + line_shadow_offset * 1.35)
		close_shadow_points.append(point + line_shadow_offset)
	draw_polyline(
		broad_shadow_points,
		Color(0.0, 0.0, 0.0, 0.20),
		width + line_shadow_width_extra + 8.0,
		true
	)
	draw_polyline(
		close_shadow_points,
		line_shadow_color,
		width + line_shadow_width_extra,
		true
	)
	draw_polyline(points, color, width, true)


func _draw_arc_marking(
	center: Vector2,
	radius: float,
	start_angle: float,
	end_angle: float,
	color: Color,
	width: float,
	point_count: int
) -> void:
	draw_arc(
		center + line_shadow_offset * 1.35,
		radius,
		start_angle,
		end_angle,
		point_count,
		Color(0.0, 0.0, 0.0, 0.20),
		width + line_shadow_width_extra + 8.0,
		true
	)
	draw_arc(
		center + line_shadow_offset,
		radius,
		start_angle,
		end_angle,
		point_count,
		line_shadow_color,
		width + line_shadow_width_extra,
		true
	)
	draw_arc(
		center,
		radius,
		start_angle,
		end_angle,
		point_count,
		color,
		width,
		true
	)
