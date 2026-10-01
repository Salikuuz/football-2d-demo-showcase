class_name FootballPlayerSkinVisuals
extends RefCounted


static func _draw_circle_aa(
	canvas: CanvasItem,
	position: Vector2,
	radius: float,
	color: Color,
	filled: bool = true,
	width: float = -1.0,
	_antialiased: bool = true
) -> void:
	canvas.draw_circle(position, radius, color, filled, width, true)


static func _screen_pixels_per_world_unit(canvas: CanvasItem) -> float:
	if canvas == null or not canvas.is_inside_tree():
		return 1.0
	var screen_transform := canvas.get_global_transform_with_canvas()
	var x_scale: float = screen_transform.x.length()
	var y_scale: float = screen_transform.y.length()
	return maxf(0.001, (x_scale + y_scale) * 0.5)


static func _physical_pixels_per_world_unit(canvas: CanvasItem) -> float:
	var logical_scale := _screen_pixels_per_world_unit(canvas)
	if canvas == null or not canvas.is_inside_tree():
		return logical_scale
	var viewport := canvas.get_viewport()
	var window := canvas.get_window()
	if viewport == null or window == null:
		return logical_scale
	var logical_size := viewport.get_visible_rect().size
	var physical_size := Vector2(window.size)
	if (
		logical_size.x <= 0.0
		or logical_size.y <= 0.0
		or physical_size.x <= 0.0
		or physical_size.y <= 0.0
	):
		return logical_scale
	var presentation_scale := minf(
		physical_size.x / logical_size.x,
		physical_size.y / logical_size.y
	)
	return maxf(0.001, logical_scale * presentation_scale)


static func _screen_safe_stroke_width(
	canvas: CanvasItem,
	world_width: float,
	minimum_screen_pixels: float = 1.90
) -> float:
	return maxf(
		world_width,
		minimum_screen_pixels / _physical_pixels_per_world_unit(canvas)
	)


static func _draw_arc_screen_aa(
	canvas: CanvasItem,
	center: Vector2,
	radius: float,
	start_angle: float,
	end_angle: float,
	point_count: int,
	color: Color,
	width: float = -1.0,
	antialiased: bool = true
) -> void:
	canvas.draw_arc(
		center, radius, start_angle, end_angle, point_count, color,
		_screen_safe_stroke_width(canvas, width), antialiased
	)


static func _draw_line_screen_aa(
	canvas: CanvasItem,
	from: Vector2,
	to: Vector2,
	color: Color,
	width: float = -1.0,
	antialiased: bool = true
) -> void:
	canvas.draw_line(
		from, to, color,
		_screen_safe_stroke_width(canvas, width), antialiased
	)


static func _draw_polyline_screen_aa(
	canvas: CanvasItem,
	points: PackedVector2Array,
	color: Color,
	width: float = -1.0,
	antialiased: bool = true
) -> void:
	canvas.draw_polyline(
		points, color,
		_screen_safe_stroke_width(canvas, width), antialiased
	)


static func has_animated_details(item_id: String, item: Dictionary = {}) -> bool:
	return bool(item.get("animated", false)) or item_id in [
		"player_skin.andromeda",
		"player_skin.ember",
		"player_skin.neon_pitch",
		"player_skin.shadow_play",
		"player_skin.mint_control",
		"player_skin.sunset_playmaker",
		"player_skin.golden_touch",
		"player_skin.dark_vanguard",
	]


static func get_outer_detail_scale(item: Dictionary) -> float:
	# Outer silhouettes need to survive the large world-to-screen reduction used
	# by the match camera. Higher rarities gain presence, not collision size.
	match str(item.get("rarity", "common")):
		"uncommon":
			return 1.26
		"rare":
			return 1.36
		"epic":
			return 1.44
		"legendary":
			return 1.38
	return 1.12


static func is_inner_pattern_animated(pattern: String) -> bool:
	return pattern in [
		"galaxy",
		"flame",
		"rings",
		"event_horizon",
		"celestial_runes",
		"reactor_core",
		"samba_flux",
		"thunder_core",
	]


static func is_outer_decoration_animated(decoration: String) -> bool:
	return decoration in [
		"flame_crown",
		"orbit",
		"shadow_crescents",
		"dot_orbit",
		"sun_rays",
		"double_halo",
		"pressure_spikes",
		"void_tendrils",
		"astral_wings",
		"plasma_blades",
		"dark_aura",
		"trickster_ribbons",
		"nordic_lightning",
	]


static func is_skin_signature_animated(item_id: String) -> bool:
	return item_id in [
		"player_skin.ember",
		"player_skin.neon_pitch",
		"player_skin.mint_control",
		"player_skin.dark_vanguard",
		"player_skin.abyssal_sovereign",
		"player_skin.omega_reactor",
		"player_skin.brazilian_prince_10",
		"player_skin.nordic_terminator_9",
	]


static func is_frame_style_animated(frame_style: String) -> bool:
	return frame_style in [
		"cosmic_gate",
		"ember_rail",
		"neon_circuit",
		"control_nodes",
		"sun_gate",
		"champion_halo",
		"singularity_crown",
		"seraphic_throne",
		"omega_reactor",
		"joga_bonito",
		"terminator_engine",
	]


static func is_frame_icon_animation(frame_style: String) -> bool:
	return frame_style in [
		"cosmic_gate",
		"neon_circuit",
		"singularity_crown",
		"joga_bonito",
	]


static func is_material_style_animated(material_style: String) -> bool:
	return material_style in ["pearl", "stardust", "vortex"]


static func draw_skin(
	canvas: CanvasItem,
	center: Vector2,
	item_id: String,
	item: Dictionary,
	inner_radius: float,
	team_radius: float,
	visual_scale: float,
	animation_time: float
) -> void:
	_draw_skin_pass(
		canvas, center, item_id, item, inner_radius, team_radius,
		visual_scale, animation_time, true, true
	)


static func draw_skin_static(
	canvas: CanvasItem,
	center: Vector2,
	item_id: String,
	item: Dictionary,
	inner_radius: float,
	team_radius: float,
	visual_scale: float
) -> void:
	_draw_skin_pass(
		canvas, center, item_id, item, inner_radius, team_radius,
		visual_scale, 0.0, true, false
	)


static func draw_skin_animated(
	canvas: CanvasItem,
	center: Vector2,
	item_id: String,
	item: Dictionary,
	inner_radius: float,
	team_radius: float,
	visual_scale: float,
	animation_time: float
) -> void:
	_draw_skin_pass(
		canvas, center, item_id, item, inner_radius, team_radius,
		visual_scale, animation_time, false, true
	)


static func _draw_skin_pass(
	canvas: CanvasItem,
	center: Vector2,
	item_id: String,
	item: Dictionary,
	inner_radius: float,
	team_radius: float,
	visual_scale: float,
	animation_time: float,
	draw_static: bool,
	draw_animated: bool
) -> void:
	if item_id == "player_skin.classic":
		return
	var primary: Color = _catalog_color(item, "primary", Color(0.47, 0.22, 0.92))
	var secondary: Color = _catalog_color(item, "secondary", Color(0.82, 0.95, 1.0))
	var pattern: String = str(item.get(
		"pattern",
		"galaxy" if item_id == "player_skin.andromeda" else "rings"
	))
	var decoration: String = str(item.get("outer_deco", ""))
	var rarity: String = str(item.get("rarity", "common"))
	if draw_static:
		var fill: Color = (
			Color(0.47, 0.22, 0.92, 0.24)
			if pattern == "galaxy"
			else Color(primary, 0.34)
		)
		_draw_circle_aa(canvas, center, inner_radius - 2.0 * visual_scale, fill)
	if (draw_animated and is_inner_pattern_animated(pattern)) or (draw_static and not is_inner_pattern_animated(pattern)):
		_draw_inner_pattern(canvas, center, pattern, primary, secondary, inner_radius, visual_scale, animation_time)
	if (draw_animated and is_outer_decoration_animated(decoration)) or (draw_static and not is_outer_decoration_animated(decoration)):
		_draw_outer_decoration(canvas, center, decoration, primary, secondary, team_radius, visual_scale * get_outer_detail_scale(item), animation_time)
	# The rarity silhouette pulses for every non-common skin, so it belongs to
	# the animated cache layer instead of forcing the whole badge to redraw.
	if rarity != "common" and draw_animated:
		_draw_outer_flash_layer(canvas, center, rarity, primary, secondary, team_radius, visual_scale, animation_time)
	if (draw_animated and is_skin_signature_animated(item_id)) or (draw_static and not is_skin_signature_animated(item_id)):
		_draw_skin_signature(canvas, center, item_id, primary, secondary, inner_radius, team_radius, visual_scale, animation_time)


