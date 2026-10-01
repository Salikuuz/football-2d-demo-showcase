class_name FootballCosmeticPreview
extends Control


const GOAL_THEME_ICON_PATH: String = "res://Assets/goal_themes/goal_theme_icon.png"
const GOAL_THEME_ICON_TEXTURE: Texture2D = preload("res://Assets/goal_themes/goal_theme_icon.png")

var item_id: String = ""
var item: Dictionary = {}
var _base_item: Dictionary = {}
var _player_skin_color_index: int = FootballCosmeticInventory.PLAYER_SKIN_ORIGINAL_COLOR
var _team_skin_color_indices: Dictionary = {
	&"blue": FootballCosmeticInventory.PLAYER_SKIN_ORIGINAL_COLOR,
	&"red": FootballCosmeticInventory.PLAYER_SKIN_ORIGINAL_COLOR,
}
var _goal_explosion_color_index: int = FootballCosmeticInventory.PLAYER_SKIN_ORIGINAL_COLOR
var _player_banner_color_index: int = FootballCosmeticInventory.PLAYER_SKIN_ORIGINAL_COLOR
var _frame_palette_id: String = "frame_palette.classic_touch"
var _player_material_id: String = "player_material.matte"
var _team_primary_color_indices: Dictionary = {&"blue": 0, &"red": 0}
var _preview_player_skin_id: String = "player_skin.classic"
var _preview_player_skin_item: Dictionary = {}
var preview_team: StringName = &"blue"
var _preview_time: float = 0.0
var _banner_texture: Texture2D
var _goal_theme_texture: Texture2D


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	var slot: StringName = StringName(item.get("slot", &""))
	var animated_skin: bool = (
		slot == FootballCosmeticInventory.SLOT_PLAYER_SKIN
		and FootballPlayerSkinVisuals.has_animated_details(item_id, item)
	)
	var animated_banner: bool = (
		slot == FootballCosmeticInventory.SLOT_PLAYER_BANNER
		and FootballPlayerBannerVisuals.is_animated(item)
	)
	var animated_material: bool = (
		slot == FootballCosmeticInventory.SLOT_PLAYER_MATERIAL
		and bool(item.get("animated", false))
	)
	if (
		slot != FootballCosmeticInventory.SLOT_GOAL_EXPLOSION
		and slot != FootballCosmeticInventory.SLOT_ABILITY_PARTICLE
		and not animated_skin
		and not animated_banner
		and not animated_material
	):
		return
	_preview_time = fmod(
		_preview_time + delta,
		1.6
		if slot in [
			FootballCosmeticInventory.SLOT_GOAL_EXPLOSION,
			FootballCosmeticInventory.SLOT_ABILITY_PARTICLE,
		]
		else 60.0
	)
	queue_redraw()


func set_cosmetic(next_item_id: String, next_item: Dictionary) -> void:
	item_id = next_item_id
	_base_item = next_item.duplicate(true)
	_refresh_display_item()
	_banner_texture = (
		FootballPlayerBannerVisuals.load_image(item)
		if StringName(item.get("slot", &""))
		== FootballCosmeticInventory.SLOT_PLAYER_BANNER
		else null
	)
	_goal_theme_texture = null
	if StringName(item.get("slot", &"")) == FootballCosmeticInventory.SLOT_GOAL_THEME:
		_goal_theme_texture = _resolve_goal_theme_texture(item)
	queue_redraw()


func set_player_skin_color_index(color_index: int) -> void:
	_player_skin_color_index = FootballCosmeticInventory.sanitize_player_skin_color_index(
		color_index
	)
	_refresh_display_item()
	queue_redraw()


func set_player_skin_team_color_indices(blue_index: int, red_index: int) -> void:
	_team_skin_color_indices[&"blue"] = (
		FootballCosmeticInventory.sanitize_player_skin_color_index(blue_index)
	)
	_team_skin_color_indices[&"red"] = (
		FootballCosmeticInventory.sanitize_player_skin_color_index(red_index)
	)
	_refresh_display_item()
	queue_redraw()


func set_goal_explosion_color_index(color_index: int) -> void:
	_goal_explosion_color_index = FootballCosmeticInventory.sanitize_goal_explosion_color_index(
		color_index
	)
	_refresh_display_item()
	queue_redraw()


func set_player_banner_color_index(color_index: int) -> void:
	_player_banner_color_index = FootballCosmeticInventory.sanitize_player_banner_color_index(
		color_index
	)
	_refresh_display_item()
	queue_redraw()


func set_frame_palette_id(palette_id: String) -> void:
	_frame_palette_id = palette_id
	_refresh_display_item()
	queue_redraw()


func set_player_material_id(material_id: String) -> void:
	_player_material_id = material_id
	queue_redraw()


func set_team_primary_color_indices(blue_index: int, red_index: int) -> void:
	_team_primary_color_indices[&"blue"] = FootballCosmeticInventory.sanitize_team_primary_color_index(&"blue", blue_index)
	_team_primary_color_indices[&"red"] = FootballCosmeticInventory.sanitize_team_primary_color_index(&"red", red_index)
	queue_redraw()


func set_preview_player_skin(skin_id: String, skin_item: Dictionary) -> void:
	_preview_player_skin_id = skin_id
	_preview_player_skin_item = skin_item.duplicate(true)
	queue_redraw()




