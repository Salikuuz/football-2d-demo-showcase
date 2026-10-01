class_name FootballGoalExplosionAtmosphere
extends Control


var cosmetic_id: String = "goal_explosion.classic"
var rarity: String = "common"
var pattern: String = "classic"
var primary: Color = Color.WHITE
var secondary: Color = Color.WHITE
var lifetime: float = 1.75
var intensity: float = 0.0

var _elapsed: float = 0.0
var _visual_lifetime: float = 1.75
var _hold_until_goal_replay: bool = false


static func supports_item(cosmetic_item: Dictionary) -> bool:
	return str(cosmetic_item.get("rarity", "common")) in [
		"rare",
		"epic",
		"legendary",
	]


func setup(
	selected_cosmetic_id: String,
	cosmetic_item: Dictionary,
	fallback_color: Color
) -> void:
	cosmetic_id = selected_cosmetic_id
	rarity = str(cosmetic_item.get("rarity", "common"))
	pattern = (
		"galaxy"
		if cosmetic_id == "goal_explosion.andromeda"
		else str(cosmetic_item.get("pattern", "classic"))
	)
	primary = _catalog_color(cosmetic_item, "primary", fallback_color)
	secondary = _catalog_color(
		cosmetic_item,
		"secondary",
		primary.lightened(0.48)
	)
	match rarity:
		"legendary":
			lifetime = 2.55
			intensity = 1.0
		"epic":
			lifetime = 2.15
			intensity = 0.72
		"rare":
			lifetime = 1.85
			intensity = 0.46
		_:
			lifetime = 1.45
			intensity = 0.0
	_visual_lifetime = lifetime
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func hold_until_goal_replay(fallback_seconds: float) -> void:
	_hold_until_goal_replay = true
	# The replay-start callback removes the effect exactly. Keep a generous
	# fallback so a cancelled/aborted replay can never leave it around forever.
	lifetime = maxf(lifetime, maxf(0.0, fallback_seconds) + 1.0)
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fit_to_viewport()
	get_viewport().size_changed.connect(_fit_to_viewport)
	queue_redraw()


func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()
	if _elapsed >= lifetime:
		queue_free()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _fit_to_viewport() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	queue_redraw()


func _draw() -> void:
	if intensity <= 0.0 or size.x <= 1.0 or size.y <= 1.0:
		return
	var raw_progress: float = _elapsed / maxf(0.01, _visual_lifetime)
	var natural_progress: float = clampf(raw_progress, 0.0, 1.0)
	# Hold the arena coverage at its mature state until replay, but keep a
	# separate unbounded animation clock. Previously progress itself was capped
	# at 0.62, which froze every animated pattern after roughly 1.5 seconds.
	var progress: float = (
		minf(natural_progress, 0.62)
		if _hold_until_goal_replay
		else natural_progress
	)
	var motion_progress: float = (
		raw_progress
		if _hold_until_goal_replay
		else natural_progress
	)
	var attack: float = smoothstep(0.0, 0.07, progress)
	var release: float = (
		1.0
		if _hold_until_goal_replay
		else 1.0 - smoothstep(0.42, 1.0, progress)
	)
	var envelope: float = attack * release
	var bounds := Rect2(Vector2.ZERO, size)
	var center: Vector2 = size * 0.5

	# The wash changes the whole pitch atmosphere without covering names or HUD.
	draw_rect(bounds, Color(primary.darkened(0.42), envelope * intensity * 0.20))
	draw_rect(bounds, Color(secondary, envelope * intensity * 0.045), false, 5.0)
	_draw_edge_pressure(bounds, envelope, motion_progress)

	match pattern:
		"confetti":
			_draw_confetti(envelope, motion_progress)
		"flame":
			_draw_flame_front(envelope, motion_progress)
		"electric":
			_draw_electric_storm(envelope, motion_progress)
		"vortex":
			_draw_vortex(center, envelope, motion_progress)
		"pixel":
			_draw_pixel_field(envelope, motion_progress)
		"crown":
			_draw_crown_sky(center, envelope, progress, motion_progress)
		"frost":
			_draw_frosted_edges(envelope, progress, motion_progress)
		"comet":
			_draw_comet_sky(envelope, progress, motion_progress)
		"trophy":
			_draw_trophy_lights(center, envelope, motion_progress)
		"stadium":
			_draw_stadium_roar(center, envelope, motion_progress)
		"galaxy":
			_draw_galaxy(center, envelope, motion_progress)


