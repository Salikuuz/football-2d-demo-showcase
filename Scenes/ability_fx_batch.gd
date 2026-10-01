class_name FootballAbilityFxBatch
extends Node2D

# One batched renderer for every player's ability state. Active rings and their
# short activation pulses are MultiMesh instances, so 12 players still render
# through a single draw submission instead of 12 independent particle clouds.

const MAX_PLAYERS: int = 16
const INSTANCES_PER_PLAYER: int = 2
const QUAD_SIZE: float = 390.0

var _players_parent: Node
var _multimesh_instance: MultiMeshInstance2D
var _multimesh: MultiMesh
var _instance_visible := PackedByteArray()


func _ready() -> void:
	z_index = 2
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_players_parent = get_node_or_null("../Players")
	_build_batch()
	set_process(true)


func _build_batch() -> void:
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_2D
	_multimesh.use_colors = true
	_multimesh.use_custom_data = true
	_multimesh.instance_count = MAX_PLAYERS * INSTANCES_PER_PLAYER
	_multimesh.visible_instance_count = _multimesh.instance_count
	_instance_visible.resize(_multimesh.instance_count)
	_instance_visible.fill(0)
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * QUAD_SIZE
	_multimesh.mesh = quad

	_multimesh_instance = MultiMeshInstance2D.new()
	_multimesh_instance.name = "AbilityFxMultiMesh"
	_multimesh_instance.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_multimesh_instance.multimesh = _multimesh
	_multimesh_instance.material = _make_material()
	add_child(_multimesh_instance)
	for instance_index in range(_multimesh.instance_count):
		_multimesh.set_instance_transform_2d(
			instance_index,
			Transform2D(0.0, Vector2.ZERO, 0.0, Vector2.ZERO)
		)
		_multimesh.set_instance_color(instance_index, Color(0.0, 0.0, 0.0, 0.0))
		_multimesh.set_instance_custom_data(instance_index, Color(0.0, 0.0, 0.0, 0.0))


func _make_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
render_mode unshaded, blend_add;

varying vec4 fx_custom;

void vertex() {
	fx_custom = INSTANCE_CUSTOM;
}

float ring_band(float radius, float center, float width) {
	return 1.0 - smoothstep(width, width + 0.018, abs(radius - center));
}

