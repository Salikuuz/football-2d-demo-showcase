extends Control


const ABILITY_ICON_PATHS: Array[String] = [
	"res://Characters/ability_none.svg",
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

const ABILITY_DIFFICULTIES: Dictionary = {
	1: 2,
	2: 3,
	3: 1,
	4: 2,
	5: 2,
	6: 1,
	7: 1,
	8: 2,
	9: 3,
	10: 3,
	11: 3,
	12: 3,
	13: 2,
	14: 2,
	15: 2,
	16: 2,
	17: 2,
	18: 2,
	19: 2,
	20: 3,
	21: 2,
	FootballPlayer.ABILITY_NUTMEG: 2,
	FootballPlayer.ABILITY_DECOY_RUN: 1
}

@export var match_manager: FootballMatchManager
@export var network_manager: NetworkManager

@onready var controller_support := get_node(
	"/root/ControllerSupport"
) as FootballControllerSupport

@onready var panel: PanelContainer = $Panel
@onready var toggle_abilities_button: Button = (
	$Panel/VBox/TrainingActions/ToggleAbilitiesButton
)
@onready var hint_label: Label = $Panel/VBox/Hint
@onready var ability_scroll: ScrollContainer = (
	$Panel/VBox/AbilityScroll
)
@onready var ability_columns: HBoxContainer = (
	$Panel/VBox/AbilityScroll/AbilityColumns
)
@onready var training_actions: GridContainer = (
	$Panel/VBox/TrainingActions
)
@onready var send_ball_button: Button = (
	$Panel/VBox/TrainingActions/SendBallButton
)
@onready var reset_player_button: Button = (
	$Panel/VBox/TrainingActions/ResetPlayerButton
)
@onready var exit_button: Button = (
	$Panel/VBox/TrainingActions/ExitButton
)

var ability_buttons: Dictionary = {}
var _selected_ability_id: int = FootballPlayer.ABILITY_NONE
var _ability_preview: FootballAbilityPreviewCard


func _ready() -> void:
	if match_manager == null or network_manager == null:
		push_error("Freeplay HUD references are incomplete.")
		return

	_remove_legacy_reset_ball_button()

	hide()
	_build_ability_selection()
	_configure_ability_focus_navigation()
	_build_ability_previews()
	toggle_abilities_button.pressed.connect(
		func() -> void:
			_set_ability_panel_open(not ability_scroll.visible)
	)
	send_ball_button.pressed.connect(
		match_manager.send_freeplay_ball_at_player
	)
	reset_player_button.pressed.connect(
		match_manager.reset_freeplay_player
	)
	exit_button.pressed.connect(network_manager.disconnect_game)

	match_manager.freeplay_started.connect(_on_freeplay_started)
	match_manager.freeplay_ended.connect(_on_freeplay_ended)
	match_manager.freeplay_ability_changed.connect(
		_on_freeplay_ability_changed
	)

	for button in [
		toggle_abilities_button,
		send_ball_button,
		reset_player_button,
		exit_button
	]:
		button.focus_mode = Control.FOCUS_ALL
	MenuStyler.apply_premium_design(self, &"freeplay")
	for ability_value in ability_buttons:
		var ability_id := int(ability_value)
		MenuStyler.style_ability_role_button(
			ability_buttons[ability_id] as Button,
			_get_ability_role_color(ability_id)
		)
	MenuStyler.install_click_sounds(self)
	UIMotion.prepare_buttons(self)
	_apply_responsive_layout()
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_set_ability_panel_open(false)


func _apply_responsive_layout() -> void:
	if not is_inside_tree():
		return
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var compact: bool = viewport_size.y < 800.0 or viewport_size.x < 1280.0
	_layout_panel(ability_scroll.visible, viewport_size)
	for action_value in training_actions.get_children():
		var action_button := action_value as Button
		if action_button != null:
			action_button.custom_minimum_size.y = 36.0
			action_button.add_theme_font_size_override(
				"font_size",
				14 if compact else 16
			)
	ability_scroll.custom_minimum_size = Vector2(
		minf(980.0, maxf(420.0, viewport_size.x - 72.0)),
		minf(480.0, maxf(260.0, viewport_size.y - 190.0))
	)
	for column_value in ability_columns.get_children():
		var column := column_value as VBoxContainer
		if column != null:
			column.custom_minimum_size.x = 166.0 if compact else 205.0
	for button_value in ability_buttons.values():
		var button := button_value as Button
		if button != null:
			button.custom_minimum_size.y = 38.0 if compact else 44.0
			button.add_theme_font_size_override("font_size", 12 if compact else 14)


func _remove_legacy_reset_ball_button() -> void:
	var button := get_node_or_null(
		"Panel/VBox/TrainingActions/ResetBallButton"
	) as Button
	if button == null:
		return
	var parent: Node = button.get_parent()
	if parent != null:
		parent.remove_child(button)
	button.queue_free()


func _build_ability_selection() -> void:
	_create_ability_column(
		"ATTACK",
		Color(1.0, 0.36, 0.30),
		[1, 9, 3, 4, 15, 19, 20, FootballPlayer.ABILITY_NUTMEG]
	)
	_create_ability_column(
		"PLAYMAKER",
		Color(0.77, 0.43, 1.0),
		[2, 10, 5, 8, 11, 16, 18, 21]
	)
	var mixed_column := _create_ability_column(
		"FLEXIBLE",
		Color(0.60, 0.94, 0.34),
		[0, 12, FootballPlayer.ABILITY_DECOY_RUN]
	)
	_add_column_header(
		mixed_column,
		"DEFENSE",
		Color(0.24, 0.88, 0.66)
	)
	_add_ability_buttons(mixed_column, [6, 7, 13, 14, 17])


func _build_ability_previews() -> void:
	_ability_preview = FootballAbilityPreviewCard.new()
	_ability_preview.name = "AbilityPreview"
	add_child(_ability_preview)
	for ability_value in ability_buttons:
		var ability_id := int(ability_value)
		_ability_preview.register_button(
			ability_buttons[ability_id] as Button,
			ability_id
		)


func _create_ability_column(
	title: String,
	color: Color,
	ability_ids: Array
) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(205.0, 0.0)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 6)
	ability_columns.add_child(column)
	_add_column_header(column, title, color)
	_add_ability_buttons(column, ability_ids)
	return column