func _resolve_goal_theme_texture(goal_theme_item: Dictionary) -> Texture2D:
	var icon_path: String = str(goal_theme_item.get("icon_path", GOAL_THEME_ICON_PATH))
	if not icon_path.is_empty():
		var loaded_texture := load(icon_path) as Texture2D
		if loaded_texture != null:
			return loaded_texture
	return GOAL_THEME_ICON_TEXTURE

func _refresh_display_item() -> void:
	var slot: StringName = StringName(_base_item.get("slot", &""))
	if slot == FootballCosmeticInventory.SLOT_PLAYER_SKIN:
		item = FootballCosmeticInventory.apply_player_skin_color(
			item_id,
			_base_item,
			_player_skin_color_index
		)
		if preview_team in [&"blue", &"red"]:
			item = FootballCosmeticInventory.apply_player_skin_team_profile(
				_frame_palette_id,
				item,
				preview_team
			)
	elif slot == FootballCosmeticInventory.SLOT_GOAL_EXPLOSION:
		item = FootballCosmeticInventory.apply_goal_explosion_color(
			_base_item,
			_goal_explosion_color_index
		)
	elif slot == FootballCosmeticInventory.SLOT_PLAYER_BANNER:
		item = FootballCosmeticInventory.apply_player_banner_color(
			_base_item,
			_player_banner_color_index
		)
	else:
		item = _base_item.duplicate(true)


func set_preview_team(team: StringName) -> void:
	preview_team = team if team in [&"both", &"blue", &"red"] else &"blue"
	_refresh_display_item()
	queue_redraw()


func get_player_preview_spec() -> Dictionary:
	var outer_radius: float = _player_preview_outer_radius()
	var visual_scale: float = outer_radius / 132.0
	return {
		"outer_radius": outer_radius,
		"team_radius": 124.0 * visual_scale,
		"trim_radius": 111.0 * visual_scale,
		"inner_radius": 103.0 * visual_scale,
		"has_cosmetic_layer": item_id != "player_skin.classic",
		"outer_deco": str(item.get("outer_deco", "")),
		"outer_detail_scale": FootballPlayerSkinVisuals.get_outer_detail_scale(item),
		"animated": FootballPlayerSkinVisuals.has_animated_details(item_id, item),
		"pattern": str(item.get(
			"pattern",
			"galaxy" if item_id == "player_skin.andromeda" else "rings"
		)),
		"side_by_side": preview_team == &"both",
	}


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var draw_size: Vector2 = size
	var center: Vector2 = draw_size * 0.5
	var slot: StringName = StringName(item.get("slot", &""))
	var is_andromeda: bool = item_id.contains("andromeda")
	var primary: Color = _item_color("primary", Color(0.35, 0.72, 1.0))
	var secondary: Color = _item_color("secondary", Color(0.96, 0.96, 0.98))
	match slot:
		FootballCosmeticInventory.SLOT_PLAYER_SKIN:
			if preview_team == &"both":
				_draw_player_preview_pair(draw_size)
			else:
				_draw_player_preview(center, secondary)
		FootballCosmeticInventory.SLOT_FRAME_PALETTE:
			_draw_player_preview_pair(draw_size)
		FootballCosmeticInventory.SLOT_PLAYER_MATERIAL:
			_draw_player_preview_pair(draw_size)
		FootballCosmeticInventory.SLOT_TEAM_COLOR:
			_draw_player_preview_pair(draw_size)
		FootballCosmeticInventory.SLOT_GOAL_EXPLOSION:
			_draw_explosion_preview(center, primary, secondary)
		FootballCosmeticInventory.SLOT_PLAYER_BANNER:
			_draw_banner_preview(draw_size, primary, secondary, is_andromeda)
		FootballCosmeticInventory.SLOT_GOAL_THEME:
			_draw_goal_theme_preview(draw_size, primary, secondary)
		FootballCosmeticInventory.SLOT_ABILITY_PARTICLE:
			_draw_ability_particle_preview(center, primary, secondary)
		FootballCosmeticInventory.SLOT_QUICK_CHAT:
			_draw_quick_chat_preview(draw_size, primary)
		_:
			draw_circle(center, 42.0, Color(0.2, 0.22, 0.24, 0.9))


func _draw_player_preview(
	center: Vector2,
	secondary: Color
) -> void:
	_draw_player_preview_for_team(
		center,
		preview_team,
		_player_item_for_team(preview_team),
		secondary,
		_player_preview_outer_radius()
	)


func _draw_player_preview_pair(draw_size: Vector2) -> void:
	var pair_radius: float = clampf(
		minf(draw_size.x * 0.205, draw_size.y * 0.29),
		18.0,
		58.0
	)
	var center_y: float = draw_size.y * 0.47
	for team_data: Dictionary in [
		{"team": &"blue", "x": draw_size.x * 0.27, "label": "BLUE"},
		{"team": &"red", "x": draw_size.x * 0.73, "label": "RED"},
	]:
		var team_name: StringName = StringName(team_data["team"])
		var team_item: Dictionary = _player_item_for_team(team_name)
		var team_secondary := _dictionary_color(
			team_item,
			"frame_secondary",
			Color.WHITE
		)
		var team_center := Vector2(float(team_data["x"]), center_y)
		_draw_player_preview_for_team(
			team_center,
			team_name,
			team_item,
			team_secondary,
			pair_radius
		)
		draw_string(
			ThemeDB.fallback_font,
			team_center + Vector2(-pair_radius, pair_radius + 24.0),
			str(team_data["label"]),
			HORIZONTAL_ALIGNMENT_CENTER,
			pair_radius * 2.0,
			14,
			Color("7bc4ff") if team_name == &"blue" else Color("ff7a8a")
		)


