class_name FootballFieldAtmosphere
extends Node2D


@export var playable_bounds: Rect2 = Rect2(318.0, 770.0, 6712.0, 3460.0)
@export var blue_glow: Color = Color(0.10, 0.48, 1.0, 1.0)
@export var red_glow: Color = Color(1.0, 0.16, 0.28, 1.0)
@export_range(0, 64, 1) var particle_count: int = 28
@export_range(0.0, 1.0, 0.01) var effect_opacity: float = 0.72
@export var match_manager: FootballMatchManager

@export_category("Crowd Audio")
@export_range(-60.0, 0.0, 0.5) var crowd_calm_volume_db: float = -31.0
@export_range(-60.0, 0.0, 0.5) var crowd_final_seconds_volume_db: float = -25.0
@export_range(-60.0, 0.0, 0.5) var crowd_danger_volume_db: float = -20.0
@export_range(0.1, 10.0, 0.1) var crowd_response_speed: float = 3.4

const CROWD_AMBIENCE_BASENAME := "res://Audio/crowd_stadium_ambience"
const CROWD_DANGER_BASENAME := "res://Audio/crowd_danger_ooh"
const CROWD_GOAL_BASENAME := "res://Audio/crowd_goal_cheer"
const CROWD_AUDIO_EXTENSIONS: Array[String] = [".wav", ".ogg", ".mp3"]
const CROWD_DANGER_TRIGGER := 0.72
const CROWD_DANGER_RESET := 0.45
const CROWD_REACTION_COOLDOWN := 2.25

var _time: float = 0.0
var _particles: Array[Dictionary] = []
var _atmosphere_active: bool = false
var _field_variant_index: int = 0
var _display_seconds: int = 0
var _is_overtime: bool = false
var _match_mood: StringName = &"normal"
var _crowd_ambience_audio: AudioStreamPlayer
var _crowd_reaction_audio: AudioStreamPlayer
var _crowd_danger: float = 0.0
var _crowd_danger_armed: bool = true
var _crowd_reaction_cooldown: float = 0.0



const MAP_AMBIENCE_PROFILES: Array[Dictionary] = [
	{"name": "aurora", "tint": Color("69efcf"), "pulse": 0.68, "sparkle": 0.82},
	{"name": "pitch", "tint": Color("8ce07d"), "pulse": 0.56, "sparkle": 0.52},
	{"name": "verdant", "tint": Color("a8df83"), "pulse": 0.62, "sparkle": 0.66},
	{"name": "ridge", "tint": Color("87e0ff"), "pulse": 0.58, "sparkle": 0.72},
	{"name": "golden", "tint": Color("ffd477"), "pulse": 0.60, "sparkle": 0.68},
	{"name": "dusk", "tint": Color("f0a8da"), "pulse": 0.64, "sparkle": 0.76},
	{"name": "violet", "tint": Color("9c70ff"), "pulse": 0.78, "sparkle": 0.96},
	{"name": "pastel", "tint": Color("ffd0a5"), "pulse": 0.58, "sparkle": 0.72, "effect": "sun"},
	{"name": "stellar", "tint": Color("b9c8dd"), "pulse": 0.64, "sparkle": 1.10},
	{"name": "inkstorm", "tint": Color("b2b2b6"), "pulse": 0.42, "sparkle": 0.28},
	{"name": "roseflow", "tint": Color("ff8fbd"), "pulse": 0.66, "sparkle": 0.88},
	{"name": "ivory", "tint": Color("dbe8ff"), "pulse": 0.48, "sparkle": 0.54},
	{"name": "lime", "tint": Color("9bed55"), "pulse": 0.56, "sparkle": 0.52, "lighting_strength": 1.65, "team_glow_strength": 2.08, "particle_strength": 1.35},
]


func _ready() -> void:
	_build_crowd_audio()
	_build_particles()
	if match_manager != null:
		match_manager.match_started.connect(_on_match_started)
		match_manager.match_ended.connect(_on_match_ended)
		match_manager.match_cancelled.connect(_on_match_cancelled)
		match_manager.freeplay_started.connect(_on_freeplay_started)
		match_manager.freeplay_ended.connect(_on_freeplay_ended)
		match_manager.timer_changed.connect(_on_timer_changed)
		match_manager.field_variant_changed.connect(_on_field_variant_changed)
		_field_variant_index = match_manager.current_field_variant
		_atmosphere_active = (
			match_manager.game_has_started
			or match_manager.freeplay_active
		)
	visible = _atmosphere_active
	set_process(_atmosphere_active)
	if _atmosphere_active:
		_start_crowd_ambience()
	queue_redraw()