func _draw_edge_pressure(bounds: Rect2, envelope: float, progress: float) -> void:
	for edge_index: int in range(5):
		var inset: float = float(edge_index) * 13.0
		var edge_alpha: float = (
			envelope
			* intensity
			* (0.12 - float(edge_index) * 0.018)
			* (0.82 + sin(progress * TAU * 2.0 + float(edge_index)) * 0.18)
		)
		draw_rect(
			bounds.grow(-inset),
			Color(primary, maxf(0.0, edge_alpha)),
			false,
			7.0
		)


func _draw_confetti(envelope: float, progress: float) -> void:
	for index: int in range(54):
		var x_ratio: float = float((index * 73 + 17) % 101) / 100.0
		var phase: float = fposmod(progress * 1.55 + float(index % 9) * 0.103, 1.0)
		var point := Vector2(
			x_ratio * size.x,
			lerpf(-40.0, size.y + 40.0, phase)
		)
		var piece_size := Vector2(12.0 + float(index % 3) * 5.0, 6.0)
		draw_set_transform(point, progress * 8.0 + float(index), Vector2.ONE)
		draw_rect(
			Rect2(-piece_size * 0.5, piece_size),
			Color(primary if index % 3 == 0 else secondary, envelope * 0.78),
			true
		)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_flame_front(envelope: float, progress: float) -> void:
	var column_count: int = 22
	var column_width: float = size.x / float(column_count)
	for index: int in range(column_count + 1):
		var wave: float = 0.72 + 0.28 * sin(progress * 13.0 + float(index) * 1.7)
		var height: float = size.y * (0.13 + 0.13 * wave) * intensity
		var base := Vector2(float(index) * column_width, size.y)
		var flame := PackedVector2Array([
			base - Vector2(column_width * 0.55, 0.0),
			base - Vector2(column_width * 0.18, height * 0.42),
			base + Vector2(0.0, -height),
			base + Vector2(column_width * 0.25, -height * 0.38),
			base + Vector2(column_width * 0.55, 0.0),
		])
		draw_colored_polygon(
			flame,
			Color(primary if index % 2 == 0 else secondary, envelope * 0.34)
		)


func _draw_electric_storm(envelope: float, progress: float) -> void:
	for index: int in range(12):
		var from_left: bool = index % 2 == 0
		var start := Vector2(
			0.0 if from_left else size.x,
			float((index * 67 + 23) % 101) / 100.0 * size.y
		)
		var direction: float = 1.0 if from_left else -1.0
		var end := Vector2(size.x if from_left else 0.0, start.y + sin(progress * 9.0 + float(index)) * size.y * 0.2)
		var points := PackedVector2Array([
			start,
			start + Vector2(direction * size.x * 0.28, -55.0 + float(index % 4) * 28.0),
			start + Vector2(direction * size.x * 0.56, 48.0 - float(index % 3) * 35.0),
			end,
		])
		draw_polyline(
			points,
			Color(secondary if index % 3 == 0 else primary, envelope * 0.38),
			2.0 + intensity * 3.0,
			true
		)


func _draw_vortex(center: Vector2, envelope: float, progress: float) -> void:
	var max_radius: float = maxf(size.x, size.y) * 0.68
	for orbit: int in range(8):
		var radius: float = max_radius * (0.18 + float(orbit) * 0.105)
		var angle: float = progress * 4.6 + float(orbit) * 0.62
		draw_arc(
			center,
			radius,
			angle,
			angle + PI * 1.18,
			72,
			Color(primary if orbit % 2 == 0 else secondary, envelope * 0.30),
			3.0 + intensity * 4.0,
			true
		)


