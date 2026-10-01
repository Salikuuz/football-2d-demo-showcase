extends Node2D


const GoalExplosionAtmosphere = preload(
	"res://Scenes/goal_explosion_atmosphere.gd"
)
const GOAL_SOUND_VOLUME_DB: float = -8.5
const GOAL_SOUND_STREAMS: Dictionary = {
	"goal_explosion.classic": preload(
		"res://Audio/GoalFX/goal_fx_classic_burst.wav"
	),
	"goal_explosion.andromeda": preload(
		"res://Audio/GoalFX/goal_fx_andromeda_collapse.wav"
	),
	"goal_explosion.goal_rush": preload(
		"res://Audio/GoalFX/goal_fx_goal_rush.wav"
	),
	"goal_explosion.confetti_cup": preload(
		"res://Audio/GoalFX/goal_fx_confetti_cup.wav"
	),
	"goal_explosion.ember_burst": preload(
		"res://Audio/GoalFX/goal_fx_ember_burst.wav"
	),
	"goal_explosion.electric_net": preload(
		"res://Audio/GoalFX/goal_fx_electric_net.wav"
	),
	"goal_explosion.cyclone": preload(
		"res://Audio/GoalFX/goal_fx_touchline_cyclone.wav"
	),
	"goal_explosion.pixel_break": preload(
		"res://Audio/GoalFX/goal_fx_pixel_break.wav"
	),
	"goal_explosion.crown_burst": preload(
		"res://Audio/GoalFX/goal_fx_crown_burst.wav"
	),
	"goal_explosion.ice_breaker": preload(
		"res://Audio/GoalFX/goal_fx_ice_breaker.wav"
	),
	"goal_explosion.comet_strike": preload(
		"res://Audio/GoalFX/goal_fx_comet_strike.wav"
	),
	"goal_explosion.trophy_lift": preload(
		"res://Audio/GoalFX/goal_fx_trophy_lift.wav"
	),
	"goal_explosion.stadium_roar": preload(
		"res://Audio/GoalFX/goal_fx_stadium_roar.wav"
	),
}


var team_color: Color = Color.WHITE
var lifetime: float = 1.75
var _visual_lifetime: float = 1.75
var _hold_arena_until_goal_replay: bool = false
var _arena_hold_fallback_seconds: float = 0.0
var _elapsed: float = 0.0
var _directions: Array[Vector2] = []
var _speeds: Array[float] = []
var _sizes: Array[float] = []
var _spin_offsets: Array[float] = []
var _smoke_directions: Array[Vector2] = []
var _smoke_distances: Array[float] = []
var _smoke_sizes: Array[float] = []
var _ray_directions: Array[Vector2] = []
var cosmetic_id: String = "goal_explosion.classic"
var cosmetic_item: Dictionary = {}
var color_index: int = FootballCosmeticInventory.PLAYER_SKIN_ORIGINAL_COLOR
var arena_atmosphere: Control
var _goal_audio: AudioStreamPlayer


