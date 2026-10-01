extends Control


const ABILITY_ICON_PATHS: Array[String] = [
	"",
	"res://Characters/ability_burst.svg",
	"res://Characters/ability_quick_trigger.svg",
	"res://Characters/ability_power_strike.svg",
	"res://Characters/ability_overdrive.svg",
	"res://Characters/ability_heel_turn.svg",
	"res://Characters/ability_enforcer.svg",
	"res://Characters/ability_goalkeeper_reach.svg",
	"res://Characters/ability_time_skip_pass.svg",
	"res://Characters/ability_direct_finish.svg",
	"res://Characters/ability_elastic_step.svg",
	"res://Characters/ability_meta_vision.svg",
	"res://Characters/ability_copycat.svg",
	"res://Characters/ability_reflex_block.svg",
	"res://Characters/ability_iron_anchor.svg",
	"res://Characters/ability_blind_spot.svg",
	"res://Characters/ability_boogie_woogie.svg",
	"res://Characters/ability_echo.svg",
	"res://Characters/ability_return_tag.svg",
	"res://Characters/ability_breakaway.png",
	"res://Characters/ability_snapback.svg",
	"res://Characters/ability_side_swipe.svg",
	"res://Characters/ability_nutmeg.svg",
	"res://Characters/ability_decoy_run.svg"
]

const PANEL_BACKGROUND: Color = Color(0.008, 0.021, 0.014, 0.95)
const PANEL_BORDER: Color = Color(0.94, 0.94, 0.96, 0.58)
const ICON_BACKGROUND: Color = Color(0.012, 0.03, 0.02, 0.98)
const COOLDOWN_BACKGROUND: Color = Color(0.055, 0.07, 0.058, 0.92)
const READY_COLOR: Color = Color(0.38, 1.0, 0.65, 1.0)
const COOLDOWN_COLOR: Color = Color(0.72, 0.82, 0.87, 1.0)
const ACTIVE_COLOR: Color = Color(1.0, 0.83, 0.32, 1.0)
## Kept deliberately compact so it remains peripheral information rather than
## covering the lower playfield.
const HUD_VISUAL_SCALE: Vector2 = Vector2.ONE
const CONTROLLER_PROMPT_COVERAGE_SHADER: Shader = preload(
	"res://Scenes/controller_prompt_coverage.gdshader"
)


@export var players_parent: Node2D
@export var match_manager: FootballMatchManager

@onready var controller_support := get_node(
	"/root/ControllerSupport"
) as FootballControllerSupport
@onready var panel: PanelContainer = $Panel
@onready var accent_bar: ColorRect = $Panel/HBox/AccentBar
@onready var icon_frame: PanelContainer = $Panel/HBox/IconFrame
@onready var icon: TextureRect = (
	$Panel/HBox/IconFrame/IconStack/Icon
)
@onready var cooldown_overlay: Control = (
	$Panel/HBox/IconFrame/IconStack/CooldownOverlay
)
@onready var active_border: Panel = (
	$Panel/HBox/IconFrame/IconStack/ActiveBorder
)
@onready var key_chip: PanelContainer = (
	$Panel/HBox/Info/HeaderRow/KeyChip
)
@onready var key_icon: TextureRect = (
	$Panel/HBox/Info/HeaderRow/KeyChip/KeyContent/KeyIcon
)
@onready var key_label: Label = (
	$Panel/HBox/Info/HeaderRow/KeyChip/KeyContent/KeyLabel
)
@onready var input_hints_panel: PanelContainer = $InputHints
@onready var team_input_hints_panel: PanelContainer = $TeamInputHints
@onready var state_label: Label = (
	$Panel/HBox/Info/HeaderRow/RoleLabel
)
@onready var detail_label: Label = (
	$Panel/HBox/Info/AbilityName
)
@onready var status_label: Label = (
	$Panel/HBox/Info/Status
)
@onready var cooldown_bar: ProgressBar = (
	$Panel/HBox/Info/CooldownBar
)

