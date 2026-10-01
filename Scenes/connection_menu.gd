extends Control


const SETTINGS_PATH: String = "user://player_settings.cfg"
const OPTIONS_MENU_VERTICAL_OFFSET: float = -105.0
const DIRECTION_INDICATOR_SETTING: StringName = (
	&"gameplay/show_direction_indicator"
)
const BALL_STYLE_THEODORE: StringName = &"theodore"
const BALL_STYLE_CLASSIC: StringName = &"classic"
const BALL_APPEARANCE_BUTTON_SIZE := Vector2(88.0, 88.0)
const BALL_APPEARANCE_ICON_SIZE: int = 68
const CONTROLLER_ICON: Texture2D = preload(
	"res://Assets/controller_gamepad.svg"
)
const MAIN_CARD_SINGLEPLAYER_ICON: Texture2D = preload(
	"res://theodoreball.png"
)
const MAIN_CARD_FREEPLAY_ICON: Texture2D = preload(
	"res://Characters/football.png"
)
const MAIN_CARD_LOOTBOX_ICON: Texture2D = preload(
	"res://Assets/lobby_lootbox_icon.svg"
)
const MAIN_CARD_LOCKER_ICON: Texture2D = preload(
	"res://Assets/lobby_locker_icon.svg"
)
const CONTROLLER_TEST_PANEL_SCRIPT: Script = preload(
	"res://Scenes/controller_test_panel.gd"
)
const LOCKER_MENU_SCRIPT: Script = preload("res://Scenes/locker_menu.gd")
const BATTLE_PASS_MENU_SCRIPT: Script = preload(
	"res://Scenes/battle_pass_menu.gd"
)
const MAIN_MENU_BACKDROP_SCRIPT: Script = preload(
	"res://Scenes/main_menu_backdrop.gd"
)
const GLOBAL_LEADERBOARD_DICTATOR_NAME: String = "Dictator Mbappe"
const GLOBAL_LEADERBOARD_DICTATOR_GOALS: int = 888888
const CONTROLLER_BINDINGS: Array[Dictionary] = [
	{
		"action": &"shoot",
		"label": "Shoot",
		"prefix": "shoot"
	},
	{
		"action": &"ability",
		"label": "Ability",
		"prefix": "ability"
	},
	{
		"action": &"soft_pass",
		"label": "Soft Pass",
		"prefix": "soft_pass"
	},
	{
		"action": &"request_pass",
		"label": "Request Pass",
		"prefix": "pass_request"
	},
	{
		"action": &"quick_chat",
		"label": "Quick Chat",
		"prefix": "quick_chat"
	},
	{
		"action": &"leaderboard",
		"label": "Leaderboard",
		"prefix": "leaderboard"
	}
]

@export var network_manager: NetworkManager
@export var match_manager: FootballMatchManager

@onready var controller_support := get_node(
	"/root/ControllerSupport"
) as FootballControllerSupport
@onready var menu_center: CenterContainer = $CenterContainer
@onready var local_host_button: Button = (
	$CenterContainer/VBoxContainer/LocalHostButton
)
@onready var career_stats_label: Label = (
	$CenterContainer/VBoxContainer/CareerStatsLabel
)
@onready var leaderboards_button: Button = _ensure_leaderboards_button()
@onready var local_join_button: Button = (
	$CenterContainer/VBoxContainer/LocalJoinButton
)
@onready var singleplayer_button: Button = _ensure_singleplayer_button()
@onready var multiplayer_button: Button = (
	$CenterContainer/VBoxContainer/MultiplayerButton
)
@onready var freeplay_button: Button = (
	$CenterContainer/VBoxContainer/FreeplayButton
)
@onready var options_button: Button = (
	$CenterContainer/VBoxContainer/OptionsButton
)
@onready var locker_button: Button = _ensure_locker_button()
@onready var battle_pass_button: Button = _ensure_battle_pass_button()
@onready var exit_button: Button = (
	$CenterContainer/VBoxContainer/ExitButton
)
@onready var options_panel: VBoxContainer = (
	$CenterContainer/VBoxContainer/OptionsPanel
)
@onready var multiplayer_panel: VBoxContainer = (
	$CenterContainer/VBoxContainer/MultiplayerPanel
)
@onready var lobby_name_edit: LineEdit = (
	$CenterContainer/VBoxContainer/MultiplayerPanel/LobbyNameEdit
)
@onready var create_lobby_button: Button = (
	$CenterContainer/VBoxContainer/MultiplayerPanel/CreateLobbyButton
)
@onready var lobby_visibility_option: OptionButton = (
	_ensure_lobby_visibility_option()
)
@onready var steam_game_mode_option: OptionButton = (
	_ensure_steam_game_mode_option()
)
@onready var lobby_count_label: Label = (
	$CenterContainer/VBoxContainer/MultiplayerPanel/BrowserHeader/LobbyCountLabel
)
@onready var refresh_lobbies_button: Button = (
	$CenterContainer/VBoxContainer/MultiplayerPanel/BrowserHeader/RefreshButton
)
@onready var lobby_list: VBoxContainer = (
	$CenterContainer/VBoxContainer/MultiplayerPanel/LobbyScroll/LobbyList
)
@onready var multiplayer_back_button: Button = (
	_ensure_multiplayer_back_button()
)
@onready var lobby_refresh_timer: Timer = (
	$CenterContainer/VBoxContainer/MultiplayerPanel/RefreshTimer
)
@onready var volume_slider: HSlider = (
	$CenterContainer/VBoxContainer/OptionsPanel/VolumeSlider
)
@onready var direction_indicator_toggle: CheckButton = (
	$CenterContainer/VBoxContainer/OptionsPanel/DirectionIndicatorToggle
)
@onready var fullscreen_toggle: CheckButton = (
	_ensure_fullscreen_toggle()
)
@onready var ball_appearance_picker: VBoxContainer = (
	_ensure_ball_appearance_picker()
)
@onready var bindings_mode_button: Button = (
	$CenterContainer/VBoxContainer/OptionsPanel/BindingsModeButton
)
@onready var ability_key_button: Button = (
	$CenterContainer/VBoxContainer/OptionsPanel/AbilityKeyButton
)
@onready var soft_pass_key_button: Button = (
	$CenterContainer/VBoxContainer/OptionsPanel/SoftPassKeyButton
)
@onready var pass_request_key_button: Button = (
	$CenterContainer/VBoxContainer/OptionsPanel/PassRequestKeyButton
)
@onready var quick_chat_key_button: Button = (
	$CenterContainer/VBoxContainer/OptionsPanel/QuickChatKeyButton
)
@onready var controller_status_label: Label = (
	$CenterContainer/VBoxContainer/OptionsPanel/ControllerStatusLabel
)
@onready var controller_prompt_style_button: Button = (
	$CenterContainer/VBoxContainer/OptionsPanel/ControllerPromptStyleButton
)
@onready var controller_bindings: GridContainer = (
	$CenterContainer/VBoxContainer/OptionsPanel/ControllerBindings
)
@onready var controller_shoot_button: Button = (
	$CenterContainer/VBoxContainer/OptionsPanel/ControllerBindings/ShootButton
)
@onready var controller_ability_button: Button = (
	$CenterContainer/VBoxContainer/OptionsPanel/ControllerBindings/AbilityButton
)
@onready var controller_soft_pass_button: Button = (
	$CenterContainer/VBoxContainer/OptionsPanel/ControllerBindings/SoftPassButton
)
@onready var controller_pass_request_button: Button = (
	$CenterContainer/VBoxContainer/OptionsPanel/ControllerBindings/PassRequestButton
)
@onready var controller_quick_chat_button: Button = (
	$CenterContainer/VBoxContainer/OptionsPanel/ControllerBindings/QuickChatButton
)
@onready var controller_leaderboard_button: Button = (
	$CenterContainer/VBoxContainer/OptionsPanel/ControllerBindings/LeaderboardButton
)
@onready var movement_stick_button: Button = (
	$CenterContainer/VBoxContainer/OptionsPanel/ControllerBindings/MovementStickButton
)
@onready var reset_controller_button: Button = (
	$CenterContainer/VBoxContainer/OptionsPanel/ControllerBindings/ResetControllerButton
)
@onready var options_back_button: Button = (
	$CenterContainer/VBoxContainer/OptionsPanel/BackButton
)
@onready var connection_label: Label = (
	$CenterContainer/VBoxContainer/ConnectionLabel
)
@onready var menu_content: VBoxContainer = (
	$CenterContainer/VBoxContainer
)
@onready var toggle_menu_button: Button = $ToggleMenuButton

var _waiting_for_key_action: StringName = &""
var _steam_mode_popup: PopupPanel
var _steam_standard_button: Button
var _steam_draft_button: Button
var _steam_ladder_button: Button
var _steam_ladder_fresh_button: Button
var _steam_ranked_size_buttons: Array[Button] = []
var _singleplayer_popup: PopupPanel
var _ranked_info_popup: PopupPanel
var _ranked_info_button: Button
var _ranked_info_close_button: Button
var _singleplayer_custom_button: Button
var _singleplayer_rank_label: RichTextLabel
var _singleplayer_rank_snapshot: Dictionary = {}
var _ranked_glint_nodes: Array = []
var _ranked_glint_accum: float = 0.0
var _singleplayer_queue_label: Label
var _singleplayer_size_buttons: Array[Button] = []
var _waiting_for_controller_action: StringName = &""
var _controller_rebind_button: Button
var _show_controller_bindings: bool = false
var _settings := ConfigFile.new()
var _ball_appearance_buttons: Dictionary = {}
var _ball_appearance_button_group: ButtonGroup
var _selected_ball_appearance_style: StringName = BALL_STYLE_THEODORE
var _options_transition: Tween
var _multiplayer_transition: Tween
var _menu_controls_transition: Tween
var _main_buttons_hidden: bool = false
var _multiplayer_open: bool = false
var _lobby_join_buttons: Array[Button] = []
var _career_goals: int = 0
var _career_saves: int = 0
var _controller_test_panel
var _locker_menu: FootballLockerMenu
var _battle_pass_menu: FootballBattlePassMenu
var _battle_pass_match_in_progress: bool = false
var _main_dashboard: VBoxContainer
var _play_dashboard_panel: PanelContainer
var _club_dashboard_panel: PanelContainer
var _main_header_strip: HBoxContainer
var _mode_shelf: HBoxContainer
var _secondary_mode_grid: GridContainer
var _utility_row: HBoxContainer
var _leaderboards_popup: PopupPanel
var _leaderboards_stats_label: Label
var _leaderboards_status_label: Label
var _leaderboards_category_label: Label
var _leaderboards_rows: VBoxContainer
var _leaderboards_scroll: ScrollContainer
var _leaderboards_mmr_button: Button
var _leaderboards_goals_button: Button
var _leaderboards_saves_button: Button
var _leaderboards_refresh_button: Button
var _leaderboards_back_button: Button
var _leaderboards_active_category: StringName = &"pve_mmr"
var _leaderboards_entries: Dictionary = {
	&"pve_mmr": [],
	&"goals": [],
	&"saves": [],
}
var _leaderboards_statuses: Dictionary = {
	&"pve_mmr": "STEAM OFFLINE",
	&"goals": "STEAM OFFLINE",
	&"saves": "STEAM OFFLINE",
}
var _leaderboards_steam_manager: Node
var _leaderboards_value_header_label: Label
var _leaderboards_scope_note: Label


func _ensure_leaderboards_button() -> Button:
	var main_menu := get_node_or_null("CenterContainer/VBoxContainer") as VBoxContainer
	if main_menu == null:
		return null
	var existing := main_menu.get_node_or_null("LeaderboardsButton") as Button
	if existing != null:
		return existing
	var button := Button.new()
	button.name = "LeaderboardsButton"
	button.text = "LEADERBOARDS"
	button.custom_minimum_size.y = 54.0
	main_menu.add_child(button)
	var options_node := main_menu.get_node_or_null("OptionsButton") as Button
	if options_node != null:
		main_menu.move_child(button, options_node.get_index())
	return button


func _ensure_singleplayer_button() -> Button:
	var main_menu := get_node_or_null(
		"CenterContainer/VBoxContainer"
	) as VBoxContainer
	if main_menu == null:
		push_error("Main menu container is missing.")
		return null
	var existing := main_menu.get_node_or_null(
		"SingleplayerButton"
	) as Button
	if existing != null:
		return existing
	var button := Button.new()
	button.name = "SingleplayerButton"
	button.text = "SINGLEPLAYER"
	button.custom_minimum_size.y = 60.0
	main_menu.add_child(button)
	main_menu.move_child(button, local_host_button.get_index())
	return button


func _ensure_locker_button() -> Button:
	var main_menu := get_node_or_null(
		"CenterContainer/VBoxContainer"
	) as VBoxContainer
	if main_menu == null:
		push_error("Main menu container is missing; Locker button cannot be created.")
		return null
	var existing := main_menu.get_node_or_null("LockerButton") as Button
	if existing != null:
		return existing
	var button := Button.new()
	button.name = "LockerButton"
	button.text = "Locker"
	button.custom_minimum_size.y = 60.0
	main_menu.add_child(button)
	main_menu.move_child(button, options_button.get_index())
	return button


func _ensure_battle_pass_button() -> Button:
	var main_menu := get_node_or_null(
		"CenterContainer/VBoxContainer"
	) as VBoxContainer
	if main_menu == null:
		push_error("Main menu container is missing; Lootbox button cannot be created.")
		return null
	var existing := main_menu.get_node_or_null("BattlePassButton") as Button
	if existing != null:
		return existing
	var button := Button.new()
	button.name = "BattlePassButton"
	button.text = "Lootbox"
	button.custom_minimum_size.y = 60.0
	main_menu.add_child(button)
	main_menu.move_child(button, locker_button.get_index())
	return button


func _ensure_fullscreen_toggle() -> CheckButton:
	var options := get_node_or_null(
		"CenterContainer/VBoxContainer/OptionsPanel"
	) as VBoxContainer
	if options == null:
		push_error("Options panel is missing.")
		return null

	var toggle := options.get_node_or_null("FullscreenToggle") as CheckButton
	if toggle == null:
		toggle = CheckButton.new()
		toggle.name = "FullscreenToggle"
		options.add_child(toggle)

	toggle.text = "Fullscreen (F11)"
	toggle.tooltip_text = (
		"Switch between fullscreen and windowed mode. F11 does the same thing."
	)
	var direction_toggle := options.get_node_or_null(
		"DirectionIndicatorToggle"
	) as CheckButton
	if direction_toggle != null:
		options.move_child(
			toggle,
			mini(direction_toggle.get_index() + 1, options.get_child_count() - 1)
		)
	return toggle


func _ensure_ball_appearance_picker() -> VBoxContainer:
	var options := get_node_or_null(
		"CenterContainer/VBoxContainer/OptionsPanel"
	) as VBoxContainer
	if options == null:
		push_error("Options panel is missing.")
		return null

	# The old text dropdown was created at runtime. Remove it if an older scene
	# happens to contain one so only the visual picker consumes layout space.
	var legacy_option := options.get_node_or_null("BallAppearanceOption")
	if legacy_option != null:
		legacy_option.free()

	var picker := options.get_node_or_null("BallAppearancePicker") as VBoxContainer
	if picker == null:
		picker = VBoxContainer.new()
		picker.name = "BallAppearancePicker"
		picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		picker.add_theme_constant_override("separation", 6)
		options.add_child(picker)

	for child: Node in picker.get_children():
		child.free()

	var title := Label.new()
	title.name = "Title"
	title.text = "Ball Appearance"
	title.add_theme_font_size_override("font_size", 18)
	picker.add_child(title)

	var choices := HFlowContainer.new()
	choices.name = "Choices"
	choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choices.add_theme_constant_override("h_separation", 10)
	choices.add_theme_constant_override("v_separation", 10)
	picker.add_child(choices)

	_ball_appearance_buttons.clear()
	_ball_appearance_button_group = ButtonGroup.new()
	for variant: Dictionary in FootballBall.get_ball_appearance_variants():
		var style := StringName(variant.get("style", BALL_STYLE_THEODORE))
		var display_name := str(variant.get("display_name", style))
		var texture := variant.get("texture") as Texture2D
		if texture == null:
			continue
		var button := Button.new()
		button.name = "Ball_%s" % str(style).capitalize().replace(" ", "")
		button.custom_minimum_size = BALL_APPEARANCE_BUTTON_SIZE
		button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		button.toggle_mode = true
		button.button_group = _ball_appearance_button_group
		button.icon = texture
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", BALL_APPEARANCE_ICON_SIZE)
		button.tooltip_text = display_name
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(_on_ball_appearance_button_pressed.bind(style))
		choices.add_child(button)
		_ball_appearance_buttons[style] = button

	# HFlowContainer's automatic focus search can jump diagonally into another
	# row when a wrapped row has fewer buttons. Rebuild explicit horizontal
	# neighbors whenever the picker is resized so D-pad left/right always stays
	# on the current visual row, including the short bottom row.
	choices.resized.connect(_queue_ball_appearance_focus_refresh)

	picker.tooltip_text = (
		"Choose the ball by its appearance. This changes only how the ball is "
		+ "rendered on your own screen; physics and other players are unchanged."
	)
	var fullscreen := options.get_node_or_null("FullscreenToggle") as CheckButton
	if fullscreen != null:
		options.move_child(
		picker,
		mini(fullscreen.get_index() + 1, options.get_child_count() - 1)
		)
	_refresh_ball_appearance_picker()
	_queue_ball_appearance_focus_refresh()
	return picker