func setup(
	color: Color,
	selected_cosmetic_id: String = "goal_explosion.classic",
	selected_color_index: int = FootballCosmeticInventory.PLAYER_SKIN_ORIGINAL_COLOR,
	hold_arena_until_goal_replay: bool = false,
	arena_hold_fallback_seconds: float = 0.0
) -> void:
	cosmetic_id = selected_cosmetic_id
	_hold_arena_until_goal_replay = hold_arena_until_goal_replay
	_arena_hold_fallback_seconds = maxf(0.0, arena_hold_fallback_seconds)
	color_index = FootballCosmeticInventory.sanitize_goal_explosion_color_index(
		selected_color_index
	)
	team_color = (
		color.lerp(Color(0.46, 0.18, 1.0), 0.42)
		if cosmetic_id == "goal_explosion.andromeda"
		else color
	)
	var base_item: Dictionary = FootballCosmeticInventory.CATALOG.get(
		cosmetic_id,
		{}
	) as Dictionary
	cosmetic_item = FootballCosmeticInventory.apply_goal_explosion_color(
		base_item,
		color_index
	)
	var primary_html: String = str(cosmetic_item.get("primary", ""))
	if not primary_html.is_empty() and Color.html_is_valid(primary_html):
		team_color = (
			Color(primary_html)
			if color_index >= 0
			else color.lerp(Color(primary_html), 0.58)
		)
	_build_arena_atmosphere()
	# Keep the local burst timing exactly as it was even when the map-wide
	# atmosphere is held for the scorer-focus pause.
	_visual_lifetime = lifetime
	if _hold_arena_until_goal_replay and arena_atmosphere != null:
		arena_atmosphere.call(
			"hold_until_goal_replay",
			_arena_hold_fallback_seconds
		)
		lifetime = maxf(
			lifetime,
			float(arena_atmosphere.get("lifetime"))
		)
		add_to_group("goal_explosion_hold_until_replay")
	_play_goal_sound()
	z_index = 80
	var random := RandomNumberGenerator.new()
	random.seed = int(
		absf(global_position.x * 31.0)
		+ absf(global_position.y * 17.0)
		+ color.r * 997.0
	)
	for index in range(220):
		var angle := random.randf_range(0.0, TAU)
		_directions.append(Vector2.from_angle(angle))
		_speeds.append(random.randf_range(430.0, 940.0))
		_sizes.append(random.randf_range(6.0, 19.0))
		_spin_offsets.append(random.randf_range(-1.2, 1.2))
	for index in range(48):
		var angle := (
			float(index) / 48.0 * TAU
			+ random.randf_range(-0.035, 0.035)
		)
		_ray_directions.append(Vector2.from_angle(angle))
	for index in range(52):
		_smoke_directions.append(
			Vector2.from_angle(random.randf_range(0.0, TAU))
		)
		_smoke_distances.append(random.randf_range(250.0, 880.0))
		_smoke_sizes.append(random.randf_range(42.0, 115.0))
	queue_redraw()


func _play_goal_sound() -> void:
	var stream: AudioStream = GOAL_SOUND_STREAMS.get(
		cosmetic_id,
		GOAL_SOUND_STREAMS["goal_explosion.classic"]
	) as AudioStream
	if stream == null:
		return
	_goal_audio = AudioStreamPlayer.new()
	_goal_audio.name = "CosmeticGoalSound"
	_goal_audio.stream = stream
	_goal_audio.volume_db = GOAL_SOUND_VOLUME_DB
	add_child(_goal_audio)
	_goal_audio.play()


func _build_arena_atmosphere() -> void:
	if not GoalExplosionAtmosphere.supports_item(cosmetic_item):
		return
	var atmosphere_canvas := CanvasLayer.new()
	atmosphere_canvas.name = "ArenaAtmosphereLayer"
	# Match ScreenVisualFX and remain beneath the gameplay HUD CanvasLayer.
	atmosphere_canvas.layer = 0
	add_child(atmosphere_canvas)
	arena_atmosphere = GoalExplosionAtmosphere.new()
	arena_atmosphere.name = "ArenaAtmosphere"
	atmosphere_canvas.add_child(arena_atmosphere)
	arena_atmosphere.setup(cosmetic_id, cosmetic_item, team_color)
	lifetime = maxf(lifetime, float(arena_atmosphere.get("lifetime")))


func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()
	if _elapsed >= lifetime:
		queue_free()


