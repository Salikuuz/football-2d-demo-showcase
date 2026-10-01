class_name ChampionsLeagueCard
extends Button


const CARD_BACK_RED: Texture2D = preload("res://Assets/draft/card_back_red.png")
const CARD_BACK_BLUE: Texture2D = preload("res://Assets/draft/card_back_blue.png")
const CARD_FRONT_RED: Texture2D = preload("res://Assets/draft/card_front_red.png")
const CARD_FRONT_BLUE: Texture2D = preload("res://Assets/draft/card_front_blue.png")
const CARD_HOVER_SOUND: AudioStream = preload("res://cardsounds/cardhover.mp3")
const CARD_ACTION_SOUNDS: Array[AudioStream] = [
	preload("res://cardsounds/cardsound_fast_1.wav"),
	preload("res://cardsounds/cardsound_fast_2.wav"),
	preload("res://cardsounds/cardsound_fast_3.wav"),
	preload("res://cardsounds/cardsound_fast_4.wav"),
]
const ABILITY_ICON_PATHS: Array[String] = [
	"res://Characters/ability_none.svg", "res://Characters/ability_burst.svg",
	"res://Characters/ability_quick_trigger.svg", "res://Characters/ability_power_strike.svg",
	"res://Characters/ability_overdrive.svg", "res://Characters/ability_heel_turn.svg",
	"res://Characters/ability_enforcer.svg", "res://Characters/ability_goalkeeper_reach.svg",
	"res://Characters/ability_time_skip_pass.svg", "res://Characters/ability_direct_finish.svg",
	"res://Characters/ability_elastic_step.svg", "res://Characters/ability_meta_vision.svg",
	"res://Characters/ability_copycat.svg", "res://Characters/ability_reflex_block.svg",
	"res://Characters/ability_iron_anchor.svg", "res://Characters/ability_blind_spot.svg",
	"res://Characters/ability_boogie_woogie.svg", "res://Characters/ability_echo.svg",
	"res://Characters/ability_return_tag.svg", "res://Characters/ability_breakaway.png",
	"res://Characters/ability_snapback.svg", "res://Characters/ability_side_swipe.svg",
	"res://Characters/ability_nutmeg.svg", "res://Characters/ability_decoy_run.svg",
]
const PERK_ICON_PATHS: Array[String] = [
	"res://Characters/ability_overdrive.svg",
	"res://Assets/perk_icons/02_quick_release.svg",
	"res://Assets/perk_icons/03_final_touch.svg",
	"res://Assets/perk_icons/04_heavy_leather.svg",
	"res://Assets/perk_icons/05_hot_streak.svg",
	"res://Characters/ability_goalkeeper_reach.svg",
	"res://Characters/ability_nutmeg.svg",
	"res://Assets/perk_icons/08_endless_engine.svg",
	"res://Assets/perk_icons/09_counter_runner.svg",
	"res://Assets/perk_icons/10_elastic_laces.svg",
	"res://Characters/ability_echo.svg",
	"res://Assets/perk_icons/12_give_and_go.svg",
	"res://Assets/perk_icons/13_tempo_controller.svg",
	"res://Assets/perk_icons/14_thread_the_needle.svg",
	"res://Assets/perk_icons/15_second_conductor.svg",
	"res://Assets/perk_icons/16_rapid_recharge.svg",
	"res://Assets/perk_icons/17_overclocked_core.svg",
	"res://Assets/perk_icons/18_extended_cut.svg",
	"res://Assets/perk_icons/19_combo_engine.svg",
	"res://Assets/perk_icons/20_arcane_balance.svg",
	"res://Assets/perk_icons/21_last_stand.svg",
	"res://Assets/perk_icons/22_sweeper_keeper.svg",
	"res://Assets/perk_icons/23_pressing_trap.svg",
	"res://Assets/perk_icons/24_counter_shield.svg",
	"res://Characters/ability_boogie_woogie.svg",
	"res://Assets/perk_icons/26_multi_cast.svg",
	"res://Assets/perk_icons/27_afterburner.svg",
	"res://Assets/perk_icons/28_loaded_follow_up.svg",
	"res://Assets/perk_icons/29_one_two_engine.svg",
	"res://Assets/perk_icons/30_combo_window.svg",
	"res://Assets/perk_icons/31_ability_relay.svg",
	"res://Assets/perk_icons/32_clutch_catalyst.svg",
	"res://Assets/perk_icons/33_countercharge.svg",
	"res://Assets/perk_icons/34_finisher_loop.svg",
	"res://Assets/perk_icons/35_first_time_finish.svg",
	"res://Assets/perk_icons/36_hot_potato.svg",
	"res://Assets/perk_icons/37_backdoor_deal.svg",
	"res://Assets/perk_icons/38_free_refill.svg",
	"res://Assets/perk_icons/39_loaded_dice.svg",
	"res://Assets/perk_icons/40_black_market.svg",
	"res://Assets/perk_icons/41_chase_scene.svg",
	"res://Assets/perk_icons/42_victory_tax.svg",
	"res://Assets/perk_icons/43_reverse_card.svg",
	"res://Assets/perk_icons/44_double_feature.svg",
	"res://Assets/perk_icons/45_overflow.svg",
	"res://Characters/ability_breakaway.png",
	"res://Assets/perk_icons/47_ability_mastery.svg",
	"res://Assets/perk_icons/48_vector_break.svg",
	"res://Assets/perk_icons/49_magnus_overload.svg",
	"res://Assets/perk_icons/50_tap_cannon.svg",
	"res://Assets/perk_icons/51_redline_eject.svg",
	"res://Assets/perk_icons/52_phantom_magnet.svg",
	"res://Assets/perk_icons/53_bruiser_trigger.svg",
	"res://Assets/perk_icons/54_handbrake_dive.svg",
	"res://Assets/perk_icons/55_emergency_exit.svg",
	"res://Assets/perk_icons/56_instinct_finish.svg",
	"res://Assets/perk_icons/57_slingshot_step.svg",
	"res://Assets/perk_icons/58_persistent_memory.svg",
	"res://Assets/perk_icons/59_perfect_parry.svg",
	"res://Assets/perk_icons/60_pocket_anchor.svg",
	"res://Assets/perk_icons/61_shadow_carry.svg",
	"res://Assets/perk_icons/62_boogie_ball.svg",
]