static func draw_team_frame(
	canvas: CanvasItem,
	center: Vector2,
	item_id: String,
	item: Dictionary,
	team_color: Color,
	outer_radius: float,
	team_radius: float,
	visual_scale: float,
	animation_time: float,
	draw_static: bool = true,
	draw_animated: bool = true
) -> void:
	var primary: Color = _catalog_color(
		item,
		"frame_primary",
		_catalog_color(item, "primary", team_color.lightened(0.22))
	)
	var secondary: Color = _catalog_color(
		item,
		"frame_secondary",
		_catalog_color(item, "secondary", Color.WHITE)
	)
	var team_glow: Color = _catalog_color(
		item,
		"team_glow",
		team_color.lightened(0.24)
	)
	var frame_style: String = str(item.get("frame_style", "classic_rails"))
	var rail_radius: float = lerpf(team_radius, outer_radius, 0.58)
	var outer: float = outer_radius + 2.0 * visual_scale
	var pulse: float = 0.5 + 0.5 * sin(animation_time * 3.0)

	# Static frame geometry is cached. Only the tiny pulsing/moving part is
	# rebuilt by the animated cosmetic layer.
	if draw_static:
		_draw_arc_screen_aa(canvas,
			center,
			rail_radius,
			0.0,
			TAU,
			64,
			Color(primary, 0.30),
			3.0 * visual_scale,
			true
		)
	if draw_animated:
		_draw_arc_screen_aa(canvas,
			center,
			outer + 1.5 * visual_scale,
			-2.82,
			-0.30,
			40,
			Color(team_glow, 0.34 + pulse * 0.18),
			2.0 * visual_scale,
			true
		)
	var frame_style_is_animated: bool = is_frame_style_animated(frame_style)
	if (frame_style_is_animated and draw_animated) or (not frame_style_is_animated and draw_static):
		match frame_style:
			"classic_rails":
				_draw_arc_screen_aa(canvas, center, rail_radius, -2.75, -0.38, 36, Color(secondary, 0.76), 3.5 * visual_scale, true)
				_draw_arc_screen_aa(canvas, center, rail_radius, 0.38, 2.75, 36, Color(team_color.lightened(0.36), 0.88), 3.5 * visual_scale, true)
			"cosmic_gate":
				var rotation: float = animation_time * 0.34
				for arm: int in range(3):
					var start: float = rotation + float(arm) * TAU / 3.0
					_draw_arc_screen_aa(canvas, center, rail_radius, start, start + 0.72, 18, Color(secondary, 0.94), 5.0 * visual_scale, true)
					_draw_circle_aa(canvas, center + Vector2.from_angle(start + 0.72) * outer, 3.0 * visual_scale, Color.WHITE)
			"velocity_cut":
				for side: float in [-1.0, 1.0]:
					var angle: float = 0.0 if side > 0.0 else PI
					_draw_arc_screen_aa(canvas, center, rail_radius, angle - 0.58, angle + 0.58, 18, Color(secondary, 0.94), 6.0 * visual_scale, true)
					for offset: float in [-10.0, 10.0]:
						_draw_line_screen_aa(canvas, center + Vector2(side * team_radius, offset * visual_scale), center + Vector2(side * (outer_radius + 14.0 * visual_scale), (offset - 5.0) * visual_scale), Color(primary.lightened(0.3), 0.82), 4.0 * visual_scale, true)
			"crystal_edge":
				for index: int in range(8):
					var direction: Vector2 = Vector2.from_angle(float(index) * TAU / 8.0)
					var tangent: Vector2 = direction.orthogonal()
					var root: Vector2 = center + direction * rail_radius
					var tip: Vector2 = center + direction * (outer + (5.0 if index % 2 == 0 else 1.0) * visual_scale)
					canvas.draw_colored_polygon(PackedVector2Array([root - tangent * 4.0 * visual_scale, tip, root + tangent * 4.0 * visual_scale]), Color(secondary, 0.74))
			"royal_seal":
				for quadrant: int in range(4):
					var start: float = float(quadrant) * PI * 0.5 + 0.12
					_draw_arc_screen_aa(canvas, center, rail_radius, start, start + 1.02, 20, Color(secondary, 0.90), 6.0 * visual_scale, true)
					_draw_circle_aa(canvas, center + Vector2.from_angle(start + 0.51) * rail_radius, 3.5 * visual_scale, Color(primary.lightened(0.35), 0.96))
			"ember_rail":
				for segment: int in range(7):
					var start: float = float(segment) * TAU / 7.0 + 0.06
					var width: float = 0.48 + pulse * 0.12
					_draw_arc_screen_aa(canvas, center, rail_radius, start, start + width, 14, Color(secondary if segment % 2 else primary.lightened(0.25), 0.92), (4.0 + pulse * 2.0) * visual_scale, true)
			"neon_circuit":
				var scan: float = animation_time * 1.35
				_draw_arc_screen_aa(canvas, center, rail_radius, scan, scan + PI * 1.35, 42, Color(secondary, 0.94), 4.0 * visual_scale, true)
				_draw_arc_screen_aa(canvas, center, outer, -scan, -scan + PI * 0.82, 30, Color(primary.lightened(0.35), 0.82), 2.5 * visual_scale, true)
				for node_index: int in range(4):
					_draw_circle_aa(canvas, center + Vector2.from_angle(scan + float(node_index) * PI * 0.5) * rail_radius, 3.0 * visual_scale, Color.WHITE)
			"eclipse":
				_draw_arc_screen_aa(canvas, center, rail_radius, -2.62, -0.30, 38, Color(0.005, 0.006, 0.012, 0.92), 8.0 * visual_scale, true)
				_draw_arc_screen_aa(canvas, center, rail_radius, 0.48, 2.48, 34, Color(secondary, 0.76), 5.0 * visual_scale, true)
			"aerial_fins":
				for side: float in [-1.0, 1.0]:
					var side_angle: float = 0.0 if side > 0.0 else PI
					_draw_arc_screen_aa(canvas, center, rail_radius, side_angle - 0.72, side_angle + 0.72, 22, Color(secondary, 0.92), 5.0 * visual_scale, true)
					for feather: int in range(3):
						var y: float = (float(feather) - 1.0) * 10.0 * visual_scale
						_draw_line_screen_aa(canvas, center + Vector2(side * outer_radius, y), center + Vector2(side * (outer_radius + 10.0 * visual_scale), y - side * 5.0 * visual_scale), Color(secondary, 0.72), 3.0 * visual_scale, true)
			"pressure_slash":
				for slash: int in range(4):
					var angle: float = float(slash) * PI * 0.5 + 0.32
					_draw_arc_screen_aa(canvas, center, rail_radius, angle, angle + 0.64, 14, Color(secondary, 0.94), 7.0 * visual_scale, true)
					var direction: Vector2 = Vector2.from_angle(angle + 0.32)
					_draw_line_screen_aa(canvas, center + direction * team_radius, center + direction.rotated(-0.14) * (outer + 7.0 * visual_scale), Color(primary.lightened(0.28), 0.88), 4.0 * visual_scale, true)
			"chrome_hex":
				var hexagon := PackedVector2Array()
				for index: int in range(7):
					hexagon.append(center + Vector2.from_angle(float(index) * TAU / 6.0) * rail_radius)
				_draw_polyline_screen_aa(canvas, hexagon, Color(secondary, 0.88), 4.0 * visual_scale, true)
			"control_nodes":
				for index: int in range(8):
					var angle: float = animation_time * 0.32 + float(index) * TAU / 8.0
					var node_position: Vector2 = center + Vector2.from_angle(angle) * rail_radius
					_draw_circle_aa(canvas, node_position, (2.5 + float(index % 2)) * visual_scale, Color(secondary, 0.92))
					if index % 2 == 0:
						_draw_line_screen_aa(canvas, node_position, center + Vector2.from_angle(angle) * team_radius, Color(primary.lightened(0.28), 0.58), 2.0 * visual_scale, true)
			"sun_gate":
				for index: int in range(12):
					var direction: Vector2 = Vector2.from_angle(float(index) * TAU / 12.0)
					var length: float = (5.0 + (3.0 if index % 3 == 0 else 0.0) + pulse * 2.0) * visual_scale
					_draw_line_screen_aa(canvas, center + direction * rail_radius, center + direction * (rail_radius + length), Color(secondary, 0.84), (3.0 if index % 3 == 0 else 2.0) * visual_scale, true)
			"fortress":
				for corner: int in range(4):
					var angle: float = float(corner) * PI * 0.5 + PI * 0.25
					var direction: Vector2 = Vector2.from_angle(angle)
					var tangent: Vector2 = direction.orthogonal()
					var root: Vector2 = center + direction * rail_radius
					_draw_polyline_screen_aa(canvas, PackedVector2Array([root - tangent * 11.0 * visual_scale, center + direction * (outer + 7.0 * visual_scale), root + tangent * 11.0 * visual_scale]), Color(secondary, 0.88), 6.0 * visual_scale, true)
			"champion_halo":
				var halo: float = animation_time * 0.72
				_draw_arc_screen_aa(canvas, center, rail_radius, halo, halo + PI * 1.55, 48, Color(secondary, 0.94), 6.0 * visual_scale, true)
				_draw_arc_screen_aa(canvas, center, outer + 4.0 * visual_scale, -halo, -halo + PI * 1.05, 38, Color(primary.lightened(0.34), 0.82), 3.0 * visual_scale, true)
			"vanguard_armor":
				# Heavy overlapping armor plates, with a dim under-ring so the frame
				# still reads as one premium silhouette at normal gameplay size.
				_draw_arc_screen_aa(canvas, 
					center,
					rail_radius - 2.0 * visual_scale,
					0.0,
					TAU,
					64,
					Color(0.003, 0.004, 0.009, 0.96),
					10.0 * visual_scale,
					true
				)
				for plate: int in range(6):
					var start: float = float(plate) * TAU / 6.0 + 0.10
					var plate_end: float = start + 0.72
					_draw_arc_screen_aa(canvas, center, rail_radius, start, plate_end, 15, Color(0.008, 0.009, 0.018, 0.98), 9.0 * visual_scale, true)
					_draw_arc_screen_aa(canvas, center, rail_radius + 1.5 * visual_scale, start + 0.06, plate_end - 0.06, 12, Color(secondary, 0.82), 2.5 * visual_scale, true)
					_draw_arc_screen_aa(canvas, center, rail_radius - 2.5 * visual_scale, start + 0.18, plate_end - 0.13, 10, Color(primary.lightened(0.18), 0.68), 2.0 * visual_scale, true)
					var rivet_angle: float = start + 0.12
					var rivet_position: Vector2 = center + Vector2.from_angle(rivet_angle) * (rail_radius + 1.0 * visual_scale)
					_draw_circle_aa(canvas, rivet_position, 2.2 * visual_scale, Color(0.02, 0.025, 0.045, 1.0))
					_draw_circle_aa(canvas, rivet_position, 0.9 * visual_scale, Color(secondary, 0.92))
			"singularity_crown":
				var void_rotation: float = animation_time * 0.82
				_draw_arc_screen_aa(canvas, center, rail_radius, 0.0, TAU, 64, Color(0.0, 0.0, 0.015, 0.96), 9.0 * visual_scale, true)
				for shard: int in range(5):
					var shard_angle: float = void_rotation + float(shard) * TAU / 5.0
					_draw_arc_screen_aa(canvas, center, rail_radius, shard_angle, shard_angle + 0.48, 12, Color(secondary, 0.94), 4.5 * visual_scale, true)
					_draw_circle_aa(canvas, center + Vector2.from_angle(shard_angle + 0.48) * outer, 3.0 * visual_scale, Color.WHITE)
			"seraphic_throne":
				var holy_pulse: float = 0.78 + pulse * 0.22
				for wing_index: int in range(6):
					var wing_angle: float = -PI * 0.5 + float(wing_index) * TAU / 6.0
					_draw_arc_screen_aa(canvas, center, rail_radius, wing_angle - 0.34, wing_angle + 0.34, 15, Color(secondary, 0.92), 6.0 * visual_scale, true)
					_draw_line_screen_aa(canvas, center + Vector2.from_angle(wing_angle) * rail_radius, center + Vector2.from_angle(wing_angle) * (outer + 8.0 * holy_pulse * visual_scale), Color(primary.lightened(0.34), 0.78), 3.0 * visual_scale, true)
			"omega_reactor":
				var reactor_rotation: float = animation_time * 1.45
				for blade: int in range(8):
					var blade_angle: float = reactor_rotation + float(blade) * TAU / 8.0
					_draw_arc_screen_aa(canvas, center, rail_radius, blade_angle, blade_angle + 0.38, 10, Color(secondary if blade % 2 == 0 else primary.lightened(0.28), 0.94), 6.0 * visual_scale, true)
					_draw_line_screen_aa(canvas, center + Vector2.from_angle(blade_angle) * team_radius, center + Vector2.from_angle(blade_angle + 0.12) * (outer + 5.0 * visual_scale), Color(secondary, 0.72), 3.0 * visual_scale, true)
			"joga_bonito":
				# Broken, counter-rotating rails make the badge appear to feint left
				# and right without obscuring which team owns the player.
				var feint: float = sin(animation_time * 2.7) * 0.24
				for rail: int in range(3):
					var start: float = feint + float(rail) * TAU / 3.0
					var rail_color: Color = secondary if rail % 2 == 0 else primary
					_draw_arc_screen_aa(canvas, center, rail_radius, start, start + 1.14, 24, Color(rail_color, 0.96), (6.5 - float(rail)) * visual_scale, true)
					var jewel_position: Vector2 = center + Vector2.from_angle(start + 1.14) * (outer + 3.0 * visual_scale)
					_draw_circle_aa(canvas, jewel_position, 4.2 * visual_scale, Color(0.015, 0.08, 0.20, 0.98))
					_draw_circle_aa(canvas, jewel_position, 2.1 * visual_scale, Color.WHITE)
				_draw_arc_screen_aa(canvas, center, outer + 7.0 * visual_scale, -feint + 0.35, -feint + 2.70, 38, Color(primary.lightened(0.24), 0.64), 3.0 * visual_scale, true)
			"terminator_engine":
				# Heavy segmented armor and live electrical bridges give Haaland a
				# larger visual mass while keeping the collision body untouched.
				var engine_pulse: float = 0.5 + 0.5 * sin(animation_time * 4.8)
				_draw_arc_screen_aa(canvas, center, rail_radius, 0.0, TAU, 64, Color(0.015, 0.055, 0.09, 0.98), 11.0 * visual_scale, true)
				for plate: int in range(6):
					var plate_start: float = float(plate) * TAU / 6.0 + 0.10
					_draw_arc_screen_aa(canvas, center, rail_radius, plate_start, plate_start + 0.72, 16, Color(primary.darkened(0.34), 0.98), 8.0 * visual_scale, true)
					_draw_arc_screen_aa(canvas, center, rail_radius + 2.0 * visual_scale, plate_start + 0.08, plate_start + 0.64, 12, Color(secondary, 0.78 + engine_pulse * 0.18), 2.5 * visual_scale, true)
					var plate_direction: Vector2 = Vector2.from_angle(plate_start + 0.36)
					_draw_circle_aa(canvas, center + plate_direction * (outer + 3.0 * visual_scale), (2.7 + engine_pulse) * visual_scale, Color.WHITE)
				for bridge: int in range(3):
					var bridge_angle: float = animation_time * 0.22 + float(bridge) * TAU / 3.0
					_draw_arc_screen_aa(canvas, center, outer + 8.0 * visual_scale, bridge_angle, bridge_angle + 0.48, 10, Color(primary.lightened(0.32), 0.56 + engine_pulse * 0.28), 4.0 * visual_scale, true)
			_:
				_draw_arc_screen_aa(canvas, center, rail_radius, -2.62, -0.52, 32, Color(secondary, 0.82), 4.0 * visual_scale, true)
	var icon_animation: bool = is_frame_icon_animation(frame_style)
	if (icon_animation and draw_animated) or (not icon_animation and draw_static):
		_draw_icon_language_accents(
			canvas,
			center,
			item_id,
			frame_style,
			primary,
			secondary,
			team_color,
			outer,
			visual_scale,
			animation_time
		)

	# Small team-color locks are static and stay cached.
	if draw_static:
		for lock_index: int in range(4):
			var lock_angle: float = float(lock_index) * PI * 0.5
			_draw_arc_screen_aa(canvas, center, team_radius + 1.0 * visual_scale, lock_angle - 0.12, lock_angle + 0.12, 6, Color(team_color.lightened(0.32), 0.98), 4.0 * visual_scale, true)