func _queue_ball_appearance_focus_refresh() -> void:
	# Wait until the HFlowContainer has completed its wrap/layout pass before
	# reading button positions. Multiple deferred refreshes are harmless and
	# keep navigation correct after resolution/fullscreen layout changes.
	_configure_ball_appearance_focus_neighbors.call_deferred()


func _configure_ball_appearance_focus_neighbors() -> void:
	if ball_appearance_picker == null or not is_instance_valid(ball_appearance_picker):
		return
	var choices := ball_appearance_picker.get_node_or_null("Choices") as HFlowContainer
	if choices == null:
		return

	var rows: Array = []
	var current_row: Array[Button] = []
	var current_y: float = 0.0
	const ROW_TOLERANCE: float = 2.0

	for child: Node in choices.get_children():
		var button := child as Button
		if button == null or not button.visible:
			continue
		var button_y := button.position.y
		if current_row.is_empty():
			current_y = button_y
		elif absf(button_y - current_y) > ROW_TOLERANCE:
			rows.append(current_row)
			current_row = []
			current_y = button_y
		current_row.append(button)
	if not current_row.is_empty():
		rows.append(current_row)

	for row_variant: Variant in rows:
		var row: Array = row_variant
		if row.is_empty():
			continue
		for index: int in range(row.size()):
			var button := row[index] as Button
			if button == null:
				continue
			var left_button := row[wrapi(index - 1, 0, row.size())] as Button
			var right_button := row[wrapi(index + 1, 0, row.size())] as Button
			_set_main_focus_neighbor(button, SIDE_LEFT, left_button)
			_set_main_focus_neighbor(button, SIDE_RIGHT, right_button)


func _ensure_lobby_visibility_option() -> OptionButton:
	var panel := get_node_or_null(
		"CenterContainer/VBoxContainer/MultiplayerPanel"
	) as VBoxContainer
	if panel == null:
		push_error("Steam multiplayer panel is missing.")
		return null

	var option := panel.get_node_or_null("LobbyVisibility") as OptionButton
	if option == null:
		option = OptionButton.new()
		option.name = "LobbyVisibility"
		panel.add_child(option)
	option.clear()
	option.add_item("Public — appears in browser", NetworkManager.STEAM_LOBBY_PUBLIC)
	option.add_item(
		"Friends Only — friends/invites",
		NetworkManager.STEAM_LOBBY_FRIENDS_ONLY
	)
	option.add_item("Private — invite only", NetworkManager.STEAM_LOBBY_PRIVATE)
	option.select(0)
	option.tooltip_text = (
		"Public lobbies appear in the browser. Friends Only and Private "
		+ "lobbies are joined through Steam friends/invites."
	)
	var name_edit := panel.get_node_or_null("LobbyNameEdit") as LineEdit
	if name_edit != null:
		panel.move_child(
			option,
			mini(name_edit.get_index() + 1, panel.get_child_count() - 1)
		)
	return option


func _ensure_steam_game_mode_option() -> OptionButton:
	var panel := get_node_or_null(
		"CenterContainer/VBoxContainer/MultiplayerPanel"
	) as VBoxContainer
	if panel == null:
		push_error("Steam multiplayer panel is missing.")
		return null
	var option := panel.get_node_or_null("SteamGameMode") as OptionButton
	if option == null:
		option = OptionButton.new()
		option.name = "SteamGameMode"
		panel.add_child(option)
	option.clear()
	option.add_item("Standard Match", NetworkManager.STEAM_SESSION_STANDARD)
	option.add_item("Draft", NetworkManager.STEAM_SESSION_DRAFT)
	option.add_item("Seasonal PvE Ladder", NetworkManager.STEAM_SESSION_LADDER)
	option.add_item("Co-op PvE Ranked", NetworkManager.STEAM_SESSION_PVE_RANKED)
	option.select(0)
	option.tooltip_text = (
		"Ladder is a cooperative CPU run. A loss restarts at rung one."
	)
	# The choice belongs to the Create Lobby action, not the browser form.
	# Keep this node as a compatibility source for old scenes/tests, but do not
	# consume layout space before the host actually asks to create a lobby.
	option.hide()
	var visibility := panel.get_node_or_null("LobbyVisibility") as OptionButton
	if visibility != null:
		panel.move_child(
			option,
			mini(visibility.get_index() + 1, panel.get_child_count() - 1)
		)
	return option


func _ensure_multiplayer_back_button() -> Button:
	var panel := get_node_or_null(
		"CenterContainer/VBoxContainer/MultiplayerPanel"
	) as VBoxContainer
	if panel == null:
		push_error("Steam multiplayer panel is missing.")
		return null

	var button := panel.get_node_or_null("BackButton") as Button
	if button == null:
		button = Button.new()
		button.name = "BackButton"
		panel.add_child(button)

	button.text = "←  BACK TO MAIN MENU"
	button.tooltip_text = (
		"Cancel the current Steam action and return to the main menu."
	)
	button.custom_minimum_size = Vector2(0.0, 48.0)
	button.add_theme_font_size_override("font_size", 19)

	# Keep it above the lobby browser so it can never be clipped below
	# the scroll area on smaller resolutions.
	panel.move_child(button, mini(2, panel.get_child_count() - 1))
	return button


func _ready() -> void:
	if (
		network_manager == null
		or match_manager == null
		or multiplayer_back_button == null
		or lobby_visibility_option == null
		or steam_game_mode_option == null
		or fullscreen_toggle == null
		or ball_appearance_picker == null
	):
		push_error("Connection menu references are incomplete.")
		return

	_ensure_options_scroll_layout()
	_build_main_menu_dashboard()
	_build_leaderboards_popup()
	_build_singleplayer_popup()
	_controller_test_panel = CONTROLLER_TEST_PANEL_SCRIPT.new()
	_controller_test_panel.controller_support = controller_support
	add_child(_controller_test_panel)
	_controller_test_panel.hide()
	_controller_test_panel.closed.connect(_on_controller_test_closed)
	_locker_menu = LOCKER_MENU_SCRIPT.new() as FootballLockerMenu
	_locker_menu.name = "LockerMenu"
	add_child(_locker_menu)
	_locker_menu.closed.connect(_on_locker_closed)
	_battle_pass_menu = BATTLE_PASS_MENU_SCRIPT.new() as FootballBattlePassMenu
	_battle_pass_menu.name = "BattlePassMenu"
	add_child(_battle_pass_menu)
	_battle_pass_menu.closed.connect(_on_battle_pass_closed)
	if OS.has_feature("web"):
		_configure_mobile_web_menu()
	else:
		_build_steam_mode_popup()

	singleplayer_button.pressed.connect(_open_singleplayer_popup)
	multiplayer_button.pressed.connect(
		func() -> void:
			_set_multiplayer_open(true)
	)
	create_lobby_button.pressed.connect(_create_steam_lobby)
	refresh_lobbies_button.pressed.connect(_refresh_steam_lobbies)
	multiplayer_back_button.pressed.connect(
		_return_to_main_menu_from_multiplayer
	)
	lobby_refresh_timer.timeout.connect(_refresh_steam_lobbies)
	freeplay_button.pressed.connect(
		network_manager.start_freeplay
	)
	options_button.pressed.connect(
		func() -> void:
			_set_options_open(true)
	)
	leaderboards_button.pressed.connect(_open_leaderboards)
	locker_button.pressed.connect(_open_locker)
	battle_pass_button.pressed.connect(_open_battle_pass)
	exit_button.pressed.connect(
		func() -> void:
			get_tree().quit()
	)
	options_back_button.pressed.connect(
		func() -> void:
			_set_options_open(false)
	)
	toggle_menu_button.pressed.connect(_toggle_main_buttons)
	volume_slider.value_changed.connect(
		_on_volume_changed
	)
	direction_indicator_toggle.toggled.connect(
		_on_direction_indicator_toggled
	)
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	var fullscreen_manager := get_node_or_null("/root/FullscreenManager")
	if (
		fullscreen_manager != null
		and fullscreen_manager.has_signal("fullscreen_changed")
		and not fullscreen_manager.is_connected(
			"fullscreen_changed", _on_fullscreen_changed
		)
	):
		fullscreen_manager.connect("fullscreen_changed", _on_fullscreen_changed)
	ability_key_button.pressed.connect(
		_begin_key_rebind.bind(&"ability", ability_key_button)
	)
	soft_pass_key_button.pressed.connect(
		_begin_key_rebind.bind(&"soft_pass", soft_pass_key_button)
	)
	pass_request_key_button.pressed.connect(
		_begin_key_rebind.bind(
			&"request_pass",
			pass_request_key_button
		)
	)
	quick_chat_key_button.pressed.connect(
		_begin_key_rebind.bind(
			&"quick_chat",
			quick_chat_key_button
		)
	)
	bindings_mode_button.pressed.connect(_toggle_bindings_mode)
	controller_prompt_style_button.pressed.connect(_open_controller_test_panel)
	controller_prompt_style_button.hide()
	var controller_buttons: Array[Button] = [
		controller_shoot_button,
		controller_ability_button,
		controller_soft_pass_button,
		controller_pass_request_button,
		controller_quick_chat_button,
		controller_leaderboard_button
	]
	for index in range(CONTROLLER_BINDINGS.size()):
		var binding := CONTROLLER_BINDINGS[index]
		controller_buttons[index].pressed.connect(
			_begin_controller_rebind.bind(
				StringName(binding["action"]),
				controller_buttons[index]
			)
		)
	movement_stick_button.pressed.connect(_toggle_movement_stick)
	reset_controller_button.pressed.connect(_reset_controller_bindings)
	controller_support.input_method_changed.connect(
		_on_input_method_changed
	)
	controller_support.bindings_changed.connect(
		_update_controller_binding_texts
	)
	controller_support.controller_list_changed.connect(
		_update_controller_binding_texts
	)
	network_manager.connection_changed.connect(
		_on_connection_changed
	)
	network_manager.session_started.connect(_on_session_started)
	network_manager.session_ended.connect(_on_session_ended)
	network_manager.lobby_search_started.connect(
		_on_lobby_search_started
	)
	network_manager.lobby_list_updated.connect(
		_on_lobby_list_updated
	)
	match_manager.player_stat_earned.connect(
		_on_player_stat_earned
	)
	match_manager.match_started.connect(_on_battle_pass_match_started)
	match_manager.match_results_ready.connect(_on_battle_pass_match_results)
	match_manager.match_cancelled.connect(_on_battle_pass_match_cancelled)
	match_manager.singleplayer_ranked_state_changed.connect(
		_update_singleplayer_rank_summary
	)
	MenuStyler.apply_premium_design(self, &"menu")
	# Apply the intentional per-action colors after the shared premium pass so
	# the dashboard buttons do not all fall back to the generic white accent.
	_apply_menu_styling()
	MenuStyler.install_click_sounds(self)
	_apply_main_dashboard_styles()
	_refresh_steam_connection_status()
	UIMotion.prepare_buttons(self)
	_load_settings()
	_set_options_open(false, false)
	_set_multiplayer_open(false, false)
	_prepare_lobby_browser()
	_apply_responsive_menu_layout()
	# Reassert Web-only visibility/text after settings and shared styling have run.
	if OS.has_feature("web"):
		_configure_mobile_web_menu()
	get_viewport().size_changed.connect(_apply_responsive_menu_layout)
	call_deferred("_animate_initial_entrance")


func _build_main_menu_dashboard() -> void:
	if menu_content == null or _main_dashboard != null:
		return
	var backdrop := MAIN_MENU_BACKDROP_SCRIPT.new() as Control
	backdrop.name = "MainMenuBackdrop"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	move_child(backdrop, 0)

	_build_main_menu_header()

	_main_dashboard = VBoxContainer.new()
	_main_dashboard.name = "MainDashboard"
	_main_dashboard.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_main_dashboard.add_theme_constant_override("separation", 10)
	menu_content.add_child(_main_dashboard)
	menu_content.move_child(
		_main_dashboard,
		mini(_main_header_strip.get_index() + 1, menu_content.get_child_count() - 1)
	)

	var section_header := HBoxContainer.new()
	section_header.name = "PlaySectionHeader"
	section_header.add_theme_constant_override("separation", 12)
	_main_dashboard.add_child(section_header)
	var section_title := Label.new()
	section_title.name = "PlaySectionTitle"
	section_title.text = "PLAY"
	section_title.add_theme_font_size_override("font_size", 26)
	section_title.add_theme_color_override("font_color", Color(0.94, 0.97, 1.0))
	section_header.add_child(section_title)
	var header_spacer := Control.new()
	header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section_header.add_child(header_spacer)
	var section_hint := Label.new()
	section_hint.name = "PlaySectionMeta"
	section_hint.text = "CHOOSE YOUR MODE"
	section_hint.add_theme_font_size_override("font_size", 12)
	section_hint.add_theme_color_override("font_color", MenuStyler.MUTED_TEXT)
	section_header.add_child(section_hint)

	_mode_shelf = HBoxContainer.new()
	_mode_shelf.name = "ModeShelf"
	_mode_shelf.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mode_shelf.add_theme_constant_override("separation", 14)
	_main_dashboard.add_child(_mode_shelf)

	_play_dashboard_panel = PanelContainer.new()
	_play_dashboard_panel.name = "PlayPanel"
	_play_dashboard_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_play_dashboard_panel.size_flags_stretch_ratio = 0.95
	_mode_shelf.add_child(_play_dashboard_panel)
	var featured_margin := MarginContainer.new()
	featured_margin.name = "FeaturedMargin"
	featured_margin.add_theme_constant_override("margin_left", 12)
	featured_margin.add_theme_constant_override("margin_right", 12)
	featured_margin.add_theme_constant_override("margin_top", 12)
	featured_margin.add_theme_constant_override("margin_bottom", 12)
	_play_dashboard_panel.add_child(featured_margin)
	var featured_column := VBoxContainer.new()
	featured_column.name = "DashboardContent"
	featured_column.add_theme_constant_override("separation", 7)
	featured_margin.add_child(featured_column)
	var featured_badge := Label.new()
	featured_badge.name = "FeaturedBadge"
	featured_badge.text = "FEATURED"
	featured_badge.add_theme_font_size_override("font_size", 13)
	featured_badge.add_theme_color_override("font_color", Color("f4c95d"))
	featured_column.add_child(featured_badge)
	var featured_copy := Label.new()
	featured_copy.name = "FeaturedCopy"
	featured_copy.text = "CLIMB THE PVE LADDER OR BUILD A CUSTOM MATCH"
	featured_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	featured_copy.add_theme_font_size_override("font_size", 12)
	featured_copy.add_theme_color_override("font_color", MenuStyler.MUTED_TEXT)
	featured_column.add_child(featured_copy)
	singleplayer_button.reparent(featured_column)
	singleplayer_button.size_flags_vertical = Control.SIZE_EXPAND_FILL

	_club_dashboard_panel = PanelContainer.new()
	_club_dashboard_panel.name = "ClubhousePanel"
	_club_dashboard_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_club_dashboard_panel.size_flags_stretch_ratio = 1.35
	_mode_shelf.add_child(_club_dashboard_panel)
	var secondary_margin := MarginContainer.new()
	secondary_margin.name = "SecondaryMargin"
	secondary_margin.add_theme_constant_override("margin_left", 0)
	secondary_margin.add_theme_constant_override("margin_right", 0)
	secondary_margin.add_theme_constant_override("margin_top", 0)
	secondary_margin.add_theme_constant_override("margin_bottom", 0)
	_club_dashboard_panel.add_child(secondary_margin)
	_secondary_mode_grid = GridContainer.new()
	_secondary_mode_grid.name = "ModeCardGrid"
	_secondary_mode_grid.columns = 2
	_secondary_mode_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_secondary_mode_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_secondary_mode_grid.add_theme_constant_override("h_separation", 10)
	_secondary_mode_grid.add_theme_constant_override("v_separation", 10)
	secondary_margin.add_child(_secondary_mode_grid)

	local_host_button.hide()
	local_join_button.hide()
	multiplayer_button.reparent(_secondary_mode_grid)
	freeplay_button.reparent(_secondary_mode_grid)
	battle_pass_button.reparent(_secondary_mode_grid)
	locker_button.reparent(_secondary_mode_grid)
	for card: Button in [
		multiplayer_button,
		freeplay_button,
		battle_pass_button,
		locker_button,
	]:
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.size_flags_vertical = Control.SIZE_EXPAND_FILL

	_utility_row = HBoxContainer.new()
	_utility_row.name = "UtilityRow"
	_utility_row.add_theme_constant_override("separation", 8)
	_main_dashboard.add_child(_utility_row)
	leaderboards_button.reparent(_utility_row)
	options_button.reparent(_utility_row)
	exit_button.reparent(_utility_row)
	for utility_button: Button in [
		leaderboards_button,
		options_button,
		exit_button,
	]:
		utility_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	connection_label.reparent(_main_dashboard)
	connection_label.name = "ConnectionLabel"
	connection_label.custom_minimum_size.y = 32.0
	connection_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	_decorate_main_mode_card(
		singleplayer_button,
		"SINGLEPLAYER",
		"PvE RANKED  •  CUSTOM  •  1v1–6v6",
		MAIN_CARD_SINGLEPLAYER_ICON,
		Color(0.30, 0.88, 0.57),
		true
	)
	_decorate_main_mode_card(
		multiplayer_button,
		"MULTIPLAYER",
		"STEAM LOBBIES",
		CONTROLLER_ICON,
		Color(0.32, 0.57, 0.96)
	)
	_decorate_main_mode_card(
		freeplay_button,
		"FREEPLAY",
		"TRAINING GROUND",
		MAIN_CARD_FREEPLAY_ICON,
		Color(0.32, 0.82, 0.94)
	)
	_decorate_main_mode_card(
		battle_pass_button,
		"LOOTBOX",
		"REWARDS & DROPS",
		MAIN_CARD_LOOTBOX_ICON,
		Color(0.91, 0.54, 0.30)
	)
	_decorate_main_mode_card(
		locker_button,
		"LOCKER",
		"COSMETICS & LOADOUT",
		MAIN_CARD_LOCKER_ICON,
		Color(0.75, 0.48, 0.92)
	)
	leaderboards_button.text = "LEADERBOARDS"
	options_button.text = "OPTIONS"
	exit_button.text = "EXIT"
	_wire_main_menu_focus()