var ability_id: int = FootballPlayer.ABILITY_NONE
var card_kind: StringName = FootballMatchManager.DRAFT_KIND_ABILITY
var selected: bool = false
var revealed: bool = false
var card_team: StringName = FootballMatchManager.TEAM_RED
var _accent := Color(0.62, 0.48, 1.0)
var _hovered: bool = false
var _pointer_hovered: bool = false
var _indicator_active: bool = false
var _indicator_time: float = 0.0
var _top_indicator_base_position := Vector2.ZERO
var _bottom_indicator_base_position := Vector2.ZERO
var _base_scale := Vector2.ONE
var _flip_tween: Tween
var _hover_tween: Tween
var _hover_audio: AudioStreamPlayer
var _action_audio: AudioStreamPlayer


func _ready() -> void:
	_build_card_audio()
	mouse_entered.connect(_on_pointer_entered)
	mouse_exited.connect(_on_pointer_exited)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	pressed.connect(_play_random_action_sound)
	resized.connect(_sync_pivot)
	_build_shimmer_material()
	_build_card_back_material()
	_update_card_back_texture()
	_update_display()
	_apply_reveal_visibility()
	_top_indicator_base_position = $HoverTopIndicator.position
	_bottom_indicator_base_position = $HoverBottomIndicator.position
	_update_hover_indicators()
	set_process(true)


func _build_card_audio() -> void:
	_hover_audio = AudioStreamPlayer.new()
	_hover_audio.name = "HoverAudio"
	_hover_audio.stream = CARD_HOVER_SOUND
	_hover_audio.volume_db = -8.0
	add_child(_hover_audio)
	_action_audio = AudioStreamPlayer.new()
	_action_audio.name = "ActionAudio"
	_action_audio.volume_db = -5.0
	add_child(_action_audio)


func _on_pointer_entered() -> void:
	_pointer_hovered = true
	_on_mouse_entered()
	_play_hover_sound()


func _play_hover_sound() -> void:
	if disabled or _hover_audio == null:
		return
	_hover_audio.play()


func _on_pointer_exited() -> void:
	_pointer_hovered = false
	_on_mouse_exited()


func _on_focus_entered() -> void:
	_on_mouse_entered()
	_play_hover_sound()


func _on_focus_exited() -> void:
	if not _pointer_hovered:
		_on_mouse_exited()


func is_pointer_hovered() -> bool:
	return _pointer_hovered