static func draw_team_material(
	canvas: CanvasItem,
	center: Vector2,
	material_item: Dictionary,
	team_color: Color,
	team_radius: float,
	trim_radius: float,
	visual_scale: float,
	animation_time: float,
	draw_static: bool = true,
	draw_animated: bool = true
) -> void:
	var style: String = str(material_item.get("material_style", "matte"))
	if style == "matte":
		return
	var band_radius: float = (team_radius + trim_radius) * 0.5
	var band_width: float = maxf(2.0, team_radius - trim_radius - 1.5 * visual_scale)
	var highlight: Color = team_color.lightened(0.52)
	var shadow: Color = team_color.darkened(0.62)
	var style_is_animated: bool = is_material_style_animated(style)
	if (style_is_animated and draw_animated) or (not style_is_animated and draw_static):
		match style:
			"anodized":
				_draw_arc_screen_aa(canvas, center, band_radius, PI * 1.04, PI * 1.88, 40, Color(highlight, 0.82), band_width * 0.42, true)
				_draw_arc_screen_aa(canvas, center, band_radius, PI * 0.04, PI * 0.88, 40, Color(shadow, 0.34), band_width * 0.32, true)
			"brushed":
				for index: int in range(20):
					var angle: float = float(index) * TAU / 20.0
					var color: Color = Color(highlight, 0.54) if index % 2 == 0 else Color(shadow, 0.32)
					_draw_arc_screen_aa(canvas, center, band_radius, angle, angle + 0.105, 4, color, band_width * 0.60, true)
			"carbon":
				for index: int in range(24):
					var angle: float = float(index) * TAU / 24.0
					var color: Color = Color(0.04, 0.05, 0.06, 0.58) if index % 2 == 0 else Color(highlight, 0.45)
					_draw_arc_screen_aa(canvas, center, band_radius, angle, angle + 0.17, 4, color, band_width * 0.68, true)
			"pearl":
				var shift: float = fmod(animation_time * 0.48, TAU)
				for index: int in range(3):
					var start: float = shift + float(index) * TAU / 3.0
					var pearl: Color = [Color("72f1ff"), Color("d68cff"), Color("fff08a")][index]
					_draw_arc_screen_aa(canvas, center, band_radius, start, start + 1.30, 22, Color(pearl, 0.60), band_width * 0.55, true)
			"circuit":
				for index: int in range(12):
					var angle: float = float(index) * TAU / 12.0
					var direction := Vector2.from_angle(angle)
					_draw_circle_aa(canvas, center + direction * band_radius, 1.8 * visual_scale, Color(highlight, 0.95))
					_draw_arc_screen_aa(canvas, center, band_radius, angle + 0.06, angle + 0.30, 5, Color(highlight, 0.72), 1.6 * visual_scale, true)
			"stardust":
				for index: int in range(18):
					var angle: float = float(index) * 2.399963 + animation_time * (0.08 if index % 2 == 0 else -0.05)
					var radius: float = lerpf(trim_radius + 2.0 * visual_scale, team_radius - 2.0 * visual_scale, float(index % 4) / 3.0)
					_draw_circle_aa(canvas, center + Vector2.from_angle(angle) * radius, (1.0 + float(index % 3) * 0.45) * visual_scale, Color(highlight, 0.82))
			"vortex":
				var spin: float = animation_time * 1.35
				for index: int in range(5):
					var start: float = spin + float(index) * TAU / 5.0
					_draw_arc_screen_aa(canvas, center, band_radius, start, start + 0.62, 10, Color(highlight, 0.82), band_width * 0.58, true)


static func _draw_icon_language_accents(
	canvas: CanvasItem,
	center: Vector2,
	item_id: String,
	frame_style: String,
	primary: Color,
	secondary: Color,
	team_color: Color,
	radius: float,
	visual_scale: float,
	animation_time: float
) -> void:
	var motif: String = "diamond"
	var angles: Array[float] = [-2.42, 0.72]
	var motif_size: float = 7.0
	match frame_style:
		"classic_rails":
			motif = "tab"
			angles = [-PI * 0.5, PI * 0.5]
			motif_size = 5.0
		"cosmic_gate":
			motif = "diamond"
			angles = [animation_time * 0.34, animation_time * 0.34 + TAU / 3.0, animation_time * 0.34 + TAU * 2.0 / 3.0]
			motif_size = 6.5
		"velocity_cut":
			motif = "arrow"
			angles = [0.0, PI]
			motif_size = 7.5
		"crystal_edge":
			motif = "crystal"
			angles = [-PI * 0.5, 0.0, PI * 0.5, PI]
			motif_size = 6.5
		"royal_seal":
			motif = "crown"
			angles = [-PI * 0.5]
			motif_size = 8.5
		"ember_rail":
			motif = "flame"
			angles = [-2.25, -PI * 0.5, -0.88]
			motif_size = 7.0
		"neon_circuit":
			motif = "node"
			angles = [animation_time * 1.35, animation_time * 1.35 + PI]
			motif_size = 6.0
		"eclipse":
			motif = "blade"
			angles = [-2.55, 0.58]
			motif_size = 8.0
		"aerial_fins":
			motif = "wing"
			angles = [0.0, PI]
			motif_size = 8.0
		"pressure_slash":
			motif = "blade"
			angles = [-2.28, -0.72, 0.86, 2.42]
			motif_size = 7.0
		"chrome_hex":
			motif = "hex"
			angles = [-2.10, -1.04, 1.04, 2.10]
			motif_size = 6.5
		"control_nodes":
			motif = "node"
			angles = [-2.35, -0.78, 0.78, 2.35]
			motif_size = 5.5
		"sun_gate":
			motif = "sun"
			angles = [-PI * 0.5, PI * 0.5]
			motif_size = 7.5
		"fortress":
			motif = "shield"
			angles = [-2.36, -0.78, 0.78, 2.36]
			motif_size = 7.0
		"champion_halo":
			motif = "crown"
			angles = [-PI * 0.5, PI * 0.5]
			motif_size = 7.5
		"vanguard_armor":
			motif = "armor"
			angles = [-2.45, -0.70, 0.70, 2.45]
			motif_size = 8.0
		"singularity_crown":
			motif = "crystal"
			angles = [animation_time * 0.82, animation_time * 0.82 + TAU / 3.0, animation_time * 0.82 + TAU * 2.0 / 3.0]
			motif_size = 7.5
		"seraphic_throne":
			motif = "wing"
			angles = [-2.42, -0.72, 0.72, 2.42]
			motif_size = 8.5
		"omega_reactor":
			motif = "blade"
			angles = [-2.36, -0.78, 0.78, 2.36]
			motif_size = 8.0
		"joga_bonito":
			motif = "diamond"
			angles = [animation_time * 0.55, animation_time * 0.55 + TAU / 3.0, animation_time * 0.55 + TAU * 2.0 / 3.0]
			motif_size = 7.5
		"terminator_engine":
			motif = "crystal"
			angles = [-2.36, -0.78, 0.78, 2.36]
			motif_size = 8.5

	var outline: Color = Color(0.018, 0.025, 0.055, 0.98)
	var fill: Color = secondary
	var inset: Color = primary.lightened(0.28)
	for angle: float in angles:
		var motif_center: Vector2 = center + Vector2.from_angle(angle) * radius
		_draw_icon_motif(
			canvas,
			motif_center,
			angle,
			motif,
			motif_size * visual_scale,
			outline,
			fill,
			inset
		)

	if item_id != "player_skin.classic":
		var star_angle: float = -0.72
		var star_center: Vector2 = center + Vector2.from_angle(star_angle) * (
			radius + 8.0 * visual_scale
		)
		_draw_icon_motif(
			canvas,
			star_center,
			0.0,
			"star",
			5.2 * visual_scale,
			outline,
			Color(1.0, 0.95, 0.42, 1.0),
			Color.WHITE
		)

	# A small team-colored speed tick echoes the icon motion marks without
	# replacing the skin palette.
	for y_sign: float in [-1.0, 1.0]:
		var tick_y: float = y_sign * 9.0 * visual_scale
		_draw_line_screen_aa(canvas, 
			center + Vector2(-radius - 3.0 * visual_scale, tick_y),
			center + Vector2(-radius - 12.0 * visual_scale, tick_y),
			Color(team_color.lightened(0.28), 0.88),
			3.0 * visual_scale,
			true
		)


