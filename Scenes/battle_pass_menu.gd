class_name FootballBattlePassMenu
extends Control


signal closed

const DROP_PAGE_SIZE: int = 12
const LOOTBOX_GOLD: Color = Color("f4c95d")
const PANEL_COSMIC: Color = Color(0.08, 0.05, 0.20, 0.44)
const LootboxVisual = preload("res://Scenes/lootbox_visual.gd")
const LOOTBOX_CHARGE_SOUND: AudioStream = preload(
	"res://Audio/sfx_ability_activate.wav"
)
const LOOTBOX_UNLOCK_SOUND: AudioStream = preload(
	"res://Characters/universfield-game-bonus-144751.mp3"
)
const LOOTBOX_REVEAL_SOUND: AudioStream = preload(
	"res://Audio/sfx_countdown_go.wav"
)

var battle_pass: FootballBattlePass
var _window: PanelContainer
var _level_label: Label
var _xp_label: Label
var _lootbox_count_label: Label
var _progress: ProgressBar
var _open_button: Button
var _lootbox_visual: Control
var _result_preview: FootballCosmeticPreview
var _result_title: Label
var _result_meta: Label
var _pool_grid: GridContainer
var _pool_page_label: Label
var _previous_page_button: Button
var _next_page_button: Button
var _close_button: Button
var _close_canvas_layer: CanvasLayer
var _pool_page: int = 1
var _opening: bool = false
var _charge_audio: AudioStreamPlayer
var _unlock_audio: AudioStreamPlayer
var _reveal_audio: AudioStreamPlayer


func _ready() -> void:
	battle_pass = get_node_or_null("/root/BattlePass") as FootballBattlePass
	if battle_pass == null:
		push_error("Lootbox menu requires the BattlePass progression autoload.")
		return
	_build_ui()
	_build_lootbox_audio()
	battle_pass.progress_changed.connect(_on_progress_changed)
	battle_pass.lootbox_opened.connect(_on_lootbox_opened)
	get_viewport().size_changed.connect(_apply_responsive_layout)
	MenuStyler.apply_premium_design(self, &"menu")
	MenuStyler.install_click_sounds(self)
	_apply_lootbox_styles()
	_apply_responsive_layout()
	_position_close_button.call_deferred()
	_wire_controller_focus.call_deferred()
	if _close_canvas_layer != null:
		_close_canvas_layer.visible = false
	hide()


func open_menu() -> void:
	# The connection menu applies its shared theme after child _ready calls.
	# Restore the Lootbox-specific translucent cosmic surfaces when opening so
	# the parent theme cannot make this screen opaque again.
	_apply_lootbox_styles()
	_refresh()
	_show_idle_lootbox()
	show()
	if _close_canvas_layer != null:
		_close_canvas_layer.visible = true
	_position_close_button.call_deferred()
	_grab_initial_focus.call_deferred()


func close_menu() -> void:
	if _opening:
		return
	if _close_canvas_layer != null:
		_close_canvas_layer.visible = false
	hide()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"ui_cancel") and not _opening:
		get_viewport().set_input_as_handled()
		close_menu()
		return
	var joy_button := event as InputEventJoypadButton
	if joy_button == null or not joy_button.pressed or _opening:
		return
	if joy_button.button_index == JOY_BUTTON_LEFT_SHOULDER:
		get_viewport().set_input_as_handled()
		_change_pool_page(-1)
	elif joy_button.button_index == JOY_BUTTON_RIGHT_SHOULDER:
		get_viewport().set_input_as_handled()
		_change_pool_page(1)


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var background := FootballBattlePassBackground.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 18.0
	center.offset_top = 18.0
	center.offset_right = -18.0
	center.offset_bottom = -18.0
	add_child(center)
	_window = PanelContainer.new()
	_window.name = "BattlePassWindow"
	center.add_child(_window)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	_window.add_child(margin)
	var root_column := VBoxContainer.new()
	root_column.add_theme_constant_override("separation", 12)
	margin.add_child(root_column)
	_build_header(root_column)
	_build_progress(root_column)
	var body := HBoxContainer.new()
	body.name = "LootboxBody"
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	root_column.add_child(body)
	_build_lootbox_chamber(body)
	_build_drop_pool(body)