var _displayed_ability: int = -1
var _hud_should_show: bool = false
var _was_active: bool = false
var _previous_cooldown_fraction: float = 0.0
var _role_accent: Color = READY_COLOR
var _ready_flash_remaining: float = 0.0
var _ready_flash_total: float = 0.0
var _ready_tween: Tween
var _team_hint_stable_x: float = -1.0
var _charge_pips: HBoxContainer
var _ability_tile: Control
var _context_badge: PanelContainer
var _cooldown_edge: ColorRect
var _icon_stack: Control
var _was_cooling_down: bool = false
var _controller_prompt_coverage_material: ShaderMaterial
var _mobile_web_layout: bool = false


func _ready() -> void:
	hide()
	# Keep the scene/root position untouched so manual HUD positioning in the
	# editor is preserved. Only the visual panel is reduced by another 10%.
	panel.scale = HUD_VISUAL_SCALE
	call_deferred("_refresh_compact_panel_pivot")
	cooldown_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	active_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cooldown_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_base_visual_style()
	MenuStyler.apply_premium_design(self, &"hud")
	# The shared HUD skin supplies the surrounding polish; these local overrides
	# keep the ability readout light, peripheral, and separate from the pitch.
	_apply_base_visual_style()
	_configure_compact_layout()
	_merge_control_hint_panels()
	_configure_input_hints()
	_refresh_input_prompts()
	controller_support.input_method_changed.connect(_on_input_method_changed)
	controller_support.bindings_changed.connect(_on_bindings_changed)


func configure_for_mobile_web() -> void:
	if _mobile_web_layout:
		return
	_mobile_web_layout = true

	# Touch controls already label Shoot/Pass/Call/Ability, so the desktop
	# keyboard/controller hint strip only wastes pitch space on a phone. Keep the
	# actual ability icon, cooldown and charge information visible.
	if input_hints_panel != null:
		input_hints_panel.hide()
	if team_input_hints_panel != null:
		team_input_hints_panel.hide()
	if key_chip != null:
		key_chip.hide()

	# Move the compact ability tile above the floating left joystick instead of
	# letting the two controls overlap at the lower-left corner. This is only
	# applied by the mobile Web HUD; desktop placement stays byte-for-byte in the
	# normal path.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.anchor_left = 0.0
	panel.anchor_right = 0.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 34.0
	panel.offset_right = 112.0
	panel.offset_top = -292.0
	panel.offset_bottom = -206.0
	call_deferred("_refresh_compact_panel_pivot")



func _refresh_compact_panel_pivot() -> void:
	panel.pivot_offset = panel.size * 0.5
	panel.scale = HUD_VISUAL_SCALE