func _draw_goal_theme_preview(draw_size: Vector2, _primary: Color, _secondary: Color) -> void:
	# Goal Theme previews use the exact same PNG as the item cards.
	# Load the shared icon directly as a fallback too, so the preview cannot
	# fall back to a stale placeholder if the cached slot texture is missing.
	var theme_texture: Texture2D = _goal_theme_texture
	if theme_texture == null:
		theme_texture = load(GOAL_THEME_ICON_PATH) as Texture2D
	if theme_texture == null:
		theme_texture = GOAL_THEME_ICON_TEXTURE
	if theme_texture == null:
		return
	var texture_size: Vector2 = theme_texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	var panel_rect := Rect2(Vector2(14.0, 18.0), draw_size - Vector2(28.0, 36.0))
	draw_rect(panel_rect, Color(0.055, 0.038, 0.13, 0.86), true)
	var max_size: Vector2 = Vector2(panel_rect.size.x * 0.72, panel_rect.size.y * 0.72)
	var scale_factor: float = minf(
		max_size.x / texture_size.x,
		max_size.y / texture_size.y
	)
	var icon_size: Vector2 = texture_size * scale_factor
	var icon_rect := Rect2(panel_rect.get_center() - icon_size * 0.5, icon_size)
	draw_texture_rect(theme_texture, icon_rect, false, Color.WHITE)
	var caption_width: float = maxf(24.0, panel_rect.size.x - 24.0)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(panel_rect.position.x + 12.0, panel_rect.position.y + panel_rect.size.y - 8.0),
		"GOAL THEME",
		HORIZONTAL_ALIGNMENT_CENTER,
		caption_width,
		16,
		Color(0.92, 0.94, 0.98, 0.84)
	)


func _player_item_for_team(team_name: StringName) -> Dictionary:
	var color_index: int = int(_team_skin_color_indices.get(
		team_name,
		FootballCosmeticInventory.PLAYER_SKIN_ORIGINAL_COLOR
	))
	var colored_item: Dictionary = FootballCosmeticInventory.apply_player_skin_color(
		_player_visual_id(),
		_player_visual_base_item(),
		color_index
	)
	return FootballCosmeticInventory.apply_player_skin_team_profile(
		_active_frame_palette_id(),
		colored_item,
		team_name
	)


func _draw_player_preview_for_team(
	center: Vector2,
	team_name: StringName,
	display_item: Dictionary,
	secondary: Color,
	outer_radius: float
) -> void:
	# These proportions and layers mirror Characters/player.gd. The preview is
	# deliberately a scaled player badge, not a separate cosmetic illustration.
	var team_color: Color = FootballCosmeticInventory.get_team_primary_color_from_index(
		team_name,
		int(_team_primary_color_indices.get(team_name, 0))
	)
	var active_palette_id: String = _active_frame_palette_id()
	var custom_frame_palette: bool = active_palette_id != "frame_palette.classic_touch"
	var frame_color: Color = secondary if custom_frame_palette else Color(0.92, 0.97, 0.97, 0.96)
	var frame_primary: Color = _dictionary_color(display_item, "frame_primary", team_color)
	var frame_glow: Color = _dictionary_color(display_item, "team_glow", team_color)
	var frame_ring_color: Color = (
		team_color.lerp(frame_primary, 0.68) if custom_frame_palette else team_color
	)
	var visual_scale: float = outer_radius / 132.0
	var team_radius: float = 124.0 * visual_scale
	var trim_radius: float = 111.0 * visual_scale
	var inner_radius: float = 103.0 * visual_scale
	var shadow_offset := Vector2(0.0, 13.0) * visual_scale
	draw_circle(center + shadow_offset * 1.30, outer_radius + 10.0 * visual_scale, Color(0.0, 0.0, 0.0, 0.16))
	draw_circle(center + shadow_offset * 0.70, outer_radius + 5.0 * visual_scale, Color(0.0, 0.005, 0.008, 0.28))
	draw_circle(
		center,
		outer_radius + 7.0 * visual_scale,
		Color(frame_glow, 0.38) if custom_frame_palette else Color(team_color, 0.20)
	)
	draw_circle(center, outer_radius, Color(0.008, 0.018, 0.025, 0.92))
	draw_circle(center, team_radius, Color(frame_ring_color, 0.92 if custom_frame_palette else 0.88))
	var material_item: Dictionary = _active_player_material_item()
	FootballPlayerSkinVisuals.draw_team_material(
		self,
		center,
		material_item,
		team_color,
		team_radius,
		trim_radius,
		visual_scale,
		_preview_time
	)
	_draw_material_identity_overlays(
		center,
		material_item,
		team_color,
		team_radius,
		trim_radius,
		visual_scale,
		_preview_time
	)
	draw_circle(center, trim_radius, frame_color)
	draw_circle(center, inner_radius, Color(0.035, 0.065, 0.09).lerp(team_color.darkened(0.68), 0.18))
	FootballPlayerSkinVisuals.draw_skin(
		self,
		center,
		_player_visual_id(),
		display_item,
		inner_radius,
		team_radius,
		visual_scale,
		_preview_time
	)
	FootballPlayerSkinVisuals.draw_team_frame(
		self,
		center,
		_player_visual_id(),
		display_item,
		team_color,
		outer_radius,
		team_radius,
		visual_scale,
		_preview_time
	)
	var frame_highlight := Color(
		minf(team_color.r + 0.28, 1.0),
		minf(team_color.g + 0.28, 1.0),
		minf(team_color.b + 0.28, 1.0),
		0.68
	)
	if custom_frame_palette:
		frame_highlight = frame_primary.lerp(frame_glow, 0.24)
		frame_highlight.a = 0.92
		draw_arc(
			center, outer_radius - 2.0 * visual_scale, 0.0, TAU, 64,
			Color(frame_primary, 0.42), 2.2 * visual_scale, true
		)
	draw_arc(center, team_radius - 3.0 * visual_scale, PI * 1.08, PI * 1.88, 42, frame_highlight, 3.0 * visual_scale, true)
	draw_arc(
		center, team_radius - 4.0 * visual_scale, PI * 0.08, PI * 0.88, 42,
		Color(frame_glow, 0.48) if custom_frame_palette else Color(0.0, 0.01, 0.018, 0.22),
		4.0 * visual_scale if custom_frame_palette else 5.0 * visual_scale, true
	)
	draw_arc(
		center, inner_radius - 2.0 * visual_scale, 0.0, TAU, 48,
		Color(frame_primary, 0.40) if custom_frame_palette else Color(frame_color, 0.26),
		2.5 * visual_scale, true
	)
	for post_direction: Vector2 in [Vector2.UP, Vector2.DOWN]:
		var post_position: Vector2 = center + post_direction * (team_radius - 6.5 * visual_scale)
		draw_circle(post_position, 5.5 * visual_scale, frame_color)
		draw_circle(
			post_position, 2.7 * visual_scale,
			Color(frame_glow, 0.98) if custom_frame_palette else Color(team_color, 0.94)
		)