func _build_header(parent: VBoxContainer) -> void:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	parent.add_child(header)
	var emblem := Label.new()
	emblem.name = "LootboxEmblem"
	emblem.text = "LOOT"
	emblem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emblem.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	emblem.custom_minimum_size = Vector2(82.0, 56.0)
	emblem.add_theme_font_size_override("font_size", 18)
	header.add_child(emblem)
	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	var title := Label.new()
	title.text = "FIRST TOUCH LOOTBOX"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color.WHITE)
	heading.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "LEVEL UP TO EARN LOOTBOXES - EVERY BOX GRANTS ONE NEW COSMETIC"
	subtitle.add_theme_color_override("font_color", Color("c6d4ef"))
	heading.add_child(subtitle)
	# Reserve the header slot, but keep the real BACK button on its own
	# CanvasLayer. This is the same proven approach used by the map selector's
	# CLOSE button: the visual rectangle and GUI hit rectangle stay 1:1 and no
	# lobby/scroll/container Control can steal part of the click area.
	var close_spacer := Control.new()
	close_spacer.custom_minimum_size = Vector2(112.0, 46.0)
	close_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(close_spacer)

	_close_canvas_layer = CanvasLayer.new()
	_close_canvas_layer.name = "LootboxBackCanvasLayer"
	_close_canvas_layer.layer = 1200
	add_child(_close_canvas_layer)

	_close_button = Button.new()
	_close_button.name = "CloseButton"
	_close_button.text = "BACK"
	_close_button.custom_minimum_size = Vector2(112.0, 46.0)
	_close_button.size = Vector2(112.0, 46.0)
	_close_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_close_button.focus_mode = Control.FOCUS_ALL
	_close_button.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	_close_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_close_button.set_meta("_motion_ready", true)
	_close_button.set_meta("_menu_style_ready", true)
	_close_button.pressed.connect(close_menu)
	_close_canvas_layer.add_child(_close_button)
	_window.resized.connect(_position_close_button)
	get_viewport().size_changed.connect(_position_close_button)


func _position_close_button() -> void:
	if (
		_close_button == null
		or _window == null
		or not is_instance_valid(_close_button)
		or not is_instance_valid(_window)
	):
		return
	var window_rect: Rect2 = _window.get_global_rect()
	_close_button.position = Vector2(
		window_rect.end.x - 24.0 - 112.0,
		window_rect.position.y + 18.0
	)
	_close_button.size = Vector2(112.0, 46.0)


func _build_progress(parent: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	_level_label = Label.new()
	_level_label.custom_minimum_size.x = 175.0
	_level_label.add_theme_font_size_override("font_size", 18)
	row.add_child(_level_label)
	_progress = ProgressBar.new()
	_progress.name = "LootboxProgress"
	_progress.show_percentage = false
	_progress.custom_minimum_size.y = 18.0
	_progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_progress)
	_xp_label = Label.new()
	_xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_xp_label.custom_minimum_size.x = 125.0
	row.add_child(_xp_label)
	_lootbox_count_label = Label.new()
	_lootbox_count_label.name = "AvailableLootboxes"
	_lootbox_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_lootbox_count_label.custom_minimum_size.x = 190.0
	_lootbox_count_label.add_theme_color_override("font_color", LOOTBOX_GOLD)
	_lootbox_count_label.add_theme_font_size_override("font_size", 17)
	row.add_child(_lootbox_count_label)