func _configure_compact_layout() -> void:
	# Build the compact ability tile fresh instead of reparenting nodes out of the
	# old HBox layout. Reparenting container-managed controls caused the icon,
	# border, pips and key badge to fight over their rects and overlap visually.
	var old_hbox := panel.get_node_or_null("HBox") as Control
	if old_hbox != null:
		old_hbox.hide()
	accent_bar.hide()
	state_label.hide()
	status_label.hide()
	cooldown_bar.hide()
	panel.custom_minimum_size = Vector2(78.0, 86.0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_ability_tile = panel.get_node_or_null("AbilityTile") as Control
	if _ability_tile != null:
		_ability_tile.queue_free()
	_ability_tile = Control.new()
	_ability_tile.name = "AbilityTile"
	_ability_tile.custom_minimum_size = Vector2(78.0, 86.0)
	_ability_tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(_ability_tile)

	icon_frame = PanelContainer.new()
	icon_frame.name = "AbilityIconFrame"
	icon_frame.position = Vector2(10.0, 1.0)
	icon_frame.size = Vector2(58.0, 58.0)
	icon_frame.custom_minimum_size = Vector2(58.0, 58.0)
	icon_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ability_tile.add_child(icon_frame)

	_icon_stack = Control.new()
	_icon_stack.name = "IconStack"
	_icon_stack.custom_minimum_size = Vector2(56.0, 56.0)
	_icon_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon_stack.clip_contents = true
	icon_frame.add_child(_icon_stack)

	icon = TextureRect.new()
	icon.name = "Icon"
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 7.0
	icon.offset_top = 7.0
	icon.offset_right = -7.0
	icon.offset_bottom = -7.0
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon_stack.add_child(icon)

	cooldown_overlay = Panel.new()
	cooldown_overlay.name = "CooldownOverlay"
	cooldown_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cooldown_overlay.z_index = 2
	_icon_stack.add_child(cooldown_overlay)

	# The cooldown is read directly on the icon. A thin accent edge follows the
	# top of the dark sweep so progress stays obvious without a second progress
	# bar underneath the ability.
	_cooldown_edge = ColorRect.new()
	_cooldown_edge.name = "CooldownEdge"
	_cooldown_edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cooldown_edge.z_index = 3
	_cooldown_edge.visible = false
	_icon_stack.add_child(_cooldown_edge)

	# A tiny bottom row of charge pips lives on the icon edge instead of floating
	# through the artwork.
	_charge_pips = HBoxContainer.new()
	_charge_pips.name = "ChargePips"
	_charge_pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_charge_pips.add_theme_constant_override("separation", 2)
	_charge_pips.position = Vector2(29.0, 54.0)
	_charge_pips.visible = false
	_ability_tile.add_child(_charge_pips)

	key_chip = PanelContainer.new()
	key_chip.name = "AbilityKeyChip"
	key_chip.position = Vector2(20.0, 61.0)
	key_chip.custom_minimum_size = Vector2(38.0, 18.0)
	key_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ability_tile.add_child(key_chip)

	var key_content := HBoxContainer.new()
	key_content.name = "KeyContent"
	key_content.alignment = BoxContainer.ALIGNMENT_CENTER
	key_content.add_theme_constant_override("separation", 2)
	key_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	key_chip.add_child(key_content)

	key_icon = TextureRect.new()
	key_icon.name = "KeyIcon"
	key_icon.custom_minimum_size = Vector2(13.0, 13.0)
	key_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	key_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	key_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	key_icon.hide()
	key_content.add_child(key_icon)

	key_label = Label.new()
	key_label.name = "KeyLabel"
	key_label.text = "SHIFT"
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	key_label.add_theme_font_size_override("font_size", 8)
	key_label.add_theme_color_override("font_color", Color(0.90, 0.94, 0.96, 1.0))
	key_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	key_content.add_child(key_label)

	# Only exceptional ability states get text, and the badge sits outside the
	# core tile so the default HUD remains just icon + keybind.
	_context_badge = PanelContainer.new()
	_context_badge.name = "ContextBadge"
	_context_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_context_badge.visible = false
	_context_badge.position = Vector2(72.0, 14.0)
	_ability_tile.add_child(_context_badge)

	detail_label = Label.new()
	detail_label.name = "ContextLabel"
	detail_label.custom_minimum_size = Vector2.ZERO
	detail_label.add_theme_font_size_override("font_size", 8)
	detail_label.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0, 1.0))
	detail_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	detail_label.add_theme_constant_override("outline_size", 1)
	detail_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_context_badge.add_child(detail_label)

	# The runtime-created controls need the same visual styling as the scene
	# controls they replace.
	_apply_base_visual_style()
	_apply_icon_frame_style(false, false)
	_update_context_badge_style()
	call_deferred("_fit_ability_key_chip")


func _ensure_compact_info_nodes(_info: VBoxContainer) -> void:
	# Kept as a no-op for compatibility with older scene revisions.
	pass


func _process(delta: float) -> void:
	if _ready_flash_remaining > 0.0:
		_ready_flash_remaining = maxf(0.0, _ready_flash_remaining - delta)
	var player := _get_local_player()
	var should_show_controls := (
		player != null
		and match_manager != null
		and match_manager.game_has_started
	)
	var should_show_ability := (
		should_show_controls
		and player.selected_ability > 0
	)
	panel.visible = should_show_ability
	input_hints_panel.visible = should_show_controls
	team_input_hints_panel.visible = false
	if should_show_controls != _hud_should_show:
		_hud_should_show = should_show_controls
		if should_show_controls:
			# This root fills the viewport while its child panels stay compact.
			# Keep the full-screen Control at unit scale so edge-anchored HUD pieces
			# remain stable through resize/fullscreen transitions.
			show()
			modulate.a = 1.0
			scale = Vector2.ONE
		else:
			hide()
	if not should_show_ability:
		return

	if _displayed_ability != player.selected_ability:
		_displayed_ability = player.selected_ability
		_update_ability_identity(player.selected_ability)
		UIMotion.pulse(icon_frame, Vector2(1.08, 1.08), 0.24)

	var cooldown_fraction := player.get_ability_cooldown_fraction()
	_update_cooldown_visuals(cooldown_fraction)
	cooldown_bar.value = clampf(1.0 - cooldown_fraction, 0.0, 1.0)

	active_border.visible = false
	var cooling_down := cooldown_fraction > 0.0
	if player.local_ability_active != _was_active or cooling_down != _was_cooling_down:
		_apply_icon_frame_style(player.local_ability_active, cooling_down)
	if player.local_ability_active and not _was_active:
		# Pulse the icon instead of the scaled panel. UIMotion.pulse() resets its
		# target to Vector2.ONE, which would otherwise undo the compact HUD scale.
		UIMotion.pulse(icon_frame, Vector2(1.07, 1.07), 0.24)
	if (
		_previous_cooldown_fraction > 0.0
		and cooldown_fraction <= 0.0
	):
		_play_cooldown_ready_feedback()

	_was_active = player.local_ability_active
	_was_cooling_down = cooling_down
	_previous_cooldown_fraction = cooldown_fraction
	_update_state_labels(player, cooldown_fraction)