func _draw_material_identity_overlays(
	center: Vector2,
	material_item: Dictionary,
	team_color: Color,
	team_radius: float,
	trim_radius: float,
	visual_scale: float,
	time_seconds: float
) -> void:
	var material_style: String = str(material_item.get("material_style", "matte"))
	if material_style == "" or material_style == "matte":
		return
	var ring_mid: float = lerpf(trim_radius, team_radius, 0.55)
	var ring_span: float = maxf(3.0 * visual_scale, team_radius - trim_radius)
	var bright: Color = team_color.lightened(0.36)
	var soft: Color = team_color.lightened(0.18)
	var dark: Color = team_color.darkened(0.26)
	match material_style:
		"anodized":
			for band in range(3):
				var offset: float = float(band) * 0.16
				var glow_color: Color = bright.lerp(Color(0.92, 0.60 + 0.08 * band, 1.0, 1.0), 0.35)
				draw_arc(center, ring_mid - band * 1.8 * visual_scale, -0.55 + offset, 0.85 + offset, 28, Color(glow_color, 0.55), 2.4 * visual_scale, true)
				draw_arc(center, ring_mid - band * 1.8 * visual_scale, PI + 0.30 + offset, PI + 1.55 + offset, 28, Color(soft, 0.40), 2.0 * visual_scale, true)
		"brushed":
			for i in range(10):
				var angle: float = -0.92 + i * 0.22
				var inner: Vector2 = center + Vector2.RIGHT.rotated(angle) * (trim_radius + 2.0 * visual_scale)
				var outer: Vector2 = center + Vector2.RIGHT.rotated(angle + 0.12) * (team_radius - 2.2 * visual_scale)
				draw_line(inner, outer, Color(bright, 0.34 if i % 2 == 0 else 0.22), 1.6 * visual_scale, true)
				inner = center + Vector2.RIGHT.rotated(angle + PI) * (trim_radius + 2.0 * visual_scale)
				outer = center + Vector2.RIGHT.rotated(angle + PI + 0.12) * (team_radius - 2.2 * visual_scale)
				draw_line(inner, outer, Color(bright, 0.30 if i % 2 == 0 else 0.18), 1.6 * visual_scale, true)
		"carbon":
			for i in range(12):
				var a0: float = float(i) * TAU / 12.0
				var p0: Vector2 = center + Vector2.RIGHT.rotated(a0) * (trim_radius + 1.5 * visual_scale)
				var p1: Vector2 = center + Vector2.RIGHT.rotated(a0 + 0.16) * (ring_mid - 1.5 * visual_scale)
				var p2: Vector2 = center + Vector2.RIGHT.rotated(a0 + 0.32) * (team_radius - 2.0 * visual_scale)
				var p3: Vector2 = center + Vector2.RIGHT.rotated(a0 + 0.16) * (ring_mid + 2.0 * visual_scale)
				draw_colored_polygon(PackedVector2Array([p0, p1, p2, p3]), Color(dark, 0.26))
				draw_polyline(PackedVector2Array([p0, p1, p2, p3, p0]), Color(bright, 0.22), 1.0 * visual_scale, true)
		"pearl":
			var pearl_a: Color = Color(1.0, 0.82, 0.98, 0.48)
			var pearl_b: Color = Color(0.72, 0.96, 1.0, 0.34)
			draw_arc(center, ring_mid, -0.25, 1.95, 34, pearl_a, 3.2 * visual_scale, true)
			draw_arc(center, ring_mid - 2.0 * visual_scale, PI * 0.82, PI * 1.72, 30, pearl_b, 2.4 * visual_scale, true)
			for i in range(6):
				var sparkle_pos: Vector2 = center + Vector2.RIGHT.rotated(time_seconds * 0.55 + i * TAU / 6.0) * (ring_mid + sin(time_seconds * 1.4 + i) * 1.6 * visual_scale)
				draw_circle(sparkle_pos, 1.2 * visual_scale, Color(1,1,1,0.55))
		"circuit":
			for i in range(8):
				var angle: float = time_seconds * 0.18 + float(i) * TAU / 8.0
				var p0: Vector2 = center + Vector2.RIGHT.rotated(angle) * (trim_radius + 1.5 * visual_scale)
				var p1: Vector2 = center + Vector2.RIGHT.rotated(angle) * (team_radius - 3.6 * visual_scale)
				var p2: Vector2 = p1 + Vector2.RIGHT.rotated(angle + (0.35 if i % 2 == 0 else -0.35)) * (5.0 * visual_scale)
				draw_line(p0, p1, Color(bright, 0.42), 1.7 * visual_scale, true)
				draw_line(p1, p2, Color(bright, 0.42), 1.7 * visual_scale, true)
				draw_circle(p1, 1.8 * visual_scale, Color(bright, 0.75))
		"stardust":
			for i in range(14):
				var angle: float = float(i) * TAU / 14.0 + sin(time_seconds * 0.7 + i * 0.9) * 0.08
				var radius: float = trim_radius + 2.0 * visual_scale + fmod(float(i) * 3.1, ring_span - 1.0 * visual_scale)
				var capped_radius: float = minf(radius, team_radius - 1.5 * visual_scale)
				var pos: Vector2 = center + Vector2.RIGHT.rotated(angle) * capped_radius
				var size: float = 1.1 * visual_scale + float(i % 3) * 0.35 * visual_scale
				draw_circle(pos, size, Color(1.0, 1.0, 1.0, 0.68))
				draw_line(pos + Vector2(-size, 0), pos + Vector2(size, 0), Color(bright, 0.42), 1.0 * visual_scale, true)
				draw_line(pos + Vector2(0, -size), pos + Vector2(0, size), Color(bright, 0.42), 1.0 * visual_scale, true)
		"vortex":
			for band in range(4):
				var start: float = time_seconds * 0.45 + float(band) * 0.52
				var end: float = start + 1.02 + float(band) * 0.12
				draw_arc(center, ring_mid - band * 1.5 * visual_scale, start, end, 32, Color(bright, 0.34 - band * 0.05), 2.1 * visual_scale, true)
				draw_arc(center, ring_mid + band * 0.9 * visual_scale, start + PI, end + PI * 0.92, 32, Color(soft, 0.26 - band * 0.04), 1.8 * visual_scale, true)
		_:
			pass