func _build_lootbox_chamber(parent: HBoxContainer) -> void:
	var chamber := PanelContainer.new()
	chamber.name = "LootboxChamber"
	chamber.custom_minimum_size.x = 420.0
	chamber.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(chamber)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	chamber.add_child(margin)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)
	var kicker := Label.new()
	kicker.text = "COSMIC LOOTBOX"
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kicker.add_theme_font_size_override("font_size", 17)
	kicker.add_theme_color_override("font_color", LOOTBOX_GOLD)
	column.add_child(kicker)
	var reveal_stage := CenterContainer.new()
	reveal_stage.name = "RevealStage"
	reveal_stage.custom_minimum_size = Vector2(340.0, 270.0)
	reveal_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(reveal_stage)
	_result_preview = FootballCosmeticPreview.new()
	_result_preview.name = "LootboxResultPreview"
	_result_preview.custom_minimum_size = Vector2(320.0, 250.0)
	_result_preview.set_preview_team(&"blue")
	_result_preview.hide()
	reveal_stage.add_child(_result_preview)
	_lootbox_visual = LootboxVisual.new() as Control
	_lootbox_visual.name = "LootboxVisual"
	_lootbox_visual.custom_minimum_size = Vector2(330.0, 250.0)
	reveal_stage.add_child(_lootbox_visual)
	_result_title = Label.new()
	_result_title.name = "LootboxResultTitle"
	_result_title.text = "EARN A LEVEL TO UNLOCK A LOOTBOX"
	_result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_result_title.add_theme_font_size_override("font_size", 21)
	column.add_child(_result_title)
	_result_meta = Label.new()
	_result_meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_meta.add_theme_color_override("font_color", Color("aebbd0"))
	column.add_child(_result_meta)
	_open_button = Button.new()
	_open_button.name = "OpenLootboxButton"
	_open_button.text = "OPEN LOOTBOX"
	_open_button.custom_minimum_size.y = 56.0
	_open_button.pressed.connect(_open_lootbox)
	column.add_child(_open_button)


func _build_drop_pool(parent: HBoxContainer) -> void:
	var pool_panel := PanelContainer.new()
	pool_panel.name = "DropPoolPanel"
	pool_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pool_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(pool_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	pool_panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)
	var heading := HBoxContainer.new()
	column.add_child(heading)
	var title := Label.new()
	title.text = "POSSIBLE DROPS"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 22)
	heading.add_child(title)
	_previous_page_button = Button.new()
	_previous_page_button.name = "PreviousDropPage"
	_previous_page_button.text = "<"
	_previous_page_button.tooltip_text = "Previous drops page (L1)"
	_previous_page_button.custom_minimum_size = Vector2(42.0, 36.0)
	_previous_page_button.pressed.connect(_change_pool_page.bind(-1))
	heading.add_child(_previous_page_button)
	_pool_page_label = Label.new()
	_pool_page_label.custom_minimum_size.x = 90.0
	_pool_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pool_page_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heading.add_child(_pool_page_label)
	_next_page_button = Button.new()
	_next_page_button.name = "NextDropPage"
	_next_page_button.text = ">"
	_next_page_button.tooltip_text = "Next drops page (R1)"
	_next_page_button.custom_minimum_size = Vector2(42.0, 36.0)
	_next_page_button.pressed.connect(_change_pool_page.bind(1))
	heading.add_child(_next_page_button)
	var pool_note := Label.new()
	pool_note.text = "PURE RNG - EVERY UNOWNED DROP HAS AN EQUAL CHANCE"
	pool_note.add_theme_color_override("font_color", Color("9eabc1"))
	column.add_child(pool_note)
	var scroll := ScrollContainer.new()
	scroll.name = "DropPoolScroll"
	scroll.clip_contents = true
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	_pool_grid = GridContainer.new()
	_pool_grid.name = "DropPoolGrid"
	_pool_grid.columns = 3
	_pool_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pool_grid.add_theme_constant_override("h_separation", 8)
	_pool_grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(_pool_grid)