static func _draw_icon_motif(
	canvas: CanvasItem,
	center: Vector2,
	rotation: float,
	motif: String,
	size: float,
	outline: Color,
	fill: Color,
	inset: Color
) -> void:
	var local_points: PackedVector2Array
	match motif:
		"arrow":
			local_points = PackedVector2Array([
				Vector2(-1.0, -0.62), Vector2(0.10, -0.62),
				Vector2(0.10, -1.0), Vector2(1.05, 0.0),
				Vector2(0.10, 1.0), Vector2(0.10, 0.62),
				Vector2(-1.0, 0.62),
			])
		"crystal":
			local_points = PackedVector2Array([
				Vector2(-0.72, 0.0), Vector2(0.0, -1.18),
				Vector2(0.72, 0.0), Vector2(0.0, 1.18),
			])
		"crown":
			local_points = PackedVector2Array([
				Vector2(-1.0, 0.55), Vector2(-0.84, -0.72),
				Vector2(-0.34, -0.12), Vector2(0.0, -1.0),
				Vector2(0.34, -0.12), Vector2(0.84, -0.72),
				Vector2(1.0, 0.55),
			])
		"flame":
			local_points = PackedVector2Array([
				Vector2(-0.72, 0.78), Vector2(-0.42, -0.18),
				Vector2(0.0, -1.14), Vector2(0.22, -0.20),
				Vector2(0.72, -0.72), Vector2(0.58, 0.72),
			])
		"wing":
			local_points = PackedVector2Array([
				Vector2(-0.95, 0.72), Vector2(-0.45, -0.34),
				Vector2(0.22, -1.0), Vector2(0.06, -0.18),
				Vector2(1.0, -0.58), Vector2(0.38, 0.52),
			])
		"blade":
			local_points = PackedVector2Array([
				Vector2(-1.12, 0.55), Vector2(0.48, -1.0),
				Vector2(1.08, -0.58), Vector2(-0.42, 1.0),
			])
		"hex":
			local_points = PackedVector2Array([
				Vector2(-0.82, -0.48), Vector2(0.0, -0.94),
				Vector2(0.82, -0.48), Vector2(0.82, 0.48),
				Vector2(0.0, 0.94), Vector2(-0.82, 0.48),
			])
		"shield", "armor":
			local_points = PackedVector2Array([
				Vector2(-0.88, -0.72), Vector2(0.88, -0.72),
				Vector2(1.0, 0.08), Vector2(0.0, 1.05),
				Vector2(-1.0, 0.08),
			])
		"sun":
			local_points = PackedVector2Array([
				Vector2(-0.72, 0.0), Vector2(-0.30, -0.30),
				Vector2(0.0, -1.08), Vector2(0.30, -0.30),
				Vector2(0.72, 0.0), Vector2(0.30, 0.30),
				Vector2(0.0, 1.08), Vector2(-0.30, 0.30),
			])
		"star":
			local_points = PackedVector2Array()
			for index: int in range(10):
				var point_angle: float = -PI * 0.5 + float(index) * PI / 5.0
				var point_radius: float = 1.0 if index % 2 == 0 else 0.42
				local_points.append(Vector2.from_angle(point_angle) * point_radius)
		"node":
			local_points = PackedVector2Array([
				Vector2(-0.82, -0.82), Vector2(0.82, -0.82),
				Vector2(0.82, 0.82), Vector2(-0.82, 0.82),
			])
		_:
			local_points = PackedVector2Array([
				Vector2(-1.0, 0.0), Vector2(0.0, -0.72),
				Vector2(1.0, 0.0), Vector2(0.0, 0.72),
			])

	var outline_points := PackedVector2Array()
	var fill_points := PackedVector2Array()
	for local_point: Vector2 in local_points:
		outline_points.append(center + (local_point * size * 1.28).rotated(rotation))
		fill_points.append(center + (local_point * size).rotated(rotation))
	canvas.draw_colored_polygon(outline_points, outline)
	canvas.draw_colored_polygon(fill_points, fill)
	_draw_circle_aa(canvas, center, maxf(1.4, size * 0.18), inset)