func _player_visual_id() -> String:
	return (
		_preview_player_skin_id
		if StringName(_base_item.get("slot", &""))
		in [
			FootballCosmeticInventory.SLOT_FRAME_PALETTE,
			FootballCosmeticInventory.SLOT_PLAYER_MATERIAL,
			FootballCosmeticInventory.SLOT_TEAM_COLOR,
		]
		else item_id
	)


func _player_visual_base_item() -> Dictionary:
	return (
		_preview_player_skin_item
		if StringName(_base_item.get("slot", &""))
		in [
			FootballCosmeticInventory.SLOT_FRAME_PALETTE,
			FootballCosmeticInventory.SLOT_PLAYER_MATERIAL,
			FootballCosmeticInventory.SLOT_TEAM_COLOR,
		]
		else _base_item
	)


func _active_frame_palette_id() -> String:
	return (
		item_id
		if StringName(_base_item.get("slot", &""))
		== FootballCosmeticInventory.SLOT_FRAME_PALETTE
		else _frame_palette_id
	)


func _active_player_material_item() -> Dictionary:
	var active_id: String = (
		item_id
		if StringName(_base_item.get("slot", &""))
		== FootballCosmeticInventory.SLOT_PLAYER_MATERIAL
		else _player_material_id
	)
	return FootballCosmeticInventory.CATALOG.get(
		active_id,
		FootballCosmeticInventory.CATALOG["player_material.matte"]
	) as Dictionary


func _dictionary_color(source: Dictionary, key: String, fallback: Color) -> Color:
	var html: String = str(source.get(key, ""))
	return Color(html) if Color.html_is_valid(html) else fallback


func _player_preview_outer_radius() -> float:
	var smallest_side: float = minf(size.x, size.y)
	if smallest_side <= 1.0:
		return 75.0
	# Team-frame decorations can extend roughly 11% beyond the nominal radius.
	# Reserving that space keeps every skin inside its actual preview/hitbox.
	return clampf(smallest_side * 0.39, 18.0, 75.0)