void fragment() {
	vec2 p = UV * 2.0 - vec2(1.0);
	float radius = length(p);
	float angle = atan(p.y, p.x);
	float normalized_angle = (angle + 3.14159265) / 6.28318530;
	float pattern = floor(fx_custom.x + 0.5);
	float pulse_mode = fx_custom.y;
	float phase = fx_custom.z;

	float frequency = 8.0;
	if (pattern == 1.0) frequency = 12.0;
	else if (pattern == 2.0) frequency = 10.0;
	else if (pattern == 3.0) frequency = 6.0;
	else if (pattern == 4.0) frequency = 14.0;
	else if (pattern == 5.0) frequency = 7.0;
	else if (pattern == 6.0) frequency = 9.0;
	else if (pattern >= 7.0) frequency = 11.0;

	float spin = TIME * (pulse_mode > 0.5 ? 0.32 : 0.075);
	float cell = fract((normalized_angle + spin + phase) * frequency);
	float segment = smoothstep(0.08, 0.16, cell) * (1.0 - smoothstep(0.68, 0.82, cell));
	float wave = 0.5 + 0.5 * sin(angle * (4.0 + pattern) + TIME * 1.4 + phase * 6.28);
	float main_radius = mix(0.70, 0.77, pulse_mode);
	float ring = ring_band(radius, main_radius, mix(0.026, 0.040, pulse_mode));
	float accent_ring = ring_band(radius, main_radius - 0.09, 0.014) * (0.30 + 0.32 * wave);
	float segmented = ring * mix(segment, 0.72 + 0.28 * wave, step(5.0, pattern));
	float glow = exp(-pow((radius - main_radius) * 8.5, 2.0)) * 0.22;
	float inner_glow = (1.0 - smoothstep(0.48, 0.80, radius)) * 0.045;
	float alpha = segmented * 0.90 + accent_ring + glow + inner_glow;
	alpha *= COLOR.a;
	vec3 tint = COLOR.rgb * (1.0 + segmented * 0.32 + glow * 0.45);
	COLOR = vec4(tint, clamp(alpha, 0.0, 1.0));
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material


func _process(_delta: float) -> void:
	if _players_parent == null or not is_instance_valid(_players_parent):
		_players_parent = get_node_or_null("../Players")
	if _players_parent == null:
		_hide_all()
		return
	var slot := 0
	for child_index in range(_players_parent.get_child_count()):
		if slot >= MAX_PLAYERS:
			break
		var player := _players_parent.get_child(child_index) as FootballPlayer
		if player == null:
			continue
		_update_player_slot(slot, player)
		slot += 1
	for unused_slot in range(slot, MAX_PLAYERS):
		_hide_instance(unused_slot * INSTANCES_PER_PLAYER)
		_hide_instance(unused_slot * INSTANCES_PER_PLAYER + 1)


func _update_player_slot(slot: int, player: FootballPlayer) -> void:
	var active_index := slot * INSTANCES_PER_PLAYER
	var pulse_index := active_index + 1
	var active := (
		player.local_ability_active
		and player.local_active_ability_id != FootballPlayer.ABILITY_NONE
	)
	var cue_active := player.get_ability_fx_cue_remaining() > 0.0
	if not active:
		_hide_instance(active_index)
	else:
		var active_color := player.get_ability_fx_color()
		var player_scale := player.get_ability_fx_presentation_scale()
		_set_instance(
			active_index,
			to_local(player.global_position),
			player_scale,
			Color(active_color, 0.58),
			player.get_ability_fx_pattern_index(),
			0.0,
			float(slot) * 0.071
		)

	if not cue_active:
		_hide_instance(pulse_index)
		return
	var cue_total := maxf(0.01, player.get_ability_fx_cue_total())
	var remaining_ratio := clampf(
		player.get_ability_fx_cue_remaining() / cue_total,
		0.0,
		1.0
	)
	var progress := 1.0 - remaining_ratio
	var cue_color := player.get_ability_fx_color()
	var pulse_scale := player.get_ability_fx_presentation_scale() * lerpf(0.82, 1.48, progress)
	_set_instance(
		pulse_index,
		to_local(player.global_position),
		pulse_scale,
		Color(cue_color.lightened(0.18), pow(remaining_ratio, 1.25) * 0.88),
		player.get_ability_fx_pattern_index(),
		1.0,
		float(slot) * 0.071
	)


func _set_instance(
	instance_index: int,
	position: Vector2,
	scale_value: float,
	color: Color,
	pattern_index: int,
	pulse_mode: float,
	phase: float
) -> void:
	var transform := Transform2D(
		0.0,
		Vector2.ONE * maxf(0.01, scale_value),
		0.0,
		position
	)
	_instance_visible[instance_index] = 1
	_multimesh.set_instance_transform_2d(instance_index, transform)
	_multimesh.set_instance_color(instance_index, color)
	_multimesh.set_instance_custom_data(
		instance_index,
		Color(float(pattern_index), pulse_mode, phase, 1.0)
	)


func _hide_instance(instance_index: int) -> void:
	if _instance_visible[instance_index] == 0:
		return
	_instance_visible[instance_index] = 0
	_multimesh.set_instance_transform_2d(
		instance_index,
		Transform2D(0.0, Vector2.ZERO, 0.0, Vector2.ZERO)
	)
	_multimesh.set_instance_color(instance_index, Color(0.0, 0.0, 0.0, 0.0))
	_multimesh.set_instance_custom_data(instance_index, Color(0.0, 0.0, 0.0, 0.0))


func _hide_all() -> void:
	for instance_index in range(_multimesh.instance_count):
		_hide_instance(instance_index)
