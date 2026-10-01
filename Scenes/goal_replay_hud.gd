extends Control


const BANNER_SCRIPT: Script = preload("res://Scenes/goal_replay_banner.gd")
const CONTROLLER_PROMPT_COVERAGE_SHADER: Shader = preload(
	"res://Scenes/controller_prompt_coverage.gdshader"
)
const REPLAY_SKIP_CONTROLLER_BUTTON: int = JOY_BUTTON_A

@export var match_manager: FootballMatchManager

@onready var controller_support := get_node(
	"/root/ControllerSupport"
) as FootballControllerSupport
@onready var panel: PanelContainer = $Panel
@onready var replay_label: Label = $Panel/Margin/VBox/ReplayLabel
@onready var slow_motion_label: Label = $Panel/Margin/VBox/SlowMotionLabel
@onready var vote_row: HBoxContainer = $Panel/Margin/VBox/VoteRow
@onready var skip_action_label: Label = $Panel/Margin/VBox/VoteRow/SkipActionLabel
@onready var skip_prompt_icon: TextureRect = $Panel/Margin/VBox/VoteRow/PromptIcon
@onready var skip_prompt_label: Label = $Panel/Margin/VBox/VoteRow/PromptLabel
@onready var vote_count_label: Label = $Panel/Margin/VBox/VoteRow/VoteCountLabel

var _local_vote_sent: bool = false
var _replay_vignette: ColorRect
var _banner_root: Control
var _banner_art: FootballGoalReplayBanner
var _banner_name: Label
var _banner_subtitle: Label
var _banner_tween: Tween
var _controller_prompt_coverage_material: ShaderMaterial
var _last_vote_count: int = 0
var _last_total_voters: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.hide()
	if match_manager == null:
		push_error("Goal replay HUD needs a MatchManager.")
		return
	match_manager.goal_replay_state_changed.connect(
		_on_goal_replay_state_changed
	)
	match_manager.goal_replay_presentation_changed.connect(
		_on_goal_replay_presentation_changed
	)
	_build_replay_presentation()
	MenuStyler.style_panel(
		panel,
		Color(0.96, 0.96, 0.98),
		Color(0.055, 0.055, 0.06, 0.80)
	)
	MenuStyler.apply_premium_design(self, &"popup")
	_apply_responsive_layout()
	_prepare_skip_prompt_icon()
	controller_support.input_method_changed.connect(_on_input_method_changed)
	controller_support.bindings_changed.connect(_on_bindings_changed)
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_on_goal_replay_state_changed(
		match_manager.goal_replay_active,
		0,
		0,
		match_manager.goal_replay_slow_motion
	)
	_on_goal_replay_presentation_changed(
		match_manager.goal_replay_active,
		match_manager.goal_replay_presentation
	)


func _build_replay_presentation() -> void:
	_replay_vignette = ColorRect.new()
	_replay_vignette.name = "ReplayVignette"
	_replay_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_replay_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