func set_indicator_active(value: bool) -> void:
	if _indicator_active == value and is_node_ready():
		_update_hover_indicators()
		return
	_indicator_active = value
	_indicator_time = 0.0
	if is_node_ready():
		$HoverTopIndicator.position = _top_indicator_base_position
		$HoverBottomIndicator.position = _bottom_indicator_base_position
		_update_hover_indicators()


func _play_random_action_sound() -> void:
	if _action_audio == null or CARD_ACTION_SOUNDS.is_empty():
		return
	_action_audio.stream = CARD_ACTION_SOUNDS.pick_random()
	_action_audio.play()


func set_card_data(kind: StringName, value: int) -> void:
	card_kind = kind
	ability_id = value
	if is_node_ready():
		_update_display()


func set_ability_id(value: int) -> void:
	set_card_data(FootballMatchManager.DRAFT_KIND_ABILITY, value)


func set_team(value: StringName) -> void:
	card_team = (
		FootballMatchManager.TEAM_BLUE
		if value == FootballMatchManager.TEAM_BLUE
		else FootballMatchManager.TEAM_RED
	)
	if is_node_ready():
		_update_card_back_texture()


func _update_card_back_texture() -> void:
	$Back.texture = (
		CARD_BACK_BLUE
		if card_team == FootballMatchManager.TEAM_BLUE
		else CARD_BACK_RED
	)
	$FaceTexture.texture = (
		CARD_FRONT_BLUE
		if card_team == FootballMatchManager.TEAM_BLUE
		else CARD_FRONT_RED
	)


func set_selected(value: bool) -> void:
	selected = value
	if selected and not revealed:
		set_revealed(true)
	if is_node_ready():
		_update_display()


func is_revealed() -> bool:
	return revealed


func set_revealed(value: bool, immediate: bool = false) -> void:
	if revealed == value and is_node_ready():
		_apply_reveal_visibility()
		return
	revealed = value
	if not is_node_ready():
		return
	if immediate:
		if _flip_tween != null and _flip_tween.is_running():
			_flip_tween.kill()
		scale.x = _base_scale.x
		_apply_reveal_visibility()
		return
	if _flip_tween != null and _flip_tween.is_running():
		_flip_tween.kill()
	var target_scale_x: float = maxf(0.01, _base_scale.x)
	_flip_tween = create_tween()
	_flip_tween.tween_property(self, "scale:x", 0.035, 0.12).set_trans(
		Tween.TRANS_QUAD
	).set_ease(Tween.EASE_IN)
	_flip_tween.tween_callback(_apply_reveal_visibility)
	_flip_tween.tween_property(self, "scale:x", target_scale_x, 0.16).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)


func _apply_reveal_visibility() -> void:
	$Back.visible = not revealed
	$FaceTexture.visible = revealed
	$InnerFrame.visible = revealed
	$RarityStrip.visible = revealed
	$Margin.visible = revealed
	$Shimmer.visible = false
	queue_redraw()


func _update_display() -> void:
	var definition: Dictionary = {}
	var card_name := ""
	var description := ""
	var role: StringName
	var icon_id := ability_id
	var show_icon := true
	var perk_icon_path := ""
	if card_kind == FootballMatchManager.DRAFT_KIND_PERK:
		definition = FootballMatchManager.get_draft_perk_definition(ability_id)
		card_name = str(definition.get("name", "Unknown Perk"))
		description = str(definition.get("description", ""))
		role = StringName(definition.get("role", &"flexible"))
		icon_id = -1
		if ability_id > 0 and ability_id <= PERK_ICON_PATHS.size():
			perk_icon_path = PERK_ICON_PATHS[ability_id - 1]
		show_icon = not perk_icon_path.is_empty()
	else:
		card_name = FootballPlayer.get_ability_name(ability_id)
		description = FootballPlayer.get_ability_description(ability_id)
		role = FootballPlayer.get_ability_role(ability_id)
	_accent = _role_color(role)
	$Margin/Content/TopRow/TypeLabel.text = (
		"PERK" if card_kind == FootballMatchManager.DRAFT_KIND_PERK else "ABILITY"
	)
	$Margin/Content/TopRow/RoleLabel.text = str(role).to_upper()
	$Margin/Content/TopRow/RoleLabel.add_theme_color_override("font_color", _accent)
	$Margin/Content/NamePlate/AbilityName.text = card_name
	var description_label := (
		$Margin/Content/DescriptionPlate/DescriptionMargin/Description
		as RichTextLabel
	)
	description_label.text = "[center]%s[/center]" % _short_card_description(description)
	description_label.tooltip_text = description
	$Margin/Content/Footer.text = (
		"LOCKED IN"
		if selected
		else "CLICK AGAIN TO CHOOSE"
	)
	$RarityStrip.color = _accent
	$Margin/Content/ArtFrame/Icon.visible = show_icon
	$Margin/Content/ArtFrame/Icon.texture = null
	if show_icon and not perk_icon_path.is_empty():
		$Margin/Content/ArtFrame/Icon.texture = load(perk_icon_path) as Texture2D
	elif show_icon and icon_id >= 0 and icon_id < ABILITY_ICON_PATHS.size():
		$Margin/Content/ArtFrame/Icon.texture = load(ABILITY_ICON_PATHS[icon_id]) as Texture2D
	$Margin/Content/ArtFrame/Icon.material = null
	_apply_styles()
	queue_redraw()