func _fit_ability_key_chip() -> void:
	if key_chip == null or _ability_tile == null:
		return
	key_chip.reset_size()
	var width := clampf(key_chip.size.x, 28.0, 48.0)
	key_chip.size = Vector2(width, 18.0)
	key_chip.position = Vector2(39.0 - width * 0.5, 61.0)


func _merge_control_hint_panels() -> void:
	# One compact control strip is cleaner than two separate boxes around the HUD.
	# Communication actions live on the LEFT and ball actions on the RIGHT:
	# Quick Chat | Request Pass || Shoot | Pass.
	var main_grid := input_hints_panel.get_node_or_null("Grid") as GridContainer
	var team_grid := team_input_hints_panel.get_node_or_null("Grid") as GridContainer
	if main_grid == null or team_grid == null:
		return
	main_grid.columns = 5
	main_grid.add_theme_constant_override("h_separation", 9)
	main_grid.add_theme_constant_override("v_separation", 0)

	var quick_chat := team_grid.get_node_or_null("QuickChatHint") as Control
	var request_pass := team_grid.get_node_or_null("PassRequestHint") as Control
	var shoot := main_grid.get_node_or_null("ShootHint") as Control
	var pass_hint := main_grid.get_node_or_null("PassHint") as Control
	if quick_chat != null:
		quick_chat.reparent(main_grid)
	if request_pass != null:
		request_pass.reparent(main_grid)

	var group_spacer := main_grid.get_node_or_null("ActionGroupSpacer") as Control
	if group_spacer == null:
		group_spacer = Control.new()
		group_spacer.name = "ActionGroupSpacer"
		group_spacer.custom_minimum_size = Vector2(5.0, 1.0)
		group_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		main_grid.add_child(group_spacer)

	# GridContainer placement follows child order, so force the exact visual order
	# instead of relying on whatever order the rows had before reparenting.
	if quick_chat != null:
		main_grid.move_child(quick_chat, 0)
	if request_pass != null:
		main_grid.move_child(request_pass, 1)
	main_grid.move_child(group_spacer, 2)
	if shoot != null:
		main_grid.move_child(shoot, 3)
	if pass_hint != null:
		main_grid.move_child(pass_hint, 4)
	team_input_hints_panel.hide()



func _configure_input_hints() -> void:
	_configure_input_hint_panel(
		input_hints_panel,
		["ShootHint", "PassHint", "QuickChatHint", "PassRequestHint"]
	)