func _process(delta: float) -> void:
	_time = fposmod(_time + delta, 120.0)
	_update_crowd_audio(delta)
	queue_redraw()


func set_atmosphere_active(active: bool) -> void:
	_atmosphere_active = active
	visible = active
	set_process(active)
	if active:
		_start_crowd_ambience()
		queue_redraw()
	else:
		_stop_crowd_audio()


func _build_crowd_audio() -> void:
	_crowd_ambience_audio = AudioStreamPlayer.new()
	_crowd_ambience_audio.name = "CrowdAmbienceAudio"
	_crowd_ambience_audio.volume_db = crowd_calm_volume_db
	add_child(_crowd_ambience_audio)

	_crowd_reaction_audio = AudioStreamPlayer.new()
	_crowd_reaction_audio.name = "CrowdReactionAudio"
	_crowd_reaction_audio.volume_db = -12.0
	add_child(_crowd_reaction_audio)

	var ambience := _load_optional_crowd_stream(CROWD_AMBIENCE_BASENAME)
	if ambience != null:
		if ambience is AudioStreamMP3:
			(ambience as AudioStreamMP3).loop = true
		elif ambience is AudioStreamOggVorbis:
			(ambience as AudioStreamOggVorbis).loop = true
		_crowd_ambience_audio.stream = ambience
	var danger_reaction := _load_optional_crowd_stream(CROWD_DANGER_BASENAME)
	if danger_reaction != null:
		_crowd_reaction_audio.stream = danger_reaction
	if match_manager != null:
		var goal_cheer := _load_optional_crowd_stream(CROWD_GOAL_BASENAME)
		if goal_cheer != null:
			match_manager.goal_reaction_crowd_sound = goal_cheer
			match_manager.goal_reaction_crowd_volume_db = -9.5


func _load_optional_crowd_stream(base_path: String) -> AudioStream:
	for extension: String in CROWD_AUDIO_EXTENSIONS:
		var candidate := base_path + extension
		if not ResourceLoader.exists(candidate):
			continue
		var stream := load(candidate) as AudioStream
		if stream != null:
			return stream
	return null


func _start_crowd_ambience() -> void:
	if _crowd_ambience_audio == null or _crowd_ambience_audio.stream == null:
		return
	_crowd_ambience_audio.volume_db = crowd_calm_volume_db
	if not _crowd_ambience_audio.playing:
		_crowd_ambience_audio.play()


func _stop_crowd_audio() -> void:
	_crowd_danger = 0.0
	_crowd_danger_armed = true
	_crowd_reaction_cooldown = 0.0
	if _crowd_ambience_audio != null:
		_crowd_ambience_audio.stop()
	if _crowd_reaction_audio != null:
		_crowd_reaction_audio.stop()


func _update_crowd_audio(delta: float) -> void:
	if not _atmosphere_active or match_manager == null:
		return
	_crowd_reaction_cooldown = maxf(0.0, _crowd_reaction_cooldown - delta)
	var target_danger := _calculate_crowd_danger()
	_crowd_danger = move_toward(
		_crowd_danger,
		target_danger,
		delta * (crowd_response_speed if target_danger > _crowd_danger else crowd_response_speed * 0.62)
	)
	var target_volume := crowd_calm_volume_db
	if _display_seconds > 0 and _display_seconds <= 15:
		target_volume = maxf(target_volume, crowd_final_seconds_volume_db)
	if _is_overtime:
		target_volume = maxf(target_volume, crowd_final_seconds_volume_db + 1.5)
	target_volume = lerpf(target_volume, crowd_danger_volume_db, _crowd_danger)
	if _crowd_ambience_audio != null and _crowd_ambience_audio.playing:
		_crowd_ambience_audio.volume_db = move_toward(
			_crowd_ambience_audio.volume_db,
			target_volume,
			delta * 12.0
		)

	if _crowd_danger <= CROWD_DANGER_RESET:
		_crowd_danger_armed = true
	if (
		_crowd_danger_armed
		and _crowd_danger >= CROWD_DANGER_TRIGGER
		and _crowd_reaction_cooldown <= 0.0
	):
		_crowd_danger_armed = false
		_crowd_reaction_cooldown = CROWD_REACTION_COOLDOWN
		_play_crowd_danger_reaction()