func _draw_explosion_preview(
	center: Vector2,
	primary: Color,
	secondary: Color
) -> void:
	var phase: float = fmod(_preview_time, 1.6) / 1.6
	var expansion: float = 1.0 - pow(1.0 - phase, 3.0)
	var fade: float = maxf(0.12, 1.0 - phase)
	var radius: float = maxf(28.0, minf(size.x, size.y) * 0.40)
	var pattern: String = (
		"galaxy" if item_id.contains("andromeda")
		else str(item.get("pattern", "rays"))
	)
	draw_circle(center, radius * lerpf(0.22, 0.72, expansion), Color(primary, fade * 0.16))
	match pattern:
		"confetti":
			_draw_preview_confetti(center, radius, phase, primary, secondary)
		"flame":
			_draw_preview_flame(center, radius, phase, primary, secondary)
		"electric":
			_draw_preview_electric(center, radius, phase, primary, secondary)
		"vortex":
			_draw_preview_vortex(center, radius, phase, primary, secondary)
		"pixel":
			_draw_preview_pixel(center, radius, phase, primary, secondary)
		"crown":
			_draw_preview_crown(center, radius, phase, primary, secondary)
		"frost":
			_draw_preview_frost(center, radius, phase, primary, secondary)
		"comet":
			_draw_preview_comet(center, radius, phase, primary, secondary)
		"trophy":
			_draw_preview_trophy(center, radius, phase, primary, secondary)
		"stadium":
			_draw_preview_stadium(center, radius, phase, primary, secondary)
		"galaxy":
			_draw_preview_galaxy(center, radius, phase, primary, secondary)
		_:
			_draw_preview_rays(center, radius, phase, primary, secondary)


func _draw_preview_rays(center: Vector2, radius: float, phase: float, primary: Color, secondary: Color) -> void:
	for index: int in range(18):
		var direction := Vector2.from_angle(TAU * float(index) / 18.0)
		draw_line(center + direction * radius * 0.18, center + direction * radius * lerpf(0.5, 1.0, phase), Color(primary if index % 2 == 0 else secondary, 1.0 - phase * 0.7), lerpf(5.0, 1.5, phase), true)
	draw_circle(center, radius * lerpf(0.32, 0.08, phase), secondary)


