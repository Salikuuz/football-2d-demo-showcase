class_name FootballMainMenuBackdrop
extends Control


var _time: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_time = fmod(_time + delta, 120.0)
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.005, 0.012, 0.016, 0.18))
	var pulse: float = 0.82 + sin(_time * 0.75) * 0.08
	_draw_team_glow(Vector2(size.x * 0.12, size.y * 0.48), Color(0.12, 0.55, 1.0), pulse)
	_draw_team_glow(Vector2(size.x * 0.88, size.y * 0.48), Color(1.0, 0.18, 0.28), pulse)

	var center_x: float = size.x * 0.5
	var beam_width: float = minf(size.x * 0.20, 360.0)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(center_x - beam_width * 0.18, 0.0),
			Vector2(center_x + beam_width * 0.18, 0.0),
			Vector2(center_x + beam_width, size.y),
			Vector2(center_x - beam_width, size.y),
		]),
		Color(0.66, 0.88, 1.0, 0.025)
	)
	for ring_index: int in range(4):
		var radius: float = 110.0 + float(ring_index) * 78.0
		draw_arc(
			Vector2(center_x, size.y * 0.50),
			radius,
			0.0,
			TAU,
			96,
			Color(0.82, 0.92, 1.0, 0.035 - float(ring_index) * 0.005),
			2.0
		)
	for spark_index: int in range(28):
		var x_ratio: float = fmod(float(spark_index * 67 + 13), 101.0) / 101.0
		var y_ratio: float = fmod(float(spark_index * 43 + 7), 97.0) / 97.0
		var shimmer: float = 0.45 + 0.35 * sin(_time + float(spark_index) * 0.73)
		draw_circle(
			Vector2(x_ratio * size.x, y_ratio * size.y),
			1.2 + float(spark_index % 3) * 0.45,
			Color(0.8, 0.92, 1.0, maxf(0.08, shimmer))
		)


func _draw_team_glow(center: Vector2, color: Color, pulse: float) -> void:
	for glow_index: int in range(8, 0, -1):
		var ratio: float = float(glow_index) / 8.0
		var glow_color := Color(color.r, color.g, color.b, 0.012 + (1.0 - ratio) * 0.014)
		draw_circle(center, 360.0 * ratio * pulse, glow_color)