func _build_main_menu_header() -> void:
	if _main_header_strip != null:
		return
	var title := menu_content.get_node_or_null("MenuTitle") as Label
	var chapter := menu_content.get_node_or_null("ChapterSubtitle") as Label
	_main_header_strip = HBoxContainer.new()
	_main_header_strip.name = "MainHeaderStrip"
	_main_header_strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_main_header_strip.add_theme_constant_override("separation", 18)
	menu_content.add_child(_main_header_strip)
	menu_content.move_child(_main_header_strip, 0)
	var brand_column := VBoxContainer.new()
	brand_column.name = "BrandColumn"
	brand_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand_column.add_theme_constant_override("separation", -2)
	_main_header_strip.add_child(brand_column)
	if title != null:
		title.reparent(brand_column)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	if chapter != null:
		chapter.reparent(brand_column)
		chapter.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	career_stats_label.reparent(_main_header_strip)
	career_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	career_stats_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	career_stats_label.size_flags_horizontal = Control.SIZE_SHRINK_END


func _decorate_main_mode_card(
	button: Button,
	title_text: String,
	subtitle_text: String,
	icon_texture: Texture2D,
	accent: Color,
	featured: bool = false
) -> void:
	if button == null:
		return
	var old_content := button.get_node_or_null("CardContent")
	if old_content != null:
		old_content.queue_free()
	button.text = ""
	button.clip_contents = true
	button.custom_minimum_size.y = 252.0 if featured else 118.0
	button.set_meta("main_card_accent", accent)
	button.set_meta("main_card_featured", featured)
	var margin := MarginContainer.new()
	margin.name = "CardContent"
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20 if featured else 14)
	margin.add_theme_constant_override("margin_right", 20 if featured else 14)
	margin.add_theme_constant_override("margin_top", 16 if featured else 12)
	margin.add_theme_constant_override("margin_bottom", 16 if featured else 12)
	button.add_child(margin)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 16 if featured else 11)
	margin.add_child(row)
	var icon := TextureRect.new()
	icon.name = "CardIcon"
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = icon_texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var icon_size := 92.0 if featured else 58.0
	icon.custom_minimum_size = Vector2(icon_size, icon_size)
	row.add_child(icon)
	var copy := VBoxContainer.new()
	copy.name = "CardCopy"
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 4)
	row.add_child(copy)
	var title := Label.new()
	title.name = "CardTitle"
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.text = title_text
	title.add_theme_font_size_override("font_size", 29 if featured else 20)
	title.add_theme_color_override("font_color", Color(0.98, 0.99, 1.0))
	copy.add_child(title)
	var subtitle := Label.new()
	subtitle.name = "CardSubtitle"
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	subtitle.text = subtitle_text
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_size_override("font_size", 13 if featured else 11)
	subtitle.add_theme_color_override("font_color", Color(accent.r, accent.g, accent.b, 0.92))
	copy.add_child(subtitle)


func _create_dashboard_panel(
	panel_name: String,
	title_text: String,
	subtitle_text: String
) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = panel_name
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.name = "DashboardContent"
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)
	var title := Label.new()
	title.name = "PanelTitle"
	title.text = title_text
	title.add_theme_font_size_override("font_size", 25)
	column.add_child(title)
	var subtitle := Label.new()
	subtitle.name = "PanelSubtitle"
	subtitle.text = subtitle_text
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", MenuStyler.MUTED_TEXT)
	column.add_child(subtitle)
	var separator := HSeparator.new()
	column.add_child(separator)
	return panel


func _wire_main_menu_focus() -> void:
	_set_main_focus_neighbor(singleplayer_button, SIDE_RIGHT, multiplayer_button)
	_set_main_focus_neighbor(singleplayer_button, SIDE_BOTTOM, leaderboards_button)
	_set_main_focus_neighbor(multiplayer_button, SIDE_LEFT, singleplayer_button)
	_set_main_focus_neighbor(multiplayer_button, SIDE_RIGHT, freeplay_button)
	_set_main_focus_neighbor(multiplayer_button, SIDE_BOTTOM, battle_pass_button)
	_set_main_focus_neighbor(freeplay_button, SIDE_LEFT, multiplayer_button)
	_set_main_focus_neighbor(freeplay_button, SIDE_BOTTOM, locker_button)
	_set_main_focus_neighbor(battle_pass_button, SIDE_TOP, multiplayer_button)
	_set_main_focus_neighbor(battle_pass_button, SIDE_LEFT, singleplayer_button)
	_set_main_focus_neighbor(battle_pass_button, SIDE_RIGHT, locker_button)
	_set_main_focus_neighbor(battle_pass_button, SIDE_BOTTOM, leaderboards_button)
	_set_main_focus_neighbor(locker_button, SIDE_TOP, freeplay_button)
	_set_main_focus_neighbor(locker_button, SIDE_LEFT, battle_pass_button)
	_set_main_focus_neighbor(locker_button, SIDE_BOTTOM, exit_button)
	_set_main_focus_neighbor(leaderboards_button, SIDE_TOP, singleplayer_button)
	_set_main_focus_neighbor(leaderboards_button, SIDE_RIGHT, options_button)
	_set_main_focus_neighbor(options_button, SIDE_LEFT, leaderboards_button)
	_set_main_focus_neighbor(options_button, SIDE_RIGHT, exit_button)
	_set_main_focus_neighbor(options_button, SIDE_TOP, battle_pass_button)
	_set_main_focus_neighbor(exit_button, SIDE_LEFT, options_button)
	_set_main_focus_neighbor(exit_button, SIDE_TOP, locker_button)


func _set_main_focus_neighbor(source: Control, side: int, target: Control) -> void:
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


func _apply_main_dashboard_styles() -> void:
	if _play_dashboard_panel != null:
		var featured_panel_style := StyleBoxFlat.new()
		featured_panel_style.bg_color = Color(0.018, 0.032, 0.036, 0.90)
		featured_panel_style.border_color = Color(0.30, 0.88, 0.57, 0.42)
		featured_panel_style.set_border_width_all(1)
		featured_panel_style.set_corner_radius_all(15)
		featured_panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.46)
		featured_panel_style.shadow_size = 10
		_play_dashboard_panel.add_theme_stylebox_override("panel", featured_panel_style)
	if _club_dashboard_panel != null:
		var secondary_panel_style := StyleBoxFlat.new()
		secondary_panel_style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
		secondary_panel_style.border_color = Color(0.0, 0.0, 0.0, 0.0)
		secondary_panel_style.set_border_width_all(0)
		_club_dashboard_panel.add_theme_stylebox_override("panel", secondary_panel_style)

	for card: Button in [
		singleplayer_button,
		multiplayer_button,
		freeplay_button,
		battle_pass_button,
		locker_button,
	]:
		_apply_main_mode_card_style(card)

	for utility_button: Button in [leaderboards_button, options_button, exit_button]:
		utility_button.custom_minimum_size.y = 44.0
		utility_button.add_theme_font_size_override("font_size", 14)

	var status_style := StyleBoxFlat.new()
	status_style.bg_color = Color(0.018, 0.028, 0.032, 0.72)
	status_style.border_color = Color(0.48, 0.72, 0.68, 0.26)
	status_style.set_border_width_all(1)
	status_style.set_corner_radius_all(7)
	connection_label.add_theme_stylebox_override("normal", status_style)
	connection_label.add_theme_constant_override("outline_size", 0)


func _apply_main_mode_card_style(button: Button) -> void:
	if button == null:
		return
	var accent: Color = button.get_meta(
		"main_card_accent",
		Color(0.94, 0.94, 0.96)
	)
	var featured: bool = bool(button.get_meta("main_card_featured", false))
	MenuStyler.style_accent_card_button(button, accent, featured)


func _apply_menu_styling() -> void:
	bindings_mode_button.icon = CONTROLLER_ICON
	controller_prompt_style_button.icon = CONTROLLER_ICON
	MenuStyler.style_button(
		singleplayer_button,
		Color(0.30, 0.88, 0.57),
		60.0
	)
	MenuStyler.style_button(
		multiplayer_button,
		Color(0.32, 0.57, 0.96),
		60.0
	)
	MenuStyler.style_button(
		create_lobby_button,
		Color(0.38, 0.9, 0.62),
		52.0
	)
	MenuStyler.style_button(
		refresh_lobbies_button,
		Color(0.84, 0.72, 0.40),
		44.0
	)
	MenuStyler.style_button(
		multiplayer_back_button,
		Color(0.58, 0.66, 0.74),
		48.0
	)
	MenuStyler.style_button(
		freeplay_button,
		Color(1.0, 0.57, 0.25),
		60.0
	)
	MenuStyler.style_button(
		options_button,
		Color(0.46, 0.78, 0.82),
		60.0
	)
	MenuStyler.style_button(
		locker_button,
		Color(0.76, 0.54, 0.92),
		60.0
	)
	MenuStyler.style_button(
		battle_pass_button,
		Color(0.98, 0.74, 0.22),
		60.0
	)
	MenuStyler.style_button(
		exit_button,
		Color(1.0, 0.35, 0.38),
		60.0
	)
	MenuStyler.style_button(
		toggle_menu_button,
		Color(0.84, 0.72, 0.40),
		46.0
	)
	for option_button in [
		bindings_mode_button,
		ability_key_button,
		soft_pass_key_button,
		pass_request_key_button,
		quick_chat_key_button
	]:
		MenuStyler.style_button(
			option_button,
			Color(0.84, 0.72, 0.40),
			48.0
		)
	for controller_button in [
		controller_prompt_style_button,
		controller_shoot_button,
		controller_ability_button,
		controller_soft_pass_button,
		controller_pass_request_button,
		controller_quick_chat_button,
		controller_leaderboard_button,
		movement_stick_button,
		reset_controller_button
	]:
		MenuStyler.style_button(
			controller_button,
			Color(0.84, 0.72, 0.40),
			44.0
		)
	MenuStyler.style_button(
		options_back_button,
		Color(0.58, 0.66, 0.74),
		48.0
	)
	connection_label.add_theme_color_override(
		"font_color",
		Color(0.64, 0.7, 0.76)
	)


func _apply_responsive_menu_layout() -> void:
	if not is_inside_tree():
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var maximum_content_width: float = 1240.0
	if options_panel.visible:
		maximum_content_width = 620.0
	elif multiplayer_panel.visible:
		maximum_content_width = 900.0
	MenuStyler.apply_responsive_content_width(
		menu_content,
		viewport_size,
		320.0,
		maximum_content_width
	)
	var compact: bool = viewport_size.y < 800.0 or viewport_size.x < 1280.0
	var title := menu_content.find_child("MenuTitle", true, false) as Label
	if title != null:
		title.add_theme_font_size_override("font_size", 42 if compact else 58)
	var chapter_subtitle := menu_content.find_child(
		"ChapterSubtitle", true, false
	) as Label
	if chapter_subtitle != null:
		chapter_subtitle.add_theme_font_size_override(
			"font_size",
			16 if compact else 22
		)
	var career_stats := menu_content.find_child(
		"CareerStatsLabel", true, false
	) as Label
	if career_stats != null:
		career_stats.add_theme_font_size_override("font_size", 15 if compact else 18)
	menu_content.add_theme_constant_override("separation", 6 if compact else 9)
	if _main_dashboard != null:
		_main_dashboard.add_theme_constant_override("separation", 7 if compact else 10)
	if _mode_shelf != null:
		_mode_shelf.add_theme_constant_override("separation", 10 if compact else 14)
	if _secondary_mode_grid != null:
		_secondary_mode_grid.add_theme_constant_override("h_separation", 8 if compact else 10)
		_secondary_mode_grid.add_theme_constant_override("v_separation", 8 if compact else 10)
	var featured_height := 220.0 if compact else 270.0
	if singleplayer_button != null:
		singleplayer_button.custom_minimum_size.y = featured_height
	for card: Button in [multiplayer_button, freeplay_button, battle_pass_button, locker_button]:
		if card != null:
			card.custom_minimum_size.y = 103.0 if compact else 126.0
	for utility_button: Button in [leaderboards_button, options_button, exit_button]:
		if utility_button != null:
			utility_button.custom_minimum_size.y = 40.0 if compact else 46.0
	_wire_main_menu_focus.call_deferred()
	var options_scroll := options_panel.get_node_or_null("OptionsScroll") as ScrollContainer
	if options_scroll != null:
		options_scroll.custom_minimum_size.y = clampf(
			viewport_size.y - 138.0,
			320.0,
			620.0
		)


func _ensure_options_scroll_layout() -> void:
	if options_panel.get_node_or_null("OptionsScroll") != null:
		return
	var scroll := ScrollContainer.new()
	scroll.name = "OptionsScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	var content := VBoxContainer.new()
	content.name = "OptionsContent"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	for child in options_panel.get_children():
		child.reparent(content)
	options_panel.add_child(scroll)
	scroll.add_child(content)




func _prepare_lobby_browser() -> void:
	if Engine.has_singleton("Steam") and _steam_api().getSteamID() != 0:
		lobby_name_edit.placeholder_text = (
			"%s's Lobby" % _steam_api().getPersonaName()
		)
	else:
		lobby_name_edit.placeholder_text = "My Lobby"
	_show_lobby_browser_message(
		"Press Refresh to search public Steam lobbies. "
		+ "Friends Only / Private lobbies are joined through Steam invites."
	)


func _return_to_main_menu_from_multiplayer() -> void:
	# Also cancels an in-progress Steam search, lobby creation, or join.
	# This prevents an asynchronous callback from reopening or connecting
	# after the player has already returned to the main menu.
	network_manager.disconnect_game()
	if _steam_mode_popup != null:
		_steam_mode_popup.hide()
	_set_multiplayer_open(false)


