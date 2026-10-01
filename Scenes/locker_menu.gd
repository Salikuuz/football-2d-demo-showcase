class_name FootballLockerMenu
extends Control


signal closed

const PREVIEW_SCRIPT: Script = preload("res://Scenes/cosmetic_preview.gd")
const QUICK_CHAT_WHEEL_SCRIPT: Script = preload(
	"res://Scenes/locker_quick_chat_wheel.gd"
)
const MIXED_SKIN_COLOR: int = -2
const LOCKER_GOLD: Color = Color("f4c95d")
const LOCKER_PANEL: Color = Color(0.075, 0.045, 0.18, 0.46)
const GOAL_THEME_ITEM_ICON: Texture2D = preload("res://Assets/goal_themes/goal_theme_icon.png")
const CATEGORY_DATA: Array[Dictionary] = [
	{"slot": &"player_skin", "label": "PLAYER"},
	{"slot": &"frame_palette", "label": "FRAME PALETTE"},
	{"slot": &"player_material", "label": "MATERIAL"},
	{"slot": &"team_color", "label": "TEAM COLORS"},
	{"slot": &"goal_explosion", "label": "GOAL FX"},
	{"slot": &"goal_theme", "label": "GOAL THEMES"},
	{"slot": &"player_banner", "label": "BANNERS"},
	{"slot": &"ability_particle", "label": "ABILITY FX"},
	{"slot": &"quick_chat", "label": "QUICK CHAT"},
]

var inventory: FootballCosmeticInventory
var current_slot: StringName = &"player_skin"
var selected_item_id: String = ""

var _window: PanelContainer
var _category_column: VBoxContainer
var _item_grid: GridContainer
var _item_scroll: ScrollContainer
var _preview: FootballCosmeticPreview
var _preview_name: Label
var _preview_status: Label
var _preview_payload: Label
var _collection_label: Label
var _quick_chat_wheel: FootballLockerQuickChatWheel
var _skin_target_row: HBoxContainer
var _skin_color_section: VBoxContainer
var _skin_color_selector: OptionButton
var _team_primary_color_section: VBoxContainer
var _team_primary_color_selector: OptionButton
var _goal_fx_color_section: VBoxContainer
var _goal_fx_color_selector: OptionButton
var _banner_color_section: VBoxContainer
var _banner_color_selector: OptionButton
var _field_ability_toggle: CheckButton
var _skin_target: StringName = &"both"
var _skin_target_buttons: Dictionary = {}
var _subtitle_label: Label
var _subtitle_edit: LineEdit
var _equip_button: Button
var _trade_button: Button
var _trade_confirm_button: Button
var _trade_hint: Label
var _trade_dialog: ConfirmationDialog
var _trade_mode: bool = false
var _trade_selection: Array[String] = []
var _close_button: Button
var _close_canvas_layer: CanvasLayer
var _category_buttons: Dictionary = {}
var _item_buttons: Dictionary = {}


func _ready() -> void:
	inventory = get_node_or_null("/root/CosmeticInventory") as FootballCosmeticInventory
	if inventory == null:
		push_error("Locker requires the CosmeticInventory autoload.")
		return
	_build_ui()
	inventory.inventory_changed.connect(_refresh_items)
	inventory.loadout_changed.connect(_on_loadout_changed)
	get_viewport().size_changed.connect(_apply_responsive_layout)
	MenuStyler.apply_premium_design(self, &"menu")
	MenuStyler.install_click_sounds(self)
	_apply_locker_styles()
	_apply_responsive_layout()
	_position_close_button.call_deferred()
	if _close_canvas_layer != null:
		_close_canvas_layer.visible = false
	hide()


func open_locker() -> void:
	show()
	if _close_canvas_layer != null:
		_close_canvas_layer.visible = true
	_position_close_button.call_deferred()
	current_slot = FootballCosmeticInventory.SLOT_PLAYER_SKIN
	_refresh_categories()
	_refresh_items()
	_apply_responsive_layout()
	_apply_locker_styles()
	var first_button: Button = _first_item_button()
	if first_button != null:
		first_button.grab_focus.call_deferred()