func _calculate_crowd_danger() -> float:
	if (
		match_manager == null
		or not match_manager.game_has_started
		or match_manager.round_resetting
		or match_manager.goal_replay_active
		or match_manager.tournament_halftime_active
	):
		return 0.0
	var ball := match_manager.ball
	if ball == null:
		return 0.0
	var velocity: Vector2 = ball.linear_velocity
	var speed := velocity.length()
	if speed < 650.0:
		return 0.0
	var position: Vector2 = ball.global_position
	var goal_x_left := playable_bounds.position.x
	var goal_x_right := playable_bounds.end.x
	var distance_to_goal_x := minf(absf(position.x - goal_x_left), absf(goal_x_right - position.x))
	var proximity := 1.0 - clampf(distance_to_goal_x / 1850.0, 0.0, 1.0)
	var speed_factor := inverse_lerp(650.0, 3600.0, clampf(speed, 650.0, 3600.0))
	var moving_toward_left := velocity.x < -120.0 and position.x < playable_bounds.get_center().x
	var moving_toward_right := velocity.x > 120.0 and position.x > playable_bounds.get_center().x
	var directional := 1.0 if moving_toward_left or moving_toward_right else 0.42
	var goal_center_y := playable_bounds.get_center().y
	var vertical_goal_factor := 1.0 - clampf(absf(position.y - goal_center_y) / 1250.0, 0.0, 1.0)
	var danger := proximity * speed_factor * directional
	danger *= lerpf(0.62, 1.0, vertical_goal_factor)
	if distance_to_goal_x < 900.0 and speed > 1200.0:
		danger = maxf(danger, 0.76)
	return clampf(danger, 0.0, 1.0)


func _play_crowd_danger_reaction() -> void:
	if _crowd_reaction_audio == null or _crowd_reaction_audio.stream == null:
		return
	_crowd_reaction_audio.stop()
	_crowd_reaction_audio.volume_db = -13.0 + _crowd_danger * 3.0
	_crowd_reaction_audio.pitch_scale = 1.0
	_crowd_reaction_audio.play()


func get_effect_profile() -> Dictionary:
	var ambience: Dictionary = get_map_ambience_profile()
	return {
		"stadium_lighting": true,
		"team_colored_glows": true,
		"subtle_particles": true,
		"tactical_rings": false,
		"particle_count": _particles.size(),
		"map_ambience": str(ambience.get("name", "stadium")),
		"match_mood": str(_match_mood),
		"overtime_lighting": _is_overtime,
		"final_minute_atmosphere": _match_mood == &"final_minute",
	}


func get_map_ambience_profile() -> Dictionary:
	var profile: Dictionary = MAP_AMBIENCE_PROFILES[
		posmod(_field_variant_index, MAP_AMBIENCE_PROFILES.size())
	].duplicate(true)
	var base_tint: Color = profile.get("tint", Color.WHITE) as Color
	var hue_shift: float = float(_field_variant_index) * 0.012
	profile["tint"] = Color.from_hsv(
		fposmod(base_tint.h + hue_shift, 1.0),
		clampf(base_tint.s, 0.0, 1.0),
		base_tint.v,
		base_tint.a
	)
	profile["name"] = "%s_%02d" % [
		str(profile.get("name", "stadium")), _field_variant_index + 1
	]
	return profile


func set_clock_state(display_seconds: int, overtime: bool) -> void:
	_display_seconds = maxi(0, display_seconds)
	_is_overtime = overtime
	_match_mood = (
		&"overtime"
		if overtime
		else &"final_minute"
		if _display_seconds > 0 and _display_seconds <= 60
		else &"normal"
	)
	queue_redraw()


func set_field_variant_index(variant_index: int) -> void:
	_field_variant_index = maxi(0, variant_index)
	queue_redraw()


func _build_particles() -> void:
	_particles.clear()
	var random := RandomNumberGenerator.new()
	random.seed = 20260809
	var bounds := playable_bounds.abs()
	for index in range(maxi(0, particle_count)):
		var side: float = -1.0 if index % 2 == 0 else 1.0
		_particles.append({
			"unit_position": Vector2(random.randf(), random.randf()),
			"speed": random.randf_range(0.010, 0.026),
			"drift": random.randf_range(18.0, 54.0) * side,
			"radius": random.randf_range(8.0, 18.0),
			"phase": random.randf_range(0.0, TAU),
			"bounds_size": bounds.size,
		})