func _build_singleplayer_popup() -> void:
	if _singleplayer_popup != null:
		return
	_singleplayer_popup = PopupPanel.new()
	_singleplayer_popup.name = "SingleplayerModePopup"
	_singleplayer_popup.exclusive = true
	add_child(_singleplayer_popup)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_bottom", 26)
	_singleplayer_popup.add_child(margin)
	var content := VBoxContainer.new()
	content.name = "SingleplayerContent"
	content.add_theme_constant_override("separation", 13)
	margin.add_child(content)
	var eyebrow := Label.new()
	eyebrow.text = "THEODORE BALL • SOLO COMPETITION"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_font_size_override("font_size", 15)
	eyebrow.add_theme_color_override("font_color", Color("a8b4c3"))
	content.add_child(eyebrow)
	var title := Label.new()
	title.text = "CHOOSE SINGLEPLAYER MODE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 31)
	title.add_theme_color_override("font_color", Color("f5f7fb"))
	content.add_child(title)
	var separator := HSeparator.new()
	content.add_child(separator)

	_singleplayer_custom_button = Button.new()
	_singleplayer_custom_button.name = "CustomSingleplayerButton"
	_singleplayer_custom_button.text = "CUSTOM MATCH"
	_singleplayer_custom_button.tooltip_text = (
		"Open the normal local-host lobby with full match settings."
	)
	_singleplayer_custom_button.custom_minimum_size.y = 62.0
	_singleplayer_custom_button.pressed.connect(
		_start_custom_singleplayer
	)
	content.add_child(_singleplayer_custom_button)

	var ranked_card := PanelContainer.new()
	ranked_card.name = "PveRankedCard"
	content.add_child(ranked_card)
	var ranked_margin := MarginContainer.new()
	ranked_margin.add_theme_constant_override("margin_left", 18)
	ranked_margin.add_theme_constant_override("margin_top", 14)
	ranked_margin.add_theme_constant_override("margin_right", 18)
	ranked_margin.add_theme_constant_override("margin_bottom", 16)
	ranked_card.add_child(ranked_margin)
	var ranked_content := VBoxContainer.new()
	ranked_content.add_theme_constant_override("separation", 10)
	ranked_margin.add_child(ranked_content)
	var ranked_header := HBoxContainer.new()
	ranked_header.name = "RankedHeader"
	ranked_header.add_theme_constant_override("separation", 8)
	ranked_content.add_child(ranked_header)
	var ranked_header_spacer := Control.new()
	ranked_header_spacer.custom_minimum_size.x = 74.0
	ranked_header.add_child(ranked_header_spacer)
	var ranked_title := Label.new()
	ranked_title.text = "PvE RANKED"
	ranked_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ranked_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ranked_title.add_theme_font_size_override("font_size", 27)
	ranked_title.add_theme_color_override("font_color", Color("f2c14e"))
	ranked_header.add_child(ranked_title)
	_ranked_info_button = Button.new()
	_ranked_info_button.name = "RankedInfoButton"
	_ranked_info_button.text = "INFO"
	_ranked_info_button.tooltip_text = "View PvE Ranked division MMR ranges."
	_ranked_info_button.custom_minimum_size = Vector2(74.0, 38.0)
	_ranked_info_button.pressed.connect(_open_ranked_info_popup)
	ranked_header.add_child(_ranked_info_button)
	var ranked_description := Label.new()
	ranked_description.text = (
		"One shared rank across every format • two-leg Draft matches • "
		+ "+30 win / -30 loss"
	)
	ranked_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ranked_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ranked_content.add_child(ranked_description)
	_singleplayer_rank_label = RichTextLabel.new()
	_singleplayer_rank_label.name = "RankSummary"
	_singleplayer_rank_label.bbcode_enabled = true
	_singleplayer_rank_label.fit_content = true
	_singleplayer_rank_label.scroll_active = false
	_singleplayer_rank_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_singleplayer_rank_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_singleplayer_rank_label.add_theme_font_size_override("normal_font_size", 20)
	ranked_content.add_child(_singleplayer_rank_label)
	var sizes := GridContainer.new()
	sizes.name = "TeamSizeGrid"
	sizes.columns = 6
	sizes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sizes.add_theme_constant_override("h_separation", 10)
	ranked_content.add_child(sizes)
	for team_size: int in range(1, 7):
		var size_button := Button.new()
		size_button.name = "Ranked%dv%dButton" % [team_size, team_size]
		size_button.text = "%dv%d" % [team_size, team_size]
		size_button.tooltip_text = (
			"Queue a %dv%d CPU match. This uses the same MMR as every format."
			% [team_size, team_size]
		)
		size_button.custom_minimum_size = Vector2(0.0, 66.0)
		size_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		size_button.pressed.connect(
			_queue_singleplayer_ranked.bind(team_size)
		)
		sizes.add_child(size_button)
		_singleplayer_size_buttons.append(size_button)
	_singleplayer_queue_label = Label.new()
	_singleplayer_queue_label.name = "QueueStatus"
	_singleplayer_queue_label.text = "SELECT A TEAM SIZE TO FIND A CPU MATCH"
	_singleplayer_queue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_singleplayer_queue_label.add_theme_font_size_override("font_size", 15)
	_singleplayer_queue_label.add_theme_color_override(
		"font_color",
		Color("8bd8ff")
	)
	ranked_content.add_child(_singleplayer_queue_label)

	var close_button := Button.new()
	close_button.name = "CloseSingleplayerButton"
	close_button.text = "BACK"
	close_button.custom_minimum_size.y = 48.0
	close_button.pressed.connect(_singleplayer_popup.hide)
	content.add_child(close_button)

	var ranked_style := StyleBoxFlat.new()
	ranked_style.bg_color = Color(0.025, 0.032, 0.045, 0.96)
	ranked_style.border_color = Color(0.95, 0.72, 0.25, 0.80)
	ranked_style.set_border_width_all(2)
	ranked_style.set_corner_radius_all(15)
	ranked_card.add_theme_stylebox_override("panel", ranked_style)
	MenuStyler.style_button(
		_singleplayer_custom_button,
		Color("68d391"),
		62.0
	)
	MenuStyler.style_button(_ranked_info_button, Color("f2c14e"), 38.0)
	for size_button: Button in _singleplayer_size_buttons:
		MenuStyler.style_button(size_button, Color("f2c14e"), 66.0)
	MenuStyler.style_button(close_button, Color("a8b4c3"), 48.0)
	_build_ranked_info_popup()
	if not _singleplayer_size_buttons.is_empty():
		_set_main_focus_neighbor(
			_singleplayer_custom_button,
			SIDE_BOTTOM,
			_singleplayer_size_buttons[0]
		)
		if _ranked_info_button != null:
			_set_main_focus_neighbor(
				_singleplayer_custom_button,
				SIDE_RIGHT,
				_ranked_info_button
			)
			_set_main_focus_neighbor(
				_ranked_info_button,
				SIDE_LEFT,
				_singleplayer_custom_button
			)
			_set_main_focus_neighbor(
				_ranked_info_button,
				SIDE_BOTTOM,
				_singleplayer_size_buttons[0]
			)
		for index: int in range(_singleplayer_size_buttons.size()):
			var size_button: Button = _singleplayer_size_buttons[index]
			_set_main_focus_neighbor(
				size_button,
				SIDE_TOP,
				_singleplayer_custom_button
			)
			_set_main_focus_neighbor(size_button, SIDE_BOTTOM, close_button)
			if index > 0:
				_set_main_focus_neighbor(
					size_button,
					SIDE_LEFT,
					_singleplayer_size_buttons[index - 1]
				)
			if index + 1 < _singleplayer_size_buttons.size():
				_set_main_focus_neighbor(
					size_button,
					SIDE_RIGHT,
					_singleplayer_size_buttons[index + 1]
				)
		_set_main_focus_neighbor(
			close_button,
			SIDE_TOP,
			_singleplayer_size_buttons[0]
		)


func _process(delta: float) -> void:
	if _ranked_glint_nodes.is_empty() and _singleplayer_rank_snapshot.is_empty():
		return
	_ranked_glint_accum += delta
	if _ranked_glint_accum < 0.09:
		return
	_ranked_glint_accum = 0.0
	_refresh_ranked_glint_labels()


func _build_ranked_info_popup() -> void:
	if _ranked_info_popup != null:
		return
	_ranked_info_popup = PopupPanel.new()
	_ranked_info_popup.name = "RankedInfoPopup"
	_ranked_info_popup.exclusive = true
	add_child(_ranked_info_popup)

	# Keep this popup substantially darker than the menu behind it. The stronger
	# shadow and nearly opaque surface prevent the underlying menu text from
	# competing with the division table.
	var popup_style := StyleBoxFlat.new()
	popup_style.bg_color = Color(0.012, 0.017, 0.024, 0.985)
	popup_style.border_color = Color(0.95, 0.72, 0.25, 0.72)
	popup_style.set_border_width_all(2)
	popup_style.set_corner_radius_all(18)
	popup_style.shadow_color = Color(0.0, 0.0, 0.0, 0.90)
	popup_style.shadow_size = 28
	popup_style.shadow_offset = Vector2(0.0, 10.0)
	_ranked_info_popup.add_theme_stylebox_override("panel", popup_style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_bottom", 28)
	_ranked_info_popup.add_child(margin)

	var content := VBoxContainer.new()
	content.name = "RankedInfoContent"
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)

	var eyebrow := Label.new()
	eyebrow.text = "RANKED LADDER"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_font_size_override("font_size", 13)
	eyebrow.add_theme_color_override("font_color", Color("a8b4c3"))
	eyebrow.add_theme_color_override(
		"font_shadow_color", Color(0.0, 0.0, 0.0, 0.90)
	)
	eyebrow.add_theme_constant_override("shadow_offset_x", 1)
	eyebrow.add_theme_constant_override("shadow_offset_y", 2)
	content.add_child(eyebrow)

	var title := Label.new()
	title.text = "PvE RANKED • DIVISIONS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", Color("f2c14e"))
	title.add_theme_color_override(
		"font_shadow_color", Color(0.0, 0.0, 0.0, 0.95)
	)
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.add_theme_constant_override("shadow_outline_size", 4)
	content.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "MMR RANGES"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color("c3ccd6"))
	subtitle.add_theme_color_override(
		"font_shadow_color", Color(0.0, 0.0, 0.0, 0.85)
	)
	subtitle.add_theme_constant_override("shadow_offset_y", 2)
	content.add_child(subtitle)

	var separator := HSeparator.new()
	content.add_child(separator)

	var table_panel := PanelContainer.new()
	table_panel.name = "DivisionTablePanel"
	table_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var table_style := StyleBoxFlat.new()
	table_style.bg_color = Color(0.025, 0.032, 0.043, 0.98)
	table_style.border_color = Color(0.62, 0.69, 0.76, 0.34)
	table_style.set_border_width_all(1)
	table_style.set_corner_radius_all(12)
	table_style.shadow_color = Color(0.0, 0.0, 0.0, 0.72)
	table_style.shadow_size = 10
	table_style.shadow_offset = Vector2(0.0, 4.0)
	table_panel.add_theme_stylebox_override("panel", table_style)
	content.add_child(table_panel)

	var table_margin := MarginContainer.new()
	table_margin.add_theme_constant_override("margin_left", 18)
	table_margin.add_theme_constant_override("margin_top", 16)
	table_margin.add_theme_constant_override("margin_right", 18)
	table_margin.add_theme_constant_override("margin_bottom", 16)
	table_panel.add_child(table_margin)

	var table := GridContainer.new()
	table.name = "DivisionTable"
	table.columns = 3
	table.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	table.add_theme_constant_override("h_separation", 24)
	table.add_theme_constant_override("v_separation", 10)
	table_margin.add_child(table)

	var headers: Array[String] = ["DIVISION", "NAME", "MMR RANGE"]
	for header_text: String in headers:
		var header := Label.new()
		header.text = header_text
		header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.add_theme_font_size_override("font_size", 14)
		header.add_theme_color_override("font_color", Color("8bd8ff"))
		header.add_theme_color_override(
			"font_shadow_color", Color(0.0, 0.0, 0.0, 0.92)
		)
		header.add_theme_constant_override("shadow_offset_y", 2)
		table.add_child(header)

	var thresholds: Array[int] = (
		FootballMatchManager.SINGLEPLAYER_RANKED_DIVISION_THRESHOLDS
	)
	for index: int in range(thresholds.size()):
		var division: int = index + 1
		var minimum_mmr: int = thresholds[index]
		var range_text: String
		if index + 1 < thresholds.size():
			range_text = "%d - %d" % [minimum_mmr, thresholds[index + 1] - 1]
		else:
			range_text = "%d+" % minimum_mmr


		var division_label := _create_ranked_info_text_control(
			"DIVISION %d" % division,
			division,
			17
		)
		table.add_child(division_label)

		var name_label := _create_ranked_info_text_control(
			FootballMatchManager.get_singleplayer_ranked_division_name(division),
			division,
			17
		)
		table.add_child(name_label)

		var range_label := _create_ranked_info_text_control(range_text, division, 17)
		table.add_child(range_label)

	_ranked_info_close_button = Button.new()
	_ranked_info_close_button.name = "CloseRankedInfoButton"
	_ranked_info_close_button.text = "BACK"
	_ranked_info_close_button.custom_minimum_size.y = 48.0
	_ranked_info_close_button.pressed.connect(_close_ranked_info_popup)
	content.add_child(_ranked_info_close_button)
	MenuStyler.style_button(
		_ranked_info_close_button,
		Color("a8b4c3"),
		48.0
	)


func _create_ranked_info_text_control(text_value: String, division: int, font_size: int) -> Control:
	if FootballMatchManager.singleplayer_ranked_division_is_animated(division):
		var rich := RichTextLabel.new()
		rich.bbcode_enabled = true
		rich.fit_content = true
		rich.scroll_active = false
		rich.autowrap_mode = TextServer.AUTOWRAP_OFF
		rich.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rich.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rich.add_theme_font_size_override("normal_font_size", font_size)
		rich.text = _format_ranked_glint_text(text_value, division)
		rich.tooltip_text = text_value
		rich.set_meta("rank_glint_text", text_value)
		rich.set_meta("rank_glint_division", division)
		_ranked_glint_nodes.append(rich)
		return rich
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	_apply_ranked_league_label_style(label, division)
	return label


func _apply_ranked_league_label_style(label: Label, division: int) -> void:
	if label == null:
		return
	var division_color: Color = FootballMatchManager.get_singleplayer_ranked_division_color(division)
	label.self_modulate = Color.WHITE
	label.material = null
	label.add_theme_color_override("font_color", division_color)
	label.add_theme_color_override("font_outline_color", Color(0.018, 0.021, 0.03, 0.98))
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.70))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.add_theme_constant_override("shadow_outline_size", 1)


func _format_ranked_glint_text(value: String, division: int) -> String:
	var base_color: Color = FootballMatchManager.get_singleplayer_ranked_division_color(division)
	var outline_color: Color = base_color.darkened(0.62)
	if not FootballMatchManager.singleplayer_ranked_division_is_animated(division):
		return (
			"[center][outline_size=2][outline_color=#%s][color=#%s]%s[/color][/outline_color][/outline_size][/center]"
		) % [outline_color.to_html(false), base_color.to_html(false), value]
	var glint_body := _build_ranked_glint_bbcode(value, division)
	return (
		"[center][outline_size=2][outline_color=#%s]%s[/outline_color][/outline_size][/center]"
	) % [outline_color.to_html(false), glint_body]


func _build_ranked_glint_bbcode(value: String, division: int) -> String:
	var base_color: Color = FootballMatchManager.get_singleplayer_ranked_division_color(division)
	var shine_color: Color = FootballMatchManager.get_singleplayer_ranked_division_shine_color(division)
	var t: float = float(Time.get_ticks_msec()) / 1000.0
	var char_count: int = maxi(1, value.length())
	var travel: float = 1.30
	var center: float = fposmod(t / travel, 1.0) * 1.90 - 0.45
	var body := ""
	for index in range(char_count):
		var ratio: float = (
			float(index) / float(maxi(1, char_count - 1))
			if char_count > 1
			else 0.5
		)
		var distance: float = abs(ratio - center)
		var intensity: float = clampf(1.0 - distance / 0.48, 0.0, 1.0)
		intensity = intensity * intensity * (3.0 - 2.0 * intensity)
		var char_color: Color = base_color.lerp(shine_color, intensity)
		body += "[color=#%s]%s[/color]" % [
			char_color.to_html(false),
			value.substr(index, 1)
		]
	return body


func _refresh_ranked_glint_labels() -> void:
	for index in range(_ranked_glint_nodes.size() - 1, -1, -1):
		var node: Variant = _ranked_glint_nodes[index]
		if not is_instance_valid(node) or not (node is RichTextLabel):
			_ranked_glint_nodes.remove_at(index)
			continue
		var rich := node as RichTextLabel
		if rich.has_meta("rank_glint_mmr"):
			rich.text = _format_global_mmr_badge(
				int(rich.get_meta("rank_glint_mmr", 0))
			)
			continue
		var text_value := str(rich.get_meta("rank_glint_text", rich.tooltip_text))
		var division := int(rich.get_meta("rank_glint_division", 0))
		rich.text = _format_ranked_glint_text(text_value, division)
	if _singleplayer_rank_label != null and is_instance_valid(_singleplayer_rank_label) and not _singleplayer_rank_snapshot.is_empty():
		_refresh_singleplayer_rank_summary_text()


func _refresh_singleplayer_rank_summary_text() -> void:
	if _singleplayer_rank_label == null:
		return
	var division: int = int(_singleplayer_rank_snapshot.get("division", 1))
	var division_name: String = str(_singleplayer_rank_snapshot.get("division_name", "KREISLIGA"))
	var mmr: int = int(_singleplayer_rank_snapshot.get("mmr", 0))
	var matches: int = int(_singleplayer_rank_snapshot.get("matches", 0))
	var base_color: Color = FootballMatchManager.get_singleplayer_ranked_division_color(division)
	var outline_color: Color = base_color.darkened(0.62)
	var rank_name_text := division_name
	if FootballMatchManager.singleplayer_ranked_division_is_animated(division):
		rank_name_text = _build_ranked_glint_bbcode(division_name, division)
	else:
		rank_name_text = "[color=#%s]%s[/color]" % [base_color.to_html(false), division_name]
	_singleplayer_rank_label.text = (
		"[center][outline_size=2][outline_color=#%s]DIVISION %d • %s  |  [color=#%s]%d MMR[/color]  |  %d MATCHES[/outline_color][/outline_size][/center]"
	) % [
		outline_color.to_html(false),
		division,
		rank_name_text,
		base_color.to_html(false),
		mmr,
		matches
	]


func _open_ranked_info_popup() -> void:
	if _ranked_info_popup == null:
		return
	_ranked_info_popup.popup_centered(Vector2i(680, 500))
	if controller_support.using_controller and _ranked_info_close_button != null:
		_ranked_info_close_button.grab_focus.call_deferred()


func _close_ranked_info_popup() -> void:
	if _ranked_info_popup != null:
		_ranked_info_popup.hide()
	if controller_support.using_controller and _ranked_info_button != null:
		_ranked_info_button.grab_focus.call_deferred()


func _open_singleplayer_popup() -> void:
	if _singleplayer_popup == null:
		return
	var snapshot: Dictionary = (
		match_manager.refresh_singleplayer_ranked_profile()
	)
	_update_singleplayer_rank_summary(snapshot)
	_singleplayer_queue_label.text = (
		"SELECT A TEAM SIZE TO FIND A CPU MATCH"
	)
	_set_singleplayer_queue_buttons_enabled(true)
	_singleplayer_popup.popup_centered(Vector2i(820, 560))
	if controller_support.using_controller:
		_singleplayer_custom_button.grab_focus.call_deferred()


func _update_singleplayer_rank_summary(snapshot: Dictionary) -> void:
	_singleplayer_rank_snapshot = snapshot.duplicate(true)
	if _singleplayer_rank_label == null:
		return
	_refresh_singleplayer_rank_summary_text()
	_sync_global_career_scores()


func _start_custom_singleplayer() -> void:
	if _singleplayer_popup != null:
		_singleplayer_popup.hide()
	network_manager.host_local()