func _draw() -> void:
	var progress := clampf(
		_elapsed / maxf(0.01, _visual_lifetime),
		0.0,
		1.0
	)
	var expansion := 1.0 - pow(1.0 - progress, 3.0)
	var fade := pow(1.0 - progress, 1.35)
	var flash := 1.0 - clampf(progress / 0.2, 0.0, 1.0)
	var bright := team_color.lightened(0.5)
	var hot := Color(1.0, 0.96, 0.82, 1.0)

	# A fast white-hot flash sells the moment when the ball disappears.
	draw_circle(
		Vector2.ZERO,
		lerpf(75.0, 470.0, expansion),
		Color(hot, flash * 0.88)
	)
	draw_circle(
		Vector2.ZERO,
		lerpf(55.0, 680.0, expansion),
		Color(team_color, flash * 0.3)
	)

	# Long energy rays make the explosion readable from across the field.
	for index in range(_ray_directions.size()):
		var direction := _ray_directions[index]
		var ray_length := lerpf(150.0, 1180.0, expansion)
		var ray_start := direction * lerpf(18.0, 120.0, expansion)
		var ray_end := direction * ray_length
		var ray_alpha := fade * (0.72 if index % 3 == 0 else 0.38)
		draw_line(
			ray_start,
			ray_end,
			Color(bright if index % 2 == 0 else team_color, ray_alpha),
			lerpf(18.0, 1.5, progress),
			true
		)

	# Three shockwaves reach far beyond the old kick-sized effect.
	_draw_shock_ring(
		lerpf(45.0, 1120.0, expansion),
		Color(team_color, fade * 0.9),
		lerpf(42.0, 4.0, progress),
		112
	)
	_draw_shock_ring(
		lerpf(25.0, 790.0, expansion),
		Color(bright, fade * 0.78),
		lerpf(29.0, 3.0, progress),
		96
	)
	_draw_shock_ring(
		lerpf(10.0, 470.0, expansion),
		Color(hot, fade * 0.64),
		lerpf(18.0, 2.0, progress),
		72
	)

	# Broad translucent energy clouds fill the gaps between the fast shards.
	for index in range(_smoke_directions.size()):
		var smoke_progress := clampf(progress * 1.2, 0.0, 1.0)
		var smoke_position := (
			_smoke_directions[index]
			* _smoke_distances[index]
			* expansion
		)
		var smoke_size := _smoke_sizes[index] * lerpf(0.35, 1.35, smoke_progress)
		var smoke_color := (
			bright if index % 4 == 0 else team_color.darkened(0.18)
		)
		draw_circle(
			smoke_position,
			smoke_size,
			Color(smoke_color, fade * 0.12)
		)

	# Hundreds of triangular fragments make the ball feel like it burst apart.
	for index in range(_directions.size()):
		var direction := _directions[index]
		var travel := _speeds[index] * _elapsed * (1.0 - progress * 0.3)
		var shard_position := direction * (30.0 + travel)
		var tangent := direction.orthogonal().rotated(
			_spin_offsets[index] * progress
		)
		var size := _sizes[index] * lerpf(1.15, 0.18, progress)
		var shard_color := (
			hot
			if index % 7 == 0
			else bright
			if index % 3 == 0
			else team_color
		)
		var points := PackedVector2Array([
			shard_position + direction * size * 2.4,
			shard_position - direction * size * 1.2 + tangent * size * 0.65,
			shard_position - direction * size * 0.8 - tangent * size * 0.65
		])
		draw_colored_polygon(points, Color(shard_color, fade))
		if index % 3 == 0:
			draw_line(
				shard_position - direction * size * 5.0,
				shard_position + direction * size,
				Color(bright, fade * 0.72),
				maxf(1.0, size * 0.24),
				true
			)

	_draw_core_star(bright, hot, progress, fade)
	if cosmetic_id == "goal_explosion.andromeda":
		_draw_andromeda_orbits(progress, expansion, fade)
	else:
		_draw_catalog_signature(progress, expansion, fade)