func _draw() -> void:
	if not _atmosphere_active:
		return
	var bounds := playable_bounds.abs()
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		return

	_draw_stadium_beams(bounds)
	_draw_map_ambience(bounds)
	_draw_match_mood_lighting(bounds)
	_draw_team_edge_glow(bounds, true)
	_draw_team_edge_glow(bounds, false)
	_draw_particles(bounds)


func _draw_stadium_beams(bounds: Rect2) -> void:
	var ambience: Dictionary = get_map_ambience_profile()
	var ambience_tint: Color = ambience.get("tint", Color.WHITE) as Color
	var ambience_pulse: float = float(ambience.get("pulse", 0.75))
	var lighting_strength: float = maxf(
		0.0, float(ambience.get("lighting_strength", 1.0))
	)
	var sweep: float = sin(_time * 0.34) * bounds.size.x * 0.035
	var beam_alpha: float = (
		0.015 + sin(_time * (0.55 + ambience_pulse * 0.2)) * 0.004
	) * effect_opacity * lighting_strength
	var cool_light := Color(ambience_tint, beam_alpha)
	var warm_light := Color(1.0, 0.94, 0.72, beam_alpha * 0.82)
	var top_y: float = bounds.position.y
	var bottom_y: float = bounds.end.y
	var center_x: float = bounds.get_center().x

	draw_colored_polygon(PackedVector2Array([
		Vector2(bounds.position.x + bounds.size.x * 0.08 + sweep, top_y),
		Vector2(bounds.position.x + bounds.size.x * 0.23 + sweep, top_y),
		Vector2(center_x - bounds.size.x * 0.03 + sweep * 0.25, bottom_y),
		Vector2(center_x - bounds.size.x * 0.19 + sweep * 0.25, bottom_y),
	]), cool_light)
	draw_colored_polygon(PackedVector2Array([
		Vector2(bounds.end.x - bounds.size.x * 0.23 - sweep, top_y),
		Vector2(bounds.end.x - bounds.size.x * 0.08 - sweep, top_y),
		Vector2(center_x + bounds.size.x * 0.19 - sweep * 0.25, bottom_y),
		Vector2(center_x + bounds.size.x * 0.03 - sweep * 0.25, bottom_y),
	]), warm_light)


func _draw_map_ambience(bounds: Rect2) -> void:
	var ambience: Dictionary = get_map_ambience_profile()
	var tint: Color = ambience.get("tint", Color.WHITE) as Color
	var sparkle: float = float(ambience.get("sparkle", 1.0))
	var horizon_alpha: float = (0.012 + sin(_time * 0.42) * 0.003) * effect_opacity
	var horizon := Rect2(
		bounds.position,
		Vector2(bounds.size.x, bounds.size.y * 0.16)
	)
	draw_rect(horizon, Color(tint, horizon_alpha), true)
	for index in range(6):
		var phase: float = _time * (0.21 + sparkle * 0.04) + float(index) * 1.71
		var x: float = bounds.position.x + fposmod(
			float(index) * bounds.size.x / 6.0 + sin(phase) * 110.0,
			bounds.size.x
		)
		var y: float = bounds.position.y + bounds.size.y * (0.08 + float(index % 3) * 0.035)
		var alpha: float = (0.045 + sin(phase * 1.7) * 0.018) * effect_opacity
		draw_circle(Vector2(x, y), 5.0 + sparkle * 2.5, Color(tint, alpha))
	var effect: String = str(ambience.get("effect", ""))
	if effect == "sun":
		var sun_center := Vector2(
			bounds.position.x + bounds.size.x * 0.16,
			bounds.position.y + bounds.size.y * 0.08
		)
		var sun_pulse: float = 0.90 + sin(_time * 0.55) * 0.10
		draw_circle(sun_center, 92.0 * sun_pulse, Color(1.0, 0.79, 0.30, 0.018 * effect_opacity))
		draw_circle(sun_center, 35.0 * sun_pulse, Color(1.0, 0.94, 0.68, 0.045 * effect_opacity))
	elif effect == "moon":
		var moon_center := Vector2(
			bounds.position.x + bounds.size.x * 0.80,
			bounds.position.y + bounds.size.y * 0.10
		)
		var moon_pulse: float = 0.92 + sin(_time * 0.38) * 0.08
		draw_circle(moon_center, 76.0 * moon_pulse, Color(0.50, 0.82, 1.0, 0.016 * effect_opacity))
		draw_arc(moon_center, 31.0 * moon_pulse, 0.25, 5.6, 28, Color(0.82, 0.95, 1.0, 0.060 * effect_opacity), 5.0, true)