func _add_column_header(
	column: VBoxContainer,
	title: String,
	color: Color
) -> void:
	var header := Label.new()
	header.text = title
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_color_override("font_color", color)
	header.add_theme_font_size_override("font_size", 16)
	column.add_child(header)


func _add_ability_buttons(
	column: VBoxContainer,
	ability_ids: Array
) -> void:
	for ability_value in ability_ids:
		var ability_id := int(ability_value)
		var button := Button.new()
		button.custom_minimum_size = Vector2(200.0, 44.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_ALL
		button.expand_icon = true
		button.add_theme_font_size_override("font_size", 14)
		button.text = FootballPlayer.get_ability_name(ability_id)
		if ability_id != FootballPlayer.ABILITY_NONE:
			button.text += "  %s" % _get_difficulty_stars(
				ability_id
			)
		button.tooltip_text = FootballPlayer.get_ability_description(
			ability_id
		)
		button.tooltip_text = _wrap_tooltip_text(
			button.tooltip_text
		)
		if ability_id < ABILITY_ICON_PATHS.size():
			var icon_path := ABILITY_ICON_PATHS[ability_id]
			if ResourceLoader.exists(icon_path):
				button.icon = load(icon_path) as Texture2D
		button.pressed.connect(
			_on_ability_pressed.bind(ability_id)
		)
		column.add_child(button)
		ability_buttons[ability_id] = button
		_apply_button_color(button, ability_id, false)


func _configure_ability_focus_navigation() -> void:
	# Freeplay uses the same three-column visual layout as the normal ability
	# selector. Explicit focus neighbors keep D-pad Up/Down inside the current
	# visual column instead of letting Godot jump diagonally to a nearby button.
	var columns: Array = [
		[
			FootballPlayer.ABILITY_BURST_DRIBBLE,
			FootballPlayer.ABILITY_DIRECT_FINISH,
			FootballPlayer.ABILITY_POWER_STRIKE,
			FootballPlayer.ABILITY_OVERDRIVE,
			FootballPlayer.ABILITY_BLIND_SPOT,
			FootballPlayer.ABILITY_BREAKAWAY,
			FootballPlayer.ABILITY_SNAPBACK,
			FootballPlayer.ABILITY_NUTMEG,
		],
		[
			FootballPlayer.ABILITY_QUICK_TRIGGER,
			FootballPlayer.ABILITY_ELASTIC_STEP,
			FootballPlayer.ABILITY_HEEL_TURN,
			FootballPlayer.ABILITY_TIME_SKIP_PASS,
			FootballPlayer.ABILITY_META_VISION,
			FootballPlayer.ABILITY_BOOGIE_WOOGIE,
			FootballPlayer.ABILITY_RETURN_TAG,
			FootballPlayer.ABILITY_SIDE_SWIPE,
		],
		[
			FootballPlayer.ABILITY_NONE,
			FootballPlayer.ABILITY_COPYCAT,
			FootballPlayer.ABILITY_DECOY_RUN,
			FootballPlayer.ABILITY_ENFORCER,
			FootballPlayer.ABILITY_GOALKEEPER_REACH,
			FootballPlayer.ABILITY_REFLEX_BLOCK,
			FootballPlayer.ABILITY_IRON_ANCHOR,
			FootballPlayer.ABILITY_ECHO,
		],
	]

	for column_index in range(columns.size()):
		var column_ids: Array = columns[column_index]
		for row_index in range(column_ids.size()):
			var ability_id := int(column_ids[row_index])
			var button := ability_buttons.get(ability_id) as Button
			if button == null:
				continue
			var up_button := ability_buttons.get(
				int(column_ids[(row_index - 1 + column_ids.size()) % column_ids.size()])
			) as Button
			var down_button := ability_buttons.get(
				int(column_ids[(row_index + 1) % column_ids.size()])
			) as Button
			_set_freeplay_focus_neighbor(button, SIDE_TOP, up_button)
			_set_freeplay_focus_neighbor(button, SIDE_BOTTOM, down_button)

			if column_index > 0:
				var left_ids: Array = columns[column_index - 1]
				var left_row := _map_freeplay_focus_row(
					row_index, column_ids.size(), left_ids.size()
				)
				_set_freeplay_focus_neighbor(
					button,
					SIDE_LEFT,
					ability_buttons.get(int(left_ids[left_row])) as Button
				)
			if column_index < columns.size() - 1:
				var right_ids: Array = columns[column_index + 1]
				var right_row := _map_freeplay_focus_row(
					row_index, column_ids.size(), right_ids.size()
				)
				_set_freeplay_focus_neighbor(
					button,
					SIDE_RIGHT,
					ability_buttons.get(int(right_ids[right_row])) as Button
				)


func _map_freeplay_focus_row(
	row_index: int,
	source_count: int,
	target_count: int
) -> int:
	if target_count <= 1 or source_count <= 1:
		return 0
	var normalized := float(row_index) / float(source_count - 1)
	return clampi(
		int(round(normalized * float(target_count - 1))),
		0,
		target_count - 1
	)


func _set_freeplay_focus_neighbor(
	source: Control,
	side: int,
	target: Control
) -> void:
	if source == null or target == null:
		return
	var path := source.get_path_to(target)
	match side:
		SIDE_LEFT:
			source.focus_neighbor_left = path
		SIDE_TOP:
			source.focus_neighbor_top = path
		SIDE_RIGHT:
			source.focus_neighbor_right = path
		SIDE_BOTTOM:
			source.focus_neighbor_bottom = path


func _on_ability_pressed(ability_id: int) -> void:
	match_manager.set_freeplay_ability(ability_id)
	_set_ability_panel_open(false)


func _on_freeplay_started() -> void:
	_set_ability_panel_open(false)
	UIMotion.show_control(self, 0.22)


func _on_freeplay_ended() -> void:
	UIMotion.hide_control(self)


func _on_freeplay_ability_changed(ability_id: int) -> void:
	_selected_ability_id = ability_id
	hint_label.text = (
		"Copycat repeats your previously selected ability  •  F4 resets ball"
		if ability_id == FootballPlayer.ABILITY_COPYCAT
		else (
			"%s equipped  •  No ability cooldowns  •  F4 resets ball"
			% FootballPlayer.get_ability_name(ability_id)
		)
	)
	for stored_id in ability_buttons:
		var button := ability_buttons[stored_id] as Button
		if button != null:
			_apply_button_color(
				button,
				int(stored_id),
				int(stored_id) == ability_id
			)


func _apply_button_color(
	button: Button,
	ability_id: int,
	selected: bool
) -> void:
	var color := (
		Color(1.0, 0.86, 0.28)
		if selected
		else _get_ability_role_color(ability_id)
	)
	button.add_theme_color_override("font_color", color)
	button.add_theme_color_override(
		"font_hover_color",
		color.lightened(0.16)
	)
	button.add_theme_color_override(
		"font_pressed_color",
		Color(1.0, 0.94, 0.62)
	)


func _get_ability_role_color(ability_id: int) -> Color:
	match FootballPlayer.get_ability_role(ability_id):
		FootballPlayer.ABILITY_ROLE_ATTACK:
			return Color(1.0, 0.36, 0.30)
		FootballPlayer.ABILITY_ROLE_PLAYMAKER:
			return Color(0.77, 0.43, 1.0)
		FootballPlayer.ABILITY_ROLE_FLEXIBLE:
			return Color(0.60, 0.94, 0.34)
		FootballPlayer.ABILITY_ROLE_DEFENSE:
			return Color(0.24, 0.88, 0.66)
	return Color.WHITE


func _get_difficulty_stars(ability_id: int) -> String:
	var difficulty := clampi(
		int(ABILITY_DIFFICULTIES.get(ability_id, 1)),
		1,
		3
	)
	return "★".repeat(difficulty) + "☆".repeat(3 - difficulty)


func _wrap_tooltip_text(
	source_text: String,
	maximum_characters: int = 52
) -> String:
	var wrapped_lines: Array[String] = []
	var safe_limit := maxi(24, maximum_characters)
	for paragraph in source_text.split("\n"):
		var current_line := ""
		for word_value in paragraph.split(" ", false):
			var word := str(word_value)
			var candidate := (
				word
				if current_line.is_empty()
				else current_line + " " + word
			)
			if (
				not current_line.is_empty()
				and candidate.length() > safe_limit
			):
				wrapped_lines.append(current_line)
				current_line = word
			else:
				current_line = candidate
		wrapped_lines.append(current_line)
	return "\n".join(wrapped_lines)


func _set_ability_panel_open(open: bool) -> void:
	if _ability_preview != null:
		_ability_preview.hide_preview()
	hint_label.visible = open
	ability_scroll.visible = open
	toggle_abilities_button.text = (
		"Close Abilities" if open else "Choose Ability"
	)
	_layout_panel(open, get_viewport_rect().size)
	if controller_support.using_controller:
		if open and not ability_buttons.is_empty():
			var target := ability_buttons.get(
				_selected_ability_id
			) as Button
			if target == null:
				target = ability_buttons.values()[0] as Button
			if target != null:
				target.grab_focus.call_deferred()
		else:
			var focus_owner := get_viewport().gui_get_focus_owner()
			if focus_owner != null and is_ancestor_of(focus_owner):
				focus_owner.release_focus()


func _layout_panel(open: bool, viewport_size: Vector2) -> void:
	var horizontal_margin := 24.0 if viewport_size.x >= 720.0 else 12.0
	var maximum_width := 1040.0 if open else 1120.0
	var minimum_width := 560.0 if open else 520.0
	var available_width := maxf(
		minimum_width,
		viewport_size.x - horizontal_margin * 2.0
	)
	var width := minf(maximum_width, available_width)
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.offset_left = -width * 0.5
	panel.offset_right = width * 0.5
	panel.offset_top = 12.0
	panel.offset_bottom = (
		minf(760.0, viewport_size.y - 12.0)
		if open
		else 110.0
	)


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not controller_support.using_controller:
		return
	if event.is_action_pressed(&"ui_cancel"):
		if ability_scroll.visible:
			_set_ability_panel_open(false)
		else:
			var focus_owner := get_viewport().gui_get_focus_owner()
			if focus_owner != null and is_ancestor_of(focus_owner):
				focus_owner.release_focus()
		get_viewport().set_input_as_handled()
		return
	var button_event := event as InputEventJoypadButton
	if (
		button_event == null
		or not button_event.pressed
		or not controller_support.is_controller_event_assigned(button_event)
	):
		return
	if button_event.button_index not in [
		JOY_BUTTON_DPAD_UP,
		JOY_BUTTON_DPAD_DOWN,
		JOY_BUTTON_DPAD_LEFT,
		JOY_BUTTON_DPAD_RIGHT
	]:
		return
	var focus_owner := get_viewport().gui_get_focus_owner()
	if focus_owner == null or not is_ancestor_of(focus_owner):
		toggle_abilities_button.grab_focus()
		get_viewport().set_input_as_handled()