func _draw_catalog_signature(progress: float, expansion: float, fade: float) -> void:
	var pattern: String = str(cosmetic_item.get("pattern", "classic"))
	if pattern == "classic" or pattern.is_empty():
		return
	var secondary_html: String = str(cosmetic_item.get("secondary", ""))
	var accent: Color = Color(secondary_html) if Color.html_is_valid(secondary_html) else team_color.lightened(0.45)
	match pattern:
		"rays":
			for index: int in range(24):
				var direction := Vector2.from_angle(float(index) * TAU / 24.0)
				draw_line(direction * 95.0, direction * lerpf(170.0, 920.0, expansion), Color(accent if index % 2 == 0 else team_color, fade * 0.9), lerpf(16.0, 2.0, progress), true)
		"confetti":
			for index: int in range(56):
				var spread: float = (float((index * 47) % 113) / 112.0 - 0.5) * 1280.0
				var fall: float = lerpf(-420.0 + float(index % 7) * 34.0, 680.0, expansion)
				var point := Vector2(spread, fall)
				var piece_size := Vector2(16.0, 8.0 + float(index % 3) * 7.0)
				draw_set_transform(point, progress * 7.0 + float(index), Vector2.ONE)
				draw_rect(Rect2(-piece_size * 0.5, piece_size), Color(accent if index % 3 else team_color, fade), true)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"flame":
			for index: int in range(13):
				var x: float = (float(index) - 6.0) * 58.0
				var height: float = lerpf(170.0, 690.0, expansion) * (0.72 + float(index % 4) * 0.1)
				var base := Vector2(x, 250.0)
				var flame := PackedVector2Array([base - Vector2(34.0, 0.0), base - Vector2(18.0, height * 0.48), base + Vector2(0.0, -height), base + Vector2(22.0, -height * 0.42), base + Vector2(34.0, 0.0)])
				draw_colored_polygon(flame, Color(accent if index % 2 else team_color, fade * 0.72))
		"electric":
			for index: int in range(18):
				var direction := Vector2.from_angle(float(index) * TAU / 18.0)
				var tangent := direction.orthogonal()
				var start: Vector2 = direction * 75.0
				var bend_one: Vector2 = direction * lerpf(130.0, 330.0, expansion) + tangent * 70.0
				var bend_two: Vector2 = direction * lerpf(210.0, 560.0, expansion) - tangent * 55.0
				var end: Vector2 = direction * lerpf(300.0, 920.0, expansion)
				draw_polyline(PackedVector2Array([start, bend_one, bend_two, end]), Color(accent, fade * 0.95), lerpf(12.0, 2.0, progress), true)
		"vortex":
			for orbit: int in range(4):
				var radius: float = lerpf(65.0 + float(orbit) * 24.0, 480.0 + float(orbit) * 95.0, expansion)
				var start_angle: float = progress * 3.5 + float(orbit) * 0.7
				draw_arc(Vector2.ZERO, radius, start_angle, start_angle + PI * 1.25, 56, Color(accent, fade * 0.84), lerpf(12.0, 2.0, progress), true)
		"pixel":
			for index: int in range(44):
				var angle: float = float(index) * 2.399
				var distance: float = lerpf(45.0, 280.0 + float((index * 67) % 620), expansion)
				var point: Vector2 = Vector2.from_angle(angle) * distance
				var block_size: float = 28.0 if index % 4 == 0 else 16.0
				draw_rect(Rect2(point - Vector2.ONE * block_size * 0.5, Vector2.ONE * block_size), Color(accent if index % 2 == 0 else team_color, fade), true)
		"crown":
			var crown_width: float = lerpf(120.0, 510.0, expansion)
			var crown_height: float = crown_width * 0.66
			var crown := PackedVector2Array([Vector2(-crown_width, crown_height * 0.42), Vector2(-crown_width * 0.82, -crown_height * 0.48), Vector2(-crown_width * 0.34, -crown_height * 0.08), Vector2(0.0, -crown_height), Vector2(crown_width * 0.34, -crown_height * 0.08), Vector2(crown_width * 0.82, -crown_height * 0.48), Vector2(crown_width, crown_height * 0.42), Vector2(-crown_width, crown_height * 0.42)])
			draw_colored_polygon(crown, Color(team_color, fade * 0.16))
			draw_polyline(crown, Color(accent, fade * 0.94), lerpf(18.0, 3.0, progress), true)
		"frost":
			var frost_radius: float = lerpf(100.0, 760.0, expansion)
			for branch: int in range(6):
				var direction := Vector2.from_angle(float(branch) * TAU / 6.0)
				draw_line(Vector2.ZERO, direction * frost_radius, Color(accent, fade * 0.92), lerpf(14.0, 2.0, progress), true)
				for ratio: float in [0.45, 0.72]:
					var root: Vector2 = direction * frost_radius * ratio
					draw_line(root, root - direction.rotated(0.65) * frost_radius * 0.2, Color(team_color, fade), 5.0, true)
					draw_line(root, root - direction.rotated(-0.65) * frost_radius * 0.2, Color(team_color, fade), 5.0, true)
		"comet":
			var head := Vector2(lerpf(-760.0, 610.0, expansion), -sin(progress * PI) * 220.0)
			for trail: int in range(11):
				var trail_end := head - Vector2(lerpf(210.0, 760.0, expansion), float(trail - 5) * 12.0)
				draw_line(trail_end, head, Color(accent if trail % 2 else team_color, fade * 0.72), maxf(2.0, 13.0 - float(trail)), true)
			draw_circle(head, lerpf(72.0, 24.0, progress), Color(accent, fade))
		"trophy":
			var lift: float = lerpf(260.0, -330.0, expansion)
			var cup_center := Vector2(0.0, lift)
			var cup_width: float = lerpf(95.0, 310.0, expansion)
			var cup := PackedVector2Array([cup_center + Vector2(-cup_width, -150.0), cup_center + Vector2(cup_width, -150.0), cup_center + Vector2(cup_width * 0.65, 70.0), cup_center + Vector2(0.0, 170.0), cup_center + Vector2(-cup_width * 0.65, 70.0), cup_center + Vector2(-cup_width, -150.0)])
			draw_colored_polygon(cup, Color(team_color, fade * 0.22))
			draw_polyline(cup, Color(accent, fade), lerpf(17.0, 3.0, progress), true)
			draw_line(cup_center + Vector2(0.0, 165.0), cup_center + Vector2(0.0, 300.0), Color(accent, fade), 13.0, true)
			draw_line(cup_center + Vector2(-150.0, 300.0), cup_center + Vector2(150.0, 300.0), Color(accent, fade), 17.0, true)
		"stadium":
			for wave: int in range(5):
				var wave_progress: float = fposmod(progress + float(wave) * 0.13, 1.0)
				var wave_radius: float = lerpf(120.0, 980.0, wave_progress)
				draw_arc(Vector2(0.0, 250.0), wave_radius, PI, TAU, 80, Color(accent if wave % 2 else team_color, (1.0 - wave_progress) * fade), 10.0, true)
			for side: float in [-1.0, 1.0]:
				var source := Vector2(side * 720.0, -460.0)
				draw_colored_polygon(PackedVector2Array([source, Vector2(-170.0, 360.0), Vector2(170.0, 360.0)]), Color(accent, fade * 0.12))