func _configure_input_hint_panel(
	hint_panel: PanelContainer,
	row_names: Array[String]
) -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.content_margin_left = 5.0
	panel_style.content_margin_top = 3.0
	panel_style.content_margin_right = 5.0
	panel_style.content_margin_bottom = 3.0
	panel_style.bg_color = Color(0.008, 0.021, 0.014, 0.72)
	panel_style.border_color = Color(0.88, 0.92, 0.95, 0.34)
	panel_style.set_border_width_all(1)
	panel_style.corner_radius_top_left = 7
	panel_style.corner_radius_top_right = 7
	panel_style.corner_radius_bottom_right = 7
	panel_style.corner_radius_bottom_left = 7
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.42)
	panel_style.shadow_size = 2
	hint_panel.add_theme_stylebox_override("panel", panel_style)
	hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for row_name in row_names:
		var row := hint_panel.get_node_or_null("Grid/%s" % row_name) as Control
		if row != null:
			row.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _refresh_input_prompts() -> void:
	_update_prompt_view(
		input_hints_panel.get_node_or_null("Grid/ShootHint") as Control,
		&"shoot"
	)
	_update_prompt_view(
		input_hints_panel.get_node_or_null("Grid/PassHint") as Control,
		&"soft_pass"
	)
	_update_prompt_view(
		input_hints_panel.get_node_or_null("Grid/QuickChatHint") as Control,
		&"quick_chat"
	)
	_update_prompt_view(
		input_hints_panel.get_node_or_null("Grid/PassRequestHint") as Control,
		&"request_pass"
	)
	_update_ability_prompt()
	if _mobile_web_layout:
		input_hints_panel.hide()
		team_input_hints_panel.hide()
		key_chip.hide()
	call_deferred("_fit_ability_key_chip")
	# Width is content-driven so normal keybinds do not reserve empty space,
	# while longer custom bindings can still expand the panel when needed.
	call_deferred("_fit_input_hint_panels")


func _fit_input_hint_panels() -> void:
	if input_hints_panel == null:
		return
	input_hints_panel.reset_size()

	var viewport_size := get_viewport_rect().size
	var edge_margin := 8.0
	var panel_shift_x := 7.0
	input_hints_panel.global_position = Vector2(
		viewport_size.x - input_hints_panel.size.x - edge_margin + panel_shift_x,
		viewport_size.y - input_hints_panel.size.y - edge_margin
	)
	team_input_hints_panel.hide()




func _prepare_controller_prompt_icon(prompt_icon: TextureRect) -> void:
	if prompt_icon == null:
		return
	if _controller_prompt_coverage_material == null:
		_controller_prompt_coverage_material = ShaderMaterial.new()
		_controller_prompt_coverage_material.shader = CONTROLLER_PROMPT_COVERAGE_SHADER
	# Mip levels are useful for moving world textures, but these HUD glyphs are
	# fixed-size vector prompts. Sampling the full source with linear filtering
	# keeps more of the original contour before the coverage shader runs.
	prompt_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	prompt_icon.material = _controller_prompt_coverage_material

func _update_prompt_view(row: Control, action: StringName) -> void:
	if row == null:
		return
	var prompt_icon := row.get_node_or_null("PromptIcon") as TextureRect
	var prompt_label := row.get_node_or_null("PromptLabel") as Label
	if prompt_icon == null or prompt_label == null:
		return
	_prepare_controller_prompt_icon(prompt_icon)
	var use_controller_icon := controller_support.using_controller
	var prompt_texture: Texture2D = null
	if use_controller_icon:
		prompt_texture = controller_support.get_controller_binding_icon(action)
	prompt_icon.texture = prompt_texture
	prompt_icon.visible = use_controller_icon and prompt_texture != null
	prompt_label.visible = not prompt_icon.visible
	prompt_label.text = controller_support.get_action_prompt(action)


func _update_ability_prompt() -> void:
	_prepare_controller_prompt_icon(key_icon)
	var use_controller_icon := controller_support.using_controller
	var prompt_texture: Texture2D = null
	if use_controller_icon:
		prompt_texture = controller_support.get_controller_binding_icon(&"ability")
	key_icon.texture = prompt_texture
	key_icon.visible = use_controller_icon and prompt_texture != null
	key_label.visible = not key_icon.visible
	key_label.text = controller_support.get_action_prompt(&"ability")


func _on_input_method_changed(
	_using_controller: bool,
	_family: StringName
) -> void:
	_refresh_input_prompts()


func _on_bindings_changed() -> void:
	_refresh_input_prompts()