func _queue_singleplayer_ranked(team_size: int) -> void:
	if _singleplayer_queue_label == null:
		return
	_set_singleplayer_queue_buttons_enabled(false)
	_singleplayer_queue_label.text = (
		"MATCHMAKING • SEARCHING FOR %dv%d OPPONENTS..."
		% [team_size, team_size]
	)
	await get_tree().create_timer(0.65).timeout
	if _singleplayer_popup == null or not _singleplayer_popup.visible:
		_set_singleplayer_queue_buttons_enabled(true)
		return
	_singleplayer_queue_label.text = "MATCH FOUND • ENTERING RANKED READY ROOM"
	await get_tree().create_timer(0.35).timeout
	if _singleplayer_popup != null:
		_singleplayer_popup.hide()
	if not network_manager.start_singleplayer_ranked(team_size):
		_set_singleplayer_queue_buttons_enabled(true)
		_singleplayer_queue_label.text = "MATCHMAKING FAILED • TRY AGAIN"


func _set_singleplayer_queue_buttons_enabled(enabled: bool) -> void:
	for button: Button in _singleplayer_size_buttons:
		button.disabled = not enabled
	if _singleplayer_custom_button != null:
		_singleplayer_custom_button.disabled = not enabled


func _create_steam_lobby() -> void:
	if _steam_mode_popup == null:
		_build_steam_mode_popup()
	if _steam_mode_popup == null:
		return
	_steam_mode_popup.popup_centered(Vector2i(700, 660))
	if _steam_standard_button != null:
		_steam_standard_button.grab_focus()


func _build_leaderboards_popup() -> void:
	_leaderboards_popup = PopupPanel.new()
	_leaderboards_popup.name = "LeaderboardsPopup"
	_leaderboards_popup.exclusive = true
	var popup_style := _create_leaderboard_style(
		Color(0.006, 0.010, 0.018, 0.998),
		Color(0.86, 0.68, 0.28, 0.94),
		2,
		24
	)
	popup_style.shadow_color = Color(0.0, 0.0, 0.0, 0.62)
	popup_style.shadow_size = 18
	popup_style.shadow_offset = Vector2(0.0, 8.0)
	_leaderboards_popup.add_theme_stylebox_override("panel", popup_style)
	add_child(_leaderboards_popup)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	_leaderboards_popup.add_child(margin)
	var column := VBoxContainer.new()
	column.name = "GlobalLeaderboardLayout"
	column.custom_minimum_size = Vector2(900.0, 540.0)
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)

	# A compact trophy-room header gives the screen identity without stealing
	# height from the actual ranking table.
	var header_panel := PanelContainer.new()
	header_panel.name = "LeaderboardPrestigeHeader"
	header_panel.add_theme_stylebox_override(
		"panel",
		_create_leaderboard_style(
			Color(0.026, 0.027, 0.035, 0.995),
			Color(0.74, 0.56, 0.20, 0.74),
			1,
			14
		)
	)
	column.add_child(header_panel)
	var header_margin := MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left", 18)
	header_margin.add_theme_constant_override("margin_right", 18)
	header_margin.add_theme_constant_override("margin_top", 2)
	header_margin.add_theme_constant_override("margin_bottom", 2)
	header_panel.add_child(header_margin)
	var title_block := VBoxContainer.new()
	title_block.add_theme_constant_override("separation", -3)
	header_margin.add_child(title_block)
	var title := Label.new()
	title.text = "◆  GLOBAL LEADERBOARDS  ◆"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.97, 0.975, 0.99))
	title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.82))
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 2)
	title_block.add_child(title)
	var subtitle := Label.new()
	subtitle.name = "PrestigeEyebrow"
	subtitle.text = "THEODORE BALL  •  HALL OF FAME  •  STEAM VERIFIED"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 10)
	subtitle.add_theme_color_override("font_color", Color(0.91, 0.72, 0.31))
	title_block.add_child(subtitle)

	var summary_and_tabs := HBoxContainer.new()
	summary_and_tabs.name = "SummaryAndTabs"
	summary_and_tabs.add_theme_constant_override("separation", 9)
	column.add_child(summary_and_tabs)

	var local_summary := PanelContainer.new()
	local_summary.name = "LocalCareerSummary"
	local_summary.add_theme_stylebox_override(
		"panel",
		_create_leaderboard_style(
			Color(0.055, 0.047, 0.027, 0.985),
			Color(0.92, 0.73, 0.31, 0.70),
			1,
			11
		)
	)
	local_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	local_summary.size_flags_stretch_ratio = 1.30
	summary_and_tabs.add_child(local_summary)
	_leaderboards_stats_label = Label.new()
	_leaderboards_stats_label.name = "LocalCareerTotals"
	_leaderboards_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_leaderboards_stats_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_leaderboards_stats_label.custom_minimum_size.y = 36.0
	_leaderboards_stats_label.add_theme_font_size_override("font_size", 14)
	_leaderboards_stats_label.add_theme_color_override(
		"font_color",
		Color(0.98, 0.84, 0.46)
	)
	local_summary.add_child(_leaderboards_stats_label)

	var tabs := HBoxContainer.new()
	tabs.name = "CategoryTabs"
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.size_flags_stretch_ratio = 1.0
	tabs.add_theme_constant_override("separation", 6)
	summary_and_tabs.add_child(tabs)
	_leaderboards_mmr_button = Button.new()
	_leaderboards_mmr_button.name = "PveMmrTab"
	_leaderboards_mmr_button.text = "PVE MMR"
	_leaderboards_mmr_button.toggle_mode = true
	_leaderboards_mmr_button.button_pressed = true
	_leaderboards_mmr_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_leaderboards_mmr_button.custom_minimum_size.y = 36.0
	_leaderboards_mmr_button.pressed.connect(
		_select_global_leaderboard_category.bind(&"pve_mmr")
	)
	tabs.add_child(_leaderboards_mmr_button)
	_leaderboards_goals_button = Button.new()
	_leaderboards_goals_button.name = "GoalsTab"
	_leaderboards_goals_button.text = "⚽ GOALS"
	_leaderboards_goals_button.toggle_mode = true
	_leaderboards_goals_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_leaderboards_goals_button.custom_minimum_size.y = 36.0
	_leaderboards_goals_button.pressed.connect(
		_select_global_leaderboard_category.bind(&"goals")
	)
	tabs.add_child(_leaderboards_goals_button)
	_leaderboards_saves_button = Button.new()
	_leaderboards_saves_button.name = "SavesTab"
	_leaderboards_saves_button.text = "◆ SAVES"
	_leaderboards_saves_button.toggle_mode = true
	_leaderboards_saves_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_leaderboards_saves_button.custom_minimum_size.y = 36.0
	_leaderboards_saves_button.pressed.connect(
		_select_global_leaderboard_category.bind(&"saves")
	)
	tabs.add_child(_leaderboards_saves_button)
	_style_leaderboard_tab(_leaderboards_mmr_button, Color(0.67, 0.51, 1.0))
	_style_leaderboard_tab(_leaderboards_goals_button, Color(0.96, 0.73, 0.24))
	_style_leaderboard_tab(_leaderboards_saves_button, Color(0.27, 0.79, 1.0))

	var board_panel := PanelContainer.new()
	board_panel.name = "GlobalBoard"
	board_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var board_style := _create_leaderboard_style(
		Color(0.012, 0.018, 0.028, 0.995),
		Color(0.46, 0.38, 0.22, 0.86),
		1,
		13
	)
	board_style.shadow_color = Color(0.0, 0.0, 0.0, 0.32)
	board_style.shadow_size = 6
	board_style.shadow_offset = Vector2(0.0, 3.0)
	board_panel.add_theme_stylebox_override("panel", board_style)
	column.add_child(board_panel)
	var board_margin := MarginContainer.new()
	board_margin.add_theme_constant_override("margin_left", 12)
	board_margin.add_theme_constant_override("margin_right", 12)
	board_margin.add_theme_constant_override("margin_top", 9)
	board_margin.add_theme_constant_override("margin_bottom", 9)
	board_panel.add_child(board_margin)
	var board_column := VBoxContainer.new()
	board_column.add_theme_constant_override("separation", 6)
	board_margin.add_child(board_column)
	var board_heading := HBoxContainer.new()
	board_heading.custom_minimum_size.y = 28.0
	board_column.add_child(board_heading)
	_leaderboards_category_label = Label.new()
	_leaderboards_category_label.text = "PVE MMR  /  ALL-TIME RECORDS"
	_leaderboards_category_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_leaderboards_category_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_leaderboards_category_label.add_theme_font_size_override("font_size", 16)
	_leaderboards_category_label.add_theme_color_override(
		"font_color",
		Color(0.94, 0.97, 1.0)
	)
	board_heading.add_child(_leaderboards_category_label)
	_leaderboards_status_label = Label.new()
	_leaderboards_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_leaderboards_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_leaderboards_status_label.add_theme_font_size_override("font_size", 11)
	_leaderboards_status_label.add_theme_color_override(
		"font_color",
		Color(0.55, 0.62, 0.68)
	)
	board_heading.add_child(_leaderboards_status_label)
	var heading_rule := ColorRect.new()
	heading_rule.name = "PrestigeRule"
	heading_rule.custom_minimum_size.y = 1.0
	heading_rule.color = Color(0.88, 0.68, 0.27, 0.23)
	heading_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_column.add_child(heading_rule)
	board_column.add_child(_create_global_leaderboard_header())
	_leaderboards_scroll = ScrollContainer.new()
	_leaderboards_scroll.name = "LeaderboardScroll"
	_leaderboards_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_leaderboards_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	board_column.add_child(_leaderboards_scroll)
	_leaderboards_rows = VBoxContainer.new()
	_leaderboards_rows.name = "LeaderboardRows"
	_leaderboards_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_leaderboards_rows.add_theme_constant_override("separation", 5)
	_leaderboards_scroll.add_child(_leaderboards_rows)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 9)
	column.add_child(footer)
	_leaderboards_scope_note = Label.new()
	_leaderboards_scope_note.text = "TOP 100 GLOBAL  •  STEAM VERIFIED"
	_leaderboards_scope_note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_leaderboards_scope_note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_leaderboards_scope_note.add_theme_font_size_override("font_size", 11)
	_leaderboards_scope_note.add_theme_color_override("font_color", Color(0.49, 0.55, 0.61))
	footer.add_child(_leaderboards_scope_note)
	_leaderboards_refresh_button = Button.new()
	_leaderboards_refresh_button.name = "RefreshButton"
	_leaderboards_refresh_button.text = "REFRESH"
	_leaderboards_refresh_button.custom_minimum_size = Vector2(122.0, 36.0)
	_leaderboards_refresh_button.pressed.connect(_refresh_global_leaderboard)
	footer.add_child(_leaderboards_refresh_button)
	_leaderboards_back_button = Button.new()
	_leaderboards_back_button.name = "BackButton"
	_leaderboards_back_button.text = "BACK"
	_leaderboards_back_button.custom_minimum_size = Vector2(122.0, 36.0)
	_leaderboards_back_button.pressed.connect(_leaderboards_popup.hide)
	footer.add_child(_leaderboards_back_button)
	_style_leaderboard_action_button(
		_leaderboards_refresh_button,
		Color(0.90, 0.70, 0.28)
	)
	_style_leaderboard_action_button(
		_leaderboards_back_button,
		Color(0.52, 0.60, 0.68)
	)

	_leaderboards_steam_manager = get_node_or_null("/root/SteamManager")
	if (
		_leaderboards_steam_manager != null
		and _leaderboards_steam_manager.has_signal("global_leaderboard_changed")
		and not _leaderboards_steam_manager.is_connected(
			"global_leaderboard_changed",
			_on_global_leaderboard_changed
		)
	):
		_leaderboards_steam_manager.connect(
			"global_leaderboard_changed",
			_on_global_leaderboard_changed
		)
	_render_global_leaderboard()


func _open_leaderboards() -> void:
	if _leaderboards_popup == null:
		return
	_leaderboards_active_category = &"pve_mmr"
	var pve_mmr := _current_pve_mmr()
	_leaderboards_stats_label.text = (
		"YOUR LEGACY  •  MMR [%d]  •  ⚽ %d  •  ◆ %d"
		% [pve_mmr, _career_goals, _career_saves]
	)
	_sync_global_career_scores()
	_select_global_leaderboard_category(_leaderboards_active_category)
	var viewport_size: Vector2 = get_viewport_rect().size
	var popup_size := Vector2i(
		int(clampf(viewport_size.x * 0.94, 900.0, 1180.0)),
		int(clampf(viewport_size.y * 0.94, 576.0, 820.0))
	)
	_leaderboards_popup.popup_centered(popup_size)
	if controller_support.using_controller and _leaderboards_mmr_button != null:
		var focus_button := _leaderboards_mmr_button
		if _leaderboards_active_category == &"goals":
			focus_button = _leaderboards_goals_button
		elif _leaderboards_active_category == &"saves":
			focus_button = _leaderboards_saves_button
		focus_button.grab_focus.call_deferred()


func _create_leaderboard_style(
	background: Color,
	border: Color,
	border_width: int,
	corner_radius: int
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	style.anti_aliasing = true
	return style


func _style_leaderboard_tab(button: Button, accent: Color) -> void:
	if button == null:
		return
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", Color(0.58, 0.63, 0.69))
	button.add_theme_color_override("font_hover_color", Color(0.94, 0.96, 0.99))
	button.add_theme_color_override("font_pressed_color", accent.lightened(0.26))
	button.add_theme_color_override("font_hover_pressed_color", accent.lightened(0.32))
	button.add_theme_color_override("font_focus_color", Color(0.96, 0.97, 1.0))
	var normal := _create_leaderboard_style(
		Color(0.018, 0.025, 0.035, 0.98),
		Color(0.24, 0.29, 0.34, 0.72),
		1,
		9
	)
	var hover := _create_leaderboard_style(
		Color(accent.darkened(0.78), 0.98),
		Color(accent, 0.72),
		1,
		9
	)
	var pressed := _create_leaderboard_style(
		Color(accent.darkened(0.76), 0.995),
		Color(accent, 0.96),
		2,
		9
	)
	var focus := _create_leaderboard_style(
		Color(0.0, 0.0, 0.0, 0.0),
		Color(accent.lightened(0.18), 0.92),
		2,
		9
	)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("hover_pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)


func _style_leaderboard_action_button(button: Button, accent: Color) -> void:
	if button == null:
		return
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", Color(0.79, 0.83, 0.88))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.97, 0.88))
	button.add_theme_color_override("font_pressed_color", accent.lightened(0.28))
	var normal := _create_leaderboard_style(
		Color(0.018, 0.025, 0.034, 0.98),
		Color(accent, 0.42),
		1,
		9
	)
	var hover := _create_leaderboard_style(
		Color(accent.darkened(0.78), 0.99),
		Color(accent, 0.86),
		1,
		9
	)
	var pressed := _create_leaderboard_style(
		Color(accent.darkened(0.72), 0.99),
		Color(accent.lightened(0.12), 0.98),
		2,
		9
	)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("hover_pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)


func _create_global_leaderboard_header() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "ColumnHeader"
	panel.custom_minimum_size.y = 30.0
	panel.add_theme_stylebox_override(
		"panel",
		_create_leaderboard_style(
			Color(0.040, 0.046, 0.054, 0.995),
			Color(0.73, 0.58, 0.27, 0.48),
			1,
			6
		)
	)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 12)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)
	var stripe_spacer := Control.new()
	stripe_spacer.custom_minimum_size.x = 4.0
	row.add_child(stripe_spacer)
	var rank_header := _create_global_board_label(
		"RANK", 76.0, HORIZONTAL_ALIGNMENT_CENTER, 11
	)
	rank_header.add_theme_color_override("font_color", Color(0.73, 0.65, 0.48))
	row.add_child(rank_header)
	var player_label := _create_global_board_label(
		"PLAYER",
		0.0,
		HORIZONTAL_ALIGNMENT_LEFT,
		11
	)
	player_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_label.add_theme_color_override("font_color", Color(0.73, 0.65, 0.48))
	row.add_child(player_label)
	_leaderboards_value_header_label = _create_global_board_label(
		"MMR", 160.0, HORIZONTAL_ALIGNMENT_RIGHT, 11
	)
	_leaderboards_value_header_label.add_theme_color_override(
		"font_color", Color(0.73, 0.65, 0.48)
	)
	row.add_child(_leaderboards_value_header_label)
	return panel


func _create_global_board_label(
	text_value: String,
	minimum_width: float,
	alignment: HorizontalAlignment,
	font_size: int
) -> Label:
	var label := Label.new()
	label.text = text_value
	label.custom_minimum_size.x = minimum_width
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.80, 0.84, 0.89))
	return label


func _leaderboard_status_color(status: String) -> Color:
	var upper := status.to_upper()
	if upper.contains("OFFLINE") or upper.contains("FAILED") or upper.contains("UNAVAILABLE"):
		return Color(0.91, 0.48, 0.45)
	if upper.contains("LOADING") or upper.contains("CONNECTING") or upper.contains("SYNCING"):
		return Color(0.91, 0.72, 0.34)
	return Color(0.45, 0.86, 0.67)


func _select_global_leaderboard_category(category: StringName) -> void:
	_leaderboards_active_category = (
		category
		if category in [&"pve_mmr", &"goals", &"saves"]
		else &"pve_mmr"
	)
	if _leaderboards_mmr_button != null:
		_leaderboards_mmr_button.set_pressed_no_signal(
			_leaderboards_active_category == &"pve_mmr"
		)
	if _leaderboards_goals_button != null:
		_leaderboards_goals_button.set_pressed_no_signal(
			_leaderboards_active_category == &"goals"
		)
	if _leaderboards_saves_button != null:
		_leaderboards_saves_button.set_pressed_no_signal(
			_leaderboards_active_category == &"saves"
		)
	_render_global_leaderboard()
	if (
		_leaderboards_steam_manager != null
		and _leaderboards_steam_manager.has_method("request_global_leaderboard")
	):
		_leaderboards_steam_manager.call(
			"request_global_leaderboard",
			_leaderboards_active_category
		)