func _draw_preview_confetti(center: Vector2, radius: float, phase: float, primary: Color, secondary: Color) -> void:
	for index: int in range(28):
		var spread: float = (float((index * 37) % 101) / 100.0 - 0.5) * radius * 1.8
		var start_y: float = -radius * 0.72 + float(index % 5) * radius * 0.12
		var fall_y: float = fposmod(phase + float(index % 7) * 0.11, 1.0) * radius * 1.55
		var point := center + Vector2(spread, start_y + fall_y)
		var piece := Vector2(radius * 0.09, radius * (0.035 if index % 2 == 0 else 0.075))
		draw_set_transform(point, phase * 5.0 + float(index), Vector2.ONE)
		draw_rect(Rect2(-piece * 0.5, piece), primary if index % 3 == 0 else secondary, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_arc(center, radius * 0.28, 0.0, TAU, 36, secondary, 4.0, true)


func _draw_preview_flame(center: Vector2, radius: float, phase: float, primary: Color, secondary: Color) -> void:
	for index: int in range(7):
		var x: float = (float(index) - 3.0) * radius * 0.18
		var height: float = radius * (0.65 + float(index % 3) * 0.18) * (0.82 + sin(phase * TAU + float(index)) * 0.12)
		var base := center + Vector2(x, radius * 0.56)
		var flame := PackedVector2Array([base - Vector2(radius * 0.13, 0.0), base - Vector2(radius * 0.06, height * 0.52), base + Vector2(0.0, -height), base + Vector2(radius * 0.08, -height * 0.46), base + Vector2(radius * 0.13, 0.0)])
		draw_colored_polygon(flame, Color(primary if index % 2 == 0 else secondary, 0.88))
	draw_circle(center + Vector2(0.0, radius * 0.34), radius * 0.22, secondary)


func _draw_preview_electric(center: Vector2, radius: float, phase: float, primary: Color, secondary: Color) -> void:
	for index: int in range(8):
		var direction := Vector2.from_angle(TAU * float(index) / 8.0 + phase * 0.18)
		var tangent := direction.orthogonal()
		var points := PackedVector2Array([center + direction * radius * 0.15, center + direction * radius * 0.42 + tangent * radius * 0.12, center + direction * radius * 0.64 - tangent * radius * 0.08, center + direction * radius])
		draw_polyline(points, secondary if index % 2 == 0 else primary, 4.0, true)
	draw_circle(center, radius * 0.18, Color.WHITE)


func _draw_preview_vortex(center: Vector2, radius: float, phase: float, primary: Color, secondary: Color) -> void:
	for arm: int in range(4):
		var points := PackedVector2Array()
		for step: int in range(24):
			var ratio: float = float(step) / 23.0
			var angle: float = phase * TAU + float(arm) * PI * 0.5 + ratio * PI * 1.7
			points.append(center + Vector2.from_angle(angle) * radius * ratio)
		draw_polyline(points, Color(primary if arm % 2 == 0 else secondary, 0.9), 4.0, true)
	draw_circle(center, radius * 0.15, secondary)


func _draw_preview_pixel(center: Vector2, radius: float, phase: float, primary: Color, secondary: Color) -> void:
	for index: int in range(30):
		var angle: float = float(index) * 2.399
		var distance: float = radius * fposmod(phase + float(index % 6) * 0.12, 1.0)
		var point: Vector2 = center + Vector2.from_angle(angle) * distance
		var block_size: float = radius * (0.14 if index % 4 == 0 else 0.09)
		draw_rect(Rect2(point - Vector2.ONE * block_size * 0.5, Vector2.ONE * block_size), primary if index % 2 == 0 else secondary, true)


func _draw_preview_crown(center: Vector2, radius: float, phase: float, primary: Color, secondary: Color) -> void:
	var scale_value: float = lerpf(0.55, 1.0, sin(phase * PI))
	var width: float = radius * scale_value
	var crown := PackedVector2Array([center + Vector2(-width, radius * 0.32), center + Vector2(-width * 0.82, -radius * 0.48), center + Vector2(-width * 0.34, -radius * 0.08), center + Vector2(0.0, -radius * 0.72), center + Vector2(width * 0.34, -radius * 0.08), center + Vector2(width * 0.82, -radius * 0.48), center + Vector2(width, radius * 0.32), center + Vector2(-width, radius * 0.32)])
	draw_colored_polygon(crown, Color(primary, 0.35))
	draw_polyline(crown, secondary, 5.0, true)
	for jewel_x: float in [-0.45, 0.0, 0.45]:
		draw_circle(center + Vector2(width * jewel_x, radius * 0.18), radius * 0.07, Color.WHITE)


func _draw_preview_frost(center: Vector2, radius: float, phase: float, primary: Color, secondary: Color) -> void:
	for branch: int in range(6):
		var direction := Vector2.from_angle(float(branch) * TAU / 6.0 + phase * 0.35)
		draw_line(center, center + direction * radius, secondary, 4.0, true)
		for ratio: float in [0.45, 0.7]:
			var root: Vector2 = center + direction * radius * ratio
			draw_line(root, root - direction.rotated(0.62) * radius * 0.23, primary, 3.0, true)
			draw_line(root, root - direction.rotated(-0.62) * radius * 0.23, primary, 3.0, true)
	draw_circle(center, radius * 0.12, Color.WHITE)


func _draw_preview_comet(center: Vector2, radius: float, phase: float, primary: Color, secondary: Color) -> void:
	var x: float = lerpf(-radius * 1.15, radius * 1.15, phase)
	var head := center + Vector2(x, sin(phase * PI) * -radius * 0.28)
	for trail: int in range(7):
		var length: float = radius * (0.42 + float(trail) * 0.08)
		draw_line(head - Vector2(length, float(trail - 3) * radius * 0.035), head, Color(primary if trail % 2 == 0 else secondary, 0.74), 5.0 - float(trail) * 0.35, true)
	draw_circle(head, radius * 0.20, secondary)
	draw_circle(head, radius * 0.09, Color.WHITE)


func _draw_preview_trophy(center: Vector2, radius: float, phase: float, primary: Color, secondary: Color) -> void:
	var lift: float = lerpf(radius * 0.32, -radius * 0.12, sin(phase * PI))
	var cup_center := center + Vector2(0.0, lift)
	var cup := PackedVector2Array([cup_center + Vector2(-radius * 0.46, -radius * 0.38), cup_center + Vector2(radius * 0.46, -radius * 0.38), cup_center + Vector2(radius * 0.30, radius * 0.12), cup_center + Vector2(0.0, radius * 0.34), cup_center + Vector2(-radius * 0.30, radius * 0.12), cup_center + Vector2(-radius * 0.46, -radius * 0.38)])
	draw_colored_polygon(cup, Color(primary, 0.42))
	draw_polyline(cup, secondary, 5.0, true)
	draw_line(cup_center + Vector2(0.0, radius * 0.32), cup_center + Vector2(0.0, radius * 0.62), secondary, 6.0, true)
	draw_line(cup_center + Vector2(-radius * 0.3, radius * 0.62), cup_center + Vector2(radius * 0.3, radius * 0.62), secondary, 7.0, true)


func _draw_preview_stadium(center: Vector2, radius: float, phase: float, primary: Color, secondary: Color) -> void:
	for wave: int in range(4):
		var wave_phase: float = fposmod(phase + float(wave) * 0.18, 1.0)
		draw_arc(center + Vector2(0.0, radius * 0.48), radius * lerpf(0.3, 1.05, wave_phase), PI, TAU, 48, Color(primary if wave % 2 == 0 else secondary, 1.0 - wave_phase), 5.0, true)
	for side: float in [-1.0, 1.0]:
		var source := center + Vector2(side * radius * 0.92, -radius * 0.82)
		draw_colored_polygon(PackedVector2Array([source, center + Vector2(-radius * 0.18, radius * 0.55), center + Vector2(radius * 0.18, radius * 0.55)]), Color(secondary, 0.13 + 0.08 * sin(phase * TAU)))
	draw_circle(center, radius * 0.16, Color.WHITE)


func _draw_preview_galaxy(center: Vector2, radius: float, phase: float, primary: Color, secondary: Color) -> void:
	for arm: int in range(3):
		var points := PackedVector2Array()
		for step: int in range(28):
			var ratio: float = float(step) / 27.0
			var angle: float = phase * 0.8 + float(arm) * TAU / 3.0 + ratio * PI * 2.2
			points.append(center + Vector2.from_angle(angle) * radius * ratio)
		draw_polyline(points, Color(primary if arm % 2 == 0 else secondary, 0.76), 3.0, true)
	draw_circle(center, radius * 0.2, Color.WHITE)


func _draw_banner_preview(
	draw_size: Vector2,
	primary: Color,
	_secondary: Color,
	is_andromeda: bool
) -> void:
	var banner_rect := Rect2(
		Vector2(10.0, draw_size.y * 0.26),
		Vector2(maxf(80.0, draw_size.x - 20.0), draw_size.y * 0.48)
	)
	var preview_item: Dictionary = item.duplicate(true)
	if is_andromeda and not preview_item.has("frame_style"):
		preview_item["frame_style"] = "electric"
	FootballPlayerBannerVisuals.draw_banner(
		self,
		banner_rect,
		preview_item,
		primary,
		true,
		_banner_texture,
		_preview_time
	)


func _draw_quick_chat_preview(draw_size: Vector2, primary: Color) -> void:
	var bubble_rect := Rect2(
		Vector2(20.0, draw_size.y * 0.27),
		Vector2(maxf(80.0, draw_size.x - 40.0), draw_size.y * 0.42)
	)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.045, 0.055, 0.96)
	style.border_color = primary
	style.set_border_width_all(3)
	style.set_corner_radius_all(16)
	draw_style_box(style, bubble_rect)
	var tail := PackedVector2Array([
		Vector2(bubble_rect.position.x + 44.0, bubble_rect.end.y - 1.0),
		Vector2(bubble_rect.position.x + 65.0, bubble_rect.end.y - 1.0),
		Vector2(bubble_rect.position.x + 48.0, bubble_rect.end.y + 20.0),
	])
	draw_colored_polygon(tail, primary)
	var payload: String = str(item.get("payload", item.get("name", "Quick Chat")))
	draw_string(
		ThemeDB.fallback_font,
		Vector2(bubble_rect.position.x + 12.0, bubble_rect.position.y + bubble_rect.size.y * 0.58),
		payload,
		HORIZONTAL_ALIGNMENT_CENTER,
		bubble_rect.size.x - 24.0,
		16,
		Color(0.94, 0.97, 1.0)
	)


