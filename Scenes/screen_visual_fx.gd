extends CanvasLayer


const GOAL_IMPACT_BOOM: AudioStream = preload(
	"res://Audio/goal_impact_boom.wav"
)

@export var match_manager: FootballMatchManager
@export_range(0.0, 0.5, 0.01)
var vignette_strength: float = 0.12
@export_range(-80.0, 12.0, 0.5)
var goal_boom_volume_db: float = -13.0

@export_category("Power Strike Flash")
@export var power_strike_flash_color: Color = Color(1.0, 0.16, 0.07, 1.0)
@export_range(0.0, 0.5, 0.01)
var power_strike_white_flash_alpha: float = 0.16
@export_range(0.0, 1.0, 0.01)
var power_strike_edge_flash_alpha: float = 0.82
@export_range(0.005, 0.10, 0.005)
var power_strike_flash_attack_seconds: float = 0.025
@export_range(0.03, 0.50, 0.01)
var power_strike_flash_release_seconds: float = 0.22

var _vignette: ColorRect
var _goal_flash: ColorRect
var _white_flash: ColorRect
var _goal_audio: AudioStreamPlayer
var _goal_flash_material: ShaderMaterial
var _flash_tween: Tween
var _previous_red_score: int = 0
var _previous_blue_score: int = 0


func _ready() -> void:
	layer = 0
	_build_vignette()
	_build_goal_flash()
	_build_audio()

	if match_manager == null:
		push_error("ScreenVisualFX MatchManager was not assigned.")
		return

	_previous_red_score = match_manager.red_score
	_previous_blue_score = match_manager.blue_score
	match_manager.score_changed.connect(_on_score_changed)


func _build_vignette() -> void:
	_vignette = ColorRect.new()
	_vignette.name = "Vignette"
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float strength = 0.12;

void fragment() {
	float distance_from_center = distance(UV, vec2(0.5));
	float edge = smoothstep(0.34, 0.79, distance_from_center);
	float top_bottom = smoothstep(0.38, 0.54, abs(UV.y - 0.5));
	float alpha = clamp(edge * strength + top_bottom * strength * 0.08, 0.0, 0.36);
	COLOR = vec4(0.004, 0.009, 0.012, alpha * COLOR.a);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("strength", vignette_strength)
	_vignette.material = material
	add_child(_vignette)


func _build_goal_flash() -> void:
	_goal_flash = ColorRect.new()
	_goal_flash.name = "GoalEdgeFlash"
	_goal_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_goal_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_goal_flash.modulate.a = 0.0

	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform vec4 flash_color = vec4(0.25, 0.65, 1.0, 1.0);

void fragment() {
	float distance_from_center = distance(UV, vec2(0.5));
	float edge = smoothstep(0.2, 0.78, distance_from_center);
	float center_glow = 1.0 - smoothstep(0.0, 0.72, distance_from_center);
	float alpha = (edge * 0.82 + center_glow * 0.16) * COLOR.a;
	COLOR = vec4(flash_color.rgb, alpha);
}
"""
	_goal_flash_material = ShaderMaterial.new()
	_goal_flash_material.shader = shader
	_goal_flash.material = _goal_flash_material
	add_child(_goal_flash)

	_white_flash = ColorRect.new()
	_white_flash.name = "GoalWhiteFlash"
	_white_flash.color = Color.WHITE
	_white_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_white_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_white_flash.modulate.a = 0.0
	add_child(_white_flash)


func _build_audio() -> void:
	_goal_audio = AudioStreamPlayer.new()
	_goal_audio.name = "GoalImpactBoom"
	_goal_audio.stream = GOAL_IMPACT_BOOM
	_goal_audio.volume_db = goal_boom_volume_db
	add_child(_goal_audio)


func play_power_strike_flash() -> void:
	if _goal_flash == null or _white_flash == null:
		return
	if _goal_flash_material == null:
		return
	if match_manager != null and match_manager.cpu_training_mode:
		return

	if _flash_tween != null:
		_flash_tween.kill()

	_goal_flash_material.set_shader_parameter(
		"flash_color",
		power_strike_flash_color
	)
	_goal_flash.modulate.a = 0.0
	_white_flash.modulate.a = 0.0

	_flash_tween = create_tween()
	_flash_tween.set_parallel(true)
	_flash_tween.tween_property(
		_white_flash,
		"modulate:a",
		clampf(power_strike_white_flash_alpha, 0.0, 0.5),
		maxf(0.005, power_strike_flash_attack_seconds)
	)
	_flash_tween.tween_property(
		_goal_flash,
		"modulate:a",
		clampf(power_strike_edge_flash_alpha, 0.0, 1.0),
		maxf(0.005, power_strike_flash_attack_seconds)
	)
	_flash_tween.chain().set_parallel(true)
	_flash_tween.tween_property(
		_white_flash,
		"modulate:a",
		0.0,
		maxf(0.03, power_strike_flash_release_seconds * 0.45)
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_flash_tween.tween_property(
		_goal_flash,
		"modulate:a",
		0.0,
		maxf(0.03, power_strike_flash_release_seconds)
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _on_score_changed(red_score: int, blue_score: int) -> void:
	var red_increased := red_score > _previous_red_score
	var blue_increased := blue_score > _previous_blue_score
	_previous_red_score = red_score
	_previous_blue_score = blue_score

	if not red_increased and not blue_increased:
		return
	if match_manager != null and match_manager.cpu_training_mode:
		return

	var color := (
		Color(1.0, 0.2, 0.28, 1.0)
		if red_increased
		else Color(0.22, 0.62, 1.0, 1.0)
	)
	_play_goal_punch(color)


func _play_goal_punch(color: Color) -> void:
	if _flash_tween != null:
		_flash_tween.kill()

	_goal_flash_material.set_shader_parameter("flash_color", color)
	_goal_flash.modulate.a = 0.0
	_white_flash.modulate.a = 0.0

	# A harder first frame and faster release makes goals feel heavier without
	# washing the field out during the following replay/focus sequence.
	_flash_tween = create_tween()
	_flash_tween.set_parallel(false)
	_flash_tween.tween_property(
		_white_flash,
		"modulate:a",
		0.31,
		0.022
	)
	_flash_tween.parallel().tween_property(
		_goal_flash,
		"modulate:a",
		1.0,
		0.03
	)
	_flash_tween.tween_property(
		_white_flash,
		"modulate:a",
		0.0,
		0.085
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_flash_tween.parallel().tween_property(
		_goal_flash,
		"modulate:a",
		0.32,
		0.10
	)
	_flash_tween.tween_property(
		_goal_flash,
		"modulate:a",
		0.0,
		0.24
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	play_goal_impact_sound()


func play_goal_impact_sound() -> void:
	if _goal_audio == null or _goal_audio.stream == null:
		return
	_goal_audio.stop()
	_goal_audio.volume_db = goal_boom_volume_db
	_goal_audio.play()