func close_locker() -> void:
	_set_trade_mode(false)
	if _close_canvas_layer != null:
		_close_canvas_layer.visible = false
	hide()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close_locker()
		return
	var joy_button := event as InputEventJoypadButton
	if joy_button == null or not joy_button.pressed:
		return
	if joy_button.button_index == JOY_BUTTON_LEFT_SHOULDER:
		get_viewport().set_input_as_handled()
		_cycle_category(-1)
	elif joy_button.button_index == JOY_BUTTON_RIGHT_SHOULDER:
		get_viewport().set_input_as_handled()
		_cycle_category(1)


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
		window_rect.end.x - 22.0 - 112.0,
		window_rect.position.y + 12.0
	)
	_close_button.size = Vector2(112.0, 48.0)


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var background := FootballBattlePassBackground.new()
	background.name = "LockerGalaxyBackground"
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 18.0
	center.offset_top = 18.0
	center.offset_right = -18.0
	center.offset_bottom = -18.0
	add_child(center)

	_window = PanelContainer.new()
	_window.name = "LockerWindow"
	center.add_child(_window)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	_window.add_child(margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.name = "Content"
	root_vbox.add_theme_constant_override("separation", 10)
	margin.add_child(root_vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	root_vbox.add_child(header)
	var heading_column := VBoxContainer.new()
	heading_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading_column)
	var title := Label.new()
	title.text = "THEODORE LOCKER"
	title.add_theme_font_size_override("font_size", 34)
	heading_column.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "BUILD YOUR MATCH LOOK  •  L1 / R1 SWITCH CATEGORY"
	subtitle.add_theme_color_override("font_color", MenuStyler.MUTED_TEXT)
	heading_column.add_child(subtitle)
	_trade_button = Button.new()
	_trade_button.name = "TradeModeButton"
	_trade_button.text = "TRADE UP"
	_trade_button.custom_minimum_size = Vector2(132.0, 48.0)
	_trade_button.pressed.connect(_toggle_trade_mode)
	header.add_child(_trade_button)
	# Reserve the header slot, but put the real BACK button on a dedicated
	# CanvasLayer. This mirrors the project's already-working map CLOSE hitbox
	# fix and prevents the lobby or locker content from overlapping its input.
	var close_spacer := Control.new()
	close_spacer.custom_minimum_size = Vector2(112.0, 48.0)
	close_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(close_spacer)

	_close_canvas_layer = CanvasLayer.new()
	_close_canvas_layer.name = "LockerBackCanvasLayer"
	_close_canvas_layer.layer = 1200
	add_child(_close_canvas_layer)

	_close_button = Button.new()
	_close_button.name = "CloseButton"
	_close_button.text = "BACK"
	_close_button.custom_minimum_size = Vector2(112.0, 48.0)
	_close_button.size = Vector2(112.0, 48.0)
	_close_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_close_button.focus_mode = Control.FOCUS_ALL
	_close_button.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	_close_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_close_button.set_meta("_motion_ready", true)
	_close_button.set_meta("_menu_style_ready", true)
	_close_button.pressed.connect(close_locker)
	_close_canvas_layer.add_child(_close_button)
	_window.resized.connect(_position_close_button)
	get_viewport().size_changed.connect(_position_close_button)

	var separator := HSeparator.new()
	root_vbox.add_child(separator)
	var collection_row := HBoxContainer.new()
	collection_row.add_theme_constant_override("separation", 10)
	root_vbox.add_child(collection_row)
	var collection_heading := Label.new()
	collection_heading.text = "COSMETIC VAULT"
	collection_heading.add_theme_font_size_override("font_size", 20)
	collection_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	collection_row.add_child(collection_heading)
	_collection_label = Label.new()
	_collection_label.name = "CollectionProgress"
	_collection_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_collection_label.add_theme_color_override("font_color", LOCKER_GOLD)
	collection_row.add_child(_collection_label)

	var body := HBoxContainer.new()
	body.name = "Body"
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	root_vbox.add_child(body)

	var category_scroll := ScrollContainer.new()
	category_scroll.name = "CategoryScroll"
	category_scroll.custom_minimum_size.x = 194.0
	category_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	category_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	category_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	category_scroll.follow_focus = true
	body.add_child(category_scroll)
	_category_column = VBoxContainer.new()
	_category_column.name = "Categories"
	_category_column.custom_minimum_size.x = 178.0
	_category_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_category_column.add_theme_constant_override("separation", 8)
	category_scroll.add_child(_category_column)
	for category: Dictionary in CATEGORY_DATA:
		var slot: StringName = StringName(category["slot"])
		var category_button := Button.new()
		category_button.name = "%sButton" % str(slot).to_pascal_case()
		category_button.text = str(category["label"])
		category_button.toggle_mode = true
		category_button.custom_minimum_size.y = 52.0
		category_button.pressed.connect(_select_category.bind(slot))
		_category_column.add_child(category_button)
		_category_buttons[slot] = category_button

	_item_scroll = ScrollContainer.new()
	_item_scroll.name = "ItemScroll"
	_item_scroll.clip_contents = true
	_item_scroll.follow_focus = true
	_item_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_item_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_item_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_item_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(_item_scroll)
	_item_grid = GridContainer.new()
	_item_grid.name = "ItemGrid"
	_item_grid.columns = 2
	_item_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_item_grid.add_theme_constant_override("h_separation", 9)
	_item_grid.add_theme_constant_override("v_separation", 9)
	_item_scroll.add_child(_item_grid)

	var preview_panel := PanelContainer.new()
	preview_panel.name = "PreviewPanel"
	preview_panel.custom_minimum_size.x = 320.0
	body.add_child(preview_panel)
	var preview_margin := MarginContainer.new()
	preview_margin.add_theme_constant_override("margin_left", 16)
	preview_margin.add_theme_constant_override("margin_right", 16)
	preview_margin.add_theme_constant_override("margin_top", 14)
	preview_margin.add_theme_constant_override("margin_bottom", 14)
	preview_panel.add_child(preview_margin)
	var preview_vbox := VBoxContainer.new()
	preview_vbox.add_theme_constant_override("separation", 9)
	preview_margin.add_child(preview_vbox)
	_preview_name = Label.new()
	_preview_name.name = "PreviewName"
	_preview_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_preview_name.add_theme_font_size_override("font_size", 23)
	preview_vbox.add_child(_preview_name)
	_preview_status = Label.new()
	_preview_status.name = "PreviewStatus"
	_preview_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_vbox.add_child(_preview_status)
	_preview = PREVIEW_SCRIPT.new() as FootballCosmeticPreview
	_preview.name = "CosmeticPreview"
	_preview.custom_minimum_size = Vector2(250.0, 250.0)
	_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_vbox.add_child(_preview)
	_preview_payload = Label.new()
	_preview_payload.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_preview_payload.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preview_payload.custom_minimum_size.y = 34.0
	preview_vbox.add_child(_preview_payload)
	_subtitle_label = Label.new()
	_subtitle_label.text = "GOAL BANNER SUBTITLE"
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_label.add_theme_color_override("font_color", MenuStyler.MUTED_TEXT)
	preview_vbox.add_child(_subtitle_label)
	_subtitle_edit = LineEdit.new()
	_subtitle_edit.name = "BannerSubtitle"
	_subtitle_edit.placeholder_text = "Write your scorer subtitle..."
	_subtitle_edit.max_length = FootballCosmeticInventory.PLAYER_SUBTITLE_MAX_LENGTH
	_subtitle_edit.tooltip_text = "Shown beneath your name on the goal-replay banner."
	_subtitle_edit.text_submitted.connect(_on_subtitle_submitted)
	_subtitle_edit.focus_exited.connect(_save_subtitle_edit)
	preview_vbox.add_child(_subtitle_edit)
	_skin_target_row = HBoxContainer.new()
	_skin_target_row.name = "LoadoutTeamSelector"
	_skin_target_row.add_theme_constant_override("separation", 5)
	preview_vbox.add_child(_skin_target_row)
	for team_data: Dictionary in [
		{"id": &"both", "label": "BOTH"},
		{"id": &"blue", "label": "BLUE"},
		{"id": &"red", "label": "RED"},
	]:
		var team_id: StringName = StringName(team_data["id"])
		var team_button := Button.new()
		team_button.name = "%sSkin" % str(team_id).to_pascal_case()
		team_button.text = str(team_data["label"])
		team_button.toggle_mode = true
		team_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		team_button.pressed.connect(_select_skin_target.bind(team_id))
		_skin_target_row.add_child(team_button)
		_skin_target_buttons[team_id] = team_button
	preview_vbox.move_child(_skin_target_row, 0)
	_skin_color_section = VBoxContainer.new()
	_skin_color_section.name = "SkinColorSection"
	_skin_color_section.add_theme_constant_override("separation", 4)
	preview_vbox.add_child(_skin_color_section)
	var color_label := Label.new()
	color_label.text = "SKIN COLOR"
	color_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	color_label.add_theme_color_override("font_color", MenuStyler.MUTED_TEXT)
	_skin_color_section.add_child(color_label)
	_skin_color_selector = OptionButton.new()
	_skin_color_selector.name = "SkinColorChoices"
	_skin_color_selector.custom_minimum_size.y = 36.0
	_skin_color_selector.add_item("Original", 0)
	_skin_color_selector.set_item_metadata(
		0,
		FootballCosmeticInventory.PLAYER_SKIN_ORIGINAL_COLOR
	)
	for color_index: int in range(FootballCosmeticInventory.PLAYER_SKIN_COLORS.size()):
		var palette: Dictionary = FootballCosmeticInventory.PLAYER_SKIN_COLORS[color_index]
		_skin_color_selector.add_item(str(palette["name"]), color_index + 1)
		_skin_color_selector.set_item_metadata(color_index + 1, color_index)
	_skin_color_selector.add_item("Mixed (Blue / Red)", 11)
	_skin_color_selector.set_item_metadata(11, MIXED_SKIN_COLOR)
	_skin_color_selector.set_item_disabled(11, true)
	_skin_color_selector.item_selected.connect(_select_skin_color_option)
	_skin_color_section.add_child(_skin_color_selector)
	_team_primary_color_section = VBoxContainer.new()
	_team_primary_color_section.name = "TeamPrimaryColorSection"
	_team_primary_color_section.add_theme_constant_override("separation", 4)
	preview_vbox.add_child(_team_primary_color_section)
	var team_primary_label := Label.new()
	team_primary_label.text = "TEAM PRIMARY COLOR"
	team_primary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	team_primary_label.add_theme_color_override("font_color", MenuStyler.MUTED_TEXT)
	_team_primary_color_section.add_child(team_primary_label)
	_team_primary_color_selector = OptionButton.new()
	_team_primary_color_selector.name = "TeamPrimaryColorChoices"
	_team_primary_color_selector.custom_minimum_size.y = 36.0
	_team_primary_color_selector.item_selected.connect(_select_team_primary_color_option)
	_team_primary_color_section.add_child(_team_primary_color_selector)
	_goal_fx_color_section = VBoxContainer.new()
	_goal_fx_color_section.name = "GoalFXColorSection"
	_goal_fx_color_section.add_theme_constant_override("separation", 4)
	preview_vbox.add_child(_goal_fx_color_section)
	var goal_color_label := Label.new()
	goal_color_label.text = "GOAL FX COLOR"
	goal_color_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	goal_color_label.add_theme_color_override("font_color", MenuStyler.MUTED_TEXT)
	_goal_fx_color_section.add_child(goal_color_label)
	_goal_fx_color_selector = OptionButton.new()
	_goal_fx_color_selector.name = "GoalFXColorChoices"
	_goal_fx_color_selector.custom_minimum_size.y = 36.0
	_goal_fx_color_selector.add_item("Original", 0)
	_goal_fx_color_selector.set_item_metadata(
		0,
		FootballCosmeticInventory.PLAYER_SKIN_ORIGINAL_COLOR
	)
	for color_index: int in range(FootballCosmeticInventory.GOAL_EXPLOSION_COLORS.size()):
		var palette: Dictionary = FootballCosmeticInventory.GOAL_EXPLOSION_COLORS[color_index]
		_goal_fx_color_selector.add_item(str(palette["name"]), color_index + 1)
		_goal_fx_color_selector.set_item_metadata(color_index + 1, color_index)
	_goal_fx_color_selector.item_selected.connect(_select_goal_fx_color_option)
	_goal_fx_color_section.add_child(_goal_fx_color_selector)
	_banner_color_section = VBoxContainer.new()
	_banner_color_section.name = "BannerColorSection"
	_banner_color_section.add_theme_constant_override("separation", 4)
	preview_vbox.add_child(_banner_color_section)
	var banner_color_label := Label.new()
	banner_color_label.text = "BANNER COLOR"
	banner_color_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_color_label.add_theme_color_override("font_color", MenuStyler.MUTED_TEXT)
	_banner_color_section.add_child(banner_color_label)
	_banner_color_selector = OptionButton.new()
	_banner_color_selector.name = "BannerColorChoices"
	_banner_color_selector.custom_minimum_size.y = 36.0
	_banner_color_selector.add_item("Original", 0)
	_banner_color_selector.set_item_metadata(
		0,
		FootballCosmeticInventory.PLAYER_SKIN_ORIGINAL_COLOR
	)
	for color_index: int in range(FootballCosmeticInventory.PLAYER_BANNER_COLORS.size()):
		var banner_palette: Dictionary = FootballCosmeticInventory.PLAYER_BANNER_COLORS[color_index]
		_banner_color_selector.add_item(str(banner_palette["name"]), color_index + 1)
		_banner_color_selector.set_item_metadata(color_index + 1, color_index)
	_banner_color_selector.add_item("Mixed (Blue / Red)", 11)
	_banner_color_selector.set_item_metadata(11, MIXED_SKIN_COLOR)
	_banner_color_selector.set_item_disabled(11, true)
	_banner_color_selector.item_selected.connect(_select_banner_color_option)
	_banner_color_section.add_child(_banner_color_selector)
	_field_ability_toggle = CheckButton.new()
	_field_ability_toggle.name = "ShowFieldAbilityIcons"
	_field_ability_toggle.text = "SHOW ABILITY ICONS ON FIELD"
	_field_ability_toggle.tooltip_text = (
		"Show your equipped ability inside your field character. "
		+ "This choice is visible to everyone; other players keep their own setting."
	)
	_field_ability_toggle.toggled.connect(_on_field_ability_icons_toggled)
	preview_vbox.add_child(_field_ability_toggle)
	_equip_button = Button.new()
	_equip_button.name = "EquipButton"
	_equip_button.text = "EQUIP"
	_equip_button.custom_minimum_size.y = 52.0
	_equip_button.pressed.connect(_equip_selected)
	preview_vbox.add_child(_equip_button)
	_trade_hint = Label.new()
	_trade_hint.name = "TradeHint"
	_trade_hint.text = "Trade five unequipped cosmetics of one rarity for one higher-rarity item."
	_trade_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_trade_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_trade_hint.add_theme_color_override("font_color", MenuStyler.MUTED_TEXT)
	_trade_hint.add_theme_font_size_override("font_size", 12)
	preview_vbox.add_child(_trade_hint)
	var trade_row := HBoxContainer.new()
	trade_row.name = "TradeUpControls"
	trade_row.add_theme_constant_override("separation", 7)
	preview_vbox.add_child(trade_row)
	_trade_confirm_button = Button.new()
	_trade_confirm_button.name = "TradeConfirmButton"
	_trade_confirm_button.text = "TRADE 0 / 5"
	_trade_confirm_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_trade_confirm_button.custom_minimum_size.y = 44.0
	_trade_confirm_button.disabled = true
	_trade_confirm_button.hide()
	_trade_confirm_button.pressed.connect(_request_trade_confirmation)
	trade_row.add_child(_trade_confirm_button)
	var controller_hint := Label.new()
	controller_hint.name = "ControllerHint"
	controller_hint.text = "D-PAD / STICK  NAVIGATE   •   CROSS  SELECT   •   CIRCLE  BACK"
	controller_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controller_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controller_hint.add_theme_color_override("font_color", MenuStyler.MUTED_TEXT)
	preview_vbox.add_child(controller_hint)
	_quick_chat_wheel = QUICK_CHAT_WHEEL_SCRIPT.new() as FootballLockerQuickChatWheel
	_quick_chat_wheel.name = "QuickChatAssignmentWheel"
	_quick_chat_wheel.slot_selected.connect(_assign_quick_chat_slot)
	add_child(_quick_chat_wheel)
	_trade_dialog = ConfirmationDialog.new()
	_trade_dialog.name = "TradeUpConfirmation"
	_trade_dialog.title = "CONFIRM TRADE UP"
	_trade_dialog.confirmed.connect(_confirm_trade_up)
	add_child(_trade_dialog)


func _select_category(slot: StringName) -> void:
	if current_slot != slot:
		_set_trade_mode(false)
	current_slot = slot
	_refresh_categories()
	_refresh_items()
	var first_button: Button = _first_item_button()
	if first_button != null:
		first_button.grab_focus.call_deferred()


func _refresh_categories() -> void:
	for slot_variant: Variant in _category_buttons.keys():
		var slot: StringName = StringName(slot_variant)
		var button: Button = _category_buttons[slot] as Button
		button.set_pressed_no_signal(slot == current_slot)


func _refresh_items() -> void:
	if inventory == null or _item_grid == null:
		return
	for child: Node in _item_grid.get_children():
		_item_grid.remove_child(child)
		child.queue_free()
	_item_buttons.clear()
	var catalog_items: Array[Dictionary] = inventory.get_catalog_items(current_slot)
	var items: Array[Dictionary] = []
	for catalog_item: Dictionary in catalog_items:
		if bool(catalog_item.get("owned", false)):
			items.append(catalog_item)
	if (
		current_slot == FootballCosmeticInventory.SLOT_TEAM_COLOR
		and _skin_target in [&"blue", &"red"]
	):
		var matching_items: Array[Dictionary] = []
		for candidate: Dictionary in items:
			if StringName(candidate.get("team", "")) == _skin_target:
				matching_items.append(candidate)
		items = matching_items
	items.sort_custom(_locker_item_precedes)
	if _collection_label != null:
		_collection_label.text = "%d OWNED  •  LOCKED ITEMS STAY IN LOOTBOX" % items.size()
	selected_item_id = ""
	for item: Dictionary in items:
		var item_id: String = str(item.get("id", ""))
		var button := Button.new()
		button.name = "Item_%s" % item_id.replace(".", "_")
		button.text = _item_button_text(item_id, item)
		if _trade_selection.has(item_id):
			button.text = "◆  %s" % str(item.get("name", item_id))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(210.0, 66.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.tooltip_text = "%s  •  %s" % [
			str(item.get("rarity", "common")).to_upper(),
			"OWNED" if bool(item.get("owned", false)) else "LOCKED",
		]
		if current_slot == FootballCosmeticInventory.SLOT_GOAL_THEME:
			button.icon = GOAL_THEME_ITEM_ICON
			button.expand_icon = true
			button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.add_theme_constant_override("icon_max_width", 40)
			button.add_theme_constant_override("h_separation", 10)
			# Menu themes can tint Button icons. Keep Goal Theme artwork at its
			# original colors instead of letting it collapse into a dark silhouette.
			for icon_state: StringName in [
				&"icon_normal_color",
				&"icon_hover_color",
				&"icon_pressed_color",
				&"icon_hover_pressed_color",
				&"icon_focus_color",
				&"icon_disabled_color",
			]:
				button.add_theme_color_override(icon_state, Color.WHITE)
		button.set_meta(&"cosmetic_item_id", item_id)
		button.pressed.connect(_on_item_pressed.bind(item_id))
		_item_grid.add_child(button)
		_item_buttons[item_id] = button
		_apply_item_card_style(button, item)
	var preferred_id: String = _preferred_item_id()
	if _item_buttons.has(preferred_id):
		_select_item(preferred_id)
	elif not items.is_empty():
		_select_item(str(items[0].get("id", "")))
	_wire_controller_focus.call_deferred()


func _locker_item_precedes(left: Dictionary, right: Dictionary) -> bool:
	return str(left.get("name", "")).naturalnocasecmp_to(
		str(right.get("name", ""))
	) < 0


func _item_button_text(item_id: String, item: Dictionary) -> String:
	var marker: String = "✓" if _is_item_equipped(item_id) else " "
	var ownership: String = "" if bool(item.get("owned", false)) else "  🔒"
	return "%s  %s%s" % [marker, str(item.get("name", item_id)), ownership]


func _on_item_pressed(item_id: String) -> void:
	_select_item(item_id)
	if _trade_mode:
		_toggle_trade_item(item_id)


func _toggle_trade_mode() -> void:
	_set_trade_mode(not _trade_mode)


func _set_trade_mode(enabled: bool) -> void:
	_trade_mode = enabled
	_trade_selection.clear()
	if _trade_button != null:
		_trade_button.text = "CANCEL TRADE" if enabled else "TRADE UP"
	if _equip_button != null:
		_equip_button.visible = not enabled
	_update_trade_controls()
	if _item_grid != null:
		_refresh_items()


func _toggle_trade_item(item_id: String) -> void:
	var item: Dictionary = inventory.get_catalog_item(item_id)
	var rarity: String = str(item.get("rarity", "common"))
	if bool(item.get("owned_by_default", false)):
		_trade_hint.text = "Starter cosmetics are permanent and cannot be traded."
		return
	if inventory.is_item_equipped_anywhere(item_id):
		_trade_hint.text = "Unequip this cosmetic before trading it."
		return
	if rarity == "legendary":
		_trade_hint.text = "Legendary is the maximum rarity."
		return
	if _trade_selection.has(item_id):
		_trade_selection.erase(item_id)
	elif _trade_selection.size() >= FootballCosmeticInventory.TRADE_UP_ITEM_COUNT:
		_trade_hint.text = "Five cosmetics are already selected."
		return
	else:
		if not _trade_selection.is_empty():
			var first_item: Dictionary = inventory.get_catalog_item(_trade_selection[0])
			if str(first_item.get("rarity", "common")) != rarity:
				_trade_hint.text = "Choose five cosmetics of the same rarity."
				return
		_trade_selection.append(item_id)
	_update_trade_controls()
	_refresh_items()


func _update_trade_controls() -> void:
	if _trade_confirm_button == null or _trade_hint == null:
		return
	_trade_confirm_button.visible = _trade_mode
	_trade_confirm_button.text = "TRADE %d / %d" % [
		_trade_selection.size(), FootballCosmeticInventory.TRADE_UP_ITEM_COUNT
	]
	_trade_confirm_button.disabled = not inventory.can_trade_up(_trade_selection)
	if not _trade_mode:
		_trade_hint.text = "Trade five unequipped cosmetics of one rarity for one higher-rarity item."
	elif _trade_selection.is_empty():
		_trade_hint.text = "Select five unequipped, non-starter cosmetics of one rarity."
	elif _trade_selection.size() < FootballCosmeticInventory.TRADE_UP_ITEM_COUNT:
		_trade_hint.text = "%d more needed." % (
			FootballCosmeticInventory.TRADE_UP_ITEM_COUNT - _trade_selection.size()
		)
	else:
		_trade_hint.text = "Ready. Reward: one random unowned item of the next rarity."


func _request_trade_confirmation() -> void:
	if not inventory.can_trade_up(_trade_selection):
		return
	var names: Array[String] = []
	for item_id: String in _trade_selection:
		names.append(str(inventory.get_catalog_item(item_id).get("name", item_id)))
	_trade_dialog.dialog_text = (
		"Consume these five cosmetics for one random higher-rarity item?\n\n- "
		+ "\n- ".join(names)
	)
	_trade_dialog.popup_centered(Vector2i(560, 330))


func _confirm_trade_up() -> void:
	var result: Dictionary = inventory.trade_up(_trade_selection)
	if not bool(result.get("ok", false)):
		_trade_hint.text = str(result.get("error", "Trade failed."))
		return
	var reward_id: String = str(result.get("reward_id", ""))
	var reward: Dictionary = inventory.get_catalog_item(reward_id)
	_trade_mode = false
	_trade_selection.clear()
	_trade_button.text = "TRADE UP"
	_equip_button.show()
	_trade_confirm_button.hide()
	current_slot = StringName(reward.get("slot", current_slot))
	_refresh_categories()
	_refresh_items()
	if _item_buttons.has(reward_id):
		_select_item(reward_id)
	_trade_hint.text = "NEW ITEM: %s" % str(reward.get("name", reward_id)).to_upper()


func _select_item(item_id: String) -> void:
	selected_item_id = item_id
	var item: Dictionary = inventory.get_catalog_item(item_id)
	var preview_team: StringName = &"red" if _skin_target == &"red" else &"blue"
	_preview.set_frame_palette_id(
		item_id
		if current_slot == FootballCosmeticInventory.SLOT_FRAME_PALETTE
		else inventory.get_equipped_item_id_for_team(
			FootballCosmeticInventory.SLOT_FRAME_PALETTE,
			preview_team
		)
	)
	_preview.set_player_material_id(
		item_id
		if current_slot == FootballCosmeticInventory.SLOT_PLAYER_MATERIAL
		else inventory.get_equipped_item_id_for_team(
			FootballCosmeticInventory.SLOT_PLAYER_MATERIAL,
			preview_team
		)
	)
	_preview.set_team_primary_color_indices(
		inventory.get_team_primary_color_index(&"blue"),
		inventory.get_team_primary_color_index(&"red")
	)
	if current_slot == FootballCosmeticInventory.SLOT_TEAM_COLOR:
		var color_team: StringName = StringName(item.get("team", "blue"))
		var color_index: int = int(item.get("color_index", 0))
		_preview.set_team_primary_color_indices(
			color_index if color_team == &"blue" else inventory.get_team_primary_color_index(&"blue"),
			color_index if color_team == &"red" else inventory.get_team_primary_color_index(&"red")
		)
	var preview_skin_id: String = inventory.get_player_skin_for_team(preview_team)
	_preview.set_preview_player_skin(
		preview_skin_id,
		inventory.get_catalog_item(preview_skin_id)
	)
	_preview.set_preview_team(_skin_target)
	_preview.set_player_skin_team_color_indices(
		inventory.get_player_skin_color_for_team(&"blue"),
		inventory.get_player_skin_color_for_team(&"red")
	)
	_preview.set_player_skin_color_index(_get_preview_skin_color_index())
	_preview.set_goal_explosion_color_index(
		inventory.get_goal_explosion_color_index()
	)
	_preview.set_player_banner_color_index(_get_preview_banner_color_index())
	_preview.set_cosmetic(item_id, item)
	_preview_name.text = str(item.get("name", item_id))
	var owned: bool = inventory.is_owned(item_id)
	var equipped: bool = _is_item_equipped(item_id)
	_preview_status.text = "EQUIPPED" if equipped else ("OWNED" if owned else "LOCKED")
	_preview_status.add_theme_color_override(
		"font_color",
		Color(0.42, 1.0, 0.66) if owned else Color(0.72, 0.72, 0.75)
	)
	_preview_payload.text = str(item.get("payload", ""))
	_preview_payload.visible = not _preview_payload.text.is_empty()
	_skin_target_row.visible = (
		FootballCosmeticInventory.SINGLE_EQUIP_SLOTS.has(current_slot)
		or current_slot == FootballCosmeticInventory.SLOT_TEAM_COLOR
	)
	_skin_color_section.visible = (
		current_slot == FootballCosmeticInventory.SLOT_PLAYER_SKIN
	)
	_goal_fx_color_section.visible = (
		current_slot == FootballCosmeticInventory.SLOT_GOAL_EXPLOSION
	)
	_banner_color_section.visible = (
		current_slot == FootballCosmeticInventory.SLOT_PLAYER_BANNER
	)
	_team_primary_color_section.visible = (
		current_slot == FootballCosmeticInventory.SLOT_PLAYER_MATERIAL
	)
	_refresh_team_primary_color_selector()
	_refresh_skin_color_buttons()
	_refresh_goal_fx_color_selector()
	_refresh_banner_color_selector()
	_field_ability_toggle.visible = (
		current_slot == FootballCosmeticInventory.SLOT_PLAYER_SKIN
	)
	_field_ability_toggle.set_pressed_no_signal(
		inventory.get_show_field_ability_icons()
	)
	_refresh_skin_target_buttons()
	_refresh_subtitle_editor()
	_equip_button.disabled = (
		not owned
		or equipped and current_slot != FootballCosmeticInventory.SLOT_QUICK_CHAT
	)
	_equip_button.text = (
		("MOVE ON WHEEL" if equipped else "PLACE ON WHEEL")
		if owned and current_slot == FootballCosmeticInventory.SLOT_QUICK_CHAT
		else "EQUIPPED"
		if equipped
		else "EQUIP"
		if owned
		else "LOCKED"
	)


func _equip_selected() -> void:
	if selected_item_id.is_empty():
		return
	var equipped: bool = false
	if current_slot == FootballCosmeticInventory.SLOT_QUICK_CHAT:
		_quick_chat_wheel.open_for_item(
			str(inventory.get_catalog_item(selected_item_id).get("name", selected_item_id)),
			inventory.get_quick_chat_loadout(),
			inventory.get_quick_chat_payloads()
		)
		return
	elif current_slot == FootballCosmeticInventory.SLOT_PLAYER_SKIN:
		if _skin_target == &"both":
			equipped = inventory.equip_item(current_slot, selected_item_id)
			if equipped:
				inventory.set_team_player_skins_enabled(false)
		else:
			equipped = inventory.equip_player_skin_for_team(
				_skin_target,
				selected_item_id
			)
	elif current_slot == FootballCosmeticInventory.SLOT_TEAM_COLOR:
		var color_item: Dictionary = inventory.get_catalog_item(selected_item_id)
		equipped = inventory.set_team_primary_color_index(
			StringName(color_item.get("team", "blue")),
			int(color_item.get("color_index", 0))
		)
	elif FootballCosmeticInventory.SINGLE_EQUIP_SLOTS.has(current_slot):
		equipped = (
			inventory.equip_item(current_slot, selected_item_id)
			if _skin_target == &"both"
			else inventory.equip_item_for_team(
				current_slot, _skin_target, selected_item_id
			)
		)
	if equipped and not selected_item_id.is_empty():
		_select_item(selected_item_id)


func _on_loadout_changed(slot: StringName, _item_id: String) -> void:
	if slot == FootballCosmeticInventory.SLOT_PLAYER_SKIN_COLOR:
		_preview.set_player_skin_team_color_indices(
			inventory.get_player_skin_color_for_team(&"blue"),
			inventory.get_player_skin_color_for_team(&"red")
		)
		_preview.set_player_skin_color_index(_get_preview_skin_color_index())
		_refresh_skin_color_buttons()
		return
	if slot == FootballCosmeticInventory.SLOT_GOAL_EXPLOSION_COLOR:
		_preview.set_goal_explosion_color_index(
			inventory.get_goal_explosion_color_index()
		)
		_refresh_goal_fx_color_selector()
		return
	if slot == FootballCosmeticInventory.SLOT_PLAYER_BANNER_COLOR:
		_preview.set_player_banner_color_index(_get_preview_banner_color_index())
		_refresh_banner_color_selector()
		return
	if slot == FootballCosmeticInventory.SLOT_TEAM_PRIMARY_COLOR:
		_preview.set_team_primary_color_indices(
			inventory.get_team_primary_color_index(&"blue"),
			inventory.get_team_primary_color_index(&"red")
		)
		_refresh_team_primary_color_selector()
		return
	_refresh_items()


func _assign_quick_chat_slot(index: int) -> void:
	if selected_item_id.is_empty():
		return
	if inventory.equip_quick_chat(index, selected_item_id):
		_refresh_items()
		_select_item(selected_item_id)


func _select_skin_target(target: StringName) -> void:
	_skin_target = target if target in [&"both", &"blue", &"red"] else &"both"
	_refresh_skin_target_buttons()
	_refresh_items()


func _select_team_primary_color_option(option_index: int) -> void:
	if inventory == null or _skin_target not in [&"blue", &"red"]:
		return
	var color_index: int = int(_team_primary_color_selector.get_item_metadata(option_index))
	inventory.set_team_primary_color_index(_skin_target, color_index)


func _refresh_team_primary_color_selector() -> void:
	if inventory == null or _team_primary_color_selector == null:
		return
	_team_primary_color_selector.clear()
	if _skin_target == &"both":
		_team_primary_color_selector.add_item("Choose BLUE or RED above")
		_team_primary_color_selector.disabled = true
		return
	_team_primary_color_selector.disabled = false
	var palette: Array[Dictionary] = (
		FootballCosmeticInventory.BLUE_TEAM_COLORS
		if _skin_target == &"blue"
		else FootballCosmeticInventory.RED_TEAM_COLORS
	)
	for color_index: int in range(palette.size()):
		var color_item_id: String = str(palette[color_index]["id"])
		var owned: bool = inventory.is_owned(color_item_id)
		_team_primary_color_selector.add_item(
			str(palette[color_index]["name"]) if owned
			else "%s  [LOCKED]" % str(palette[color_index]["name"])
		)
		_team_primary_color_selector.set_item_metadata(color_index, color_index)
		_team_primary_color_selector.set_item_disabled(color_index, not owned)
	_team_primary_color_selector.select(inventory.get_team_primary_color_index(_skin_target))


func _on_field_ability_icons_toggled(enabled: bool) -> void:
	if inventory == null:
		return
	inventory.set_show_field_ability_icons(enabled)


func _select_skin_color_option(option_index: int) -> void:
	if inventory == null:
		return
	var color_index: int = int(_skin_color_selector.get_item_metadata(option_index))
	if color_index == MIXED_SKIN_COLOR:
		return
	if _skin_target in [&"blue", &"red"]:
		inventory.set_player_skin_color_for_team(_skin_target, color_index)
	else:
		inventory.set_player_skin_color_index(color_index)


func _refresh_skin_color_buttons() -> void:
	if inventory == null:
		return
	var blue_index: int = inventory.get_player_skin_color_for_team(&"blue")
	var red_index: int = inventory.get_player_skin_color_for_team(&"red")
	var selected_index: int = MIXED_SKIN_COLOR
	if _skin_target in [&"blue", &"red"]:
		selected_index = inventory.get_player_skin_color_for_team(_skin_target)
	elif blue_index == red_index:
		selected_index = blue_index
	for option_index: int in range(_skin_color_selector.item_count):
		if int(_skin_color_selector.get_item_metadata(option_index)) == selected_index:
			_skin_color_selector.select(option_index)
			return
	_skin_color_selector.select(0)


func _select_goal_fx_color_option(option_index: int) -> void:
	if inventory == null:
		return
	var color_index: int = int(
		_goal_fx_color_selector.get_item_metadata(option_index)
	)
	inventory.set_goal_explosion_color_index(color_index)


func _refresh_goal_fx_color_selector() -> void:
	if inventory == null:
		return
	var selected_index: int = inventory.get_goal_explosion_color_index()
	for option_index: int in range(_goal_fx_color_selector.item_count):
		if int(_goal_fx_color_selector.get_item_metadata(option_index)) == selected_index:
			_goal_fx_color_selector.select(option_index)
			return
	_goal_fx_color_selector.select(0)


func _select_banner_color_option(option_index: int) -> void:
	if inventory == null:
		return
	var color_index: int = int(
		_banner_color_selector.get_item_metadata(option_index)
	)
	if color_index == MIXED_SKIN_COLOR:
		return
	if _skin_target in [&"blue", &"red"]:
		inventory.set_player_banner_color_for_team(_skin_target, color_index)
	else:
		inventory.set_player_banner_color_index(color_index)


func _refresh_banner_color_selector() -> void:
	if inventory == null or _banner_color_selector == null:
		return
	var blue_index: int = inventory.get_player_banner_color_for_team(&"blue")
	var red_index: int = inventory.get_player_banner_color_for_team(&"red")
	var selected_index: int = MIXED_SKIN_COLOR
	if _skin_target in [&"blue", &"red"]:
		selected_index = inventory.get_player_banner_color_for_team(_skin_target)
	elif blue_index == red_index:
		selected_index = blue_index
	for option_index: int in range(_banner_color_selector.item_count):
		if int(_banner_color_selector.get_item_metadata(option_index)) == selected_index:
			_banner_color_selector.select(option_index)
			return
	_banner_color_selector.select(0)


func _get_preview_skin_color_index() -> int:
	if _skin_target in [&"blue", &"red"]:
		return inventory.get_player_skin_color_for_team(_skin_target)
	# BOTH previews the Blue version when the team colors differ; switching to
	# RED shows the other exact skin/color combination.
	return inventory.get_player_skin_color_for_team(&"blue")


func _get_preview_banner_color_index() -> int:
	if _skin_target in [&"blue", &"red"]:
		return inventory.get_player_banner_color_for_team(_skin_target)
	return inventory.get_player_banner_color_for_team(&"blue")


func _refresh_skin_target_buttons() -> void:
	for target_variant: Variant in _skin_target_buttons.keys():
		var target: StringName = StringName(target_variant)
		var button: Button = _skin_target_buttons[target] as Button
		button.set_pressed_no_signal(target == _skin_target)


func _refresh_subtitle_editor() -> void:
	var show_subtitle: bool = (
		current_slot == FootballCosmeticInventory.SLOT_PLAYER_BANNER
	)
	_subtitle_label.visible = show_subtitle
	_subtitle_edit.visible = show_subtitle
	if show_subtitle and not _subtitle_edit.has_focus():
		_subtitle_edit.text = inventory.get_player_subtitle()


func _on_subtitle_submitted(_value: String) -> void:
	_save_subtitle_edit()
	_subtitle_edit.release_focus()


func _save_subtitle_edit() -> void:
	if inventory == null or _subtitle_edit == null:
		return
	inventory.set_player_subtitle(_subtitle_edit.text)
	_subtitle_edit.text = inventory.get_player_subtitle()


func _preferred_item_id() -> String:
	if current_slot == FootballCosmeticInventory.SLOT_QUICK_CHAT:
		var quick_chat: Array[String] = inventory.get_quick_chat_loadout()
		return quick_chat[0]
	if current_slot == FootballCosmeticInventory.SLOT_PLAYER_SKIN:
		return (
			inventory.get_equipped_item_id(current_slot)
			if _skin_target == &"both"
			else inventory.get_player_skin_for_team(_skin_target)
		)
	if current_slot == FootballCosmeticInventory.SLOT_TEAM_COLOR:
		var team_for_color: StringName = &"red" if _skin_target == &"red" else &"blue"
		return FootballCosmeticInventory.get_team_primary_color_item_id(
			team_for_color,
			inventory.get_team_primary_color_index(team_for_color)
		)
	if FootballCosmeticInventory.SINGLE_EQUIP_SLOTS.has(current_slot):
		return (
			inventory.get_equipped_item_id(current_slot)
			if _skin_target == &"both"
			else inventory.get_equipped_item_id_for_team(current_slot, _skin_target)
		)
	return inventory.get_equipped_item_id(current_slot)


func _is_item_equipped(item_id: String) -> bool:
	if current_slot == FootballCosmeticInventory.SLOT_QUICK_CHAT:
		return inventory.get_quick_chat_loadout().has(item_id)
	if current_slot == FootballCosmeticInventory.SLOT_PLAYER_SKIN:
		if _skin_target == &"both":
			return (
				not inventory.are_team_player_skins_enabled()
				and inventory.get_equipped_item_id(current_slot) == item_id
			)
		return (
			inventory.are_team_player_skins_enabled()
			and inventory.get_player_skin_for_team(_skin_target) == item_id
		)
	if current_slot == FootballCosmeticInventory.SLOT_TEAM_COLOR:
		var color_item: Dictionary = inventory.get_catalog_item(item_id)
		var color_team: StringName = StringName(color_item.get("team", "blue"))
		return int(color_item.get("color_index", -1)) == inventory.get_team_primary_color_index(color_team)
	if FootballCosmeticInventory.SINGLE_EQUIP_SLOTS.has(current_slot):
		return (
			(
				inventory.get_equipped_item_id_for_team(current_slot, &"blue") == item_id
				and inventory.get_equipped_item_id_for_team(current_slot, &"red") == item_id
			)
			if _skin_target == &"both"
			else inventory.get_equipped_item_id_for_team(current_slot, _skin_target) == item_id
		)
	return inventory.get_equipped_item_id(current_slot) == item_id


func _first_item_button() -> Button:
	for button_variant: Variant in _item_buttons.values():
		return button_variant as Button
	return null


func _cycle_category(direction: int) -> void:
	var current_index: int = 0
	for index: int in range(CATEGORY_DATA.size()):
		if StringName(CATEGORY_DATA[index]["slot"]) == current_slot:
			current_index = index
			break
	var next_index: int = wrapi(current_index + direction, 0, CATEGORY_DATA.size())
	_select_category(StringName(CATEGORY_DATA[next_index]["slot"]))


func _current_category_button() -> Button:
	return _category_buttons.get(current_slot, null) as Button


func _wire_controller_focus() -> void:
	if not is_inside_tree() or _close_button == null or _item_grid == null:
		return
	var category_controls: Array[Control] = []
	for category: Dictionary in CATEGORY_DATA:
		var category_button: Button = _category_buttons.get(
			StringName(category["slot"]), null
		) as Button
		if category_button != null:
			category_controls.append(category_button)
	_wire_vertical_wrap(category_controls)
	var item_controls: Array[Control] = []
	for child: Node in _item_grid.get_children():
		var item_button := child as Button
		if item_button != null:
			item_controls.append(item_button)
	var preview_controls: Array[Control] = []
	for target: StringName in [&"both", &"blue", &"red"]:
		var team_button: Button = _skin_target_buttons.get(target, null) as Button
		if team_button != null and team_button.is_visible_in_tree():
			preview_controls.append(team_button)
	for optional_control: Control in [
		_skin_color_selector,
		_team_primary_color_selector,
		_goal_fx_color_selector,
		_field_ability_toggle,
		_subtitle_edit,
	]:
		if optional_control != null and optional_control.is_visible_in_tree():
			preview_controls.append(optional_control)
	preview_controls.append(_equip_button)
	preview_controls.append(_trade_button)
	if _trade_confirm_button.visible:
		preview_controls.append(_trade_confirm_button)
	var preview_entry: Control = preview_controls[0]
	var first_item: Control = (
		item_controls[0] if not item_controls.is_empty() else _equip_button
	)
	for category_control: Control in category_controls:
		_set_focus_neighbor(category_control, SIDE_RIGHT, first_item)
	var columns: int = maxi(1, _item_grid.columns)
	var category_target: Control = _current_category_button()
	for index: int in range(item_controls.size()):
		var item_control: Control = item_controls[index]
		var column: int = index % columns
		var left_target: Control = (
			category_target
			if column == 0
			else item_controls[index - 1]
		)
		var right_target: Control = (
			preview_entry
			if column == columns - 1 or index + 1 >= item_controls.size()
			else item_controls[index + 1]
		)
		var up_index: int = index - columns
		var down_index: int = index + columns
		_set_focus_neighbor(item_control, SIDE_LEFT, left_target)
		_set_focus_neighbor(item_control, SIDE_RIGHT, right_target)
		_set_focus_neighbor(
			item_control,
			SIDE_TOP,
			item_controls[up_index] if up_index >= 0 else _close_button
		)
		_set_focus_neighbor(
			item_control,
			SIDE_BOTTOM,
			item_controls[down_index]
			if down_index < item_controls.size()
			else _equip_button
		)
	_set_focus_neighbor(_close_button, SIDE_BOTTOM, first_item)
	var item_return: Control = (
		item_controls.back() if not item_controls.is_empty() else category_target
	)
	for index: int in range(preview_controls.size()):
		var preview_control: Control = preview_controls[index]
		var previous_control: Control = (
			item_return if index == 0 else preview_controls[index - 1]
		)
		var next_control: Control = (
			_close_button
			if index + 1 >= preview_controls.size()
			else preview_controls[index + 1]
		)
		_set_focus_neighbor(preview_control, SIDE_LEFT, previous_control)
		_set_focus_neighbor(preview_control, SIDE_RIGHT, next_control)
		_set_focus_neighbor(preview_control, SIDE_TOP, previous_control)
		_set_focus_neighbor(preview_control, SIDE_BOTTOM, next_control)


func _wire_vertical_wrap(controls: Array[Control]) -> void:
	if controls.is_empty():
		return
	for index: int in range(controls.size()):
		_set_focus_neighbor(
			controls[index], SIDE_TOP, controls[wrapi(index - 1, 0, controls.size())]
		)
		_set_focus_neighbor(
			controls[index], SIDE_BOTTOM, controls[wrapi(index + 1, 0, controls.size())]
		)


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


func _apply_locker_styles() -> void:
	if _window == null:
		return
	var window_style := StyleBoxFlat.new()
	window_style.bg_color = LOCKER_PANEL
	window_style.border_color = Color(LOCKER_GOLD, 0.76)
	window_style.set_border_width_all(2)
	window_style.set_corner_radius_all(14)
	window_style.shadow_color = Color(0.0, 0.0, 0.0, 0.52)
	window_style.shadow_size = 14
	_window.add_theme_stylebox_override("panel", window_style)
	var preview_panel := find_child("PreviewPanel", true, false) as PanelContainer
	if preview_panel != null:
		var preview_style := StyleBoxFlat.new()
		preview_style.bg_color = Color(0.09, 0.055, 0.22, 0.38)
		preview_style.border_color = Color(LOCKER_GOLD, 0.48)
		preview_style.set_border_width_all(1)
		preview_style.set_corner_radius_all(10)
		preview_panel.add_theme_stylebox_override("panel", preview_style)
	for category: Dictionary in CATEGORY_DATA:
		var category_button: Button = _category_buttons.get(
			StringName(category["slot"]), null
		) as Button
		if category_button != null:
			MenuStyler.style_button(category_button, LOCKER_GOLD, 48.0)
	MenuStyler.style_button(_close_button, Color("d5dde8"), 46.0)
	MenuStyler.style_button(_equip_button, LOCKER_GOLD, 52.0)
	MenuStyler.style_button(_trade_button, Color("bb8cff"), 44.0)
	MenuStyler.style_button(_trade_confirm_button, Color("75df8c"), 44.0)


func _apply_item_card_style(button: Button, item: Dictionary) -> void:
	var accent: Color = _rarity_color(str(item.get("rarity", "common")))
	var owned: bool = bool(item.get("owned", false))
	for state: StringName in [&"normal", &"hover", &"focus", &"pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.055, 0.038, 0.13, 0.68)
		style.border_color = (
			accent.lightened(0.20)
			if state in [&"hover", &"focus"]
			else Color(accent, 0.66)
		)
		style.set_border_width_all(2 if state in [&"hover", &"focus"] else 1)
		style.set_corner_radius_all(9)
		style.content_margin_left = 14.0
		button.add_theme_stylebox_override(state, style)
	button.add_theme_color_override(
		"font_color", accent if owned else Color("8b91a2")
	)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_focus_color", Color.WHITE)


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


func _apply_responsive_layout() -> void:
	if _window == null:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var available_width: float = maxf(1.0, viewport_size.x - 36.0)
	var available_height: float = maxf(1.0, viewport_size.y - 36.0)
	_window.custom_minimum_size = Vector2(
		minf(1480.0, available_width),
		minf(720.0, available_height)
	)
	var compact_height: bool = viewport_size.y <= 720.0
	if _preview != null:
		_preview.custom_minimum_size = (
			Vector2(190.0, 82.0)
			if compact_height
			else Vector2(250.0, 250.0)
		)
	_equip_button.custom_minimum_size.y = 38.0 if compact_height else 52.0
	_trade_button.custom_minimum_size.y = 34.0 if compact_height else 44.0
	_trade_confirm_button.custom_minimum_size.y = 34.0 if compact_height else 44.0
	for target_button_variant: Variant in _skin_target_buttons.values():
		var target_button := target_button_variant as Button
		target_button.custom_minimum_size.y = 28.0 if compact_height else 0.0
	_skin_color_selector.custom_minimum_size.y = 30.0 if compact_height else 36.0
	_team_primary_color_selector.custom_minimum_size.y = 30.0 if compact_height else 36.0
	_goal_fx_color_selector.custom_minimum_size.y = 30.0 if compact_height else 36.0
	_trade_hint.add_theme_font_size_override("font_size", 10 if compact_height else 12)
	var controller_hint := find_child("ControllerHint", true, false) as Label
	if controller_hint != null:
		controller_hint.visible = viewport_size.y > 720.0
	_item_grid.columns = 1 if viewport_size.x < 1120.0 else 2
	_position_close_button.call_deferred()
	_wire_controller_focus.call_deferred()