func _play_cooldown_ready_feedback() -> void:
	_ready_flash_total = 0.42
	_ready_flash_remaining = _ready_flash_total
	UIMotion.pulse(icon_frame, Vector2(1.12, 1.12), 0.28)
	if _ready_tween != null:
		_ready_tween.kill()
	icon_frame.modulate = Color.WHITE
	_ready_tween = create_tween()
	_ready_tween.tween_property(
		icon_frame,
		"modulate",
		_role_accent.lightened(0.30),
		0.08
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_ready_tween.tween_property(
		icon_frame,
		"modulate",
		Color.WHITE,
		0.30
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _get_local_player() -> FootballPlayer:
	if players_parent == null:
		return null

	var local_peer_id := multiplayer.get_unique_id()
	var named_player := players_parent.get_node_or_null(
		str(local_peer_id)
	) as FootballPlayer
	if named_player != null:
		return named_player

	# Player nodes are normally named with their peer ID, but ownership is the
	# stable source of truth if a spawn/reload path changes the node name.
	for child in players_parent.get_children():
		var player := child as FootballPlayer
		if player != null and player.owner_peer_id == local_peer_id:
			return player
	return null


func _update_ability_identity(ability_id: int) -> void:
	_role_accent = _get_role_accent(
		FootballPlayer.get_ability_role(ability_id)
	)
	accent_bar.color = _role_accent
	_apply_role_visual_style()

	if (
		ability_id > 0
		and ability_id < ABILITY_ICON_PATHS.size()
	):
		icon.texture = load(ABILITY_ICON_PATHS[ability_id])
	else:
		icon.texture = null
	icon.material = null


func _apply_base_visual_style() -> void:
	# The outer panel is invisible; only the ability tile itself carries visual
	# weight. This keeps it closer to Overwatch-style icon-first ability HUDs.
	var panel_style := StyleBoxFlat.new()
	panel_style.content_margin_left = 0.0
	panel_style.content_margin_top = 0.0
	panel_style.content_margin_right = 0.0
	panel_style.content_margin_bottom = 0.0
	panel_style.bg_color = Color.TRANSPARENT
	panel_style.border_color = Color.TRANSPARENT
	panel_style.set_border_width_all(0)
	panel.add_theme_stylebox_override("panel", panel_style)

	var key_style := StyleBoxFlat.new()
	key_style.content_margin_left = 5.0
	key_style.content_margin_top = 1.0
	key_style.content_margin_right = 5.0
	key_style.content_margin_bottom = 1.0
	key_style.bg_color = Color(0.020, 0.028, 0.028, 0.96)
	key_style.border_color = Color(0.88, 0.92, 0.94, 0.78)
	key_style.set_border_width_all(1)
	key_style.set_corner_radius_all(5)
	key_chip.add_theme_stylebox_override("panel", key_style)

	cooldown_bar.min_value = 0.0
	cooldown_bar.max_value = 1.0
	cooldown_bar.value = 1.0


func _apply_role_visual_style() -> void:
	_apply_icon_frame_style(_was_active, _was_cooling_down)
	active_border.visible = false
	_update_context_badge_style()


func _update_cooldown_visuals(cooldown_fraction: float) -> void:
	var cooling_down := cooldown_fraction > 0.001
	cooldown_overlay.visible = cooling_down
	if _cooldown_edge != null:
		_cooldown_edge.visible = cooling_down
	if not cooling_down or _icon_stack == null:
		return

	# IconStack is already the content rectangle inside the thick outer frame.
	# Cover that entire inner square edge-to-edge; the old extra 3px inset left
	# a visible uncovered ring around the cooldown sweep.
	var inner_width := _icon_stack.size.x
	var inner_height := _icon_stack.size.y
	var fraction := clampf(cooldown_fraction, 0.0, 1.0)
	var fill_height := maxf(1.0, inner_height * fraction)
	var top_y := inner_height - fill_height
	cooldown_overlay.position = Vector2(0.0, top_y)
	cooldown_overlay.size = Vector2(inner_width, fill_height)

	var overlay_style := StyleBoxFlat.new()
	overlay_style.bg_color = Color(0.002, 0.006, 0.008, 0.80)
	overlay_style.border_color = Color.TRANSPARENT
	overlay_style.set_border_width_all(0)
	# The bottom follows the same rounded inner silhouette. Only a nearly-full
	# cooldown gets rounded top corners; otherwise the moving cutoff stays flat
	# and easy to read.
	var top_radius := 8 if fraction > 0.985 else 0
	overlay_style.corner_radius_top_left = top_radius
	overlay_style.corner_radius_top_right = top_radius
	overlay_style.corner_radius_bottom_left = 8
	overlay_style.corner_radius_bottom_right = 8
	(cooldown_overlay as Panel).add_theme_stylebox_override("panel", overlay_style)

	if _cooldown_edge != null:
		_cooldown_edge.color = Color(
			_role_accent.r,
			_role_accent.g,
			_role_accent.b,
			0.96
		)
		_cooldown_edge.position = Vector2(0.0, top_y)
		_cooldown_edge.size = Vector2(inner_width, 2.0)


func _apply_icon_frame_style(ability_active: bool, cooling_down: bool = false) -> void:
	var border_color := _role_accent
	if ability_active:
		border_color = ACTIVE_COLOR
	elif cooling_down:
		border_color = Color(0.58, 0.62, 0.64, 0.78)
	var icon_style := StyleBoxFlat.new()
	icon_style.bg_color = ICON_BACKGROUND
	icon_style.border_color = border_color
	icon_style.set_border_width_all(3)
	icon_style.set_corner_radius_all(10)
	icon_style.shadow_color = Color(
		border_color.r,
		border_color.g,
		border_color.b,
		0.34 if ability_active else 0.18
	)
	icon_style.shadow_size = 5 if ability_active else 3
	icon_frame.add_theme_stylebox_override("panel", icon_style)
	icon.modulate = Color.WHITE if not cooling_down or ability_active else Color(0.72, 0.76, 0.78, 1.0)


func _update_context_badge_style() -> void:
	if _context_badge == null:
		return
	var badge_style := StyleBoxFlat.new()
	badge_style.content_margin_left = 5.0
	badge_style.content_margin_top = 2.0
	badge_style.content_margin_right = 5.0
	badge_style.content_margin_bottom = 2.0
	badge_style.bg_color = Color(0.018, 0.026, 0.024, 0.93)
	badge_style.border_color = Color(_role_accent.r, _role_accent.g, _role_accent.b, 0.70)
	badge_style.set_border_width_all(1)
	badge_style.set_corner_radius_all(5)
	_context_badge.add_theme_stylebox_override("panel", badge_style)


func _update_state_labels(player: FootballPlayer, _cooldown_fraction: float) -> void:
	var charge_data := _get_charge_data(player)
	_update_charge_pips(int(charge_data.x), int(charge_data.y))
	var detail := _get_context_text(player)
	detail_label.text = detail
	if _context_badge != null:
		_context_badge.visible = not detail.is_empty()


func _get_charge_data(player: FootballPlayer) -> Vector2i:
	match player.selected_ability:
		FootballPlayer.ABILITY_BURST_DRIBBLE:
			return Vector2i(player.local_burst_charges, player.local_burst_max_charges)
		FootballPlayer.ABILITY_ELASTIC_STEP:
			return Vector2i(player.local_elastic_step_charges, player.local_elastic_step_max_charges)
		FootballPlayer.ABILITY_GOALKEEPER_REACH:
			return Vector2i(
				player.server_goalkeeper_reach_charges,
				player._get_effective_goalkeeper_reach_max_charges()
			)
		FootballPlayer.ABILITY_BLIND_SPOT:
			return Vector2i(
				player.server_mirage_step_charges,
				player._get_effective_mirage_step_max_charges()
			)
		FootballPlayer.ABILITY_BOOGIE_WOOGIE:
			return Vector2i(
				player.server_boogie_woogie_charges,
				player._get_effective_boogie_woogie_max_charges()
			)
	return Vector2i(0, 0)


func _update_charge_pips(charges: int, max_charges: int) -> void:
	if _charge_pips == null:
		return
	if max_charges <= 1:
		_charge_pips.hide()
		return
	while _charge_pips.get_child_count() < max_charges:
		var pip := PanelContainer.new()
		pip.custom_minimum_size = Vector2(7.0, 4.0)
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_charge_pips.add_child(pip)
	while _charge_pips.get_child_count() > max_charges:
		var stale := _charge_pips.get_child(_charge_pips.get_child_count() - 1)
		_charge_pips.remove_child(stale)
		stale.queue_free()
	for index in range(_charge_pips.get_child_count()):
		var pip := _charge_pips.get_child(index) as PanelContainer
		if pip == null:
			continue
		var pip_style := StyleBoxFlat.new()
		pip_style.bg_color = (
			ACTIVE_COLOR if index < charges and _was_active
			else _role_accent if index < charges
			else Color(0.22, 0.25, 0.26, 0.82)
		)
		pip_style.set_corner_radius_all(2)
		pip.add_theme_stylebox_override("panel", pip_style)
	var total_width := float(max_charges) * 7.0 + float(max_charges - 1) * 2.0
	_charge_pips.size = Vector2(total_width, 4.0)
	_charge_pips.position = Vector2(39.0 - total_width * 0.5, 54.0)
	_charge_pips.show()


func _get_context_text(player: FootballPlayer) -> String:
	match player.selected_ability:
		FootballPlayer.ABILITY_BREAKAWAY:
			if player.local_ability_active:
				return "BREAKAWAY PASS"
		FootballPlayer.ABILITY_SNAPBACK:
			if player.local_ability_active:
				return "RECALL READY"
		FootballPlayer.ABILITY_SIDE_SWIPE:
			if player.local_ability_active:
				return "SIDE SHOT READY"
		FootballPlayer.ABILITY_NUTMEG:
			if player.local_ability_active:
				return "NUTMEG READY"
		FootballPlayer.ABILITY_DECOY_RUN:
			if player.local_ability_active:
				return "DECOY ACTIVE"
		FootballPlayer.ABILITY_COPYCAT:
			if player.local_ability_active:
				return "COPY: %s" % FootballPlayer.get_ability_name(player.local_active_ability_id).to_upper()
			if player.local_ability_cooldown_remaining <= 0.0:
				var copied_id := player.local_copycat_stored_ability_id
				if copied_id == FootballPlayer.ABILITY_NONE and player.freeplay_cooldowns_disabled:
					copied_id = player.freeplay_copycat_source_ability
				if copied_id not in [FootballPlayer.ABILITY_NONE, FootballPlayer.ABILITY_COPYCAT, FootballPlayer.ABILITY_GOALKEEPER_REACH]:
					return "COPIED: %s" % FootballPlayer.get_ability_name(copied_id).to_upper()
				return "WAITING FOR COPY"
		FootballPlayer.ABILITY_DIRECT_FINISH:
			if player._local_direct_finish_tap_pending:
				return "TAP SHOOT: VOLLEY"
			if player.local_ability_active:
				return "VOLLEY ARMED" if player.local_direct_finish_volley_requested else "TRAP ARMED"
		FootballPlayer.ABILITY_ECHO:
			if player.local_ability_active:
				return "ECHO PLACED"
		FootballPlayer.ABILITY_REFLEX_BLOCK:
			if player.local_ability_active:
				return "BLOCK READY"
		FootballPlayer.ABILITY_META_VISION:
			if player.local_ability_active:
				return "FIELD READ"
		FootballPlayer.ABILITY_OVERDRIVE:
			if player.local_ability_active:
				return "SPEED SURGE"
		FootballPlayer.ABILITY_QUICK_TRIGGER:
			if player.local_ability_active:
				return "CURVE ARMED"
		FootballPlayer.ABILITY_POWER_STRIKE:
			if player.local_ability_active:
				return "POWER STRIKE"
		FootballPlayer.ABILITY_ENFORCER:
			if player.local_ability_active:
				return "PLAYER KICK"
		FootballPlayer.ABILITY_BOOGIE_WOOGIE:
			if player.local_ability_active:
				return "SWAP READY"
		FootballPlayer.ABILITY_IRON_ANCHOR:
			if player.local_ability_active:
				return "ANCHOR READY"
		FootballPlayer.ABILITY_HEEL_TURN:
			if player.local_ability_active:
				return "HEEL TURN"
	return ""


func _update_status_color(
	ability_active: bool,
	cooldown_fraction: float
) -> void:
	var status_color := READY_COLOR
	if ability_active:
		status_color = ACTIVE_COLOR
	elif cooldown_fraction > 0.0:
		status_color = COOLDOWN_COLOR
	state_label.add_theme_color_override("font_color", status_color)


func _get_role_accent(role: StringName) -> Color:
	match role:
		FootballPlayer.ABILITY_ROLE_ATTACK:
			return Color(1.0, 0.3, 0.38, 1.0)
		FootballPlayer.ABILITY_ROLE_PLAYMAKER:
			return Color(0.78, 0.56, 0.96, 1.0)
		FootballPlayer.ABILITY_ROLE_DEFENSE:
			return Color(0.3, 1.0, 0.62, 1.0)
		_:
			return Color(1.0, 0.78, 0.28, 1.0)
