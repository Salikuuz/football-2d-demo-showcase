extends Button

const FIELD_VARIANT_SCRIPT := preload("res://Scenes/field_variant.gd")

var _variant_index: int = 0
var _selected: bool = false

var variant_index: int:
	get:
		return _variant_index
	set(value):
		_variant_index = value
		queue_redraw()

var selected: bool:
	get:
		return _selected
	set(value):
		_selected = value
		queue_redraw()


func _ready() -> void:
	flat = true
	clip_contents = true
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _preview_rect() -> Rect2:
	var size: Vector2 = get_size()
	return Rect2(
		Vector2(14.0, 13.0),
		Vector2(maxf(40.0, size.x - 28.0), maxf(40.0, size.y - 51.0))
	)


func _draw() -> void:
	var size: Vector2 = get_size()
	var card_rect: Rect2 = Rect2(Vector2(3.0, 3.0), size - Vector2(6.0, 6.0))
	var preview_rect: Rect2 = _preview_rect()
	var outline: Color = Color(0.35, 0.47, 0.54, 0.88)
	if selected:
		outline = Color(0.62, 0.9, 1.0, 1.0)
	if is_hovered() or has_focus():
		outline = Color(1.0, 0.79, 0.28, 1.0)

	draw_style_box(_panel_style(outline), card_rect)

	# Draw this card's own exact generated map texture directly into the card.
	# No child TextureRect/material is shared, so cards cannot mirror the
	# currently selected map anymore.
	var map_texture: Texture2D = FIELD_VARIANT_SCRIPT.get_variant_texture(variant_index)
	if map_texture != null:
		draw_texture_rect(map_texture, preview_rect, false)
	else:
		draw_rect(preview_rect, FIELD_VARIANT_SCRIPT.get_variant_tint(variant_index), true)

	_draw_pitch_overlay(preview_rect)

	var label_color: Color = Color(0.96, 0.98, 1.0)
	if selected:
		label_color = Color(0.72, 0.92, 1.0)
	var theme: Dictionary = FIELD_VARIANT_SCRIPT.get_variant_theme(variant_index)
	var theme_name: String = String(theme.get("name", "MAP"))
	draw_string(
		get_theme_default_font(),
		Vector2(14.0, size.y - 12.0),
		"MAP %d  •  %s" % [variant_index + 1, theme_name],
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		15,
		label_color
	)


func _draw_pitch_overlay(rect: Rect2) -> void:
	var line_color: Color = Color(0.94, 0.97, 0.98, 0.92)
	var secondary_line: Color = Color(0.94, 0.97, 0.98, 0.70)
	var shadow_color: Color = Color(0.0, 0.0, 0.0, 0.42)
	var line_width: float = 1.9
	var shadow_offset: Vector2 = Vector2(2.0, 2.0)
	var shadow_rect: Rect2 = Rect2(rect.position + shadow_offset, rect.size)
	draw_rect(shadow_rect, shadow_color, false, 3.2, true)
	draw_rect(rect, line_color, false, line_width, true)

	var center: Vector2 = rect.get_center()
	draw_line(
		Vector2(center.x, rect.position.y) + shadow_offset,
		Vector2(center.x, rect.end.y) + shadow_offset,
		shadow_color,
		3.2,
		true
	)
	draw_line(
		Vector2(center.x, rect.position.y),
		Vector2(center.x, rect.end.y),
		line_color,
		line_width,
		true
	)
	var center_radius: float = minf(rect.size.y * 0.18, rect.size.x * 0.09)
	draw_arc(center + shadow_offset, center_radius, 0.0, TAU, 40, shadow_color, 3.2, true)
	draw_arc(center, center_radius, 0.0, TAU, 40, secondary_line, line_width, true)
	draw_circle(center + shadow_offset, 3.0, shadow_color)
	draw_circle(center, 2.2, line_color)

	var goal_area_depth: float = rect.size.x * 0.12
	var goal_area_height: float = rect.size.y * 0.48
	var goal_area_top: float = center.y - goal_area_height * 0.5
	var left_area: Rect2 = Rect2(
		Vector2(rect.position.x, goal_area_top),
		Vector2(goal_area_depth, goal_area_height)
	)
	var right_area: Rect2 = Rect2(
		Vector2(rect.end.x - goal_area_depth, goal_area_top),
		Vector2(goal_area_depth, goal_area_height)
	)
	draw_rect(Rect2(left_area.position + shadow_offset, left_area.size), shadow_color, false, 3.2, true)
	draw_rect(Rect2(right_area.position + shadow_offset, right_area.size), shadow_color, false, 3.2, true)
	draw_rect(left_area, secondary_line, false, line_width, true)
	draw_rect(right_area, secondary_line, false, line_width, true)

	var mouth_height: float = rect.size.y * 0.34
	var mouth_top: float = center.y - mouth_height * 0.5
	var goal_depth: float = maxf(9.0, rect.size.x * 0.05)
	var left_goal: Rect2 = Rect2(
		Vector2(rect.position.x - goal_depth, mouth_top),
		Vector2(goal_depth, mouth_height)
	)
	var right_goal: Rect2 = Rect2(
		Vector2(rect.end.x, mouth_top),
		Vector2(goal_depth, mouth_height)
	)
	_draw_goal(left_goal, Color(0.18, 0.57, 1.0, 0.92))
	_draw_goal(right_goal, Color(1.0, 0.2, 0.29, 0.92))


func _draw_goal(rect: Rect2, color: Color) -> void:
	var shadow_rect: Rect2 = Rect2(rect.position + Vector2(2.0, 2.0), rect.size)
	draw_rect(shadow_rect, Color(0.0, 0.0, 0.0, 0.48), false, 3.2, true)
	draw_rect(rect, Color(color.r, color.g, color.b, 0.10), true)
	draw_rect(rect, color, false, 1.8, true)
	var vertical_spacing: float = rect.size.x / 3.0
	for index in range(1, 3):
		var x: float = rect.position.x + vertical_spacing * float(index)
		draw_line(
			Vector2(x, rect.position.y),
			Vector2(x, rect.end.y),
			Color(color.r, color.g, color.b, 0.30),
			0.9,
			true
		)
	var horizontal_spacing: float = rect.size.y / 4.0
	for index in range(1, 4):
		var y: float = rect.position.y + horizontal_spacing * float(index)
		draw_line(
			Vector2(rect.position.x, y),
			Vector2(rect.end.x, y),
			Color(color.r, color.g, color.b, 0.30),
			0.9,
			true
		)


func _panel_style(outline: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.01, 0.025, 0.034, 0.99)
	style.border_color = outline
	style.set_border_width_all(2)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	return style
