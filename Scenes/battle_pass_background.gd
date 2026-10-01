class_name FootballBattlePassBackground
extends Control

var _animation_time: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visibility_changed.connect(_on_visibility_changed)
	_on_visibility_changed()
	queue_redraw()


func _process(delta: float) -> void:
	_animation_time = fmod(_animation_time + delta, 120.0)
	queue_redraw()


func _on_visibility_changed() -> void:
	set_process(is_visible_in_tree())


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var bounds := Rect2(Vector2.ZERO, size)
	draw_rect(bounds, Color("10133a"))
	for band: int in range(12):
		var ratio: float = float(band) / 12.0
		var color := Color(
			0.055 + ratio * 0.035,
			0.06 + ratio * 0.045,
			0.20 + ratio * 0.11,
			0.58
		)
		draw_rect(Rect2(0.0, size.y * ratio, size.x, size.y / 12.0 + 2.0), color)

	# A lightweight procedural galaxy: deterministic stars plus slowly rotating
	# spiral arms. No textures or shaders are compiled when the menu opens.
	var center := Vector2(size.x * 0.53, size.y * 0.48)
	var galaxy_radius: float = minf(size.x * 0.48, size.y * 0.74)
	for glow_index: int in range(9, 0, -1):
		var glow_ratio: float = float(glow_index) / 9.0
		var glow_color := Color(0.30, 0.10, 0.68, 0.032 + (1.0 - glow_ratio) * 0.026)
		draw_circle(center, galaxy_radius * glow_ratio, glow_color)

	var rotation: float = _animation_time * 0.035
	for arm: int in range(4):
		var arm_phase: float = float(arm) * TAU / 4.0 + rotation
		for point_index: int in range(42):
			var point_ratio: float = float(point_index) / 41.0
			var angle: float = arm_phase + point_ratio * TAU * 1.45
			var radius: float = galaxy_radius * (0.05 + point_ratio * 0.92)
			var squash := Vector2(cos(angle) * radius, sin(angle) * radius * 0.43)
			var shimmer: float = 0.72 + 0.28 * sin(_animation_time * 1.1 + float(point_index + arm * 7))
			var arm_color := (
				Color(0.32, 0.68, 1.0, 0.20 * shimmer * (1.0 - point_ratio * 0.45))
				if arm % 2 == 0
				else Color(0.78, 0.28, 1.0, 0.18 * shimmer * (1.0 - point_ratio * 0.45))
			)
			draw_circle(center + squash, lerpf(13.0, 2.0, point_ratio), arm_color)

	for star_index: int in range(96):
		var x_ratio: float = fmod(float(star_index * 73 + 19), 101.0) / 101.0
		var y_ratio: float = fmod(float(star_index * 47 + 11), 97.0) / 97.0
		var pulse: float = 0.55 + 0.45 * sin(_animation_time * (0.7 + float(star_index % 5) * 0.11) + float(star_index))
		var star_position := Vector2(x_ratio * size.x, y_ratio * size.y)
		var star_radius: float = 0.8 + float(star_index % 4) * 0.38
		draw_circle(star_position, star_radius, Color(0.78, 0.9, 1.0, 0.28 + pulse * 0.58))

	draw_circle(center, maxf(18.0, galaxy_radius * 0.055), Color(1.0, 0.82, 0.42, 0.18))
	draw_circle(center, maxf(5.0, galaxy_radius * 0.017), Color(1.0, 0.94, 0.76, 0.72))
	draw_rect(Rect2(0.0, size.y - 150.0, size.x, 150.0), Color(0.01, 0.015, 0.055, 0.24))