func _draw_match_mood_lighting(bounds: Rect2) -> void:
	if _match_mood == &"normal":
		return
	var overtime: bool = _match_mood == &"overtime"
	var mood_color: Color = Color("ffd75a") if overtime else Color("ff9d62")
	var speed: float = 3.1 if overtime else 1.75
	var pulse: float = 0.62 + sin(_time * speed) * 0.38
	var border_width: float = 16.0 if overtime else 10.0
	var alpha: float = (0.055 if overtime else 0.032) * pulse * effect_opacity
	draw_rect(bounds.grow(-4.0), Color(mood_color, alpha), false, border_width)
	var center_x: float = bounds.get_center().x
	var sweep_x: float = center_x + sin(_time * speed * 0.42) * bounds.size.x * 0.47
	draw_colored_polygon(PackedVector2Array([
		Vector2(sweep_x - 110.0, bounds.position.y),
		Vector2(sweep_x + 110.0, bounds.position.y),
		Vector2(sweep_x + 330.0, bounds.end.y),
		Vector2(sweep_x - 330.0, bounds.end.y),
	]), Color(mood_color, alpha * 0.42))


func _draw_team_edge_glow(bounds: Rect2, blue_side: bool) -> void:
	var ambience: Dictionary = get_map_ambience_profile()
	var team_glow_strength: float = maxf(
		0.0, float(ambience.get("team_glow_strength", 1.0))
	)
	var color: Color = blue_glow if blue_side else red_glow
	var edge_x: float = bounds.position.x if blue_side else bounds.end.x
	var direction: float = 1.0 if blue_side else -1.0
	var pulse: float = 0.84 + sin(_time * 1.25 + (0.0 if blue_side else 1.8)) * 0.16
	for layer in range(7, 0, -1):
		var width: float = 75.0 + float(layer) * 48.0
		var alpha: float = (
			0.0085
			* float(8 - layer)
			* pulse
			* effect_opacity
			* team_glow_strength
		)
		var strip := Rect2(
			Vector2(edge_x, bounds.position.y),
			Vector2(width * direction, bounds.size.y)
		).abs()
		draw_rect(strip, Color(color.r, color.g, color.b, alpha), true)


func _draw_particles(bounds: Rect2) -> void:
	var ambience: Dictionary = get_map_ambience_profile()
	var particle_strength: float = maxf(
		0.0, float(ambience.get("particle_strength", 1.0))
	)
	for index in range(_particles.size()):
		var particle: Dictionary = _particles[index]
		var unit_position: Vector2 = particle["unit_position"] as Vector2
		var phase: float = float(particle["phase"])
		var travel: float = fposmod(unit_position.y - _time * float(particle["speed"]), 1.0)
		var position := Vector2(
			bounds.position.x
			+ unit_position.x * bounds.size.x
			+ sin(_time * 0.55 + phase) * float(particle["drift"]),
			bounds.position.y + travel * bounds.size.y
		)
		position.x = clampf(position.x, bounds.position.x + 24.0, bounds.end.x - 24.0)
		var team_mix: float = unit_position.x
		var color: Color = blue_glow.lerp(red_glow, team_mix)
		var shimmer: float = 0.45 + sin(_time * 1.8 + phase) * 0.22
		color.a = clampf(
			0.075 * shimmer * effect_opacity * particle_strength,
			0.012,
			0.085
		)
		draw_circle(position, float(particle["radius"]), color)


func _on_match_started() -> void:
	set_clock_state(_display_seconds, false)
	set_atmosphere_active(true)


func _on_match_ended(_winning_team: StringName) -> void:
	set_atmosphere_active(false)


func _on_match_cancelled() -> void:
	set_atmosphere_active(false)


func _on_freeplay_started() -> void:
	set_atmosphere_active(true)


func _on_freeplay_ended() -> void:
	set_atmosphere_active(false)


func _on_timer_changed(display_seconds: int, overtime: bool) -> void:
	set_clock_state(display_seconds, overtime)


func _on_field_variant_changed(variant_index: int) -> void:
	set_field_variant_index(variant_index)