func _apply_styles() -> void:
	var normal := StyleBoxFlat.new()
	# The raster templates own the physical card silhouette. Keeping the Button
	# itself transparent prevents its taller rectangular bounds from appearing
	# behind the face-down artwork or making the revealed face look larger.
	normal.bg_color = Color.TRANSPARENT
	normal.border_color = Color.TRANSPARENT
	normal.set_border_width_all(0)
	add_theme_stylebox_override("normal", normal)
	add_theme_stylebox_override("hover", normal)
	add_theme_stylebox_override("focus", normal)
	add_theme_stylebox_override("pressed", normal)
	var inner_frame := StyleBoxFlat.new()
	inner_frame.bg_color = Color.TRANSPARENT
	inner_frame.border_color = (
		Color(1.0, 0.94, 0.72, 0.92)
		if selected
		else Color.TRANSPARENT
	)
	inner_frame.set_border_width_all(2 if selected else 0)
	inner_frame.set_corner_radius_all(13)
	inner_frame.anti_aliasing = true
	inner_frame.anti_aliasing_size = 1.0
	$InnerFrame.add_theme_stylebox_override("panel", inner_frame)
	var art := StyleBoxFlat.new()
	art.bg_color = Color(0.01, 0.015, 0.02, 0.12)
	art.border_color = Color.TRANSPARENT
	art.set_border_width_all(0)
	art.corner_radius_top_left = 30
	art.corner_radius_top_right = 30
	art.corner_radius_bottom_left = 12
	art.corner_radius_bottom_right = 12
	art.anti_aliasing = true
	art.anti_aliasing_size = 1.0
	$Margin/Content/ArtFrame.add_theme_stylebox_override("panel", art)
	var name_plate := StyleBoxFlat.new()
	name_plate.bg_color = Color.TRANSPARENT
	name_plate.border_color = Color.TRANSPARENT
	name_plate.set_border_width_all(0)
	name_plate.corner_radius_top_left = 14
	name_plate.corner_radius_top_right = 14
	name_plate.corner_radius_bottom_left = 9
	name_plate.corner_radius_bottom_right = 9
	name_plate.content_margin_left = 7.0
	name_plate.content_margin_right = 7.0
	name_plate.anti_aliasing = true
	name_plate.anti_aliasing_size = 1.0
	$Margin/Content/NamePlate.add_theme_stylebox_override("panel", name_plate)
	var description_plate := StyleBoxFlat.new()
	description_plate.bg_color = Color.TRANSPARENT
	description_plate.border_color = Color.TRANSPARENT
	description_plate.set_border_width_all(0)
	description_plate.set_corner_radius_all(8)
	description_plate.anti_aliasing = true
	description_plate.anti_aliasing_size = 1.0
	$Margin/Content/DescriptionPlate.add_theme_stylebox_override(
		"panel",
		description_plate
	)


func _short_card_description(full_text: String) -> String:
	const MAX_CARD_DESCRIPTION_CHARS := 108
	var clean := full_text.strip_edges()
	if clean.length() <= MAX_CARD_DESCRIPTION_CHARS:
		return clean
	var cutoff := clean.rfind(" ", MAX_CARD_DESCRIPTION_CHARS)
	if cutoff < 72:
		cutoff = MAX_CARD_DESCRIPTION_CHARS
	return clean.left(cutoff).strip_edges() + "…"


