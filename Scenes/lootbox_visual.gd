class_name FootballLootboxVisual
extends Control


var charge: float = 0.0:
	set(value):
		charge = clampf(value, 0.0, 1.0)
		queue_redraw()
var open_progress: float = 0.0:
	set(value):
		open_progress = clampf(value, 0.0, 1.0)
		queue_redraw()
var available: bool = false:
	set(value):
		available = value
		queue_redraw()
var reward_color: Color = Color("f4c95d"):
	set(value):
		reward_color = value
		queue_redraw()

var _animation_time: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_animation_time = fmod(_animation_time + delta, 60.0)
	queue_redraw()


func reset_box(has_lootbox: bool) -> void:
	charge = 0.0
	open_progress = 0.0
	available = has_lootbox
	rotation = 0.0
	position = Vector2.ZERO
	scale = Vector2.ONE
	modulate = Color.WHITE
	show()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		pivot_offset = size * 0.5
		queue_redraw()


func _draw() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	var visual_scale: float = minf(size.x / 330.0, size.y / 255.0)
	var center := Vector2(size.x * 0.5, size.y * 0.56)
	var pulse: float = 0.5 + 0.5 * sin(_animation_time * 2.4)
	var active_alpha: float = 1.0 if available else 0.48
	var lid_lift: float = open_progress * 55.0 * visual_scale
	var burst: float = sin(open_progress * PI)

	# Floor shadow and charging aura anchor the crate in the chamber.
	draw_set_transform(center + Vector2(0.0, 74.0 * visual_scale), 0.0, Vector2(1.8, 0.34))
	draw_circle(Vector2.ZERO, 78.0 * visual_scale, Color(0.0, 0.0, 0.0, 0.34 * active_alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for aura_index: int in range(4):
		var aura_radius: float = (88.0 + float(aura_index) * 16.0 + charge * 18.0) * visual_scale
		draw_arc(
			center,
			aura_radius,
			_animation_time * (0.34 + float(aura_index) * 0.08),
			_animation_time * (0.34 + float(aura_index) * 0.08) + PI * 1.12,
			48,
			Color(reward_color, active_alpha * (0.08 + charge * 0.13) * (1.0 - float(aura_index) * 0.15)),
			(3.0 - float(aura_index) * 0.35) * visual_scale,
			true
		)

	if burst > 0.01:
		for ray_index: int in range(18):
			var direction := Vector2.from_angle(float(ray_index) * TAU / 18.0)
			draw_line(
				center + direction * 48.0 * visual_scale,
				center + direction * (120.0 + burst * 55.0) * visual_scale,
				Color(reward_color.lightened(0.42), burst * 0.42),
				(7.0 - burst * 4.0) * visual_scale,
				true
			)

	var body_center := center + Vector2(0.0, 20.0 * visual_scale)
	var body_half := Vector2(112.0, 66.0) * visual_scale
	var side_depth: float = 22.0 * visual_scale
	var body_rect := Rect2(body_center - body_half, body_half * 2.0)
	var body_color := Color("20283d").lerp(Color("35435f"), charge * 0.34)
	var body_edge := Color("71819a").lerp(reward_color, charge * 0.72)

	# Beveled side plates create an original, compact sci-fi equipment crate.
	draw_colored_polygon(PackedVector2Array([
		body_rect.position,
		body_rect.position + Vector2(-side_depth, -side_depth * 0.55),
		Vector2(body_rect.position.x - side_depth, body_rect.end.y - side_depth * 0.30),
		Vector2(body_rect.position.x, body_rect.end.y),
	]), Color("111827"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(body_rect.end.x, body_rect.position.y),
		Vector2(body_rect.end.x + side_depth, body_rect.position.y - side_depth * 0.55),
		Vector2(body_rect.end.x + side_depth, body_rect.end.y - side_depth * 0.30),
		body_rect.end,
	]), Color("0c1321"))
	draw_rect(body_rect, Color(body_color, active_alpha), true)
	draw_rect(body_rect, Color(body_edge, active_alpha), false, 4.0 * visual_scale)

	# Reinforced corners, segmented lower rail, vents, and status lights.
	for side: float in [-1.0, 1.0]:
		var bumper_x: float = body_center.x + side * 98.0 * visual_scale
		var bumper := Rect2(
			Vector2(bumper_x - 11.0 * visual_scale, body_rect.position.y - 7.0 * visual_scale),
			Vector2(22.0, 80.0) * visual_scale
		)
		draw_rect(bumper, Color("0a101c"), true)
		draw_rect(bumper, Color(body_edge, active_alpha), false, 3.0 * visual_scale)
		for bolt_y: float in [-38.0, 38.0]:
			draw_circle(
				Vector2(bumper_x, body_center.y + bolt_y * visual_scale),
				4.0 * visual_scale,
				Color("dce7f4")
			)
	for vent_index: int in range(4):
		var vent_y: float = body_center.y + (-37.0 + float(vent_index) * 12.0) * visual_scale
		draw_line(
			Vector2(body_center.x - 82.0 * visual_scale, vent_y),
			Vector2(body_center.x - 53.0 * visual_scale, vent_y),
			Color("7c8ba0"),
			3.0 * visual_scale,
			true
		)
	var lower_rail := Rect2(
		Vector2(body_rect.position.x + 17.0 * visual_scale, body_rect.end.y - 16.0 * visual_scale),
		Vector2(body_rect.size.x - 34.0 * visual_scale, 9.0 * visual_scale)
	)
	draw_rect(lower_rail, Color("090f1a"), true)
	for segment: int in range(7):
		var segment_width: float = lower_rail.size.x / 7.0
		draw_rect(
			Rect2(
				lower_rail.position + Vector2(float(segment) * segment_width + 2.0, 2.0),
				Vector2(segment_width - 4.0, lower_rail.size.y - 4.0)
			),
			Color(reward_color, active_alpha * (0.22 + charge * 0.62))
		)

	# Football lock: a hexagonal ball panel makes the crate belong to this game.
	var lock_center := body_center + Vector2(0.0, -3.0 * visual_scale)
	var lock_points := PackedVector2Array()
	for point_index: int in range(7):
		lock_points.append(
			lock_center
			+ Vector2.from_angle(float(point_index) * TAU / 6.0 - PI * 0.5)
			* 34.0
			* visual_scale
		)
	draw_colored_polygon(lock_points, Color("0a111f"))
	draw_polyline(lock_points, Color(reward_color, active_alpha), 4.0 * visual_scale, true)
	draw_circle(lock_center, 14.0 * visual_scale, Color(reward_color, active_alpha * (0.45 + pulse * 0.35 + charge * 0.20)))
	for seam_index: int in range(5):
		var seam_angle: float = float(seam_index) * TAU / 5.0 - PI * 0.5
		draw_line(
			lock_center + Vector2.from_angle(seam_angle) * 14.0 * visual_scale,
			lock_center + Vector2.from_angle(seam_angle) * 30.0 * visual_scale,
			Color(reward_color.lightened(0.45), active_alpha * 0.80),
			2.0 * visual_scale,
			true
		)

	# Lid lifts separately during the reveal and emits a widening light seam.
	var lid_center := center + Vector2(0.0, -56.0 * visual_scale - lid_lift)
	var lid_half := Vector2(120.0, 30.0) * visual_scale
	var lid_rect := Rect2(lid_center - lid_half, lid_half * 2.0)
	if open_progress > 0.02:
		draw_colored_polygon(PackedVector2Array([
			Vector2(body_rect.position.x + 10.0 * visual_scale, body_rect.position.y),
			Vector2(body_rect.end.x - 10.0 * visual_scale, body_rect.position.y),
			Vector2(lid_rect.end.x - 22.0 * visual_scale, lid_rect.end.y),
			Vector2(lid_rect.position.x + 22.0 * visual_scale, lid_rect.end.y),
		]), Color(reward_color.lightened(0.35), open_progress * 0.30))
	draw_colored_polygon(PackedVector2Array([
		lid_rect.position + Vector2(14.0 * visual_scale, 0.0),
		Vector2(lid_rect.end.x - 14.0 * visual_scale, lid_rect.position.y),
		lid_rect.end,
		Vector2(lid_rect.position.x, lid_rect.end.y),
	]), Color(body_color.lightened(0.10), active_alpha))
	draw_polyline(PackedVector2Array([
		lid_rect.position + Vector2(14.0 * visual_scale, 0.0),
		Vector2(lid_rect.end.x - 14.0 * visual_scale, lid_rect.position.y),
		lid_rect.end,
		Vector2(lid_rect.position.x, lid_rect.end.y),
		lid_rect.position + Vector2(14.0 * visual_scale, 0.0),
	]), Color(body_edge, active_alpha), 4.0 * visual_scale, true)
	var lid_strip := Rect2(
		Vector2(lid_rect.position.x + 24.0 * visual_scale, lid_rect.end.y - 10.0 * visual_scale),
		Vector2(lid_rect.size.x - 48.0 * visual_scale, 6.0 * visual_scale)
	)
	draw_rect(lid_strip, Color(reward_color, active_alpha * (0.36 + pulse * 0.25 + charge * 0.39)), true)

	# Charging sparks make the box feel alive before it opens.
	if available:
		for spark_index: int in range(14):
			var spark_angle: float = float(spark_index) * 2.399 + _animation_time * 0.38
			var spark_distance: float = (100.0 + float((spark_index * 17) % 58) + charge * 22.0) * visual_scale
			var spark_position: Vector2 = center + Vector2.from_angle(spark_angle) * spark_distance
			var spark_alpha: float = (0.20 + charge * 0.55) * (0.45 + 0.55 * absf(sin(_animation_time * 4.0 + float(spark_index))))
			draw_circle(spark_position, (2.0 + float(spark_index % 3)) * visual_scale, Color(reward_color.lightened(0.48), spark_alpha))