func _refresh_global_leaderboard() -> void:
	_sync_global_career_scores()
	if (
		_leaderboards_steam_manager != null
		and _leaderboards_steam_manager.has_method("request_global_leaderboard")
	):
		_leaderboards_steam_manager.call(
			"request_global_leaderboard",
			_leaderboards_active_category
		)


func _sync_global_career_scores() -> void:
	if (
		_leaderboards_steam_manager != null
		and _leaderboards_steam_manager.has_method("sync_career_leaderboards")
	):
		_leaderboards_steam_manager.call(
			"sync_career_leaderboards",
			_career_goals,
			_career_saves,
			_current_pve_mmr()
		)


func _current_pve_mmr() -> int:
	if _singleplayer_rank_snapshot.is_empty() and match_manager != null:
		_singleplayer_rank_snapshot = (
			match_manager.refresh_singleplayer_ranked_profile()
		)
	return maxi(
		0,
		int(_singleplayer_rank_snapshot.get(
			"mmr",
			FootballMatchManager.PVE_RANKED_STARTING_MMR
		))
	)


func _on_global_leaderboard_changed(
	category: StringName,
	entries: Array,
	status: String
) -> void:
	if category not in [&"pve_mmr", &"goals", &"saves"]:
		return
	_leaderboards_entries[category] = entries.duplicate(true)
	_leaderboards_statuses[category] = status
	if category == _leaderboards_active_category:
		_render_global_leaderboard()


func _render_global_leaderboard() -> void:
	if _leaderboards_rows == null:
		return
	for child: Node in _leaderboards_rows.get_children():
		_leaderboards_rows.remove_child(child)
		child.queue_free()
	var category: StringName = _leaderboards_active_category
	var category_title: String = "PVE MMR"
	var accent := Color(0.64, 0.48, 1.0)
	if category == &"goals":
		category_title = "GOALS"
		accent = Color(0.95, 0.72, 0.20)
	elif category == &"saves":
		category_title = "SAVES"
		accent = Color(0.24, 0.78, 1.0)
	if _leaderboards_category_label != null:
		_leaderboards_category_label.text = "%s  /  ALL-TIME RECORDS" % category_title
		_leaderboards_category_label.add_theme_color_override("font_color", accent.lightened(0.12))
	if _leaderboards_value_header_label != null:
		_leaderboards_value_header_label.text = (
			"MMR" if category == &"pve_mmr" else category_title
		)
	if _leaderboards_scope_note != null:
		_leaderboards_scope_note.text = (
			"TOP 100 GLOBAL  •  CURRENT PVE RATING  •  STEAM VERIFIED"
			if category == &"pve_mmr"
			else "TOP 100 GLOBAL  •  BEST CAREER TOTAL  •  STEAM VERIFIED"
		)
	if _leaderboards_status_label != null:
		var status_text := str(
			_leaderboards_statuses.get(category, "STEAM OFFLINE")
		)
		_leaderboards_status_label.text = "●  %s" % status_text
		_leaderboards_status_label.add_theme_color_override(
			"font_color", _leaderboard_status_color(status_text)
		)
	var entries: Array = (
		_leaderboards_entries.get(category, []) as Array
	).duplicate(true)
	if category == &"goals":
		var dictator_entry: Dictionary = {
			"rank": 1,
			"steam_id": 0,
			"name": GLOBAL_LEADERBOARD_DICTATOR_NAME,
			"score": GLOBAL_LEADERBOARD_DICTATOR_GOALS,
		}
		var insert_index: int = entries.size()
		for index: int in range(entries.size()):
			var existing: Dictionary = entries[index] as Dictionary
			if GLOBAL_LEADERBOARD_DICTATOR_GOALS > int(existing.get("score", 0)):
				insert_index = index
				break
		entries.insert(insert_index, dictator_entry)
		for index: int in range(entries.size()):
			var displayed_entry: Dictionary = entries[index] as Dictionary
			displayed_entry["rank"] = index + 1
	if entries.is_empty():
		var empty_label := Label.new()
		empty_label.name = "EmptyState"
		empty_label.text = "CONNECTING TO THE GLOBAL TABLE..."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_label.custom_minimum_size.y = 220.0
		empty_label.add_theme_font_size_override("font_size", 18)
		empty_label.add_theme_color_override("font_color", Color(0.58, 0.66, 0.70))
		_leaderboards_rows.add_child(empty_label)
		return
	var local_steam_id: int = 0
	if (
		_leaderboards_steam_manager != null
		and _leaderboards_steam_manager.has_method(
			"is_global_leaderboard_available"
		)
		and bool(_leaderboards_steam_manager.call(
			"is_global_leaderboard_available"
		))
		and Engine.has_singleton("Steam")
	):
		local_steam_id = _steam_api().getSteamID()
	for index: int in range(entries.size()):
		var entry: Dictionary = entries[index] as Dictionary
		var is_local: bool = (
			bool(entry.get("local_only", false))
			or (
				local_steam_id > 0
				and int(entry.get("steam_id", 0)) == local_steam_id
			)
		)
		_leaderboards_rows.add_child(
			_create_global_leaderboard_row(entry, index, accent, is_local)
		)


func _create_global_leaderboard_row(
	entry: Dictionary,
	index: int,
	accent: Color,
	is_local: bool
) -> PanelContainer:
	var rank: int = maxi(1, int(entry.get("rank", index + 1)))
	var is_podium: bool = rank <= 3
	var podium_accent := accent
	var background := Color(0.026, 0.034, 0.044, 0.975)
	if index % 2 == 1:
		background = Color(0.019, 0.026, 0.036, 0.975)
	if rank == 1:
		podium_accent = Color(1.0, 0.79, 0.30)
		background = Color(0.105, 0.073, 0.026, 0.99)
	elif rank == 2:
		podium_accent = Color(0.76, 0.84, 0.92)
		background = Color(0.054, 0.067, 0.082, 0.99)
	elif rank == 3:
		podium_accent = Color(0.84, 0.52, 0.28)
		background = Color(0.082, 0.050, 0.030, 0.99)
	elif is_local:
		background = Color(accent.darkened(0.79), 0.99)

	var border_color := Color(accent, 0.22)
	var border_width := 1
	if is_podium:
		border_color = Color(podium_accent, 0.82)
		border_width = 2
	elif is_local:
		border_color = Color(accent.lightened(0.16), 0.92)
		border_width = 2

	var row_panel := PanelContainer.new()
	row_panel.name = "LeaderboardRow%03d" % index
	row_panel.set_meta("prestige_rank", rank)
	row_panel.set_meta("prestige_podium", is_podium)
	row_panel.add_theme_stylebox_override(
		"panel",
		_create_leaderboard_style(
			background,
			border_color,
			border_width,
			8
		)
	)
	row_panel.custom_minimum_size.y = 50.0 if is_podium else 44.0

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 3)
	margin.add_theme_constant_override("margin_bottom", 3)
	row_panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)

	var prestige_stripe := ColorRect.new()
	prestige_stripe.name = "RankAccent"
	prestige_stripe.custom_minimum_size.x = 4.0
	prestige_stripe.color = Color(
		podium_accent if is_podium else accent,
		0.95 if is_podium or is_local else 0.30
	)
	prestige_stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(prestige_stripe)

	var rank_text: String = "#%02d" % rank
	if rank == 1:
		rank_text = "◆  #1"
	elif rank == 2:
		rank_text = "◇  #2"
	elif rank == 3:
		rank_text = "◇  #3"
	var rank_label := _create_global_board_label(
		rank_text,
		76.0,
		HORIZONTAL_ALIGNMENT_CENTER,
		18 if is_podium else 15
	)
	rank_label.add_theme_color_override(
		"font_color",
		podium_accent if is_podium else Color(0.67, 0.72, 0.78)
	)
	row.add_child(rank_label)

	var player_name: String = str(entry.get("name", "STEAM PLAYER"))
	if is_local:
		player_name += "   •  YOU"
	var name_label := _create_global_board_label(
		player_name,
		0.0,
		HORIZONTAL_ALIGNMENT_LEFT,
		18 if is_podium else 16
	)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if is_podium:
		name_label.add_theme_color_override("font_color", podium_accent.lightened(0.20))
	elif is_local:
		name_label.add_theme_color_override("font_color", accent.lightened(0.28))
	row.add_child(name_label)

	var score := maxi(0, int(entry.get("score", 0)))
	if _leaderboards_active_category == &"pve_mmr":
		row.add_child(_create_global_mmr_badge(score))
	else:
		var score_label := _create_global_board_label(
			str(score),
			160.0,
			HORIZONTAL_ALIGNMENT_RIGHT,
			22 if is_podium else 19
		)
		score_label.add_theme_color_override(
			"font_color",
			podium_accent if is_podium else accent
		)
		row.add_child(score_label)
	return row_panel


func _create_global_mmr_badge(mmr: int) -> RichTextLabel:
	var badge := RichTextLabel.new()
	badge.name = "MmrBadge"
	badge.bbcode_enabled = true
	badge.fit_content = true
	badge.scroll_active = false
	badge.autowrap_mode = TextServer.AUTOWRAP_OFF
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.custom_minimum_size.x = 150.0
	badge.size_flags_horizontal = Control.SIZE_SHRINK_END
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.add_theme_font_size_override("normal_font_size", 20)
	badge.set_meta("rank_glint_mmr", maxi(0, mmr))
	badge.text = _format_global_mmr_badge(mmr)
	badge.tooltip_text = FootballMatchManager.get_singleplayer_ranked_division_name(
		FootballMatchManager.get_singleplayer_ranked_division_for_mmr(mmr)
	)
	_ranked_glint_nodes.append(badge)
	return badge


func _format_global_mmr_badge(mmr: int) -> String:
	var safe_mmr := maxi(0, mmr)
	var division := FootballMatchManager.get_singleplayer_ranked_division_for_mmr(
		safe_mmr
	)
	var base_color := FootballMatchManager.get_singleplayer_ranked_division_color(
		division
	)
	var outline_color := base_color.darkened(0.62)
	var digits := str(safe_mmr)
	var digit_body := (
		_build_ranked_glint_bbcode(digits, division)
		if FootballMatchManager.singleplayer_ranked_division_is_animated(division)
		else "[color=#%s]%s[/color]" % [base_color.to_html(false), digits]
	)
	return (
		"[right][outline_size=2][outline_color=#%s][color=#%s][[/color]%s[color=#%s]][/color][/outline_color][/outline_size][/right]"
		% [
			outline_color.to_html(false),
			base_color.to_html(false),
			digit_body,
			base_color.to_html(false),
		]
	)


func _build_steam_mode_popup() -> void:
	if _steam_mode_popup != null:
		return
	_steam_mode_popup = PopupPanel.new()
	_steam_mode_popup.name = "SteamModePopup"
	_steam_mode_popup.exclusive = true
	add_child(_steam_mode_popup)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	_steam_mode_popup.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	margin.add_child(content)
	var title := Label.new()
	title.text = "CHOOSE GAME MODE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	content.add_child(title)
	var explanation := Label.new()
	explanation.text = (
		"Standard creates a normal custom lobby.\n"
		+ "Draft is a two-leg card-pick mode. PvE Ranked uses Draft against CPUs."
	)
	explanation.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(explanation)
	_steam_standard_button = Button.new()
	_steam_standard_button.name = "StandardModeButton"
	_steam_standard_button.text = "STANDARD MATCH"
	_steam_standard_button.custom_minimum_size.y = 62.0
	_steam_standard_button.pressed.connect(
		func() -> void:
			_host_selected_steam_mode(NetworkManager.STEAM_SESSION_STANDARD)
	)
	content.add_child(_steam_standard_button)
	_steam_draft_button = Button.new()
	_steam_draft_button.name = "DraftModeButton"
	_steam_draft_button.text = "DRAFT  •  TWO-LEG CARD MODE"
	_steam_draft_button.tooltip_text = (
		"Three-minute legs. Pick one of five cards before each leg; "
		+ "your first-leg ability is locked for leg two."
	)
	_steam_draft_button.custom_minimum_size.y = 62.0
	_steam_draft_button.pressed.connect(
		func() -> void:
			_host_selected_steam_mode(NetworkManager.STEAM_SESSION_DRAFT)
	)
	content.add_child(_steam_draft_button)
	_steam_ladder_button = Button.new()
	_steam_ladder_button.name = "LadderModeButton"
	_steam_ladder_button.text = "CONTINUE PvE LADDER"
	_steam_ladder_button.tooltip_text = (
		"A persistent roguelike run with Ranked rules and scaling CPU teams."
	)
	_steam_ladder_button.custom_minimum_size.y = 62.0
	_steam_ladder_button.pressed.connect(
		func() -> void:
			_host_selected_steam_mode(
				NetworkManager.STEAM_SESSION_LADDER,
				false
			)
	)
	content.add_child(_steam_ladder_button)
	_steam_ladder_fresh_button = Button.new()
	_steam_ladder_fresh_button.name = "LadderFreshStartButton"
	_steam_ladder_fresh_button.text = "START FROM BEGINNING"
	_steam_ladder_fresh_button.tooltip_text = (
		"Replace the active run with a new run at rung one. Career ladder records remain."
	)
	_steam_ladder_fresh_button.custom_minimum_size.y = 62.0
	_steam_ladder_fresh_button.pressed.connect(
		func() -> void:
			_host_selected_steam_mode(
				NetworkManager.STEAM_SESSION_LADDER,
				true
			)
	)
	content.add_child(_steam_ladder_fresh_button)
	var ranked_heading := Label.new()
	ranked_heading.text = "CO-OP PVE RANKED • CHOOSE FORMAT"
	ranked_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ranked_heading.add_theme_font_size_override("font_size", 18)
	ranked_heading.add_theme_color_override(
		"font_color",
		Color(1.0, 0.82, 0.28)
	)
	content.add_child(ranked_heading)
	var ranked_sizes := HBoxContainer.new()
	ranked_sizes.name = "RankedSizeButtons"
	ranked_sizes.add_theme_constant_override("separation", 12)
	content.add_child(ranked_sizes)
	_steam_ranked_size_buttons.clear()
	for team_size: int in range(2, 7):
		var ranked_button := Button.new()
		ranked_button.name = "Ranked%dv%dButton" % [team_size, team_size]
		ranked_button.text = "%dV%d" % [team_size, team_size]
		ranked_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ranked_button.custom_minimum_size.y = 58.0
		ranked_button.tooltip_text = (
			"Human players share one side; CPUs fill empty slots, then every "
			+ "player drafts an ability and perk before each leg."
		)
		ranked_button.pressed.connect(
			_host_selected_steam_mode.bind(
				NetworkManager.STEAM_SESSION_PVE_RANKED,
				false,
				team_size
			)
		)
		ranked_sizes.add_child(ranked_button)
		_steam_ranked_size_buttons.append(ranked_button)


func _host_selected_steam_mode(
	game_mode: int,
	start_ladder_from_beginning: bool = false,
	ranked_team_size: int = 2
) -> void:
	if _steam_mode_popup != null:
		_steam_mode_popup.hide()
	_set_lobby_browser_busy(true, "Creating...")
	var lobby_type: int = lobby_visibility_option.get_selected_id()
	if not network_manager.host_steam(
		lobby_name_edit.text,
		lobby_type,
		game_mode,
		start_ladder_from_beginning,
		ranked_team_size
	):
		_set_lobby_browser_busy(false)


func _refresh_steam_lobbies() -> void:
	if not _multiplayer_open:
		return
	if not network_manager.request_steam_lobbies():
		_set_lobby_browser_busy(false)


func _on_lobby_search_started() -> void:
	_set_lobby_browser_busy(true, "Searching...")
	_show_lobby_browser_message("Searching Steam lobbies...")


func _on_lobby_list_updated(lobbies: Array[Dictionary]) -> void:
	_set_lobby_browser_busy(false)
	_render_lobby_rows(lobbies)


func _render_lobby_rows(lobbies: Array[Dictionary]) -> void:
	_clear_lobby_rows()
	lobby_count_label.text = "AVAILABLE LOBBIES — %d" % lobbies.size()
	if lobbies.is_empty():
		_show_lobby_browser_message(
			"No open lobbies found. Create one or refresh again."
		)
		return

	for lobby_data in lobbies:
		_create_lobby_row(lobby_data)


func _clear_lobby_rows() -> void:
	_lobby_join_buttons.clear()
	for child in lobby_list.get_children():
		lobby_list.remove_child(child)
		child.queue_free()


func _show_lobby_browser_message(message: String) -> void:
	_clear_lobby_rows()
	var label := Label.new()
	label.custom_minimum_size = Vector2(0.0, 110.0)
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override(
		"font_color",
		Color(0.62, 0.72, 0.78)
	)
	label.add_theme_font_size_override("font_size", 18)
	lobby_list.add_child(label)