static func _draw_inner_pattern(
	canvas: CanvasItem,
	center: Vector2,
	pattern: String,
	primary: Color,
	secondary: Color,
	inner_radius: float,
	visual_scale: float,
	animation_time: float
) -> void:
	match pattern:
		"stripes":
			for offset: int in [-28, -14, 0, 14, 28]:
				_draw_line_screen_aa(canvas, 
					center + Vector2(-inner_radius * 0.72, float(offset + 18) * visual_scale),
					center + Vector2(inner_radius * 0.72, float(offset - 18) * visual_scale),
					Color(secondary, 0.42 + float(abs(offset)) / 100.0),
					5.0 * visual_scale,
					true
				)
		"chevrons":
			for index: int in range(3):
				var spread: float = inner_radius * (0.35 + float(index) * 0.18)
				var depth: float = inner_radius * (0.12 + float(index) * 0.18)
				var chevron := PackedVector2Array([
					center + Vector2(-spread, -depth),
					center + Vector2(0.0, depth),
					center + Vector2(spread, -depth),
				])
				_draw_polyline_screen_aa(canvas, chevron, Color(secondary, 0.86 - float(index) * 0.17), (6.0 - float(index)) * visual_scale, true)
		"vanguard":
			var faceplate := PackedVector2Array([
				center + Vector2(-0.56, -0.44) * inner_radius,
				center + Vector2(0.0, -0.70) * inner_radius,
				center + Vector2(0.56, -0.44) * inner_radius,
				center + Vector2(0.42, 0.45) * inner_radius,
				center + Vector2(0.0, 0.68) * inner_radius,
				center + Vector2(-0.42, 0.45) * inner_radius,
			])
			canvas.draw_colored_polygon(faceplate, Color(primary.darkened(0.62), 0.88))
			var closed_faceplate: PackedVector2Array = faceplate.duplicate()
			closed_faceplate.append(faceplate[0])
			_draw_polyline_screen_aa(canvas, closed_faceplate, Color(secondary, 0.62), 3.0 * visual_scale, true)
			# Layered cheek guards make the faceplate more than a flat hexagon.
			for side: float in [-1.0, 1.0]:
				var cheek := PackedVector2Array([
					center + Vector2(side * inner_radius * 0.12, -inner_radius * 0.04),
					center + Vector2(side * inner_radius * 0.47, -inner_radius * 0.27),
					center + Vector2(side * inner_radius * 0.36, inner_radius * 0.35),
					center + Vector2(side * inner_radius * 0.10, inner_radius * 0.50),
				])
				canvas.draw_colored_polygon(cheek, Color(primary.darkened(0.72), 0.92))
				var closed_cheek: PackedVector2Array = cheek.duplicate()
				closed_cheek.append(cheek[0])
				_draw_polyline_screen_aa(canvas, closed_cheek, Color(secondary, 0.36), 1.8 * visual_scale, true)
			_draw_line_screen_aa(canvas, 
				center + Vector2(0.0, -inner_radius * 0.61),
				center + Vector2(0.0, inner_radius * 0.48),
				Color(secondary, 0.34),
				2.0 * visual_scale,
				true
			)
		"dots":
			for index: int in range(13):
				var angle: float = float(index) * 2.399
				var radius: float = inner_radius * (0.18 + float((index * 7) % 25) / 38.0)
				var dot_position: Vector2 = center + Vector2.from_angle(angle) * radius
				_draw_circle_aa(canvas, dot_position, (2.0 + float(index % 3)) * visual_scale, Color(secondary, 0.76))
				if index % 3 == 0:
					_draw_line_screen_aa(canvas, center, dot_position, Color(primary.lightened(0.24), 0.20), 1.5 * visual_scale, true)
		"facets":
			var facet_points: Array[Vector2] = []
			for index: int in range(8):
				var angle: float = float(index) * TAU / 8.0 - PI * 0.5
				facet_points.append(center + Vector2.from_angle(angle) * inner_radius * (0.48 if index % 2 == 0 else 0.72))
			for index: int in range(facet_points.size()):
				var next_index: int = (index + 1) % facet_points.size()
				_draw_line_screen_aa(canvas, facet_points[index], facet_points[next_index], Color(secondary, 0.68), 3.0 * visual_scale, true)
				_draw_line_screen_aa(canvas, center, facet_points[index], Color(primary.lightened(0.22), 0.46), 2.0 * visual_scale, true)
		"frost":
			for branch: int in range(6):
				var direction: Vector2 = Vector2.from_angle(float(branch) * TAU / 6.0)
				var tip: Vector2 = center + direction * inner_radius * 0.72
				_draw_line_screen_aa(canvas, center, tip, Color(secondary, 0.88), 3.5 * visual_scale, true)
				var root: Vector2 = center + direction * inner_radius * 0.45
				_draw_line_screen_aa(canvas, root, root - direction.rotated(0.62) * inner_radius * 0.24, Color(secondary, 0.72), 2.5 * visual_scale, true)
				_draw_line_screen_aa(canvas, root, root - direction.rotated(-0.62) * inner_radius * 0.24, Color(secondary, 0.72), 2.5 * visual_scale, true)
		"galaxy":
			var rotation: float = animation_time * 0.28
			for index: int in range(11):
				var angle: float = float(index) * 2.399 + rotation
				var radius: float = inner_radius * (0.22 + float((index * 7) % 24) / 40.0)
				_draw_circle_aa(canvas, 
					center + Vector2.from_angle(angle) * radius,
					(1.4 + float(index % 3) * 0.55) * visual_scale,
					Color(secondary, 0.86)
				)
			for arm: int in range(2):
				var points := PackedVector2Array()
				for step: int in range(17):
					var ratio: float = float(step) / 16.0
					var arm_angle: float = rotation + float(arm) * PI + ratio * PI * 1.55
					points.append(center + Vector2.from_angle(arm_angle) * inner_radius * ratio * 0.76)
				_draw_polyline_screen_aa(canvas, points, Color(primary.lightened(0.32), 0.52), 2.5 * visual_scale, true)
		"crown":
			var crown := PackedVector2Array([
				center + Vector2(-0.60, 0.30) * inner_radius,
				center + Vector2(-0.48, -0.36) * inner_radius,
				center + Vector2(-0.18, -0.08) * inner_radius,
				center + Vector2(0.0, -0.62) * inner_radius,
				center + Vector2(0.18, -0.08) * inner_radius,
				center + Vector2(0.48, -0.36) * inner_radius,
				center + Vector2(0.60, 0.30) * inner_radius,
			])
			_draw_polyline_screen_aa(canvas, crown, Color(secondary, 0.82), 4.0 * visual_scale, true)
		"flame":
			for index: int in range(5):
				var x: float = (float(index) - 2.0) * inner_radius * 0.22
				var pulse: float = 0.82 + sin(animation_time * 7.0 + float(index)) * 0.14
				_draw_line_screen_aa(canvas, 
					center + Vector2(x, inner_radius * 0.48),
					center + Vector2(x * 0.72, -inner_radius * 0.54 * pulse),
					Color(secondary if index % 2 else primary.lightened(0.25), 0.78),
					5.0 * visual_scale,
					true
				)
		"halves":
			_draw_arc_screen_aa(canvas, center, inner_radius * 0.62, PI * 0.5, PI * 1.5, 30, Color(secondary, 0.76), 8.0 * visual_scale, true)
			_draw_arc_screen_aa(canvas, center, inner_radius * 0.40, -PI * 0.5, PI * 0.5, 26, Color(primary.lightened(0.25), 0.88), 5.0 * visual_scale, true)
		"wings":
			for side: float in [-1.0, 1.0]:
				for feather: int in range(3):
					var y: float = (float(feather) - 1.0) * 14.0 * visual_scale
					_draw_line_screen_aa(canvas, center + Vector2(side * 8.0, y), center + Vector2(side * inner_radius * (0.48 + float(feather) * 0.08), y - 10.0 * visual_scale), Color(secondary, 0.78), 4.0 * visual_scale, true)
		"cross":
			_draw_line_screen_aa(canvas, center + Vector2(-inner_radius * 0.58, 0.0), center + Vector2(inner_radius * 0.58, 0.0), Color(secondary, 0.82), 5.0 * visual_scale, true)
			_draw_line_screen_aa(canvas, center + Vector2(0.0, -inner_radius * 0.58), center + Vector2(0.0, inner_radius * 0.58), Color(secondary, 0.82), 5.0 * visual_scale, true)
		"sunburst":
			for index: int in range(10):
				var direction := Vector2.from_angle(float(index) * TAU / 10.0)
				_draw_line_screen_aa(canvas, center + direction * inner_radius * 0.18, center + direction * inner_radius * 0.68, Color(secondary, 0.70), 3.0 * visual_scale, true)
		"rings":
			var ring_rotation: float = animation_time * 0.65
			for index: int in range(3):
				var radius: float = inner_radius * (0.28 + float(index) * 0.19)
				var start_angle: float = ring_rotation * (1.0 if index % 2 == 0 else -0.72) + float(index) * 0.65
				_draw_arc_screen_aa(canvas, center, radius, start_angle, start_angle + PI * (1.15 + float(index) * 0.16), 28, Color(secondary, 0.88 - float(index) * 0.18), (5.0 - float(index)) * visual_scale, true)
			_draw_circle_aa(canvas, center, 7.0 * visual_scale, Color(secondary, 0.92))
		"event_horizon":
			var horizon_rotation: float = animation_time * 0.92
			_draw_circle_aa(canvas, center, inner_radius * 0.34, Color(0.0, 0.0, 0.01, 0.98))
			for ring: int in range(4):
				var horizon_radius: float = inner_radius * (0.30 + float(ring) * 0.12)
				var horizon_start: float = horizon_rotation * (1.0 if ring % 2 == 0 else -0.72) + float(ring)
				_draw_arc_screen_aa(canvas, center, horizon_radius, horizon_start, horizon_start + PI * 1.36, 30, Color(secondary if ring % 2 == 0 else primary.lightened(0.38), 0.82 - float(ring) * 0.10), (5.5 - float(ring) * 0.7) * visual_scale, true)
			for star: int in range(8):
				var star_angle: float = float(star) * 2.399 + horizon_rotation * 0.35
				var star_radius: float = inner_radius * (0.45 + float(star % 3) * 0.10)
				_draw_circle_aa(canvas, center + Vector2.from_angle(star_angle) * star_radius, (1.3 + float(star % 2)) * visual_scale, Color.WHITE)
		"celestial_runes":
			var rune_rotation: float = animation_time * 0.36
			for rune: int in range(6):
				var rune_angle: float = rune_rotation + float(rune) * TAU / 6.0
				var inner_point: Vector2 = center + Vector2.from_angle(rune_angle) * inner_radius * 0.24
				var outer_point: Vector2 = center + Vector2.from_angle(rune_angle) * inner_radius * 0.70
				_draw_line_screen_aa(canvas, inner_point, outer_point, Color(secondary, 0.76), 3.0 * visual_scale, true)
				_draw_circle_aa(canvas, outer_point, 3.2 * visual_scale, Color(primary.lightened(0.30), 0.94))
			_draw_arc_screen_aa(canvas, center, inner_radius * 0.51, -rune_rotation, TAU - rune_rotation, 54, Color(secondary, 0.66), 2.5 * visual_scale, true)
		"reactor_core":
			var core_rotation: float = animation_time * 1.72
			for ring: int in range(3):
				var core_radius: float = inner_radius * (0.24 + float(ring) * 0.18)
				for segment: int in range(6):
					var segment_start: float = core_rotation * (1.0 if ring % 2 == 0 else -0.64) + float(segment) * TAU / 6.0
					_draw_arc_screen_aa(canvas, center, core_radius, segment_start, segment_start + 0.58, 10, Color(secondary if (segment + ring) % 2 == 0 else primary.lightened(0.28), 0.88), (5.0 - float(ring)) * visual_scale, true)
			_draw_circle_aa(canvas, center, (9.0 + sin(animation_time * 5.0) * 2.0) * visual_scale, Color(secondary, 0.90))
			_draw_circle_aa(canvas, center, 4.0 * visual_scale, Color.WHITE)
		"samba_flux":
			var samba_rotation: float = animation_time * 0.78
			for orbit: int in range(3):
				var radius: float = inner_radius * (0.28 + float(orbit) * 0.17)
				var direction: float = 1.0 if orbit % 2 == 0 else -1.0
				var start: float = samba_rotation * direction + float(orbit) * 0.9
				_draw_arc_screen_aa(canvas, center, radius, start, start + PI * 1.22, 28, Color(secondary if orbit % 2 == 0 else primary.lightened(0.22), 0.90 - float(orbit) * 0.12), (6.0 - float(orbit)) * visual_scale, true)
				_draw_circle_aa(canvas, center + Vector2.from_angle(start + PI * 1.22) * radius, (3.4 - float(orbit) * 0.5) * visual_scale, Color.WHITE)
			# Two sharp changes of direction read like a dribble path.
			var dribble_path := PackedVector2Array([
				center + Vector2(-0.52, 0.32) * inner_radius,
				center + Vector2(-0.12, -0.36) * inner_radius,
				center + Vector2(0.18, 0.16) * inner_radius,
				center + Vector2(0.56, -0.30) * inner_radius,
			])
			_draw_polyline_screen_aa(canvas, dribble_path, Color(primary, 0.62), 3.0 * visual_scale, true)
		"thunder_core":
			var charge: float = 0.55 + 0.45 * sin(animation_time * 5.4)
			for spoke: int in range(6):
				var angle: float = float(spoke) * TAU / 6.0
				var direction: Vector2 = Vector2.from_angle(angle)
				var tangent: Vector2 = direction.orthogonal()
				var inner_point: Vector2 = center + direction * inner_radius * 0.18
				var kink: Vector2 = center + direction * inner_radius * 0.42 + tangent * (7.0 if spoke % 2 == 0 else -7.0) * visual_scale
				var outer_point: Vector2 = center + direction * inner_radius * 0.70
				_draw_polyline_screen_aa(canvas, PackedVector2Array([inner_point, kink, outer_point]), Color(secondary, 0.62 + charge * 0.30), (3.0 + charge) * visual_scale, true)
			_draw_circle_aa(canvas, center, (12.0 + charge * 3.0) * visual_scale, Color(primary.darkened(0.50), 0.96))
			_draw_arc_screen_aa(canvas, center, (14.0 + charge * 3.0) * visual_scale, animation_time * 1.8, animation_time * 1.8 + PI * 1.45, 24, Color(secondary, 0.94), 4.0 * visual_scale, true)
		_:
			_draw_arc_screen_aa(canvas, center, inner_radius * 0.62, -0.65, 2.35, 34, Color(secondary, 0.72), 4.0 * visual_scale, true)
			_draw_circle_aa(canvas, center, 5.5 * visual_scale, Color(secondary, 0.88))