func _draw_pixel_field(envelope: float, progress: float) -> void:
	for index: int in range(46):
		var x_ratio: float = float((index * 43 + 7) % 97) / 96.0
		var y_ratio: float = float((index * 71 + 13) % 103) / 102.0
		var pulse: float = 0.45 + 0.55 * sin(progress * 18.0 + float(index))
		var block_size: float = 12.0 + float(index % 5) * 7.0
		draw_rect(
			Rect2(
				Vector2(x_ratio * size.x, y_ratio * size.y) - Vector2.ONE * block_size * 0.5,
				Vector2.ONE * block_size
			),
			Color(primary if index % 2 == 0 else secondary, envelope * maxf(0.08, pulse) * 0.48),
			true
		)


func _draw_crown_sky(
	center: Vector2,
	envelope: float,
	progress: float,
	motion_progress: float
) -> void:
	var width: float = minf(size.x * 0.34, 620.0)
	var height: float = minf(size.y * 0.30, 330.0)
	var crown_center := center + Vector2(0.0, -size.y * 0.12)
	var crown := PackedVector2Array([
		crown_center + Vector2(-width, height * 0.42),
		crown_center + Vector2(-width * 0.82, -height * 0.52),
		crown_center + Vector2(-width * 0.34, -height * 0.10),
		crown_center + Vector2(0.0, -height),
		crown_center + Vector2(width * 0.34, -height * 0.10),
		crown_center + Vector2(width * 0.82, -height * 0.52),
		crown_center + Vector2(width, height * 0.42),
		crown_center + Vector2(-width, height * 0.42),
	])
	draw_colored_polygon(crown, Color(primary, envelope * 0.10))
	draw_polyline(crown, Color(secondary, envelope * 0.58), 7.0, true)
	for ray: int in range(9):
		var angle: float = lerpf(PI * 1.12, PI * 1.88, float(ray) / 8.0)
		draw_line(
			crown_center,
			crown_center + Vector2.from_angle(angle) * size.y * (
				0.72 + progress * 0.18
				+ (
					sin(motion_progress * 5.0 + float(ray)) * 0.025
					if _hold_until_goal_replay
					else 0.0
				)
			),
			Color(secondary, envelope * 0.14),
			18.0,
			true
		)


func _draw_frosted_edges(
	envelope: float,
	progress: float,
	motion_progress: float
) -> void:
	var corners: Array[Vector2] = [
		Vector2.ZERO,
		Vector2(size.x, 0.0),
		Vector2(0.0, size.y),
		Vector2(size.x, size.y),
	]
	for corner_index: int in range(corners.size()):
		var corner: Vector2 = corners[corner_index]
		var inward := (size * 0.5 - corner).normalized()
		for branch: int in range(7):
			var direction := inward.rotated((float(branch) - 3.0) * 0.18)
			var length: float = minf(size.x, size.y) * (0.26 + float(branch % 3) * 0.045)
			var frost_pulse: float = (
				1.0 + sin(motion_progress * 4.5 + float(branch)) * 0.035
				if _hold_until_goal_replay
				else 1.0
			)
			var end: Vector2 = corner + direction * length * (0.78 + progress * 0.22) * frost_pulse
			draw_line(corner, end, Color(secondary, envelope * 0.38), 4.0, true)


func _draw_comet_sky(
	envelope: float,
	progress: float,
	motion_progress: float
) -> void:
	var comet_progress: float = progress
	if _hold_until_goal_replay and motion_progress > 0.62:
		# Repeat the comet sweep while the scorer-focus presentation is held.
		comet_progress = fposmod(motion_progress - 0.62, 1.0)
	var head := Vector2(
		lerpf(-size.x * 0.14, size.x * 1.14, comet_progress),
		lerpf(size.y * 0.78, size.y * 0.18, comet_progress)
	)
	var direction := Vector2(1.0, -0.47).normalized()
	for trail: int in range(14):
		var length: float = size.x * (0.10 + float(trail) * 0.018)
		var offset := direction.orthogonal() * (float(trail) - 6.5) * 8.0
		draw_line(
			head - direction * length + offset,
			head,
			Color(primary if trail % 2 == 0 else secondary, envelope * 0.24),
			maxf(2.0, 13.0 - float(trail) * 0.62),
			true
		)
	draw_circle(head, 42.0 + intensity * 24.0, Color(secondary, envelope * 0.74))