func _create_lobby_row(lobby_data: Dictionary) -> void:
	var lobby_id := int(lobby_data.get("id", 0))
	var member_count := int(lobby_data.get("members", 0))
	var member_limit := int(lobby_data.get("max_members", 16))
	var lobby_name := str(lobby_data.get("name", "Steam Lobby"))
	var host_name := str(lobby_data.get("host", ""))
	var match_state: String = str(lobby_data.get("state", "waiting"))
	var map_name: String = str(lobby_data.get("map", "Map 1"))
	var match_minutes: int = int(lobby_data.get("match_minutes", 3))
	var goals_to_win: int = int(lobby_data.get("goals_to_win", 5))
	var active_players: int = int(lobby_data.get("players", 0))
	var player_slots: int = int(lobby_data.get("player_slots", 12))
	var spectators: int = int(lobby_data.get("spectators", 0))
	var spectator_slots: int = int(lobby_data.get("spectator_slots", 4))
	var game_mode: String = str(lobby_data.get("mode", "standard"))
	var ranked_team_size: int = int(lobby_data.get("ranked_team_size", 2))

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0.0, 76.0)
	panel.tooltip_text = "Steam Lobby ID: %d" % lobby_id
	MenuStyler.style_panel(
		panel,
		Color(0.84, 0.72, 0.40),
		Color(0.018, 0.032, 0.024, 1.0)
	)
	lobby_list.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 9)
	margin.add_theme_constant_override("margin_bottom", 9)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", MenuStyler.MENU_SPACING)
	margin.add_child(row)

	var text_column := VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_column)

	var name_label := Label.new()
	name_label.text = lobby_name
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override(
		"font_color",
		Color(0.96, 0.94, 0.86)
	)
	text_column.add_child(name_label)

	var details := Label.new()
	var state_label: String = "IN MATCH" if match_state == "playing" else "WAITING"
	if game_mode == "ladder":
		state_label = "PVE LADDER / " + state_label
	elif game_mode == "pve_ranked":
		state_label = "PVE RANKED %dV%d / %s" % [
			ranked_team_size,
			ranked_team_size,
			state_label
		]
	elif game_mode == "draft":
		state_label = "DRAFT / " + state_label
	details.text = "%s   •   %s   •   %dm   •   FIRST TO %d" % [
		state_label, map_name, match_minutes, goals_to_win
	]
	if not host_name.is_empty():
		details.text += "   •   HOST: %s" % host_name
	var capacity_label := Label.new()
	capacity_label.text = (
		"%d/%d PLAYERS   •   %d/%d SPECTATORS   •   %d/%d CONNECTED"
		% [
			active_players, player_slots, spectators, spectator_slots,
			member_count, member_limit
		]
	)
	capacity_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	capacity_label.add_theme_font_size_override("font_size", 13)
	capacity_label.add_theme_color_override(
		"font_color",
		Color(0.5, 0.62, 0.7)
	)
	text_column.add_child(capacity_label)
	details.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	details.add_theme_font_size_override("font_size", 15)
	details.add_theme_color_override(
		"font_color",
		Color(0.6, 0.68, 0.74)
	)
	text_column.add_child(details)

	var join_button := Button.new()
	join_button.custom_minimum_size = Vector2(120.0, 48.0)
	join_button.text = "WATCH" if match_state == "playing" else "JOIN"
	join_button.pressed.connect(_join_steam_lobby.bind(lobby_id))
	MenuStyler.style_button(
		join_button,
		Color(0.31, 0.86, 0.56),
		48.0
	)
	row.add_child(join_button)
	_lobby_join_buttons.append(join_button)


func _join_steam_lobby(lobby_id: int) -> void:
	_set_lobby_browser_busy(true, "Connecting...")
	for button in _lobby_join_buttons:
		button.disabled = true
	if not network_manager.join_steam_lobby(lobby_id):
		_set_lobby_browser_busy(false)


func _set_lobby_browser_busy(
	busy: bool,
	refresh_text: String = "Refresh"
) -> void:
	refresh_lobbies_button.disabled = busy
	refresh_lobbies_button.text = refresh_text if busy else "Refresh"
	create_lobby_button.disabled = busy
	lobby_name_edit.editable = not busy
	lobby_visibility_option.disabled = busy
	steam_game_mode_option.disabled = busy
	for button in _lobby_join_buttons:
		button.disabled = busy


func _input(event: InputEvent) -> void:
	if not _waiting_for_controller_action.is_empty():
		if _handle_controller_rebind_input(event):
			get_viewport().set_input_as_handled()
		return
	if _waiting_for_key_action.is_empty():
		return

	var key_event := event as InputEventKey
	if (
		key_event == null
		or not key_event.pressed
		or key_event.echo
	):
		return

	get_viewport().set_input_as_handled()
	if key_event.keycode == KEY_ESCAPE:
		_waiting_for_key_action = &""
		_update_keybind_texts()
		return

	_set_action_key(
		_waiting_for_key_action,
		key_event.keycode,
		key_event.physical_keycode
	)
	_waiting_for_key_action = &""
	_save_settings()
	_update_keybind_texts()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not controller_support.using_controller:
		return
	if not event.is_action_pressed(&"ui_cancel"):
		return
	if not _waiting_for_controller_action.is_empty():
		_waiting_for_controller_action = &""
		_controller_rebind_button = null
		_update_controller_binding_texts()
		get_viewport().set_input_as_handled()
		return
	if options_panel.visible:
		_set_options_open(false)
		get_viewport().set_input_as_handled()
		return
	if multiplayer_panel.visible:
		_set_multiplayer_open(false)
		get_viewport().set_input_as_handled()


func _clear_removed_first_touch_bindings() -> void:
	# These actions are intentionally hidden and unbound. Keep the InputMap
	# actions themselves so old gameplay checks stay harmless, but clear every
	# keyboard/controller event and purge legacy saved binding keys.
	for action: StringName in [&"first_touch_trap", &"first_touch_dummy"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_erase_events(action)
	for key: String in [
		"first_touch_trap_keycode",
		"first_touch_trap_physical_keycode",
		"first_touch_dummy_keycode",
		"first_touch_dummy_physical_keycode",
		"first_touch_trap_joy_kind",
		"first_touch_trap_joy_button",
		"first_touch_trap_joy_axis",
		"first_touch_trap_joy_axis_value",
		"first_touch_dummy_joy_kind",
		"first_touch_dummy_joy_button",
		"first_touch_dummy_joy_axis",
		"first_touch_dummy_joy_axis_value",
	]:
		if _settings.has_section_key("controls", key):
			_settings.erase_section_key("controls", key)


func _load_settings() -> void:
	for action in [
		&"ability",
		&"soft_pass",
		&"request_pass",
		&"quick_chat"
	]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)

	var load_result := _settings.load(SETTINGS_PATH)
	_clear_removed_first_touch_bindings()
	var volume_percent := 100.0
	var ability_keycode := int(KEY_SHIFT)
	var ability_physical_keycode := 0
	var soft_pass_keycode := int(KEY_CTRL)
	var soft_pass_physical_keycode := 0
	var pass_keycode := int(KEY_R)
	var pass_physical_keycode := 0
	var chat_keycode := int(KEY_C)
	var chat_physical_keycode := 0
	var direction_indicator_enabled := true
	var fullscreen_enabled := false
	var ball_appearance := BALL_STYLE_THEODORE

	if load_result == OK:
		volume_percent = float(
			_settings.get_value("audio", "master_volume", 100.0)
		)
		ability_keycode = int(
			_settings.get_value("controls", "ability_keycode", KEY_SHIFT)
		)
		ability_physical_keycode = int(
			_settings.get_value(
				"controls",
				"ability_physical_keycode",
				0
			)
		)
		soft_pass_keycode = int(
			_settings.get_value("controls", "soft_pass_keycode", KEY_CTRL)
		)
		soft_pass_physical_keycode = int(
			_settings.get_value(
				"controls",
				"soft_pass_physical_keycode",
				0
			)
		)
		pass_keycode = int(
			_settings.get_value("controls", "pass_request_keycode", KEY_R)
		)
		pass_physical_keycode = int(
			_settings.get_value(
				"controls",
				"pass_request_physical_keycode",
				0
			)
		)
		chat_keycode = int(
			_settings.get_value("controls", "quick_chat_keycode", KEY_C)
		)
		chat_physical_keycode = int(
			_settings.get_value(
				"controls",
				"quick_chat_physical_keycode",
				0
			)
		)
		direction_indicator_enabled = bool(
			_settings.get_value(
				"gameplay",
				"direction_indicator_enabled",
				true
			)
		)
		fullscreen_enabled = bool(
			_settings.get_value(
				"display",
				"fullscreen_enabled",
				false
			)
		)
		ball_appearance = StringName(
			str(
				_settings.get_value(
					"display",
					"ball_appearance",
					"theodore"
				)
			)
		)
		_career_goals = maxi(
			0,
			int(_settings.get_value("career", "goals", 0))
		)
		_career_saves = maxi(
			0,
			int(_settings.get_value("career", "saves", 0))
		)

	# Repair settings created while Soft Pass had no project-level default binding.
	if soft_pass_keycode == 0 and soft_pass_physical_keycode == 0:
		soft_pass_keycode = int(KEY_CTRL)

	volume_slider.set_value_no_signal(volume_percent)
	direction_indicator_toggle.set_pressed_no_signal(
		direction_indicator_enabled
	)
	fullscreen_toggle.set_pressed_no_signal(fullscreen_enabled)
	_selected_ball_appearance_style = StringName(
		FootballBall.get_ball_appearance_variant(ball_appearance).get(
			"style",
			BALL_STYLE_THEODORE
		)
	)
	_refresh_ball_appearance_picker()
	_apply_master_volume(volume_percent)
	_apply_direction_indicator_setting(direction_indicator_enabled)
	_apply_ball_appearance_setting(_selected_ball_appearance_style)
	var fullscreen_manager := get_node_or_null("/root/FullscreenManager")
	if fullscreen_manager != null:
		fullscreen_manager.call("set_fullscreen", fullscreen_enabled)
	_set_action_key(
		&"ability",
		ability_keycode,
		ability_physical_keycode
	)
	_set_action_key(
		&"soft_pass",
		soft_pass_keycode,
		soft_pass_physical_keycode
	)
	_set_action_key(&"request_pass", pass_keycode, pass_physical_keycode)
	_set_action_key(&"quick_chat", chat_keycode, chat_physical_keycode)
	_load_controller_settings(load_result)
	_update_keybind_texts()
	_update_controller_binding_texts()
	_update_career_stats_text()
	_sync_global_career_scores()


func _save_settings() -> void:
	_settings.set_value(
		"audio",
		"master_volume",
		volume_slider.value
	)
	_settings.set_value(
		"gameplay",
		"direction_indicator_enabled",
		direction_indicator_toggle.button_pressed
	)
	_settings.set_value(
		"display",
		"fullscreen_enabled",
		fullscreen_toggle.button_pressed
	)
	_settings.set_value(
		"display",
		"ball_appearance",
		str(_selected_ball_appearance())
	)
	_save_action_binding(&"ability", "ability", KEY_SHIFT)
	_save_action_binding(&"soft_pass", "soft_pass", KEY_CTRL)
	_save_action_binding(&"request_pass", "pass_request", KEY_R)
	_save_action_binding(&"quick_chat", "quick_chat", KEY_C)
	_save_controller_settings()
	_settings.set_value("career", "goals", _career_goals)
	_settings.set_value("career", "saves", _career_saves)
	_settings.save(SETTINGS_PATH)


func _save_action_binding(
	action: StringName,
	setting_prefix: String,
	default_key: Key
) -> void:
	var keycode := int(default_key)
	var physical_keycode := 0
	var events := InputMap.action_get_events(action)
	for event in events:
		if event is InputEventKey:
			var key_event := event as InputEventKey
			keycode = int(key_event.keycode)
			physical_keycode = int(key_event.physical_keycode)
			break
	_settings.set_value(
		"controls",
		"%s_keycode" % setting_prefix,
		keycode
	)
	_settings.set_value(
		"controls",
		"%s_physical_keycode" % setting_prefix,
		physical_keycode
	)


func _set_action_key(
	action: StringName,
	keycode: int,
	physical_keycode: int
) -> void:
	for existing_event in InputMap.action_get_events(action):
		if existing_event is InputEventKey:
			InputMap.action_erase_event(action, existing_event)
	var key_event := InputEventKey.new()
	if physical_keycode != 0:
		key_event.physical_keycode = physical_keycode as Key
	else:
		key_event.keycode = keycode as Key
	InputMap.action_add_event(action, key_event)


func _begin_key_rebind(action: StringName, button: Button) -> void:
	_waiting_for_key_action = action
	button.text = "Press any key... (Esc cancels)"


func _get_action_key_text(action: StringName) -> String:
	return controller_support.get_keyboard_binding_text(action)


func _update_keybind_texts() -> void:
	ability_key_button.text = "Ability Key: %s" % _get_action_key_text(
		&"ability"
	)
	soft_pass_key_button.text = "Soft Pass Key: %s" % (
		_get_action_key_text(&"soft_pass")
	)
	pass_request_key_button.text = "Pass Request Key: %s" % (
		_get_action_key_text(&"request_pass")
	)
	quick_chat_key_button.text = "Quick Chat Key: %s" % (
		_get_action_key_text(&"quick_chat")
	)


func _toggle_bindings_mode() -> void:
	_set_bindings_mode(not _show_controller_bindings)


func _set_bindings_mode(show_controller: bool) -> void:
	_show_controller_bindings = show_controller
	for key_button in [
		ability_key_button,
		soft_pass_key_button,
		pass_request_key_button,
		quick_chat_key_button
	]:
		key_button.visible = not show_controller
	controller_status_label.visible = show_controller
	controller_prompt_style_button.visible = show_controller
	controller_bindings.visible = show_controller
	bindings_mode_button.text = (
		"Controls: Controller"
		if show_controller
		else "Controls: Keyboard"
	)
	_waiting_for_key_action = &""
	_waiting_for_controller_action = &""
	_controller_rebind_button = null
	_update_keybind_texts()
	_update_controller_binding_texts()
	if controller_support.using_controller:
		bindings_mode_button.grab_focus()


func _open_controller_test_panel() -> void:
	if _controller_test_panel == null:
		return
	_controller_test_panel.open_panel()


func _on_controller_test_closed() -> void:
	_update_controller_binding_texts()
	if options_panel.visible:
		controller_prompt_style_button.call_deferred("grab_focus")


func _begin_controller_rebind(
	action: StringName,
	button: Button
) -> void:
	_waiting_for_controller_action = action
	_controller_rebind_button = button
	button.text = "Press a button or move an axis..."


func _handle_controller_rebind_input(event: InputEvent) -> bool:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and key_event.keycode == KEY_ESCAPE:
			_waiting_for_controller_action = &""
			_controller_rebind_button = null
			_update_controller_binding_texts()
			return true
		return false
	var controller_event: InputEvent
	if (
		(event is InputEventJoypadButton or event is InputEventJoypadMotion)
		and not controller_support.is_controller_event_assigned(event)
	):
		return false
	if event is InputEventJoypadButton:
		var button_event := event as InputEventJoypadButton
		if not button_event.pressed:
			return false
		if button_event.button_index == JOY_BUTTON_B:
			_waiting_for_controller_action = &""
			_controller_rebind_button = null
			_update_controller_binding_texts()
			return true
		controller_event = button_event
	elif event is InputEventJoypadMotion:
		var motion_event := event as InputEventJoypadMotion
		if absf(motion_event.axis_value) < 0.72:
			return false
		var normalized_motion := InputEventJoypadMotion.new()
		normalized_motion.axis = motion_event.axis
		normalized_motion.axis_value = signf(motion_event.axis_value)
		controller_event = normalized_motion
	else:
		return false
	controller_support.set_controller_binding(
		_waiting_for_controller_action,
		controller_event
	)
	_waiting_for_controller_action = &""
	_controller_rebind_button = null
	_save_settings()
	_update_controller_binding_texts()
	return true


func _toggle_movement_stick() -> void:
	controller_support.set_movement_stick(
		not controller_support.movement_uses_right_stick
	)
	_save_settings()
	_update_controller_binding_texts()


func _reset_controller_bindings() -> void:
	controller_support.reset_controller_bindings()
	_save_settings()
	_update_controller_binding_texts()


func _update_controller_binding_texts() -> void:
	if not is_node_ready():
		return
	controller_status_label.text = "%s  •  %s" % [
		controller_support.get_prompt_family_text().to_upper(),
		controller_support.get_controller_name()
	]
	controller_prompt_style_button.text = "Controller Test / Profiles"
	controller_prompt_style_button.visible = _show_controller_bindings
	var controller_buttons: Array[Button] = [
		controller_shoot_button,
		controller_ability_button,
		controller_soft_pass_button,
		controller_pass_request_button,
		controller_quick_chat_button,
		controller_leaderboard_button
	]
	for index in range(CONTROLLER_BINDINGS.size()):
		var binding := CONTROLLER_BINDINGS[index]
		var button := controller_buttons[index]
		var action := StringName(binding["action"])
		button.text = "%s   %s" % [
			str(binding["label"]),
			controller_support.get_controller_binding_text(
				action
			)
		]
		button.icon = controller_support.get_controller_binding_icon(action)
		button.expand_icon = true
	movement_stick_button.text = "Movement   %s" % (
		controller_support.get_movement_stick_text()
	)
	movement_stick_button.icon = controller_support.get_controller_axis_icon(
		JOY_AXIS_RIGHT_X
		if controller_support.movement_uses_right_stick
		else JOY_AXIS_LEFT_X
	)
	movement_stick_button.expand_icon = true
	reset_controller_button.icon = controller_support.get_controller_button_icon(
		JOY_BUTTON_Y
	)


