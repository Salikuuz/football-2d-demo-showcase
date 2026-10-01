class_name FootballPlayerBannerVisuals
extends RefCounted


static func get_image_path(item: Dictionary) -> String:
	return str(item.get("image_path", "")).strip_edges()


static func load_image(item: Dictionary) -> Texture2D:
	var image_path: String = get_image_path(item)
	if image_path.is_empty() or not ResourceLoader.exists(image_path, "Texture2D"):
		return null
	return ResourceLoader.load(image_path, "Texture2D") as Texture2D


static func is_animated(item: Dictionary) -> bool:
	return bool(item.get("animated", true))


static func fit_full_image(source_size: Vector2, bounds: Rect2) -> Rect2:
	if (
		source_size.x <= 0.0
		or source_size.y <= 0.0
		or bounds.size.x <= 0.0
		or bounds.size.y <= 0.0
	):
		return Rect2(bounds.get_center(), Vector2.ZERO)
	var fit_scale: float = minf(
		bounds.size.x / source_size.x,
		bounds.size.y / source_size.y
	)
	var fitted_size: Vector2 = source_size * fit_scale
	return Rect2(bounds.get_center() - fitted_size * 0.5, fitted_size)


static func frame_colors(item: Dictionary, fallback: Color) -> Array[Color]:
	var primary: Color = _catalog_color(item, "primary", fallback)
	var secondary: Color = _catalog_color(item, "secondary", primary.lightened(0.36))
	return [primary, secondary]


static func draw_banner(
	canvas: CanvasItem,
	bounds: Rect2,
	item: Dictionary,
	team_color: Color,
	show_image: bool = true,
	prepared_texture: Texture2D = null,
	animation_time: float = 0.0,
	show_shadow: bool = true
) -> Rect2:
	var colors: Array[Color] = frame_colors(item, team_color)
	var primary: Color = colors[0]
	var secondary: Color = colors[1]
	var frame_style: String = str(item.get("frame_style", item.get("pattern", "pitch")))
	var outer := StyleBoxFlat.new()
	outer.bg_color = Color(0.012, 0.015, 0.02, 0.96)
	outer.border_color = Color(primary, 0.98)
	outer.set_border_width_all(3)
	outer.set_corner_radius_all(15)
	if show_shadow:
		outer.shadow_color = Color(0.0, 0.0, 0.0, 0.72)
		outer.shadow_size = 10
	canvas.draw_style_box(outer, bounds)
	var inner: Rect2 = bounds.grow(-8.0)
	canvas.draw_rect(inner, Color(0.015, 0.018, 0.024, 1.0), true)
	# Image-backed banners are prepared before CanvasItem._draw(). Loading a new
	# GPU texture during _draw() can yield a white first frame, and static banner
	# controls have no later redraw that would replace it.
	var texture: Texture2D = prepared_texture
	if texture == null and show_image:
		texture = load_image(item)
	var image_rect := Rect2()
	if texture != null:
		# User-supplied banners intentionally stretch the complete source into the
		# frame. This preserves every edge of portrait and landscape images while
		# avoiding the tiny portrait letterboxing that made Alvin unreadable.
		image_rect = inner.grow(-3.0)
		var image_tint: Color = _catalog_color(
			item,
			"image_tint",
			Color.WHITE
		)
		var image_modulate: Color = (
			Color.WHITE.lerp(image_tint, 0.22)
			if bool(item.get("custom_color", false))
			else Color.WHITE
		)
		canvas.draw_texture_rect(texture, image_rect, false, image_modulate)
		if bool(item.get("custom_color", false)):
			canvas.draw_rect(image_rect, Color(image_tint, 0.16), true)
	else:
		_draw_procedural_fill(canvas, inner, primary, secondary, frame_style)
	if is_animated(item):
		_draw_animated_effects(
			canvas,
			inner,
			primary,
			secondary,
			frame_style,
			str(item.get("pattern", "")),
			animation_time
		)
	_draw_frame_details(canvas, bounds, primary, secondary, team_color, frame_style)
	return image_rect