static func _draw_outer_decoration(
	canvas: CanvasItem,
	center: Vector2,
	decoration: String,
	primary: Color,
	secondary: Color,
	team_radius: float,
	visual_scale: float,
	animation_time: float
) -> void:
	var outer: float = team_radius + 13.0 * visual_scale
	match decoration:
		"speed_tabs":
			for side: float in [-1.0, 1.0]:
				for y_offset: float in [-22.0, 0.0, 22.0]:
					_draw_line_screen_aa(canvas, center + Vector2(side * team_radius * 0.78, y_offset * visual_scale), center + Vector2(side * outer, (y_offset - 8.0) * visual_scale), Color(secondary, 0.82), 5.0 * visual_scale, true)
		"ice_points":
			for index: int in [1, 3, 5, 7]:
				var direction := Vector2.from_angle(float(index) * TAU / 8.0)
				var tangent := direction.orthogonal()
				var root: Vector2 = center + direction * (team_radius - 2.0 * visual_scale)
				var shard := PackedVector2Array([root - tangent * 7.0 * visual_scale, center + direction * (outer + 9.0 * visual_scale), root + tangent * 7.0 * visual_scale])
				canvas.draw_colored_polygon(shard, Color(secondary, 0.78))
		"crown_points":
			for index: int in [-1, 0, 1]:
				var x: float = float(index) * 24.0 * visual_scale
				var root := center + Vector2(x, -team_radius * 0.88)
				_draw_line_screen_aa(canvas, root, root + Vector2(float(index) * 5.0, -22.0) * visual_scale, Color(secondary, 0.92), 7.0 * visual_scale, true)
		"flame_crown":
			for index: int in range(7):
				var angle: float = PI + float(index) * PI / 6.0
				var direction := Vector2.from_angle(angle)
				var flicker: float = 8.0 + 8.0 * (0.5 + 0.5 * sin(animation_time * 8.0 + float(index)))
				_draw_line_screen_aa(canvas, center + direction * team_radius, center + direction * (outer + flicker * visual_scale), Color(secondary if index % 2 else primary.lightened(0.3), 0.84), 6.0 * visual_scale, true)
		"orbit":
			var orbit_angle: float = animation_time * 1.8
			_draw_arc_screen_aa(canvas, center, outer, orbit_angle, orbit_angle + PI * 1.35, 44, Color(secondary, 0.78), 4.0 * visual_scale, true)
			_draw_circle_aa(canvas, center + Vector2.from_angle(orbit_angle + PI * 1.35) * outer, 5.0 * visual_scale, secondary)
		"shadow_crescents":
			var shadow_angle: float = animation_time * 0.7
			for side: float in [-1.0, 1.0]:
				_draw_arc_screen_aa(canvas, center, outer + 5.0 * visual_scale, shadow_angle + side * 1.3, shadow_angle + side * 1.3 + side * 0.82, 24, Color(secondary, 0.52), 7.0 * visual_scale, true)
		"wings":
			for side: float in [-1.0, 1.0]:
				var root := center + Vector2(side * team_radius * 0.82, -8.0 * visual_scale)
				for feather: int in range(3):
					_draw_line_screen_aa(canvas, root + Vector2(0.0, float(feather) * 9.0 * visual_scale), root + Vector2(side * (24.0 + float(feather) * 8.0), (-17.0 + float(feather) * 9.0) * visual_scale), Color(secondary, 0.84 - float(feather) * 0.12), 6.0 * visual_scale, true)
		"brackets":
			for quadrant: int in range(4):
				var angle: float = float(quadrant) * PI * 0.5 + PI * 0.18
				_draw_arc_screen_aa(canvas, center, outer, angle, angle + PI * 0.28, 12, Color(secondary, 0.86), 7.0 * visual_scale, true)
		"dot_orbit":
			for index: int in range(7):
				var angle: float = animation_time * 1.2 + float(index) * TAU / 7.0
				_draw_circle_aa(canvas, center + Vector2.from_angle(angle) * outer, (2.5 + float(index % 2) * 1.5) * visual_scale, Color(secondary, 0.82))
		"sun_rays":
			var pulse: float = 0.85 + sin(animation_time * 3.0) * 0.12
			for index: int in range(12):
				var direction := Vector2.from_angle(float(index) * TAU / 12.0)
				_draw_line_screen_aa(canvas, center + direction * team_radius, center + direction * outer * pulse, Color(secondary, 0.68), 4.0 * visual_scale, true)
		"shield_facets":
			for angle: float in [-2.55, -0.59, 0.59, 2.55]:
				var direction := Vector2.from_angle(angle)
				var tangent := direction.orthogonal()
				var root := center + direction * team_radius
				_draw_polyline_screen_aa(canvas, PackedVector2Array([root - tangent * 10.0 * visual_scale, center + direction * (outer + 7.0 * visual_scale), root + tangent * 10.0 * visual_scale]), Color(secondary, 0.76), 6.0 * visual_scale, true)
		"double_halo":
			var halo_angle: float = animation_time * 1.15
			_draw_arc_screen_aa(canvas, center, outer, halo_angle, halo_angle + PI * 1.15, 40, Color(secondary, 0.88), 5.0 * visual_scale, true)
			_draw_arc_screen_aa(canvas, center, outer + 8.0 * visual_scale, -halo_angle, -halo_angle + PI * 0.72, 30, Color(primary.lightened(0.32), 0.68), 3.0 * visual_scale, true)
		"blade_marks":
			for side: float in [-1.0, 1.0]:
				var root := center + Vector2(side * team_radius * 0.84, 18.0 * visual_scale)
				_draw_line_screen_aa(canvas, root, root + Vector2(side * 29.0, -31.0) * visual_scale, Color(secondary, 0.88), 8.0 * visual_scale, true)
		"pressure_spikes":
			for index: int in range(6):
				var spike_angle: float = float(index) * TAU / 6.0 + 0.16
				var direction: Vector2 = Vector2.from_angle(spike_angle)
				var tangent: Vector2 = direction.orthogonal()
				var root: Vector2 = center + direction * (team_radius - 2.0 * visual_scale)
				var tip: Vector2 = center + direction.rotated(-0.10) * (
					outer + (8.0 if index % 2 == 0 else 3.0) * visual_scale
				)
				canvas.draw_colored_polygon(
					PackedVector2Array([
						root - tangent * 5.0 * visual_scale,
						tip,
						root + tangent * 5.0 * visual_scale,
					]),
					Color(secondary if index % 2 == 0 else primary.lightened(0.30), 0.82)
				)
			_draw_arc_screen_aa(canvas, 
				center,
				outer + 3.0 * visual_scale,
				animation_time * 0.42,
				animation_time * 0.42 + 1.32,
				24,
				Color(secondary, 0.70),
				3.5 * visual_scale,
				true
			)
		"void_tendrils":
			var tendril_rotation: float = animation_time * 0.48
			# Broken event-horizon rails fill the old empty gap between the body
			# and tendril tips without turning the silhouette into a solid ring.
			var horizon_rotation: float = -animation_time * 0.34
			var horizon_radius: float = outer + 4.0 * visual_scale
			for segment: int in range(7):
				var segment_start: float = (
					horizon_rotation + float(segment) * TAU / 7.0
				)
				var segment_color: Color = (
					secondary
					if segment % 2 == 0
					else primary.lightened(0.34)
				)
				_draw_arc_screen_aa(canvas, 
					center,
					horizon_radius,
					segment_start,
					segment_start + 0.48,
					12,
					Color(segment_color, 0.66),
					(2.5 + float(segment % 2)) * visual_scale,
					true
				)
				var jewel_angle: float = segment_start + 0.48
				var jewel_position: Vector2 = (
					center
					+ Vector2.from_angle(jewel_angle) * horizon_radius
				)
				_draw_circle_aa(canvas, 
					jewel_position,
					(2.1 + float(segment % 3) * 0.45) * visual_scale,
					Color(secondary, 0.84)
				)
				_draw_circle_aa(canvas, 
					jewel_position,
					0.8 * visual_scale,
					Color.WHITE
				)

			for tendril: int in range(7):
				var tendril_angle: float = tendril_rotation + float(tendril) * TAU / 7.0
				var points := PackedVector2Array()
				for step: int in range(7):
					var ratio: float = float(step) / 6.0
					var curve_angle: float = (
						tendril_angle
						+ ratio
						* (0.38 + 0.13 * sin(
							animation_time * 1.8 + float(tendril)
						))
					)
					points.append(
						center
						+ Vector2.from_angle(curve_angle)
						* (team_radius + ratio * 34.0 * visual_scale)
					)
				var tendril_color: Color = (
					secondary
					if tendril % 2 == 0
					else primary.lightened(0.28)
				)
				_draw_polyline_screen_aa(canvas, 
					points,
					Color(tendril_color, 0.72),
					(4.6 - float(tendril % 2) * 1.2) * visual_scale,
					true
				)
				# A faint detached wisp makes the outside feel layered rather than
				# merely having thicker spokes.
				var wisp_angle: float = tendril_angle + 0.46
				var wisp_radius: float = outer + (
					12.0 + 3.0 * sin(animation_time * 2.1 + float(tendril))
				) * visual_scale
				_draw_circle_aa(canvas, 
					center + Vector2.from_angle(wisp_angle) * wisp_radius,
					(1.5 + float(tendril % 2) * 0.7) * visual_scale,
					Color(secondary, 0.46)
				)
		"astral_wings":
			var wing_breath: float = 0.88 + 0.10 * sin(animation_time * 2.4)
			for side: float in [-1.0, 1.0]:
				for feather: int in range(4):
					var root: Vector2 = center + Vector2(side * team_radius * 0.72, (float(feather) - 1.5) * 10.0 * visual_scale)
					var feather_tip: Vector2 = center + Vector2(side * (outer + (17.0 + float(feather) * 5.0) * visual_scale) * wing_breath, (-25.0 + float(feather) * 17.0) * visual_scale)
					_draw_line_screen_aa(canvas, root, feather_tip, Color(secondary, 0.88 - float(feather) * 0.09), (7.0 - float(feather) * 0.8) * visual_scale, true)
					_draw_line_screen_aa(canvas, root, feather_tip.lerp(root, 0.22), Color(primary.lightened(0.32), 0.72), 2.5 * visual_scale, true)
		"plasma_blades":
			var blade_rotation: float = animation_time * 1.32
			for blade: int in range(6):
				var blade_angle: float = blade_rotation + float(blade) * TAU / 6.0
				var direction: Vector2 = Vector2.from_angle(blade_angle)
				var tangent: Vector2 = direction.orthogonal()
				var root: Vector2 = center + direction * team_radius
				var tip: Vector2 = center + direction.rotated(0.16) * (outer + 15.0 * visual_scale)
				canvas.draw_colored_polygon(PackedVector2Array([root - tangent * 5.0 * visual_scale, tip, root + tangent * 5.0 * visual_scale]), Color(secondary if blade % 2 == 0 else primary.lightened(0.28), 0.76))
		"dark_aura":
			# A compact armored shadow aura: layered black-red arcs and small
			# deterministic motes keep the silhouette readable during gameplay.
			var breath: float = 0.5 + 0.5 * sin(animation_time * 2.35)
			_draw_arc_screen_aa(canvas, 
				center,
				outer + (3.0 + breath * 4.0) * visual_scale,
				-2.75,
				0.10,
				38,
				Color(0.005, 0.006, 0.012, 0.68),
				(10.0 + breath * 3.0) * visual_scale,
				true
			)
			# Six short shadow blades sit behind the armor. They breathe rather
			# than spin rapidly, keeping the skin threatening without visual noise.
			for blade: int in range(6):
				var blade_angle: float = float(blade) * TAU / 6.0 + 0.18 * sin(animation_time * 0.7 + float(blade))
				var blade_direction: Vector2 = Vector2.from_angle(blade_angle)
				var blade_tangent: Vector2 = blade_direction.orthogonal()
				var blade_root: Vector2 = center + blade_direction * (outer + 1.0 * visual_scale)
				var blade_tip: Vector2 = center + blade_direction * (outer + (10.0 + breath * 5.0) * visual_scale)
				canvas.draw_colored_polygon(
					PackedVector2Array([
						blade_root - blade_tangent * 3.2 * visual_scale,
						blade_tip,
						blade_root + blade_tangent * 3.2 * visual_scale,
					]),
					Color(secondary, 0.42 if blade % 2 == 0 else 0.22)
				)
			_draw_arc_screen_aa(canvas, 
				center,
				outer + 4.0 * visual_scale,
				0.28,
				2.86,
				34,
				Color(primary.lightened(0.08), 0.58),
				8.0 * visual_scale,
				true
			)
			var red_angle: float = animation_time * 0.52 - 1.2
			_draw_arc_screen_aa(canvas, 
				center,
				outer + 7.0 * visual_scale,
				red_angle,
				red_angle + 0.72,
				18,
				Color(secondary, 0.82),
				3.0 * visual_scale,
				true
			)
			for index: int in range(13):
				var seed_ratio: float = float((index * 37) % 101) / 100.0
				var angle: float = float(index) * 2.399 + animation_time * (0.12 + float(index % 3) * 0.035)
				var drift: float = fposmod(animation_time * (0.11 + float(index % 4) * 0.015) + seed_ratio, 1.0)
				var mote_radius: float = outer + (5.0 + drift * 22.0) * visual_scale
				var mote_position: Vector2 = center + Vector2.from_angle(angle) * mote_radius
				var mote_color: Color = Color(secondary, 0.68 * (1.0 - drift)) if index % 4 == 0 else Color(0.01, 0.012, 0.022, 0.72 * (1.0 - drift))
				_draw_circle_aa(canvas, 
					mote_position,
					(1.6 + float(index % 3) * 0.65) * visual_scale,
					mote_color
				)
		"trickster_ribbons":
			var ribbon_rotation: float = animation_time * 0.62
			for ribbon: int in range(4):
				var base_angle: float = ribbon_rotation + float(ribbon) * TAU / 4.0
				var points := PackedVector2Array()
				for step: int in range(7):
					var ratio: float = float(step) / 6.0
					var curve_angle: float = base_angle + ratio * (0.52 if ribbon % 2 == 0 else -0.52)
					points.append(center + Vector2.from_angle(curve_angle) * (team_radius + ratio * 30.0 * visual_scale))
				_draw_polyline_screen_aa(canvas, points, Color(secondary if ribbon % 2 == 0 else primary, 0.76), (5.0 - float(ribbon % 2)) * visual_scale, true)
				var flare: Vector2 = points[points.size() - 1]
				_draw_circle_aa(canvas, flare, 3.4 * visual_scale, Color.WHITE)
			for ghost: int in range(3):
				var ghost_angle: float = -ribbon_rotation * 0.7 + float(ghost) * TAU / 3.0
				var ghost_position: Vector2 = center + Vector2.from_angle(ghost_angle) * (outer + 19.0 * visual_scale)
				_draw_arc_screen_aa(canvas, ghost_position, 6.0 * visual_scale, ghost_angle - 1.0, ghost_angle + 1.0, 10, Color(primary.lightened(0.28), 0.48), 3.0 * visual_scale, true)
		"nordic_lightning":
			var storm_pulse: float = 0.5 + 0.5 * sin(animation_time * 6.0)
			for bolt: int in range(6):
				var bolt_angle: float = float(bolt) * TAU / 6.0 + 0.10 * sin(animation_time * 1.3)
				var direction: Vector2 = Vector2.from_angle(bolt_angle)
				var tangent: Vector2 = direction.orthogonal()
				var root: Vector2 = center + direction * team_radius
				var first: Vector2 = center + direction * (outer + 3.0 * visual_scale) + tangent * 6.0 * visual_scale
				var second: Vector2 = center + direction * (outer + 10.0 * visual_scale) - tangent * 4.0 * visual_scale
				var tip: Vector2 = center + direction * (outer + (20.0 + storm_pulse * 5.0) * visual_scale)
				_draw_polyline_screen_aa(canvas, PackedVector2Array([root, first, second, tip]), Color(secondary, 0.66 + storm_pulse * 0.28), (4.2 if bolt % 2 == 0 else 3.0) * visual_scale, true)
				_draw_circle_aa(canvas, tip, (2.2 + storm_pulse) * visual_scale, Color(primary.lightened(0.34), 0.92))
			_draw_arc_screen_aa(canvas, center, outer + 8.0 * visual_scale, animation_time * 0.9, animation_time * 0.9 + PI * 1.30, 38, Color(primary, 0.54), 5.0 * visual_scale, true)