func _draw_ability_particle_preview(
	center: Vector2,
	primary: Color,
	secondary: Color
) -> void:
	var radius: float = maxf(32.0, minf(size.x, size.y) * 0.34)
	var phase: float = fmod(_preview_time, 1.6) / 1.6
	var pattern: String = str(item.get("pattern", "classic"))
	draw_circle(center, radius * 0.42, Color(0.025, 0.05, 0.07, 0.92))
	draw_arc(center, radius * 0.43, 0.0, TAU, 48, Color(secondary, 0.38), 2.0, true)
	for index: int in range(18):
		var seed_phase: float = fposmod(
			phase + float((index * 7) % 18) / 18.0,
			1.0
		)
		var angle: float = float(index) * 2.39996
		if pattern == "orbits":
			angle += phase * TAU * (1.0 if index % 2 == 0 else -0.7)
		var distance: float = radius * lerpf(0.32, 1.02, seed_phase)
		var point: Vector2 = center + Vector2.from_angle(angle) * distance
		var alpha: float = 1.0 - seed_phase * 0.72
		var color: Color = Color(primary if index % 2 == 0 else secondary, alpha)
		match pattern:
			"streaks":
				var tangent: Vector2 = Vector2.from_angle(angle)
				draw_line(point - tangent * 18.0, point + tangent * 5.0, color, 4.0, true)
			"stars":
				_draw_particle_star(point, 7.0 + float(index % 3) * 2.0, color)
			"orbits":
				draw_arc(point, 7.0, 0.0, TAU, 16, color, 3.0, true)
				draw_circle(point + Vector2(5.0, -4.0), 2.4, Color(secondary, alpha))
			"shards":
				var direction: Vector2 = Vector2.from_angle(angle)
				var side: Vector2 = direction.orthogonal()
				draw_colored_polygon(PackedVector2Array([
					point + direction * 11.0,
					point + side * 4.0,
					point - direction * 8.0,
					point - side * 4.0,
				]), color)
			"wisps":
				var tail: Vector2 = Vector2.from_angle(angle - 0.7)
				draw_arc(point - tail * 5.0, 11.0, angle - 1.7, angle + 1.0, 12, color, 4.0, true)
			"bubbles":
				var bubble_radius: float = 5.5 + float(index % 4) * 1.8
				draw_circle(point, bubble_radius, Color(primary, alpha * 0.10))
				draw_arc(point, bubble_radius, 0.0, TAU, 18, color, 2.2, true)
				draw_circle(point + Vector2(-bubble_radius * 0.32, -bubble_radius * 0.34), 1.5, Color(secondary, alpha))
			"comets":
				var comet_direction: Vector2 = Vector2.from_angle(angle)
				draw_line(point - comet_direction * 18.0, point, Color(primary, alpha * 0.55), 4.5, true)
				draw_circle(point, 4.2 + float(index % 2), Color(secondary, alpha))
				draw_circle(point, 2.1, Color.WHITE)
			_:
				draw_circle(point, 4.5 + float(index % 3), color)


func _draw_particle_star(center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for index: int in range(10):
		var point_radius: float = radius if index % 2 == 0 else radius * 0.42
		points.append(
			center + Vector2.from_angle(-PI * 0.5 + float(index) * PI / 5.0) * point_radius
		)
	draw_colored_polygon(points, color)


func _item_color(key: String, fallback: Color) -> Color:
	var html: String = str(item.get(key, ""))
	return Color(html) if Color.html_is_valid(html) else fallback