static func _draw_animated_effects(
	canvas: CanvasItem,
	bounds: Rect2,
	primary: Color,
	secondary: Color,
	frame_style: String,
	pattern: String,
	animation_time: float
) -> void:
	var phase: float = fposmod(animation_time, 4.0) / 4.0
	var center: Vector2 = bounds.get_center()
	if frame_style == "cosmic" or pattern == "galaxy":
		canvas.draw_rect(bounds, Color(0.035, 0.012, 0.11, 0.24), true)
		for arm: int in range(3):
			var points := PackedVector2Array()
			for step: int in range(19):
				var ratio: float = float(step) / 18.0
				var angle: float = animation_time * 0.24 + float(arm) * TAU / 3.0 + ratio * PI * 1.7
				points.append(center + Vector2.from_angle(angle) * bounds.size.y * ratio * 0.43)
			canvas.draw_polyline(points, Color(primary if arm % 2 == 0 else secondary, 0.24), 2.0, true)
		for index: int in range(22):
			var star_x: float = bounds.position.x + fposmod(float(index * 83) + animation_time * (7.0 + float(index % 3) * 3.0), bounds.size.x)
			var star_y: float = bounds.position.y + float((index * 47) % 97) / 97.0 * bounds.size.y
			var twinkle: float = 0.34 + 0.5 * (0.5 + 0.5 * sin(animation_time * 3.2 + float(index)))
			canvas.draw_circle(Vector2(star_x, star_y), 1.0 + float(index % 3) * 0.55, Color(secondary, twinkle))
		canvas.draw_circle(center, 6.0 + sin(animation_time * 2.0) * 1.5, Color(secondary, 0.38))
		return
	if frame_style in ["electric", "glitch"]:
		var scan_x: float = lerpf(bounds.position.x - 28.0, bounds.end.x + 28.0, phase)
		canvas.draw_line(Vector2(scan_x, bounds.position.y + 3.0), Vector2(scan_x + 20.0, bounds.end.y - 3.0), Color(secondary, 0.32), 4.0, true)
		for index: int in range(5):
			var spark_phase: float = fposmod(phase + float(index) * 0.19, 1.0)
			var spark := bounds.position + Vector2(bounds.size.x * spark_phase, 7.0 + float((index * 23) % 79) / 79.0 * maxf(1.0, bounds.size.y - 14.0))
			canvas.draw_line(spark - Vector2(8.0, 0.0), spark + Vector2(8.0, -3.0), Color(primary, 0.58), 2.0, true)
	elif frame_style in ["royal", "champion"]:
		var gleam_x: float = lerpf(bounds.position.x - 50.0, bounds.end.x + 50.0, phase)
		var gleam := PackedVector2Array([
			Vector2(gleam_x - 22.0, bounds.end.y),
			Vector2(gleam_x + 4.0, bounds.position.y),
			Vector2(gleam_x + 22.0, bounds.position.y),
			Vector2(gleam_x - 4.0, bounds.end.y),
		])
		canvas.draw_colored_polygon(gleam, Color(secondary, 0.16))
		for index: int in range(4):
			var orbit_angle: float = animation_time * 0.7 + float(index) * TAU / 4.0
			canvas.draw_circle(center + Vector2.from_angle(orbit_angle) * Vector2(bounds.size.x * 0.42, bounds.size.y * 0.36), 2.2, Color(secondary, 0.64))
	elif frame_style in ["vanguard", "flame"]:
		for index: int in range(9):
			var rise: float = fposmod(phase + float(index) * 0.13, 1.0)
			var ember_x: float = bounds.position.x + float((index * 61) % 101) / 101.0 * bounds.size.x
			var ember_y: float = bounds.end.y - rise * bounds.size.y
			var ember_color: Color = Color(secondary if index % 3 == 0 else primary, 0.55 * (1.0 - rise))
			canvas.draw_circle(Vector2(ember_x, ember_y), 1.5 + float(index % 2), ember_color)
	else:
		var pulse_alpha: float = 0.08 + 0.05 * sin(animation_time * 2.1)
		canvas.draw_rect(bounds.grow(-3.0), Color(primary, pulse_alpha), false, 2.0)