func _draw_andromeda_orbits(
	progress: float,
	expansion: float,
	fade: float
) -> void:
	var orbit_color := Color(0.28, 0.90, 1.0, fade * 0.88)
	for orbit_index: int in range(4):
		var radius: float = lerpf(
			75.0 + float(orbit_index) * 24.0,
			620.0 + float(orbit_index) * 135.0,
			expansion
		)
		var start_angle: float = -0.8 + progress * 2.4 + float(orbit_index) * 0.48
		draw_arc(
			Vector2.ZERO,
			radius,
			start_angle,
			start_angle + PI * 1.22,
			72,
			orbit_color,
			lerpf(12.0, 2.0, progress),
			true
		)
	for star_index: int in range(28):
		var angle: float = float(star_index) * 2.399 + progress * 0.8
		var distance: float = lerpf(
			45.0,
			260.0 + float((star_index * 47) % 690),
			expansion
		)
		draw_circle(
			Vector2.from_angle(angle) * distance,
			lerpf(8.0, 1.2, progress),
			Color(0.75, 0.95, 1.0, fade)
		)


func _draw_shock_ring(
	radius: float,
	color: Color,
	width: float,
	point_count: int
) -> void:
	draw_arc(
		Vector2.ZERO,
		radius,
		0.0,
		TAU,
		point_count,
		color,
		width,
		true
	)


func _draw_core_star(
	bright: Color,
	hot: Color,
	progress: float,
	fade: float
) -> void:
	var points := PackedVector2Array()
	var point_count := 20
	for index in range(point_count):
		var angle := float(index) / float(point_count) * TAU
		var radius := (
			lerpf(150.0, 25.0, progress)
			if index % 2 == 0
			else lerpf(62.0, 10.0, progress)
		)
		points.append(Vector2.from_angle(angle) * radius)
	draw_colored_polygon(points, Color(bright, fade * fade))
	draw_circle(
		Vector2.ZERO,
		lerpf(88.0, 7.0, progress),
		Color(hot, fade)
	)