static func _draw_outer_flash_layer(
	canvas: CanvasItem,
	center: Vector2,
	rarity: String,
	primary: Color,
	secondary: Color,
	team_radius: float,
	visual_scale: float,
	animation_time: float
) -> void:
	if rarity == "common":
		return
	var detail_scale: float = get_outer_detail_scale({"rarity": rarity})
	var silhouette_radius: float = team_radius + 18.0 * visual_scale * detail_scale
	var pulse: float = 0.5 + 0.5 * sin(animation_time * 2.8)
	var accent_alpha: float = 0.34
	var accent_count: int = 2
	match rarity:
		"rare":
			accent_alpha = 0.46
			accent_count = 4
		"epic":
			accent_alpha = 0.60
			accent_count = 5
		"legendary":
			accent_alpha = 0.70
			accent_count = 6

	# Broad back-lighting makes the silhouette readable at normal match zoom.
	_draw_arc_screen_aa(canvas, 
		center,
		silhouette_radius,
		-2.78,
		-0.32,
		36,
		Color(primary.lightened(0.28), accent_alpha * 0.58),
		(3.0 + pulse * 1.5) * visual_scale,
		true
	)
	_draw_arc_screen_aa(canvas, 
		center,
		silhouette_radius,
		0.38,
		2.70,
		36,
		Color(secondary, accent_alpha * 0.48),
		2.4 * visual_scale,
		true
	)

	# Detached icon-like shards add a flashy, readable outer profile without
	# changing the circular physics body or hiding the team-colored frame.
	for index: int in range(accent_count):
		var angle: float = (
			float(index) * TAU / float(accent_count)
			+ animation_time * (0.16 if rarity in ["epic", "legendary"] else 0.0)
		)
		var direction: Vector2 = Vector2.from_angle(angle)
		var tangent: Vector2 = direction.orthogonal()
		var shard_center: Vector2 = center + direction * (
			silhouette_radius + (4.0 + pulse * 2.0) * visual_scale
		)
		var shard_length: float = (
			(7.0 if rarity == "uncommon" else 9.0) * visual_scale
		)
		var shard_width: float = (
			(2.8 if rarity == "uncommon" else 4.0) * visual_scale
		)
		canvas.draw_colored_polygon(
			PackedVector2Array([
				shard_center + direction * shard_length,
				shard_center - direction * shard_length * 0.45 + tangent * shard_width,
				shard_center - direction * shard_length * 0.45 - tangent * shard_width,
			]),
			Color(secondary if index % 2 == 0 else primary.lightened(0.34), accent_alpha)
		)
		if rarity in ["epic", "legendary"]:
			_draw_circle_aa(canvas, 
				shard_center,
				1.5 * visual_scale,
				Color.WHITE
			)