static func _draw_procedural_fill(
	canvas: CanvasItem,
	bounds: Rect2,
	primary: Color,
	secondary: Color,
	frame_style: String
) -> void:
	canvas.draw_rect(bounds, Color(primary.darkened(0.72), 0.94), true)
	for index: int in range(9):
		var ratio: float = float(index) / 8.0
		var start := bounds.position + Vector2(bounds.size.x * ratio - 30.0, bounds.size.y)
		var finish := start + Vector2(bounds.size.y * 0.82, -bounds.size.y)
		canvas.draw_line(start, finish, Color(primary, 0.08 + ratio * 0.06), 10.0, true)
	if frame_style in ["crown", "royal", "champion"]:
		var center := bounds.position + Vector2(bounds.size.x * 0.72, bounds.size.y * 0.52)
		var crown := PackedVector2Array([
			center + Vector2(-46.0, 19.0), center + Vector2(-35.0, -21.0),
			center + Vector2(-12.0, 3.0), center + Vector2(0.0, -34.0),
			center + Vector2(14.0, 3.0), center + Vector2(36.0, -21.0),
			center + Vector2(47.0, 19.0),
		])
		canvas.draw_polyline(crown, secondary, 5.0, true)
	elif frame_style in ["electric", "glitch"]:
		for index: int in range(5):
			var y: float = bounds.position.y + 14.0 + float(index) * bounds.size.y * 0.17
			canvas.draw_line(Vector2(bounds.position.x + bounds.size.x * 0.58, y), Vector2(bounds.end.x - 14.0, y - 9.0), secondary if index % 2 == 0 else primary, 3.0, true)


static func _draw_frame_details(
	canvas: CanvasItem,
	bounds: Rect2,
	primary: Color,
	secondary: Color,
	team_color: Color,
	frame_style: String
) -> void:
	canvas.draw_line(bounds.position + Vector2(18.0, 4.0), bounds.position + Vector2(bounds.size.x * 0.42, 4.0), secondary, 3.0, true)
	canvas.draw_line(bounds.end - Vector2(bounds.size.x * 0.31, 4.0), bounds.end - Vector2(18.0, 4.0), Color(team_color, 0.92), 3.0, true)
	for corner: Vector2 in [
		bounds.position + Vector2(15.0, 15.0),
		Vector2(bounds.end.x - 15.0, bounds.position.y + 15.0),
		Vector2(bounds.position.x + 15.0, bounds.end.y - 15.0),
		bounds.end - Vector2(15.0, 15.0),
	]:
		canvas.draw_circle(corner, 3.5, secondary)
	if frame_style in ["flame", "vanguard"]:
		var left := bounds.position + Vector2(4.0, bounds.size.y * 0.5)
		var right := Vector2(bounds.end.x - 4.0, bounds.position.y + bounds.size.y * 0.5)
		for direction: float in [-1.0, 1.0]:
			var base: Vector2 = left if direction < 0.0 else right
			var tip_direction: float = 1.0 if direction < 0.0 else -1.0
			var shard := PackedVector2Array([
				base + Vector2(0.0, -18.0),
				base + Vector2(tip_direction * 18.0, 0.0),
				base + Vector2(0.0, 18.0),
			])
			canvas.draw_colored_polygon(shard, Color(primary, 0.86))


static func _catalog_color(item: Dictionary, key: String, fallback: Color) -> Color:
	var html: String = str(item.get(key, ""))
	return Color(html) if Color.html_is_valid(html) else fallback