func _role_color(role: StringName) -> Color:
	match role:
		FootballPlayer.ABILITY_ROLE_ATTACK, &"attack":
			return Color(1.0, 0.31, 0.25)
		FootballPlayer.ABILITY_ROLE_PLAYMAKER, &"playmaker":
			return Color(0.22, 0.74, 1.0)
		FootballPlayer.ABILITY_ROLE_DEFENSE, &"defense":
			return Color(0.24, 0.92, 0.54)
		&"mobility":
			return Color(1.0, 0.67, 0.20)
		&"ability":
			return Color(0.72, 0.43, 1.0)
		_:
			return Color(1.0, 0.82, 0.30)


func _build_shimmer_material() -> void:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform vec4 tint : source_color = vec4(1.0);
void fragment() {
    float sweep = fract(TIME * 0.16) * 2.4 - 0.7;
    float band = smoothstep(0.16, 0.0, abs((UV.x + UV.y * 0.42) - sweep));
    float edge = smoothstep(0.50, 0.05, distance(UV, vec2(0.5)));
    COLOR = vec4(tint.rgb, band * edge * 0.14);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("tint", _accent.lightened(0.35))
	$Shimmer.material = material


func _build_card_back_material() -> void:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
void fragment() {
    vec4 color = texture(TEXTURE, UV);
    float low = min(color.r, min(color.g, color.b));
    float high = max(color.r, max(color.g, color.b));
    bool pale = low > 0.88 && (high - low) < 0.08;
    bool edge = UV.x < 0.12 || UV.x > 0.88 || UV.y < 0.09 || UV.y > 0.91;
    if (pale && edge) {
        color.a = 0.0;
    }
    COLOR = color;
}
"""
	for texture_rect: TextureRect in [$Back, $FaceTexture]:
		var material := ShaderMaterial.new()
		material.shader = shader
		texture_rect.material = material


func _process(delta: float) -> void:
	if $Shimmer.material is ShaderMaterial:
		($Shimmer.material as ShaderMaterial).set_shader_parameter(
			"tint", _accent.lightened(0.35)
		)
	if _indicator_active and not disabled:
		_indicator_time += delta
		var bob := sin(_indicator_time * 5.2) * 4.0
		$HoverTopIndicator.position = _top_indicator_base_position + Vector2(0.0, bob)
		$HoverBottomIndicator.position = _bottom_indicator_base_position + Vector2(0.0, -bob)
	else:
		$HoverTopIndicator.position = _top_indicator_base_position
		$HoverBottomIndicator.position = _bottom_indicator_base_position


func _draw() -> void:
	pass


func _update_hover_indicators() -> void:
	var active := _indicator_active and not disabled
	$HoverTopIndicator.visible = active
	$HoverBottomIndicator.visible = active


func _on_mouse_entered() -> void:
	_hovered = true
	_update_hover_indicators()
	_apply_styles()
	if _hover_tween != null and _hover_tween.is_running():
		_hover_tween.kill()
	_hover_tween = create_tween().set_parallel(true)
	_hover_tween.tween_property(self, "position:y", -7.0, 0.14).set_trans(
		Tween.TRANS_QUAD
	).set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property($Back, "modulate", Color(1.10, 1.10, 1.10, 1.0), 0.14)
	_hover_tween.tween_property($FaceTexture, "modulate", Color(1.10, 1.10, 1.10, 1.0), 0.14)
	_hover_tween.tween_property($HoverTopIndicator, "scale", Vector2(1.12, 1.12), 0.14)
	_hover_tween.tween_property($HoverBottomIndicator, "scale", Vector2(1.12, 1.12), 0.14)


func _on_mouse_exited() -> void:
	_hovered = false
	_update_hover_indicators()
	_apply_styles()
	if _hover_tween != null and _hover_tween.is_running():
		_hover_tween.kill()
	_hover_tween = create_tween().set_parallel(true)
	_hover_tween.tween_property(self, "position:y", 0.0, 0.12).set_trans(
		Tween.TRANS_QUAD
	).set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property($Back, "modulate", Color.WHITE, 0.12)
	_hover_tween.tween_property($FaceTexture, "modulate", Color.WHITE, 0.12)
	_hover_tween.tween_property($HoverTopIndicator, "scale", Vector2.ONE, 0.12)
	_hover_tween.tween_property($HoverBottomIndicator, "scale", Vector2.ONE, 0.12)
	if _flip_tween == null or not _flip_tween.is_running():
		scale = _base_scale
		rotation = 0.0


func _sync_pivot() -> void:
	pivot_offset = size * 0.5