func _load_controller_settings(load_result: int) -> void:
	if load_result != OK:
		controller_support.finish_profile_bootstrap()
		return
	controller_support.set_prompt_family_override(
		FootballControllerSupport.FAMILY_AUTO
	)
	controller_support.set_movement_stick(
		bool(
			_settings.get_value(
				"controls",
				"controller_right_stick_movement",
				false
			)
		),
		false
	)
	for binding in CONTROLLER_BINDINGS:
		var prefix := str(binding["prefix"])
		var kind_key := "%s_joy_kind" % prefix
		if not _settings.has_section_key("controls", kind_key):
			continue
		var kind := str(_settings.get_value("controls", kind_key, ""))
		var event: InputEvent
		if kind == "button":
			var button_event := InputEventJoypadButton.new()
			button_event.button_index = int(
				_settings.get_value(
					"controls",
					"%s_joy_button" % prefix,
					0
				)
			)
			event = button_event
		elif kind == "axis":
			var axis_event := InputEventJoypadMotion.new()
			axis_event.axis = int(
				_settings.get_value(
					"controls",
					"%s_joy_axis" % prefix,
					0
				)
			)
			axis_event.axis_value = float(
				_settings.get_value(
					"controls",
					"%s_joy_axis_value" % prefix,
					1.0
				)
			)
			event = axis_event
		elif kind == "unbound":
			controller_support.clear_controller_binding(
				StringName(binding["action"])
			)
		if event != null:
			controller_support.set_controller_binding(
				StringName(binding["action"]),
				event
			)
	controller_support.finish_profile_bootstrap()


func _save_controller_settings() -> void:
	# Per-controller profiles own controller bindings after bootstrap. Keep the
	# legacy player_settings values as a migration/default baseline instead of
	# overwriting them with whichever controller happened to be used last.
	if controller_support.is_profile_persistence_enabled():
		return
	_settings.set_value(
		"controls",
		"controller_prompt_family",
		str(controller_support.prompt_family_override)
	)
	_settings.set_value(
		"controls",
		"controller_right_stick_movement",
		controller_support.movement_uses_right_stick
	)
	for binding in CONTROLLER_BINDINGS:
		var action := StringName(binding["action"])
		var prefix := str(binding["prefix"])
		var event := controller_support.get_controller_binding(action)
		if event is InputEventJoypadButton:
			_settings.set_value(
				"controls",
				"%s_joy_kind" % prefix,
				"button"
			)
			_settings.set_value(
				"controls",
				"%s_joy_button" % prefix,
				(event as InputEventJoypadButton).button_index
			)
		elif event is InputEventJoypadMotion:
			var motion := event as InputEventJoypadMotion
			_settings.set_value(
				"controls",
				"%s_joy_kind" % prefix,
				"axis"
			)
			_settings.set_value(
				"controls",
				"%s_joy_axis" % prefix,
				motion.axis
			)
			_settings.set_value(
				"controls",
				"%s_joy_axis_value" % prefix,
				motion.axis_value
			)
		else:
			_settings.set_value(
				"controls",
				"%s_joy_kind" % prefix,
				"unbound"
			)


func _on_input_method_changed(
	using_gamepad: bool,
	_family: StringName
) -> void:
	_update_controller_binding_texts()
	if using_gamepad and visible:
		var focus_target := (
			bindings_mode_button
			if options_panel.visible
			else refresh_lobbies_button
			if multiplayer_panel.visible
			else toggle_menu_button
			if _main_buttons_hidden
			else singleplayer_button
		)
		focus_target.call_deferred("grab_focus")


func _on_direction_indicator_toggled(enabled: bool) -> void:
	_apply_direction_indicator_setting(enabled)
	_save_settings()


func _apply_direction_indicator_setting(enabled: bool) -> void:
	ProjectSettings.set_setting(
		DIRECTION_INDICATOR_SETTING,
		enabled
	)


func _on_fullscreen_toggled(enabled: bool) -> void:
	var fullscreen_manager := get_node_or_null("/root/FullscreenManager")
	if fullscreen_manager != null:
		fullscreen_manager.call("set_fullscreen", enabled)
	_save_settings()


func _on_fullscreen_changed(enabled: bool) -> void:
	# F11 and the options checkbox share one source of truth. Updating without
	# emitting the CheckButton signal prevents a feedback loop.
	fullscreen_toggle.set_pressed_no_signal(enabled)
	_settings.set_value("display", "fullscreen_enabled", enabled)
	_settings.save(SETTINGS_PATH)


func _selected_ball_appearance() -> StringName:
	return _selected_ball_appearance_style


func _on_ball_appearance_button_pressed(style: StringName) -> void:
	var normalized_style := StringName(
		FootballBall.get_ball_appearance_variant(style).get(
			"style",
			BALL_STYLE_THEODORE
		)
	)
	_selected_ball_appearance_style = normalized_style
	_refresh_ball_appearance_picker()
	_apply_ball_appearance_setting(normalized_style)
	_save_settings()


func _refresh_ball_appearance_picker() -> void:
	for style_variant: Variant in _ball_appearance_buttons.keys():
		var style := StringName(style_variant)
		var button := _ball_appearance_buttons.get(style) as Button
		if button != null:
			button.set_pressed_no_signal(style == _selected_ball_appearance_style)


func _apply_ball_appearance_setting(style: StringName) -> void:
	for node: Node in get_tree().get_nodes_in_group("football_balls"):
		if node.has_method("apply_local_ball_style"):
			node.call("apply_local_ball_style", style)


func _on_volume_changed(value: float) -> void:
	_apply_master_volume(value)
	_save_settings()


func _apply_master_volume(value: float) -> void:
	var normalized := clampf(value / 100.0, 0.0, 1.0)
	AudioServer.set_bus_mute(0, normalized <= 0.0)
	AudioServer.set_bus_volume_db(
		0,
		linear_to_db(maxf(normalized, 0.0001))
	)


func _on_player_stat_earned(
	peer_id: int,
	stat_name: StringName
) -> void:
	if peer_id != multiplayer.get_unique_id():
		return

	match stat_name:
		&"goals":
			_career_goals += 1
		&"saves":
			_career_saves += 1
		_:
			return

	_update_career_stats_text()
	_save_settings()
	_sync_global_career_scores()


func _update_career_stats_text() -> void:
	career_stats_label.text = (
		"CAREER   GOALS: %d   |   SAVES: %d"
		% [_career_goals, _career_saves]
	)


func _set_multiplayer_open(
	open: bool,
	animate: bool = true
) -> void:
	if (
		_multiplayer_transition != null
		and _multiplayer_transition.is_valid()
	):
		_multiplayer_transition.kill()

	_multiplayer_open = open
	if not animate:
		_apply_multiplayer_visibility(open)
		return

	_multiplayer_transition = create_tween()
	_multiplayer_transition.set_trans(Tween.TRANS_QUAD)
	_multiplayer_transition.set_ease(Tween.EASE_IN_OUT)
	_multiplayer_transition.tween_property(
		menu_content,
		"modulate:a",
		0.0,
		0.1
	)
	_multiplayer_transition.tween_callback(
		_apply_multiplayer_visibility.bind(open)
	)
	_multiplayer_transition.tween_property(
		menu_content,
		"modulate:a",
		1.0,
		0.16
	)


func _apply_multiplayer_visibility(open: bool) -> void:
	_set_menu_vertical_offset(0.0)
	career_stats_label.visible = not open
	var show_main_buttons := not open and not _main_buttons_hidden
	if _main_dashboard != null:
		_main_dashboard.visible = show_main_buttons
	for button in _get_main_buttons():
		button.visible = show_main_buttons
		button.modulate.a = 1.0
	options_panel.hide()
	multiplayer_panel.visible = open
	toggle_menu_button.visible = not open
	if open:
		_apply_responsive_menu_layout()
	else:
		_apply_responsive_menu_layout()

	if open:
		lobby_refresh_timer.start()
		_refresh_steam_lobbies.call_deferred()
		if controller_support.using_controller:
			refresh_lobbies_button.grab_focus.call_deferred()
	else:
		lobby_refresh_timer.stop()
		_set_lobby_browser_busy(false)
		if controller_support.using_controller:
			var focus_target := (
				toggle_menu_button
				if _main_buttons_hidden
				else multiplayer_button
			)
			focus_target.grab_focus.call_deferred()


func _set_options_open(open: bool, animate: bool = true) -> void:
	if (
		_options_transition != null
		and _options_transition.is_valid()
	):
		_options_transition.kill()

	if not animate:
		_apply_options_visibility(open)
		return

	_options_transition = create_tween()
	_options_transition.set_trans(Tween.TRANS_QUAD)
	_options_transition.set_ease(Tween.EASE_IN_OUT)
	_options_transition.tween_property(
		menu_content,
		"modulate:a",
		0.0,
		0.1
	)
	_options_transition.tween_callback(
		_apply_options_visibility.bind(open)
	)
	_options_transition.tween_property(
		menu_content,
		"modulate:a",
		1.0,
		0.16
	)


func _apply_options_visibility(open: bool) -> void:
	_set_menu_vertical_offset(OPTIONS_MENU_VERTICAL_OFFSET if open else 0.0)
	_multiplayer_open = false
	multiplayer_panel.hide()
	lobby_refresh_timer.stop()
	career_stats_label.visible = not open
	var show_main_buttons := not open and not _main_buttons_hidden
	if _main_dashboard != null:
		_main_dashboard.visible = show_main_buttons
	for button in _get_main_buttons():
		button.visible = show_main_buttons
		button.modulate.a = 1.0
	options_panel.visible = open
	toggle_menu_button.visible = not open
	_apply_responsive_menu_layout()
	if open:
		_queue_ball_appearance_focus_refresh()
		_set_bindings_mode(controller_support.using_controller)
		if controller_support.using_controller:
			bindings_mode_button.grab_focus()
	if not open:
		_waiting_for_key_action = &""
		_waiting_for_controller_action = &""
		_controller_rebind_button = null
		_update_keybind_texts()
		if controller_support.using_controller:
			var focus_target := (
				toggle_menu_button
				if _main_buttons_hidden
				else options_button
			)
			focus_target.grab_focus.call_deferred()


func _set_menu_vertical_offset(vertical_offset: float) -> void:
	# The options panel is taller than the main menu after the extra settings
	# were added. Shift only that view upward so its Back button stays on-screen.
	# Using matching top/bottom offsets moves the CenterContainer without
	# changing its usable height or the positioning of the normal main menu.
	# Options now scroll within the viewport, so no screen-specific upward
	# offset is needed. Retaining this method preserves the existing callers.
	menu_center.offset_top = 0.0
	menu_center.offset_bottom = 0.0


func _get_main_buttons() -> Array[Button]:
	return [
		singleplayer_button,
		multiplayer_button,
		freeplay_button,
		battle_pass_button,
		locker_button,
		leaderboards_button,
		options_button,
		exit_button
	]


func _open_locker() -> void:
	if _locker_menu == null:
		return
	_locker_menu.open_locker()


func _on_locker_closed() -> void:
	if controller_support.using_controller:
		locker_button.grab_focus.call_deferred()


func _open_battle_pass() -> void:
	if _battle_pass_menu != null:
		_battle_pass_menu.open_menu()


func _on_battle_pass_closed() -> void:
	if controller_support.using_controller:
		battle_pass_button.grab_focus.call_deferred()


func _on_battle_pass_match_started() -> void:
	_battle_pass_match_in_progress = true


func _on_battle_pass_match_cancelled() -> void:
	_battle_pass_match_in_progress = false


func _on_battle_pass_match_results(
	winning_team: StringName,
	entries: Array
) -> void:
	if not _battle_pass_match_in_progress:
		return
	_battle_pass_match_in_progress = false
	var local_peer_id: int = multiplayer.get_unique_id()
	for entry_variant: Variant in entries:
		if not entry_variant is Dictionary:
			continue
		var entry: Dictionary = entry_variant as Dictionary
		if int(entry.get("peer_id", 0)) != local_peer_id:
			continue
		var battle_pass := get_node_or_null("/root/BattlePass") as FootballBattlePass
		if battle_pass == null:
			return
		var scheduled_match_seconds: float = 300.0
		if match_manager != null:
			scheduled_match_seconds = maxf(
				1.0,
				match_manager.regulation_seconds
			)
			if match_manager.tournament_mode or match_manager.ranked_mode:
				scheduled_match_seconds *= 2.0
		battle_pass.add_match_xp(
			StringName(entry.get("team", &"")) == winning_team,
			int(entry.get("goals", 0)),
			int(entry.get("saves", 0)),
			int(entry.get("passes", 0)),
			scheduled_match_seconds
		)
		return


func _toggle_main_buttons() -> void:
	_set_main_buttons_hidden(not _main_buttons_hidden)


func _set_main_buttons_hidden(hidden: bool) -> void:
	_main_buttons_hidden = hidden
	toggle_menu_button.text = "Show Menu" if hidden else "Hide Menu"
	toggle_menu_button.tooltip_text = (
		"Restore the main menu buttons."
		if hidden
		else "Hide the main menu buttons for an unobstructed field view."
	)

	if (
		_menu_controls_transition != null
		and _menu_controls_transition.is_valid()
	):
		_menu_controls_transition.kill()

	var buttons := _get_main_buttons()
	_menu_controls_transition = create_tween()
	_menu_controls_transition.set_parallel(true)
	_menu_controls_transition.set_trans(Tween.TRANS_QUAD)
	_menu_controls_transition.set_ease(
		Tween.EASE_IN if hidden else Tween.EASE_OUT
	)
	if hidden:
		for button in buttons:
			_menu_controls_transition.tween_property(
				button,
				"modulate:a",
				0.0,
				0.12
			)
		_menu_controls_transition.chain().tween_callback(
			_finish_hiding_main_buttons
		)
	else:
		if _main_dashboard != null:
			_main_dashboard.show()
		for button in buttons:
			button.show()
			button.modulate.a = 0.0
			_menu_controls_transition.tween_property(
				button,
				"modulate:a",
				1.0,
				0.16
			)
		if controller_support.using_controller:
			singleplayer_button.grab_focus.call_deferred()


func _finish_hiding_main_buttons() -> void:
	for button in _get_main_buttons():
		button.hide()
		button.modulate.a = 1.0
	if _main_dashboard != null:
		_main_dashboard.hide()
	if controller_support.using_controller:
		toggle_menu_button.grab_focus.call_deferred()


func _animate_initial_entrance() -> void:
	if visible:
		UIMotion.show_control(self, 0.3)


func _configure_mobile_web_menu() -> void:
	# Networking is deliberately out of scope for the first mobile/PWA build.
	# Make that explicit instead of exposing a Steam button that cannot work in a
	# browser. Singleplayer, freeplay, locker, battle pass and local progression
	# continue to use the exact same menu/game code as desktop.
	multiplayer_button.disabled = true
	multiplayer_button.text = "MULTIPLAYER  •  COMING LATER"
	multiplayer_button.tooltip_text = (
		"The mobile Web build is offline for now. "
		+ "Cross-platform multiplayer will use a Web-compatible backend later."
	)
	# Browser/PWA sessions are closed by leaving the page/app; quitting the Godot
	# process produces a dead canvas with no benefit on iPhone. Desktop fullscreen
	# is also not meaningful in an installed standalone PWA.
	exit_button.hide()
	fullscreen_toggle.hide()


func _steam_api() -> Object:
	if not Engine.has_singleton("Steam"):
		return null
	return Engine.get_singleton("Steam")


func _is_steam_connected() -> bool:
	# Desktop semantic remains Steam.isSteamRunning() plus Steam.getSteamID() != 0;
	# the singleton is fetched dynamically so this same script also parses on Web.
	var steam_manager := get_node_or_null("/root/SteamManager")
	if steam_manager == null:
		return false
	if not bool(steam_manager.get("steam_initialized")):
		return false
	if not Engine.has_singleton("Steam"):
		return false
	return _steam_api().isSteamRunning() and _steam_api().getSteamID() != 0


func _steam_connection_status_text(connected: bool) -> String:
	if OS.has_feature("web"):
		return "Mobile Web • Offline build"
	return "Connected to Steam" if connected else "Not connected to Steam"


func _refresh_steam_connection_status() -> void:
	if connection_label == null:
		return
	var connected := _is_steam_connected()
	connection_label.text = _steam_connection_status_text(connected)
	connection_label.add_theme_color_override(
		"font_color",
		(
			Color(0.56, 0.86, 1.0)
			if OS.has_feature("web")
			else (Color(0.56, 0.93, 0.72) if connected else Color(0.86, 0.62, 0.62))
		)
	)


func _on_connection_changed(message: String) -> void:
	_refresh_steam_connection_status()
	UIMotion.pulse(connection_label, Vector2(1.025, 1.025), 0.18)
	if not _multiplayer_open:
		return
	var still_busy := (
		message.begins_with("Creating")
		or message.begins_with("Joining")
		or message.begins_with("Connecting")
		or message.begins_with("Searching")
	)
	if not still_busy:
		_set_lobby_browser_busy(false)


func _on_session_started() -> void:
	_multiplayer_open = false
	multiplayer_panel.hide()
	if _singleplayer_popup != null:
		_singleplayer_popup.hide()
	if _ranked_info_popup != null:
		_ranked_info_popup.hide()
	lobby_refresh_timer.stop()
	var focus_owner := get_viewport().gui_get_focus_owner()
	if focus_owner != null and is_ancestor_of(focus_owner):
		focus_owner.release_focus()
	UIMotion.hide_control(self)


func _on_session_ended() -> void:
	_apply_multiplayer_visibility(false)
	UIMotion.show_control(self, 0.26)
	if controller_support.using_controller:
		var focus_target := (
			toggle_menu_button
			if _main_buttons_hidden
			else singleplayer_button
		)
		focus_target.call_deferred("grab_focus")