void fragment() {
	float d = distance(UV, vec2(0.5));
	float edge = smoothstep(0.28, 0.72, d);
	float bars = smoothstep(0.34, 0.50, abs(UV.y - 0.5));
	float alpha = clamp(edge * 0.42 + bars * 0.10, 0.0, 0.48);
	COLOR = vec4(0.005, 0.007, 0.012, alpha);
}
"""
	var vignette_material := ShaderMaterial.new()
	vignette_material.shader = shader
	_replay_vignette.material = vignette_material
	add_child(_replay_vignette)
	move_child(_replay_vignette, 0)
	_replay_vignette.hide()

	_banner_root = Control.new()
	_banner_root.name = "ScorerBanner"
	_banner_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_root.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	add_child(_banner_root)
	_banner_art = BANNER_SCRIPT.new() as FootballGoalReplayBanner
	_banner_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_banner_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_root.add_child(_banner_art)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 38)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	_banner_root.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)
	var text_column := VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(text_column)
	_banner_name = Label.new()
	_banner_name.name = "ScorerName"
	_banner_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_banner_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_banner_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_banner_name.add_theme_color_override(
		"font_shadow_color",
		Color(0.0, 0.0, 0.0, 0.88)
	)
	_banner_name.add_theme_constant_override("shadow_offset_x", 2)
	_banner_name.add_theme_constant_override("shadow_offset_y", 3)
	_banner_name.add_theme_font_size_override("font_size", 24)
	text_column.add_child(_banner_name)
	_banner_subtitle = Label.new()
	_banner_subtitle.name = "ScorerSubtitle"
	_banner_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_banner_subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_banner_subtitle.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_banner_subtitle.add_theme_color_override(
		"font_shadow_color",
		Color(0.0, 0.0, 0.0, 0.88)
	)
	_banner_subtitle.add_theme_constant_override("shadow_offset_x", 2)
	_banner_subtitle.add_theme_constant_override("shadow_offset_y", 3)
	_banner_subtitle.add_theme_font_size_override("font_size", 14)
	_banner_subtitle.add_theme_color_override(
		"font_color",
		Color(0.78, 0.82, 0.86)
	)
	text_column.add_child(_banner_subtitle)
	_banner_root.hide()


func _apply_responsive_layout() -> void:
	if not is_inside_tree():
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	panel.offset_left = -286.0
	panel.offset_top = -72.0
	panel.offset_right = -14.0
	panel.offset_bottom = -14.0
	panel.custom_minimum_size = Vector2(272.0, 0.0)
	replay_label.add_theme_font_size_override("font_size", 13)
	slow_motion_label.add_theme_font_size_override(
		"font_size",
		11 if viewport_size.y < 800.0 else 12
	)
	var vote_font_size: int = 10 if viewport_size.y < 800.0 else 11
	skip_action_label.add_theme_font_size_override("font_size", vote_font_size)
	skip_prompt_label.add_theme_font_size_override("font_size", vote_font_size)
	vote_count_label.add_theme_font_size_override("font_size", vote_font_size)
	var prompt_size: float = 18.0 if viewport_size.y < 800.0 else 20.0
	skip_prompt_icon.custom_minimum_size = Vector2(prompt_size, prompt_size)
	if _banner_root != null:
		var presentation_size := FootballGoalReplayBanner.presentation_size(
			viewport_size
		)
		var banner_width: float = presentation_size.x
		var banner_height: float = presentation_size.y
		_banner_root.offset_left = -banner_width * 0.5
		_banner_root.offset_right = banner_width * 0.5
		_banner_root.offset_top = -banner_height - 18.0
		_banner_root.offset_bottom = -18.0


func _input(event: InputEvent) -> void:
	if (
		match_manager == null
		or not match_manager.goal_replay_active
		or _local_vote_sent
	):
		return
	var requested_skip: bool = false
	if event is InputEventKey:
		var key_event := event as InputEventKey
		requested_skip = (
			key_event.pressed
			and not key_event.echo
			and (
				key_event.keycode == KEY_SPACE
				or key_event.physical_keycode == KEY_SPACE
			)
		)
	elif event is InputEventJoypadButton:
		var button_event := event as InputEventJoypadButton
		requested_skip = (
			controller_support.is_controller_event_assigned(button_event)
			and button_event.pressed
			and button_event.button_index == REPLAY_SKIP_CONTROLLER_BUTTON
		)
	if not requested_skip:
		return
	_local_vote_sent = true
	_refresh_skip_prompt()
	match_manager.request_skip_goal_replay()
	get_viewport().set_input_as_handled()


func _on_goal_replay_state_changed(
	active: bool,
	votes: int,
	total_voters: int,
	slow_motion: bool
) -> void:
	if not active:
		_local_vote_sent = false
		panel.hide()
		if _replay_vignette != null:
			_replay_vignette.hide()
		if _banner_root != null:
			_banner_root.hide()
		return
	panel.show()
	_replay_vignette.show()
	slow_motion_label.visible = slow_motion
	_last_vote_count = votes
	_last_total_voters = total_voters
	_refresh_skip_prompt()


func _prepare_skip_prompt_icon() -> void:
	if skip_prompt_icon == null:
		return
	if _controller_prompt_coverage_material == null:
		_controller_prompt_coverage_material = ShaderMaterial.new()
		_controller_prompt_coverage_material.shader = (
			CONTROLLER_PROMPT_COVERAGE_SHADER
		)
	# Match the normal HUD controller glyph treatment instead of shrinking a
	# text name such as "SQUARE" into the replay line.
	skip_prompt_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	skip_prompt_icon.material = _controller_prompt_coverage_material


func _refresh_skip_prompt() -> void:
	if skip_action_label == null:
		return
	if _local_vote_sent:
		skip_action_label.text = "VOTED"
		skip_prompt_icon.hide()
		skip_prompt_label.hide()
		vote_count_label.text = "-  %d / %d" % [
			_last_vote_count,
			_last_total_voters
		]
		return
	skip_action_label.text = "SKIP"
	var use_controller_icon: bool = controller_support.using_controller
	var prompt_texture: Texture2D = null
	if use_controller_icon:
		prompt_texture = controller_support.get_controller_button_icon(
			REPLAY_SKIP_CONTROLLER_BUTTON
		)
	skip_prompt_icon.texture = prompt_texture
	skip_prompt_icon.visible = use_controller_icon and prompt_texture != null
	skip_prompt_label.visible = not skip_prompt_icon.visible
	# Keyboard follows the same HUD pattern: plain key text. Controller mode
	# shows the real family-specific icon (Cross on PlayStation, A on Xbox).
	skip_prompt_label.text = "SPACE"
	vote_count_label.text = "-  %d / %d" % [
		_last_vote_count,
		_last_total_voters
	]


func _on_input_method_changed(
	_using_controller: bool,
	_family: StringName
) -> void:
	_refresh_skip_prompt()


func _on_bindings_changed() -> void:
	_refresh_skip_prompt()


func _on_goal_replay_presentation_changed(
	active: bool,
	presentation: Dictionary
) -> void:
	if not active or presentation.is_empty():
		if _banner_root != null:
			_banner_root.hide()
		return
	var scoring_team := StringName(presentation.get("team", &""))
	var banner_id: String = str(
		presentation.get("banner_id", "player_banner.classic")
	)
	var banner_color_index: int = int(
		presentation.get("banner_color_index", -1)
	)
	_banner_art.set_presentation(banner_id, scoring_team, banner_color_index)
	_banner_name.text = str(presentation.get("scorer_name", "Player"))
	var subtitle: String = str(presentation.get("subtitle", "")).strip_edges()
	_banner_subtitle.text = subtitle if not subtitle.is_empty() else "GOAL SCORER"
	_banner_root.show()
	_play_scorer_presentation()


func _play_scorer_presentation() -> void:
	if _banner_root == null:
		return
	if _banner_tween != null and _banner_tween.is_valid():
		_banner_tween.kill()
	_banner_root.pivot_offset = _banner_root.size * 0.5
	_banner_root.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_banner_root.scale = Vector2(0.94, 0.94)
	var settled_position: Vector2 = _banner_root.position
	_banner_root.position = settled_position + Vector2(-42.0, 10.0)
	_banner_tween = create_tween()
	_banner_tween.set_parallel(true)
	_banner_tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	_banner_tween.tween_property(_banner_root, "modulate:a", 1.0, 0.22)
	_banner_tween.tween_property(_banner_root, "scale", Vector2.ONE, 0.34)
	_banner_tween.tween_property(_banner_root, "position", settled_position, 0.34)