func _refresh() -> void:
	if battle_pass == null:
		return
	var level: int = battle_pass.get_level()
	var max_level: int = battle_pass.get_max_level()
	_level_label.text = "LEVEL %d / %d" % [level, max_level]
	_progress.max_value = battle_pass.get_xp_for_next_level()
	_progress.value = battle_pass.get_xp_into_level()
	_xp_label.text = "%d / %d XP" % [
		battle_pass.get_xp_into_level(),
		battle_pass.get_xp_for_next_level(),
	]
	var available_lootboxes: int = battle_pass.get_available_lootboxes()
	_lootbox_count_label.text = "LOOTBOXES AVAILABLE: %d" % available_lootboxes
	_open_button.disabled = available_lootboxes <= 0 or _opening
	_open_button.text = (
		"OPEN LOOTBOX" if available_lootboxes > 0 else "NO LOOTBOXES AVAILABLE"
	)
	_rebuild_pool_page()


func _rebuild_pool_page() -> void:
	for child: Node in _pool_grid.get_children():
		_pool_grid.remove_child(child)
		child.queue_free()
	var drops: Array[Dictionary] = battle_pass.get_drop_pool()
	var page_count: int = maxi(1, ceili(float(drops.size()) / float(DROP_PAGE_SIZE)))
	_pool_page = clampi(_pool_page, 1, page_count)
	_pool_page_label.text = "%d / %d" % [_pool_page, page_count]
	var first_index: int = (_pool_page - 1) * DROP_PAGE_SIZE
	var last_index: int = mini(first_index + DROP_PAGE_SIZE, drops.size())
	for index: int in range(first_index, last_index):
		_create_drop_card(drops[index])
	_wire_controller_focus.call_deferred()