static func _draw_skin_signature(
	canvas: CanvasItem,
	center: Vector2,
	item_id: String,
	primary: Color,
	secondary: Color,
	inner_radius: float,
	_team_radius: float,
	visual_scale: float,
	animation_time: float
) -> void:
	match item_id:
		"player_skin.street_striker":
			for side: float in [-1.0, 1.0]:
				var boot_mark := PackedVector2Array([
					center + Vector2(side * inner_radius * 0.12, inner_radius * 0.10),
					center + Vector2(side * inner_radius * 0.62, inner_radius * 0.38),
					center + Vector2(side * inner_radius * 0.48, inner_radius * 0.58),
				])
				_draw_polyline_screen_aa(canvas, boot_mark, Color(secondary, 0.90), 6.0 * visual_scale, true)
		"player_skin.frostline":
			canvas.draw_colored_polygon(PackedVector2Array([
				center + Vector2(0.0, -inner_radius * 0.32),
				center + Vector2(inner_radius * 0.25, 0.0),
				center + Vector2(0.0, inner_radius * 0.32),
				center + Vector2(-inner_radius * 0.25, 0.0),
			]), Color(secondary, 0.34))
		"player_skin.royal_guard":
			_draw_circle_aa(canvas, center + Vector2(0.0, inner_radius * 0.34), 8.0 * visual_scale, Color(primary.darkened(0.42), 0.94))
			_draw_circle_aa(canvas, center + Vector2(0.0, inner_radius * 0.34), 4.0 * visual_scale, secondary)
		"player_skin.ember":
			var core_pulse: float = 8.0 + sin(animation_time * 7.0) * 2.0
			_draw_circle_aa(canvas, center, core_pulse * visual_scale, Color(secondary, 0.82))
			_draw_circle_aa(canvas, center, core_pulse * 0.45 * visual_scale, Color.WHITE)
		"player_skin.neon_pitch":
			var radar_direction: Vector2 = Vector2.from_angle(animation_time * 1.8)
			_draw_line_screen_aa(canvas, center, center + radar_direction * inner_radius * 0.72, Color(secondary, 0.78), 3.0 * visual_scale, true)
		"player_skin.shadow_play":
			_draw_circle_aa(canvas, center + Vector2(-inner_radius * 0.10, 0.0), inner_radius * 0.34, Color(primary.darkened(0.72), 0.94))
			_draw_arc_screen_aa(canvas, center, inner_radius * 0.38, -1.05, 1.05, 26, Color(secondary, 0.68), 4.0 * visual_scale, true)
		"player_skin.aerial_ace":
			canvas.draw_colored_polygon(PackedVector2Array([
				center + Vector2(0.0, -inner_radius * 0.48),
				center + Vector2(inner_radius * 0.16, inner_radius * 0.20),
				center,
				center + Vector2(-inner_radius * 0.16, inner_radius * 0.20),
			]), Color(secondary, 0.70))
		"player_skin.crimson_press":
			for index: int in range(4):
				var direction: Vector2 = Vector2.from_angle(float(index) * PI * 0.5)
				var tangent: Vector2 = direction.orthogonal()
				var tip: Vector2 = center + direction * inner_radius * 0.24
				var base: Vector2 = center + direction * inner_radius * 0.66
				canvas.draw_colored_polygon(PackedVector2Array([tip, base + tangent * 7.0 * visual_scale, base - tangent * 7.0 * visual_scale]), Color(secondary, 0.72))
		"player_skin.chrome_touch":
			var hexagon := PackedVector2Array()
			for index: int in range(7):
				hexagon.append(center + Vector2.from_angle(float(index) * TAU / 6.0) * inner_radius * 0.36)
			_draw_polyline_screen_aa(canvas, hexagon, Color(secondary, 0.84), 5.0 * visual_scale, true)
		"player_skin.mint_control":
			for index: int in range(3):
				var node_angle: float = animation_time * 0.5 + float(index) * TAU / 3.0
				var node_position: Vector2 = center + Vector2.from_angle(node_angle) * inner_radius * 0.42
				_draw_line_screen_aa(canvas, center, node_position, Color(secondary, 0.46), 2.0 * visual_scale, true)
				_draw_circle_aa(canvas, node_position, 5.0 * visual_scale, Color(secondary, 0.88))
		"player_skin.sunset_playmaker":
			_draw_line_screen_aa(canvas, center + Vector2(-inner_radius * 0.68, inner_radius * 0.20), center + Vector2(inner_radius * 0.68, inner_radius * 0.20), Color(secondary, 0.72), 4.0 * visual_scale, true)
			_draw_arc_screen_aa(canvas, center + Vector2(0.0, inner_radius * 0.20), inner_radius * 0.32, PI, TAU, 24, Color(secondary, 0.92), 5.0 * visual_scale, true)
		"player_skin.obsidian_wall":
			var shield := PackedVector2Array([
				center + Vector2(0.0, -inner_radius * 0.56),
				center + Vector2(inner_radius * 0.45, -inner_radius * 0.30),
				center + Vector2(inner_radius * 0.34, inner_radius * 0.34),
				center + Vector2(0.0, inner_radius * 0.62),
				center + Vector2(-inner_radius * 0.34, inner_radius * 0.34),
				center + Vector2(-inner_radius * 0.45, -inner_radius * 0.30),
			])
			_draw_polyline_screen_aa(canvas, shield, Color(secondary, 0.88), 5.0 * visual_scale, true)
		"player_skin.golden_touch":
			for side: float in [-1.0, 1.0]:
				for leaf: int in range(4):
					var leaf_y: float = (float(leaf) - 1.5) * 15.0 * visual_scale
					var leaf_center: Vector2 = center + Vector2(side * inner_radius * 0.40, leaf_y)
					_draw_circle_aa(canvas, leaf_center, 5.0 * visual_scale, Color(secondary, 0.72))
		"player_skin.dark_vanguard":
			var eye_pulse: float = 0.72 + 0.20 * sin(animation_time * 2.35)
			# Split visor eyes, center crest and breathing core sell the armored
			# character much more clearly than the previous single red line.
			for side: float in [-1.0, 1.0]:
				var eye_inner: Vector2 = center + Vector2(side * inner_radius * 0.07, -inner_radius * 0.17)
				var eye_outer: Vector2 = center + Vector2(side * inner_radius * 0.34, -inner_radius * 0.23)
				_draw_line_screen_aa(canvas, eye_inner, eye_outer, Color(0.0, 0.0, 0.0, 0.92), 7.0 * visual_scale, true)
				_draw_line_screen_aa(canvas, eye_inner, eye_outer, Color(secondary, eye_pulse), 3.0 * visual_scale, true)
				var vent_y: float = inner_radius * (0.14 + (0.10 if side > 0.0 else 0.0))
				_draw_line_screen_aa(canvas, 
					center + Vector2(side * inner_radius * 0.12, vent_y),
					center + Vector2(side * inner_radius * 0.35, vent_y + inner_radius * 0.08),
					Color(secondary, 0.42),
					2.0 * visual_scale,
					true
				)
			canvas.draw_colored_polygon(PackedVector2Array([
				center + Vector2(-inner_radius * 0.17, inner_radius * 0.02),
				center + Vector2(0.0, inner_radius * 0.42),
				center + Vector2(inner_radius * 0.17, inner_radius * 0.02),
			]), Color(0.0, 0.0, 0.0, 0.82))
			canvas.draw_colored_polygon(PackedVector2Array([
				center + Vector2(0.0, -inner_radius * 0.59),
				center + Vector2(inner_radius * 0.10, -inner_radius * 0.29),
				center + Vector2(0.0, -inner_radius * 0.12),
				center + Vector2(-inner_radius * 0.10, -inner_radius * 0.29),
			]), Color(secondary, 0.66))
			var core_radius: float = (3.6 + 1.2 * sin(animation_time * 2.35)) * visual_scale
			_draw_circle_aa(canvas, center + Vector2(0.0, inner_radius * 0.31), core_radius + 2.0 * visual_scale, Color(0.0, 0.0, 0.0, 0.88))
			_draw_circle_aa(canvas, center + Vector2(0.0, inner_radius * 0.31), core_radius, Color(secondary, 0.88))
			_draw_circle_aa(canvas, center + Vector2(0.0, inner_radius * 0.31), 1.2 * visual_scale, Color.WHITE)
		"player_skin.abyssal_sovereign":
			var singularity_pulse: float = 0.88 + 0.10 * sin(animation_time * 3.2)
			_draw_circle_aa(canvas, center, inner_radius * 0.20 * singularity_pulse, Color(0.0, 0.0, 0.008, 1.0))
			_draw_arc_screen_aa(canvas, center, inner_radius * 0.28, animation_time, animation_time + PI * 1.42, 30, Color(secondary, 0.96), 4.0 * visual_scale, true)
			_draw_circle_aa(canvas, center + Vector2.from_angle(animation_time) * inner_radius * 0.28, 3.2 * visual_scale, Color.WHITE)
		"player_skin.celestial_seraph":
			var star_points := PackedVector2Array()
			for point: int in range(12):
				var point_radius: float = inner_radius * (0.46 if point % 2 == 0 else 0.20)
				star_points.append(center + Vector2.from_angle(-PI * 0.5 + float(point) * PI / 6.0) * point_radius)
			canvas.draw_colored_polygon(star_points, Color(secondary, 0.28))
			var closed_star: PackedVector2Array = star_points.duplicate()
			closed_star.append(star_points[0])
			_draw_polyline_screen_aa(canvas, closed_star, Color(secondary, 0.92), 3.0 * visual_scale, true)
			_draw_circle_aa(canvas, center, 6.0 * visual_scale, Color.WHITE)
		"player_skin.omega_reactor":
			var omega_rotation: float = animation_time * 1.7
			for arm: int in range(3):
				var arm_angle: float = omega_rotation + float(arm) * TAU / 3.0
				var arm_direction: Vector2 = Vector2.from_angle(arm_angle)
				_draw_line_screen_aa(canvas, center + arm_direction * inner_radius * 0.18, center + arm_direction * inner_radius * 0.58, Color(secondary, 0.94), 6.0 * visual_scale, true)
			_draw_circle_aa(canvas, center, (7.0 + 2.0 * sin(animation_time * 5.0)) * visual_scale, Color.WHITE)
		"player_skin.brazilian_prince_10":
			var ten_pulse: float = 0.78 + 0.18 * sin(animation_time * 3.6)
			# A compact number ten is readable at match zoom and makes this skin
			# unmistakably Neymar rather than another gold legendary.
			_draw_line_screen_aa(canvas, center + Vector2(-10.0, -15.0) * visual_scale, center + Vector2(-10.0, 15.0) * visual_scale, Color(secondary, 0.96), 5.0 * visual_scale, true)
			_draw_circle_aa(canvas, center + Vector2(8.0, 0.0) * visual_scale, 12.0 * visual_scale, Color(primary.darkened(0.48), 0.92))
			_draw_arc_screen_aa(canvas, center + Vector2(8.0, 0.0) * visual_scale, 12.0 * visual_scale, 0.0, TAU, 28, Color(secondary, ten_pulse), 4.5 * visual_scale, true)
			_draw_circle_aa(canvas, center + Vector2(8.0, 0.0) * visual_scale, 3.0 * visual_scale, Color.WHITE)
			for sparkle: int in range(3):
				var sparkle_angle: float = animation_time * 1.1 + float(sparkle) * TAU / 3.0
				_draw_circle_aa(canvas, center + Vector2.from_angle(sparkle_angle) * inner_radius * 0.62, 2.5 * visual_scale, Color.WHITE)
		"player_skin.nordic_terminator_9":
			var reactor_pulse: float = 0.72 + 0.22 * sin(animation_time * 5.2)
			# The nine is housed inside an armored reactor, echoing Haaland's
			# striker number while preserving the cold mechanical theme.
			_draw_circle_aa(canvas, center, inner_radius * 0.39, Color(0.01, 0.06, 0.11, 0.94))
			_draw_arc_screen_aa(canvas, center, inner_radius * 0.39, 0.0, TAU, 34, Color(primary.darkened(0.15), 0.96), 6.0 * visual_scale, true)
			_draw_arc_screen_aa(canvas, center + Vector2(0.0, -4.0) * visual_scale, 13.0 * visual_scale, 0.0, TAU, 28, Color(secondary, reactor_pulse), 4.5 * visual_scale, true)
			_draw_line_screen_aa(canvas, center + Vector2(11.0, 2.0) * visual_scale, center + Vector2(3.0, 18.0) * visual_scale, Color(secondary, reactor_pulse), 5.0 * visual_scale, true)
			_draw_circle_aa(canvas, center + Vector2(0.0, -4.0) * visual_scale, 3.5 * visual_scale, Color.WHITE)
			for brace: int in range(4):
				var brace_direction: Vector2 = Vector2.from_angle(float(brace) * PI * 0.5 + PI * 0.25)
				_draw_line_screen_aa(canvas, center + brace_direction * inner_radius * 0.43, center + brace_direction * inner_radius * 0.64, Color(primary.lightened(0.28), 0.82), 5.0 * visual_scale, true)


static func _catalog_color(item: Dictionary, key: String, fallback: Color) -> Color:
	var html: String = str(item.get(key, ""))
	return Color(html) if Color.html_is_valid(html) else fallback