func _draw_trophy_lights(center: Vector2, envelope: float, progress: float) -> void:
	for beam: int in range(12):
		var x_ratio: float = float(beam) / 11.0
		var source := Vector2(x_ratio * size.x, 0.0)
		var spread: float = 60.0 + sin(progress * 5.0 + float(beam)) * 28.0
		draw_colored_polygon(
			PackedVector2Array([
				source - Vector2(spread, 0.0),
				source + Vector2(spread, 0.0),
				center + Vector2((x_ratio - 0.5) * size.x * 0.22, size.y * 0.42),
			]),
			Color(secondary if beam % 3 == 0 else primary, envelope * 0.055)
		)
	for sparkle: int in range(30):
		var point := Vector2(
			float((sparkle * 61 + 11) % 101) / 100.0 * size.x,
			float((sparkle * 37 + 5) % 97) / 96.0 * size.y
		)
		var sparkle_size: float = 3.0 + 4.0 * absf(sin(progress * 12.0 + float(sparkle)))
		draw_circle(point, sparkle_size, Color(secondary, envelope * 0.62))


func _draw_stadium_roar(center: Vector2, envelope: float, progress: float) -> void:
	for wave: int in range(7):
		var wave_progress: float = fposmod(progress * 1.35 + float(wave) * 0.11, 1.0)
		var radius: float = lerpf(size.y * 0.12, size.x * 0.72, wave_progress)
		draw_arc(
			center + Vector2(0.0, size.y * 0.34),
			radius,
			PI,
			TAU,
			100,
			Color(primary if wave % 2 == 0 else secondary, envelope * (1.0 - wave_progress) * 0.42),
			5.0 + intensity * 5.0,
			true
		)
	for side: float in [-1.0, 1.0]:
		var source := Vector2(size.x * (0.08 if side < 0.0 else 0.92), 0.0)
		draw_colored_polygon(
			PackedVector2Array([
				source - Vector2(45.0, 0.0),
				source + Vector2(45.0, 0.0),
				center + Vector2(side * size.x * 0.16, size.y * 0.44),
			]),
			Color(secondary, envelope * 0.13)
		)


func _draw_galaxy(center: Vector2, envelope: float, progress: float) -> void:
	for star: int in range(72):
		var x_ratio: float = float((star * 67 + 13) % 103) / 102.0
		var y_ratio: float = float((star * 41 + 7) % 97) / 96.0
		var pulse: float = 0.32 + 0.68 * absf(sin(progress * 11.0 + float(star)))
		draw_circle(
			Vector2(x_ratio * size.x, y_ratio * size.y),
			1.5 + float(star % 4),
			Color(secondary, envelope * pulse * 0.72)
		)
	var radius_limit: float = maxf(size.x, size.y) * 0.48
	for arm: int in range(4):
		var points := PackedVector2Array()
		for step: int in range(44):
			var ratio: float = float(step) / 43.0
			var angle: float = progress * 1.7 + float(arm) * TAU / 4.0 + ratio * TAU * 1.32
			points.append(
				center
				+ Vector2(cos(angle), sin(angle) * 0.48)
				* radius_limit
				* ratio
			)
		draw_polyline(
			points,
			Color(primary if arm % 2 == 0 else secondary, envelope * 0.31),
			5.0,
			true
		)


func _catalog_color(
	cosmetic_item: Dictionary,
	key: String,
	fallback: Color
) -> Color:
	var html: String = str(cosmetic_item.get(key, ""))
	return Color(html) if Color.html_is_valid(html) else fallback