func _create_drop_card(drop: Dictionary) -> void:
	var card := Button.new()
	card.custom_minimum_size = Vector2(190.0, 132.0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.focus_mode = Control.FOCUS_ALL
	card.pressed.connect(_preview_drop.bind(drop))
	_pool_grid.add_child(card)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 7.0
	column.offset_top = 6.0
	column.offset_right = -7.0
	column.offset_bottom = -6.0
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(column)
	var preview := FootballCosmeticPreview.new()
	preview.custom_minimum_size.y = 78.0
	preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview.clip_contents = true
	preview.set_preview_team(&"blue")
	preview.set_cosmetic(str(drop.get("item_id", "")), drop)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(preview)
	var label := Label.new()
	label.text = str(drop.get("name", "Cosmetic"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.add_theme_color_override(
		"font_color", _rarity_color(str(drop.get("rarity", "common")))
	)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(label)
	if bool(drop.get("owned", false)):
		var owned := Label.new()
		owned.text = "OWNED"
		owned.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		owned.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		owned.offset_left = -72.0
		owned.offset_top = 5.0
		owned.offset_right = -6.0
		owned.offset_bottom = 27.0
		owned.add_theme_color_override("font_color", Color("75e6a2"))
		owned.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(owned)
	_apply_drop_card_style(card, str(drop.get("rarity", "common")), bool(drop.get("owned", false)))


func _preview_drop(drop: Dictionary) -> void:
	if _opening:
		return
	_show_idle_lootbox()
	_result_title.text = "POSSIBLE DROP: %s" % str(
		drop.get("name", "Cosmetic")
	).to_upper()
	_result_title.add_theme_color_override(
		"font_color", _rarity_color(str(drop.get("rarity", "common")))
	)
	_result_meta.text = "%s - %s" % [
		str(drop.get("rarity", "common")).to_upper(),
		_slot_display_name(StringName(drop.get("slot", &""))),
	]


func _open_lootbox() -> void:
	if _opening or battle_pass.get_available_lootboxes() <= 0:
		return
	_opening = true
	_open_button.disabled = true
	_open_button.text = "OPENING..."
	_result_title.text = "CHARGING LOOTBOX..."
	_result_meta.text = ""
	_lootbox_visual.show()
	_lootbox_visual.call("reset_box", true)
	_result_preview.hide()
	var reward: Dictionary = battle_pass.open_lootbox()
	if reward.is_empty():
		_opening = false
		_result_title.text = "COLLECTION COMPLETE"
		_refresh()
		return
	_play_lootbox_sound(_charge_audio, 0.82)
	var shake := create_tween()
	shake.set_loops(6)
	shake.tween_property(_lootbox_visual, "rotation", -0.022, 0.065)
	shake.tween_property(_lootbox_visual, "rotation", 0.022, 0.065)
	var charge_tween := create_tween()
	charge_tween.set_parallel(true)
	charge_tween.set_trans(Tween.TRANS_QUAD)
	charge_tween.set_ease(Tween.EASE_IN)
	charge_tween.tween_property(_lootbox_visual, "charge", 1.0, 0.78)
	charge_tween.tween_property(_lootbox_visual, "scale", Vector2(1.055, 1.055), 0.78)
	await charge_tween.finished
	shake.kill()
	_lootbox_visual.rotation = 0.0
	_result_title.text = "UNLOCKING..."
	_play_lootbox_sound(_unlock_audio, 0.94)
	var open_tween := create_tween()
	open_tween.set_parallel(true)
	open_tween.set_trans(Tween.TRANS_BACK)
	open_tween.set_ease(Tween.EASE_OUT)
	open_tween.tween_property(_lootbox_visual, "open_progress", 1.0, 0.62)
	open_tween.tween_property(_lootbox_visual, "scale", Vector2(1.12, 1.12), 0.62)
	await open_tween.finished
	await get_tree().create_timer(0.28).timeout
	_lootbox_visual.hide()
	_result_preview.set_cosmetic(str(reward.get("item_id", "")), reward)
	_result_preview.pivot_offset = _result_preview.size * 0.5
	_result_preview.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_result_preview.scale = Vector2(0.42, 0.42)
	_result_preview.show()
	var rarity: String = str(reward.get("rarity", "common"))
	_play_lootbox_sound(_reveal_audio, _reveal_pitch_for_rarity(rarity))
	var reveal := create_tween()
	reveal.set_parallel(true)
	reveal.set_trans(Tween.TRANS_BACK)
	reveal.set_ease(Tween.EASE_OUT)
	reveal.tween_property(_result_preview, "scale", Vector2.ONE, 0.72)
	reveal.tween_property(_result_preview, "modulate", Color.WHITE, 0.48)
	await reveal.finished
	_opening = false
	_result_title.text = str(reward.get("name", "NEW COSMETIC")).to_upper()
	_result_title.add_theme_color_override("font_color", _rarity_color(rarity))
	_result_meta.text = "%s DROP - ADDED TO LOCKER" % rarity.to_upper()
	_refresh()


func _build_lootbox_audio() -> void:
	_charge_audio = _create_lootbox_audio_player(
		"LootboxChargeAudio",
		LOOTBOX_CHARGE_SOUND,
		-9.0
	)
	_unlock_audio = _create_lootbox_audio_player(
		"LootboxUnlockAudio",
		LOOTBOX_UNLOCK_SOUND,
		-6.0
	)
	_reveal_audio = _create_lootbox_audio_player(
		"LootboxRevealAudio",
		LOOTBOX_REVEAL_SOUND,
		-5.0
	)


func _create_lootbox_audio_player(
	player_name: String,
	stream: AudioStream,
	volume_db: float
) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.stream = stream
	player.volume_db = volume_db
	add_child(player)
	return player


func _play_lootbox_sound(player: AudioStreamPlayer, pitch: float) -> void:
	if player == null or player.stream == null:
		return
	player.stop()
	player.pitch_scale = clampf(pitch, 0.5, 2.0)
	player.play()


func _reveal_pitch_for_rarity(rarity: String) -> float:
	match rarity:
		"legendary":
			return 1.22
		"epic":
			return 1.12
		"rare":
			return 1.05
	return 0.96


func _show_idle_lootbox() -> void:
	if battle_pass == null or _lootbox_visual == null:
		return
	var has_lootbox: bool = battle_pass.get_available_lootboxes() > 0
	_result_preview.hide()
	_lootbox_visual.call("reset_box", has_lootbox)
	_result_title.text = (
		"LOOTBOX READY"
		if has_lootbox
		else "EARN A LEVEL TO UNLOCK A LOOTBOX"
	)
	_result_title.add_theme_color_override("font_color", LOOTBOX_GOLD)
	_result_meta.text = "EVERY UNOWNED COSMETIC HAS AN EQUAL CHANCE"


func _change_pool_page(direction: int) -> void:
	var page_count: int = maxi(
		1,
		ceili(float(battle_pass.get_drop_pool().size()) / float(DROP_PAGE_SIZE))
	)
	_pool_page = clampi(_pool_page + direction, 1, page_count)
	_rebuild_pool_page()
	var first_card := _pool_grid.get_child(0) as Button if _pool_grid.get_child_count() > 0 else null
	if first_card != null:
		first_card.grab_focus()


func _wire_controller_focus() -> void:
	if (
		not is_inside_tree()
		or _close_button == null
		or _previous_page_button == null
		or _next_page_button == null
	):
		return
	var cards: Array[Control] = []
	for child: Node in _pool_grid.get_children():
		var card := child as Button
		if card != null:
			cards.append(card)
	var first_card: Control = cards[0] if not cards.is_empty() else _open_button
	_set_focus_neighbor(_close_button, SIDE_BOTTOM, _next_page_button)
	_set_focus_neighbor(_previous_page_button, SIDE_LEFT, _open_button)
	_set_focus_neighbor(_previous_page_button, SIDE_RIGHT, _next_page_button)
	_set_focus_neighbor(_previous_page_button, SIDE_BOTTOM, first_card)
	_set_focus_neighbor(_next_page_button, SIDE_LEFT, _previous_page_button)
	_set_focus_neighbor(_next_page_button, SIDE_RIGHT, _close_button)
	_set_focus_neighbor(_next_page_button, SIDE_BOTTOM, first_card)
	_set_focus_neighbor(_open_button, SIDE_RIGHT, first_card)
	_set_focus_neighbor(_open_button, SIDE_TOP, _close_button)
	var columns: int = maxi(1, _pool_grid.columns)
	for index: int in range(cards.size()):
		var card: Control = cards[index]
		var column: int = index % columns
		var up_index: int = index - columns
		var down_index: int = index + columns
		_set_focus_neighbor(
			card,
			SIDE_LEFT,
			_open_button if column == 0 else cards[index - 1]
		)
		_set_focus_neighbor(
			card,
			SIDE_RIGHT,
			_close_button
			if column == columns - 1 or index + 1 >= cards.size()
			else cards[index + 1]
		)
		_set_focus_neighbor(
			card,
			SIDE_TOP,
			cards[up_index] if up_index >= 0 else _previous_page_button
		)
		_set_focus_neighbor(
			card,
			SIDE_BOTTOM,
			cards[down_index] if down_index < cards.size() else _open_button
		)


func _grab_initial_focus() -> void:
	if _open_button != null and not _open_button.disabled:
		_open_button.grab_focus()
	elif _pool_grid != null and _pool_grid.get_child_count() > 0:
		var first_card := _pool_grid.get_child(0) as Button
		if first_card != null:
			first_card.grab_focus()
	elif _close_button != null:
		_close_button.grab_focus()


func _set_focus_neighbor(source: Control, side: int, target: Control) -> void:
	if source == null or target == null:
		return
	var path: NodePath = source.get_path_to(target)
	match side:
		SIDE_LEFT:
			source.focus_neighbor_left = path
		SIDE_TOP:
			source.focus_neighbor_top = path
		SIDE_RIGHT:
			source.focus_neighbor_right = path
		SIDE_BOTTOM:
			source.focus_neighbor_bottom = path


func _on_progress_changed(_level: int, _season_xp: int) -> void:
	if not _opening:
		_refresh()


func _on_lootbox_opened(_lootbox_number: int, _item_id: String) -> void:
	if not _opening:
		_refresh()


func _apply_lootbox_styles() -> void:
	var window_style := StyleBoxFlat.new()
	window_style.bg_color = PANEL_COSMIC
	window_style.border_color = Color(LOOTBOX_GOLD, 0.76)
	window_style.set_border_width_all(2)
	window_style.set_corner_radius_all(14)
	window_style.shadow_color = Color(0.0, 0.0, 0.0, 0.52)
	window_style.shadow_size = 14
	_window.add_theme_stylebox_override("panel", window_style)
	for panel_name: String in ["LootboxChamber", "DropPoolPanel"]:
		var panel := find_child(panel_name, true, false) as PanelContainer
		if panel == null:
			continue
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.09, 0.055, 0.22, 0.36)
		style.border_color = Color(LOOTBOX_GOLD, 0.42)
		style.set_border_width_all(1)
		style.set_corner_radius_all(10)
		panel.add_theme_stylebox_override("panel", style)
	var emblem := find_child("LootboxEmblem", true, false) as Label
	if emblem != null:
		var emblem_style := StyleBoxFlat.new()
		emblem_style.bg_color = LOOTBOX_GOLD
		emblem_style.border_color = Color("fff0ae")
		emblem_style.set_border_width_all(2)
		emblem_style.set_corner_radius_all(8)
		emblem.add_theme_stylebox_override("normal", emblem_style)
		emblem.add_theme_color_override("font_color", Color("171b2d"))
	MenuStyler.style_button(_open_button, LOOTBOX_GOLD, 56.0)


func _apply_drop_card_style(card: Button, rarity: String, owned: bool) -> void:
	var accent: Color = _rarity_color(rarity)
	for state: StringName in [&"normal", &"hover", &"focus", &"pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.06, 0.045, 0.15, 0.56)
		style.border_color = accent.lightened(0.18) if state in [&"hover", &"focus"] else Color(accent, 0.65)
		style.set_border_width_all(2 if state in [&"hover", &"focus"] else 1)
		style.set_corner_radius_all(8)
		card.add_theme_stylebox_override(state, style)
	card.modulate = Color(0.78, 0.82, 0.86) if owned else Color.WHITE


func _apply_responsive_layout() -> void:
	if _window == null:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	_window.custom_minimum_size = Vector2(
		minf(1480.0, viewport_size.x - 36.0),
		minf(840.0, viewport_size.y - 36.0)
	)
	var chamber := find_child("LootboxChamber", true, false) as PanelContainer
	if chamber != null:
		chamber.custom_minimum_size.x = 330.0 if viewport_size.x < 1400.0 else 420.0
	if _result_preview != null:
		_result_preview.custom_minimum_size.y = 170.0 if viewport_size.y < 800.0 else 250.0
	if _pool_grid != null:
		_pool_grid.columns = 2 if viewport_size.x < 1250.0 else 3
	_position_close_button.call_deferred()
	_wire_controller_focus.call_deferred()


func _slot_display_name(slot: StringName) -> String:
	match slot:
		FootballCosmeticInventory.SLOT_PLAYER_SKIN:
			return "PLAYER FINISH"
		FootballCosmeticInventory.SLOT_FRAME_PALETTE:
			return "FRAME PALETTE"
		FootballCosmeticInventory.SLOT_PLAYER_MATERIAL:
			return "PLAYER MATERIAL"
		FootballCosmeticInventory.SLOT_TEAM_COLOR:
			return "TEAM COLOR"
		FootballCosmeticInventory.SLOT_GOAL_EXPLOSION:
			return "GOAL EXPLOSION"
		FootballCosmeticInventory.SLOT_PLAYER_BANNER:
			return "PLAYER BANNER"
		FootballCosmeticInventory.SLOT_QUICK_CHAT:
			return "QUICK CHAT"
	return "COSMETIC"


func _rarity_color(rarity: String) -> Color:
	match rarity:
		"legendary":
			return Color("f3b536")
		"epic":
			return Color("c885ff")
		"rare":
			return Color("66c6ff")
		"uncommon":
			return Color("75df8c")
	return Color("d5dde8")
