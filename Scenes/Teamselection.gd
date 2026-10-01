extends Control


@onready var controller_support := get_node(
	"/root/ControllerSupport"
) as FootballControllerSupport


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
const CPU_RANDOM_OPTION_ID: int = 10000
const ABILITY_BUTTON_ICON_SIZE: float = 28.0
const ABILITY_BUTTON_ICON_LEFT: float = 7.0
const ABILITY_BUTTON_TEXT_LEFT_MARGIN: float = 42.0
const ABILITY_BUTTON_TEXT_RIGHT_MARGIN: float = 5.0
const PVE_RANKED_TEAM_PANEL_VISUAL_OFFSET := Vector2.ZERO
const PVE_RANKED_PARTY_PREVIEW_SIZE := Vector2(81.0, 81.0)
const PVE_RANKED_PARTY_PREVIEW_GAP: float = 7.0
const LOBBY_COSMETIC_TRIGGER_THRESHOLD: float = 0.55
const MAP_THUMBNAIL_SCRIPT := preload("res://Scenes/map_variant_thumbnail.gd")
const FIELD_VARIANT_SCRIPT := preload("res://Scenes/field_variant.gd")
const LOCKER_MENU_SCRIPT: Script = preload("res://Scenes/locker_menu.gd")
const BATTLE_PASS_MENU_SCRIPT: Script = preload("res://Scenes/battle_pass_menu.gd")
const LOBBY_LOCKER_ICON: Texture2D = preload("res://Assets/lobby_locker_icon.svg")
const LOBBY_LOOTBOX_ICON: Texture2D = preload("res://Assets/lobby_lootbox_icon.svg")
const CONTROLLER_PROMPT_COVERAGE_SHADER: Shader = preload(
	"res://Scenes/controller_prompt_coverage.gdshader"
)
@export var match_manager: FootballMatchManager
@export var players_parent: Node2D
@export var network_manager: NetworkManager

@export_category("Ability Difficulty Stars")
@export_range(1, 3, 1)
var burst_dribble_difficulty: int = 2
@export_range(1, 3, 1)
var curve_shot_difficulty: int = 2
@export_range(1, 3, 1)
var power_strike_difficulty: int = 1
@export_range(1, 3, 1)
var overdrive_difficulty: int = 1
@export_range(1, 3, 1)
var heel_turn_difficulty: int = 2
@export_range(1, 3, 1)
var enforcer_difficulty: int = 1
@export_range(1, 3, 1)
var goalkeeper_reach_difficulty: int = 1
@export_range(1, 3, 1)
var time_skip_pass_difficulty: int = 2
@export_range(1, 3, 1)
var direct_finish_difficulty: int = 3
@export_range(1, 3, 1)
var elastic_step_difficulty: int = 3
@export_range(1, 3, 1)
var meta_vision_difficulty: int = 2
@export_range(1, 3, 1)
var copycat_difficulty: int = 3
@export_range(1, 3, 1)
var reflex_block_difficulty: int = 3
@export_range(1, 3, 1)
var iron_anchor_difficulty: int = 2
@export_range(1, 3, 1)
var blind_spot_difficulty: int = 2
@export_range(1, 3, 1)
var boogie_woogie_difficulty: int = 2
@export_range(1, 3, 1)
var echo_difficulty: int = 2
@export_range(1, 3, 1)
var return_tag_difficulty: int = 2
@export_range(1, 3, 1)
var breakaway_difficulty: int = 2
@export_range(1, 3, 1)
var snapback_difficulty: int = 3
@export_range(1, 3, 1)
var side_swipe_difficulty: int = 2
@export_range(1, 3, 1)
var nutmeg_difficulty: int = 2
@export_range(1, 3, 1)
var decoy_run_difficulty: int = 1

@onready var red_button: Button = (
	$CenterContainer/ContentRow/TeamPanel/TeamVBox/TeamButtons/RedButton
)
@onready var lobby_title: Label = (
	$CenterContainer/ContentRow/TeamPanel/TeamVBox/LobbyTitle
)
@onready var halftime_return_button: Button = (
	$CenterContainer/ContentRow/TeamPanel/TeamVBox/HalftimeReturnButton
)
@onready var blue_button: Button = (
	$CenterContainer/ContentRow/TeamPanel/TeamVBox/TeamButtons/BlueButton
)
@onready var leave_button: Button = (
	$CenterContainer/ContentRow/TeamPanel/TeamVBox/LeaveTeamButton
)
@onready var main_menu_button: Button = (
	$CenterContainer/ContentRow/TeamPanel/TeamVBox/MainMenuButton
)
@onready var spectator_button: Button = (
	$CenterContainer/ContentRow/TeamPanel/TeamVBox/SpectatorButton
)
@onready var ready_button: Button = (
	$CenterContainer/ContentRow/TeamPanel/TeamVBox/ReadyButton
)
@onready var start_button: Button = (
	$CenterContainer/ContentRow/TeamPanel/TeamVBox/StartButton
)
@onready var team_one_roster: RichTextLabel = (
	$CenterContainer/ContentRow/TeamPanel/TeamVBox/RosterColumns/TopTeams/TeamOne/Players
)
@onready var team_two_roster: RichTextLabel = (
	$CenterContainer/ContentRow/TeamPanel/TeamVBox/RosterColumns/TopTeams/TeamTwo/Players
)
@onready var unassigned_roster: RichTextLabel = (
	$CenterContainer/ContentRow/TeamPanel/TeamVBox/RosterColumns/Unassigned/Players
)
@onready var spectator_roster: RichTextLabel = (
	$CenterContainer/ContentRow/TeamPanel/TeamVBox/RosterColumns/Spectators/Players
)
@onready var status_label: Label = (
	$CenterContainer/ContentRow/TeamPanel/TeamVBox/StatusLabel
)
@onready var side_tabs: TabContainer = (
	$CenterContainer/ContentRow/SideTabs
)
@onready var match_minutes: SpinBox = (
	$CenterContainer/ContentRow/SideTabs/HostOptions/Content/MatchMinutes
)
@onready var goals_to_win: SpinBox = (
	$CenterContainer/ContentRow/SideTabs/HostOptions/Content/GoalsToWin
)
@onready var tournament_mode: CheckButton = (
	$CenterContainer/ContentRow/SideTabs/HostOptions/Content/TournamentMode
)
@onready var blue_cpu_count: SpinBox = (
	$CenterContainer/ContentRow/SideTabs/HostOptions/Content/BlueCPURow/Count
)
@onready var red_cpu_count: SpinBox = (
	$CenterContainer/ContentRow/SideTabs/HostOptions/Content/RedCPURow/Count
)
@onready var current_settings_label: Label = (
	$CenterContainer/ContentRow/SideTabs/HostOptions/Content/CurrentSettingsLabel
)
@onready var ability_buttons: Array[Button] = [
	$CenterContainer/ContentRow/SideTabs/Abilities/AbilityNone,
	$CenterContainer/ContentRow/SideTabs/Abilities/Ability1,
	$CenterContainer/ContentRow/SideTabs/Abilities/Ability2,
	$CenterContainer/ContentRow/SideTabs/Abilities/Ability3,
	$CenterContainer/ContentRow/SideTabs/Abilities/Ability4,
	$CenterContainer/ContentRow/SideTabs/Abilities/Ability5,
	$CenterContainer/ContentRow/SideTabs/Abilities/Ability6,
	$CenterContainer/ContentRow/SideTabs/Abilities/Ability7,
	$CenterContainer/ContentRow/SideTabs/Abilities/Ability8,
	$CenterContainer/ContentRow/SideTabs/Abilities/Ability9,
	$CenterContainer/ContentRow/SideTabs/Abilities/Ability10,
	$CenterContainer/ContentRow/SideTabs/Abilities/Ability11,
	$CenterContainer/ContentRow/SideTabs/Abilities/Ability12,
	$CenterContainer/ContentRow/SideTabs/Abilities/Ability13,
	$CenterContainer/ContentRow/SideTabs/Abilities/Ability14,
	$CenterContainer/ContentRow/SideTabs/Abilities/Ability15,
	$CenterContainer/ContentRow/SideTabs/Abilities/Ability16
]

var _local_ready: bool = false
var _base_ability_tooltips: Array[String] = []
var _ability_columns: HBoxContainer
var _blue_cpu_ability_selectors: Array[OptionButton] = []
var _red_cpu_ability_selectors: Array[OptionButton] = []
var _blue_cpu_ability_rows: Array[Control] = []
var _red_cpu_ability_rows: Array[Control] = []
var _syncing_host_options: bool = false
var _cpu_division_row: HBoxContainer
var _cpu_division_selector: OptionButton
var _selected_custom_cpu_division: int = 3
var _halftime_mode: bool = false
var _ability_preview: FootballAbilityPreviewCard
var _map_selector: GridContainer
var _map_select_button: Button
var _map_overlay: Control
var _map_preview_scroll: ScrollContainer
var _map_overlay_close_button: Button
var _map_close_canvas_layer: CanvasLayer
var _map_popup_panel: PanelContainer
var _map_buttons: Array[Button] = []
var _lobby_info_label: Label
var _kick_player_selector: OptionButton
var _kick_player_button: Button
var _last_roster_snapshot: Dictionary = {}
var _latency_snapshot: Dictionary = {}
var _ranked_roster_animation_accum: float = 0.0
var _team_scroll: ScrollContainer
var _lobby_action_grid: GridContainer
var _bottom_lobby_action_grid: GridContainer
var _responsive_layout_connected: bool = false
var _compact_layout: bool = false
var _draft_mode_toggle: CheckButton
var _fun_mutator_section: PanelContainer
var _fun_mutator_buttons: Dictionary = {}
var _cpu_ability_title: Label
var _cpu_ability_grid: GridContainer
var _ladder_panel: PanelContainer
var _ladder_status_label: Label
var _singleplayer_ranked_panel: PanelContainer
var _singleplayer_ranked_status_label: RichTextLabel
var _singleplayer_ranked_progress_bar: ProgressBar
var _singleplayer_ranked_info_button: Button
var _singleplayer_ranked_snapshot: Dictionary = {}
var _pve_ranked_party_fields: Dictionary = {}
var _pve_ranked_party_slot_labels: Dictionary = {}
var _pve_ranked_party_slot_previews: Dictionary = {}
var _pve_ranked_panel_offset_request_id: int = 0
var _pve_ranked_dashboard: VBoxContainer
var _pve_ranked_top_row: HBoxContainer
var _pve_ranked_action_panel: PanelContainer
var _pve_ranked_action_column: VBoxContainer
var _pve_ranked_info_column: VBoxContainer
var _pve_ranked_bottom_row: HBoxContainer
var _lobby_shortcut_row: HBoxContainer
var _lobby_shortcut_canvas_layer: CanvasLayer
var _lobby_cosmetic_menu_layer: CanvasLayer
var _lobby_lootbox_button: Button
var _lobby_locker_button: Button
var _lobby_lootbox_prompt_icon: TextureRect
var _lobby_locker_prompt_icon: TextureRect
var _lobby_controller_prompt_coverage_material: ShaderMaterial
var _lobby_lootbox_menu: FootballBattlePassMenu
var _lobby_locker_menu: FootballLockerMenu
var _lobby_left_trigger_down: bool = false
var _lobby_right_trigger_down: bool = false
var _lobby_focus_before_cosmetic: Control
# The top-right cosmetic shortcuts live on their own CanvasLayer, so they do
# not automatically inherit Teamselection's animated visibility. Keep an
# explicit lobby-lifecycle gate so they can never leak into matches, results,
# halftime, or unrelated menus while the parent Control is tweening out.
var _lobby_cosmetic_shortcuts_allowed: bool = false


func _ensure_ability_buttons_exist() -> void:
	var abilities_container: VBoxContainer = (
		$CenterContainer/ContentRow/SideTabs/Abilities
	)
	while ability_buttons.size() <= FootballPlayer.ABILITY_COUNT:
		var ability_id := ability_buttons.size()
		var button := Button.new()
		button.name = "Ability%d" % ability_id
		button.text = FootballPlayer.get_ability_name(ability_id)
		button.disabled = true
		abilities_container.add_child(button)
		ability_buttons.append(button)


func _ready() -> void:
	if (
		match_manager == null
		or players_parent == null
		or network_manager == null
	):
		push_error("Team selection references are incomplete.")
		return

	hide()
	_ensure_ability_buttons_exist()

	red_button.pressed.connect(
		func() -> void:
			_request_team(&"red", "Red")
	)
	blue_button.pressed.connect(
		func() -> void:
			_request_team(&"blue", "Blue")
	)
	leave_button.pressed.connect(_on_leave_team_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	spectator_button.pressed.connect(
		func() -> void:
			_request_team(FootballMatchManager.TEAM_SPECTATOR, "Spectators")
	)
	ready_button.pressed.connect(_on_ready_button_pressed)
	start_button.pressed.connect(_on_start_button_pressed)
	halftime_return_button.pressed.connect(_on_halftime_return_pressed)
	match_minutes.value_changed.connect(_on_match_option_value_changed)
	goals_to_win.value_changed.connect(_on_match_option_value_changed)
	tournament_mode.toggled.connect(_on_tournament_option_toggled)
	blue_cpu_count.value_changed.connect(_on_cpu_count_changed)
	red_cpu_count.value_changed.connect(_on_cpu_count_changed)
	for index in range(ability_buttons.size()):
		_apply_ability_button_icon(
			ability_buttons[index],
			index
		)
		ability_buttons[index].pressed.connect(
			_on_ability_pressed.bind(index)
		)
		ability_buttons[index].tooltip_text = (
			FootballPlayer.get_ability_description(index)
		)
		_append_difficulty_to_tooltip(
			ability_buttons[index],
			index
		)
		ability_buttons[index].tooltip_text = (
			_wrap_tooltip_text(
				ability_buttons[index].tooltip_text
			)
		)
		_base_ability_tooltips.append(
			ability_buttons[index].tooltip_text
		)
	_build_compact_ability_grid()
	_configure_ability_focus_navigation()
	_build_ability_previews()
	_build_cpu_division_option()
	_build_cpu_ability_options()
	_build_map_selector()
	_build_network_lobby_controls()
	_build_compact_host_options_layout()
	_build_draft_mode_option()
	_build_fun_mutator_options()
	_build_compact_lobby_actions()
	_ensure_team_panel_scroll()
	_build_ladder_status_panel()
	_build_singleplayer_ranked_status_panel()
	_build_pve_ranked_party_formation_fields()
	_build_lobby_cosmetic_shortcuts()
	if not controller_support.input_method_changed.is_connected(
		_on_lobby_input_method_changed
	):
		controller_support.input_method_changed.connect(
			_on_lobby_input_method_changed
		)
	_update_lobby_cosmetic_shortcut_prompts(
		controller_support.using_controller,
		controller_support.get_prompt_family()
	)
	if not visibility_changed.is_connected(_on_teamselection_visibility_changed):
		visibility_changed.connect(_on_teamselection_visibility_changed)

	match_manager.roster_details_changed.connect(
		_on_roster_details_changed
	)
	match_manager.team_join_result.connect(
		_on_team_join_result
	)
	match_manager.ability_selection_result.connect(
		_on_ability_selection_result
	)
	match_manager.ready_state_result.connect(
		_on_ready_state_result
	)
	match_manager.match_start_result.connect(
		_on_match_start_result
	)
	match_manager.match_started.connect(_on_match_started)
	match_manager.match_ended.connect(_on_match_ended)
	match_manager.match_cancelled.connect(_on_match_cancelled)
	match_manager.freeplay_started.connect(_on_freeplay_started)
	match_manager.results_dismissed.connect(
		_on_results_dismissed
	)
	match_manager.match_settings_changed.connect(
		_on_match_settings_changed
	)
	match_manager.cpu_settings_changed.connect(
		_on_cpu_settings_changed
	)
	match_manager.cpu_difficulty_changed.connect(
		_on_cpu_difficulty_changed
	)
	match_manager.cpu_ability_preferences_changed.connect(
		_on_cpu_ability_preferences_changed
	)
	match_manager.tournament_mode_changed.connect(
		_on_tournament_mode_changed
	)
	match_manager.ranked_mode_changed.connect(_on_ranked_mode_changed)
	match_manager.champions_league_mode_changed.connect(
		_on_champions_league_mode_changed
	)
	match_manager.draft_state_changed.connect(_on_draft_state_changed)
	match_manager.fun_mutators_changed.connect(_on_fun_mutators_changed)
	match_manager.halftime_changed.connect(_on_halftime_changed)
	match_manager.field_variant_changed.connect(_on_field_variant_changed)
	match_manager.ladder_state_changed.connect(_on_ladder_state_changed)
	match_manager.singleplayer_ranked_state_changed.connect(
		_on_singleplayer_ranked_state_changed
	)

	network_manager.session_started.connect(_on_session_started)
	network_manager.session_ended.connect(_on_session_ended)
	network_manager.latency_snapshot_updated.connect(
		_on_latency_snapshot_updated
	)
	network_manager.lobby_metadata_changed.connect(
		_on_lobby_metadata_changed
	)
	_apply_menu_styling()
	MenuStyler.install_click_sounds(self)
	UIMotion.prepare_buttons(self)
	side_tabs.tab_changed.connect(_on_side_tab_changed)

	start_button.disabled = not multiplayer.is_server()
	side_tabs.set_tab_title(0, "Abilities")
	side_tabs.set_tab_title(1, "Host Options")
	_style_side_tab_bar()
	_apply_responsive_layout()
	if not _responsive_layout_connected:
		get_viewport().size_changed.connect(_apply_responsive_layout)
		_responsive_layout_connected = true
	side_tabs.set_tab_hidden(1, not multiplayer.is_server())
	_on_roster_details_changed({
		"red": [],
		"blue": [],
		"spectators": [],
		"unassigned": []
	})
	_on_match_settings_changed(
		match_manager.regulation_seconds,
		match_manager.goals_to_win
	)
	_on_cpu_settings_changed(
		match_manager.requested_blue_cpu_count,
		match_manager.requested_red_cpu_count
	)
	_on_cpu_difficulty_changed(match_manager.cpu_ai_level)
	_on_cpu_ability_preferences_changed(
		match_manager.blue_cpu_ability_preferences,
		match_manager.red_cpu_ability_preferences
	)
	_on_field_variant_changed(match_manager.current_field_variant)
	_on_ranked_mode_changed(match_manager.ranked_mode)
	_on_fun_mutators_changed(match_manager.get_fun_mutators())
	_on_ladder_state_changed(match_manager.get_ladder_snapshot())
	_on_singleplayer_ranked_state_changed(
		match_manager.get_singleplayer_ranked_snapshot()
	)


func _build_ladder_status_panel() -> void:
	var team_vbox := find_child("TeamVBox", true, false) as VBoxContainer
	if team_vbox == null:
		return
	_ladder_panel = team_vbox.get_node_or_null("LadderStatus") as PanelContainer
	if _ladder_panel == null:
		_ladder_panel = PanelContainer.new()
		_ladder_panel.name = "LadderStatus"
		_ladder_panel.custom_minimum_size.y = 82.0
		team_vbox.add_child(_ladder_panel)
		team_vbox.move_child(
			_ladder_panel,
			mini(start_button.get_index() + 1, team_vbox.get_child_count() - 1)
		)
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 14)
		margin.add_theme_constant_override("margin_right", 14)
		margin.add_theme_constant_override("margin_top", 9)
		margin.add_theme_constant_override("margin_bottom", 9)
		_ladder_panel.add_child(margin)
		_ladder_status_label = Label.new()
		_ladder_status_label.name = "Status"
		_ladder_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_ladder_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		margin.add_child(_ladder_status_label)
	else:
		_ladder_status_label = _ladder_panel.find_child("Status", true, false) as Label
	MenuStyler.style_panel(
		_ladder_panel,
		Color(0.95, 0.72, 0.24),
		Color(0.03, 0.035, 0.04, 0.90)
	)
	_ladder_panel.hide()


func _on_ladder_state_changed(snapshot: Dictionary) -> void:
	var enabled: bool = bool(snapshot.get("enabled", false))
	if _ladder_panel != null:
		_ladder_panel.visible = enabled
	if enabled and _ladder_status_label != null:
		var encounter: Dictionary = snapshot.get("encounter", {}) as Dictionary
		var levels: Array = encounter.get("cpu_levels", []) as Array
		var human_team: String = str(snapshot.get("human_team", "blue")).to_upper()
		_ladder_status_label.text = (
			"SEASONAL LADDER  %d/%d\n%s  •  %d ENEMIES  •  CPU %s"
			% [
				int(snapshot.get("rung", 1)),
				int(snapshot.get("max_rung", 12)),
				str(encounter.get("name", "Preparing encounter")),
				int(encounter.get("enemy_count", 0)),
				str(levels)
			]
		)
		_ladder_status_label.text += (
			"\nCHAMPIONS LEAGUE  •  YOUR TEAM: %s" % human_team
		)
	if enabled:
		var ladder_human_team := StringName(snapshot.get("human_team", "blue"))
		blue_button.disabled = ladder_human_team != FootballMatchManager.TEAM_BLUE
		red_button.disabled = ladder_human_team != FootballMatchManager.TEAM_RED
	if side_tabs != null:
		side_tabs.set_tab_hidden(1, not multiplayer.is_server() or enabled)


func _build_singleplayer_ranked_status_panel() -> void:
	var team_vbox := find_child("TeamVBox", true, false) as VBoxContainer
	if team_vbox == null:
		return
	_singleplayer_ranked_panel = PanelContainer.new()
	_singleplayer_ranked_panel.name = "SingleplayerRankedStatus"
	_singleplayer_ranked_panel.custom_minimum_size.y = 178.0
	team_vbox.add_child(_singleplayer_ranked_panel)
	team_vbox.move_child(
		_singleplayer_ranked_panel,
		mini(start_button.get_index() + 1, team_vbox.get_child_count() - 1)
	)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	_singleplayer_ranked_panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 7)
	margin.add_child(content)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	content.add_child(header)

	var header_spacer := Control.new()
	header_spacer.custom_minimum_size.x = 74.0
	header.add_child(header_spacer)

	var header_title := Label.new()
	header_title.text = "PVE RANKED"
	header_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_title.add_theme_font_size_override("font_size", 22)
	header_title.add_theme_color_override("font_color", Color("f2c14e"))
	header.add_child(header_title)

	_singleplayer_ranked_info_button = Button.new()
	_singleplayer_ranked_info_button.name = "RankedInfoButton"
	_singleplayer_ranked_info_button.text = "INFO"
	_singleplayer_ranked_info_button.tooltip_text = (
		"View PvE Ranked divisions, MMR ranges and progression rules."
	)
	_singleplayer_ranked_info_button.custom_minimum_size = Vector2(74.0, 38.0)
	_singleplayer_ranked_info_button.pressed.connect(
		_open_ranked_info_popup_from_teamselection
	)
	header.add_child(_singleplayer_ranked_info_button)

	_singleplayer_ranked_status_label = RichTextLabel.new()
	_singleplayer_ranked_status_label.name = "Status"
	_singleplayer_ranked_status_label.bbcode_enabled = true
	_singleplayer_ranked_status_label.fit_content = true
	_singleplayer_ranked_status_label.scroll_active = false
	_singleplayer_ranked_status_label.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)
	_singleplayer_ranked_status_label.custom_minimum_size.y = 112.0
	_singleplayer_ranked_status_label.add_theme_font_size_override(
		"normal_font_size",
		15
	)
	content.add_child(_singleplayer_ranked_status_label)

	_singleplayer_ranked_progress_bar = ProgressBar.new()
	_singleplayer_ranked_progress_bar.name = "DivisionProgress"
	_singleplayer_ranked_progress_bar.custom_minimum_size.y = 12.0
	_singleplayer_ranked_progress_bar.show_percentage = false
	_singleplayer_ranked_progress_bar.min_value = 0.0
	_singleplayer_ranked_progress_bar.max_value = 1.0
	content.add_child(_singleplayer_ranked_progress_bar)

	MenuStyler.style_panel(
		_singleplayer_ranked_panel,
		Color("f2c14e"),
		Color(0.025, 0.03, 0.045, 0.94)
	)
	MenuStyler.style_button(
		_singleplayer_ranked_info_button,
		Color("f2c14e"),
		38.0
	)
	_singleplayer_ranked_panel.hide()
	_ensure_pve_ranked_dashboard()


func _ensure_pve_ranked_dashboard() -> void:
	if _pve_ranked_dashboard != null:
		return
	var team_vbox := lobby_title.get_parent() as VBoxContainer
	if team_vbox == null:
		return

	_pve_ranked_dashboard = VBoxContainer.new()
	_pve_ranked_dashboard.name = "PveRankedDashboard"
	_pve_ranked_dashboard.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pve_ranked_dashboard.add_theme_constant_override("separation", 14)
	team_vbox.add_child(_pve_ranked_dashboard)

	_pve_ranked_top_row = HBoxContainer.new()
	_pve_ranked_top_row.name = "TopRow"
	_pve_ranked_top_row.custom_minimum_size.y = 230.0
	_pve_ranked_top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pve_ranked_top_row.add_theme_constant_override("separation", 18)
	_pve_ranked_dashboard.add_child(_pve_ranked_top_row)

	_pve_ranked_action_panel = PanelContainer.new()
	_pve_ranked_action_panel.name = "ActionPanel"
	_pve_ranked_action_panel.custom_minimum_size = Vector2(340.0, 230.0)
	_pve_ranked_action_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	MenuStyler.style_panel(
		_pve_ranked_action_panel,
		Color(0.32, 0.90, 0.68),
		Color(0.018, 0.032, 0.031, 0.94)
	)
	_pve_ranked_top_row.add_child(_pve_ranked_action_panel)

	var action_margin := MarginContainer.new()
	action_margin.add_theme_constant_override("margin_left", 16)
	action_margin.add_theme_constant_override("margin_right", 16)
	action_margin.add_theme_constant_override("margin_top", 14)
	action_margin.add_theme_constant_override("margin_bottom", 14)
	_pve_ranked_action_panel.add_child(action_margin)

	_pve_ranked_action_column = VBoxContainer.new()
	_pve_ranked_action_column.name = "Actions"
	_pve_ranked_action_column.add_theme_constant_override("separation", 10)
	action_margin.add_child(_pve_ranked_action_column)

	var action_title := Label.new()
	action_title.name = "Title"
	action_title.text = "MATCH ACTIONS"
	action_title.add_theme_font_size_override("font_size", 18)
	action_title.add_theme_color_override("font_color", Color(0.72, 1.0, 0.86))
	_pve_ranked_action_column.add_child(action_title)

	var action_copy := Label.new()
	action_copy.name = "Description"
	action_copy.text = "Choose the arena, then lock in when your party is ready."
	action_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	action_copy.add_theme_font_size_override("font_size", 12)
	action_copy.add_theme_color_override("font_color", Color(0.62, 0.70, 0.76))
	_pve_ranked_action_column.add_child(action_copy)

	var top_spacer := Control.new()
	top_spacer.name = "FlexibleSpace"
	top_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pve_ranked_top_row.add_child(top_spacer)

	_pve_ranked_info_column = VBoxContainer.new()
	_pve_ranked_info_column.name = "RankedInformation"
	_pve_ranked_info_column.custom_minimum_size = Vector2(680.0, 230.0)
	_pve_ranked_info_column.size_flags_horizontal = Control.SIZE_SHRINK_END
	_pve_ranked_top_row.add_child(_pve_ranked_info_column)

	_pve_ranked_bottom_row = HBoxContainer.new()
	_pve_ranked_bottom_row.name = "BottomRow"
	_pve_ranked_bottom_row.custom_minimum_size.y = 66.0
	_pve_ranked_bottom_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bottom_spacer := Control.new()
	bottom_spacer.name = "FlexibleSpace"
	bottom_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pve_ranked_bottom_row.add_child(bottom_spacer)
	_pve_ranked_dashboard.add_child(_pve_ranked_bottom_row)
	_pve_ranked_dashboard.hide()


func _set_pve_ranked_dashboard_layout(enabled: bool) -> void:
	_ensure_pve_ranked_dashboard()
	if _pve_ranked_dashboard == null:
		return
	var team_vbox := lobby_title.get_parent() as VBoxContainer
	if team_vbox == null:
		return
	var map_selector := (
		_map_select_button.get_parent() as Control
		if _map_select_button != null
		else null
	)
	var roster_title := find_child("RosterTitle", true, false) as Label
	var roster_columns := find_child("RosterColumns", true, false) as VBoxContainer

	if enabled:
		_pve_ranked_dashboard.show()
		if _lobby_action_grid != null and _lobby_action_grid.get_parent() != _pve_ranked_action_column:
			_lobby_action_grid.reparent(_pve_ranked_action_column)
		if map_selector != null and map_selector.get_parent() != _pve_ranked_action_column:
			map_selector.reparent(_pve_ranked_action_column)
		if _singleplayer_ranked_panel != null and _singleplayer_ranked_panel.get_parent() != _pve_ranked_info_column:
			_singleplayer_ranked_panel.reparent(_pve_ranked_info_column)
		if roster_title != null and roster_title.get_parent() != _pve_ranked_dashboard:
			roster_title.reparent(_pve_ranked_dashboard)
		if roster_columns != null and roster_columns.get_parent() != _pve_ranked_dashboard:
			roster_columns.reparent(_pve_ranked_dashboard)
		if main_menu_button.get_parent() != _pve_ranked_bottom_row:
			main_menu_button.reparent(_pve_ranked_bottom_row)

		_pve_ranked_dashboard.move_child(_pve_ranked_top_row, 0)
		if roster_title != null:
			_pve_ranked_dashboard.move_child(roster_title, 1)
		if roster_columns != null:
			_pve_ranked_dashboard.move_child(roster_columns, 2)
		_pve_ranked_dashboard.move_child(
			_pve_ranked_bottom_row,
			_pve_ranked_dashboard.get_child_count() - 1
		)
		if _bottom_lobby_action_grid != null:
			_bottom_lobby_action_grid.hide()
		_lobby_action_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if map_selector != null:
			map_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_singleplayer_ranked_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		main_menu_button.custom_minimum_size = Vector2(270.0, 44.0)
		main_menu_button.size_flags_horizontal = Control.SIZE_SHRINK_END
		main_menu_button.size_flags_vertical = Control.SIZE_SHRINK_END
		MenuStyler.style_button(main_menu_button, Color(1.0, 0.32, 0.38), 44.0)
	else:
		for control: Control in [
			_lobby_action_grid,
			map_selector,
			main_menu_button,
			_singleplayer_ranked_panel,
			roster_title,
			roster_columns,
		]:
			if control != null and control.get_parent() != team_vbox:
				control.reparent(team_vbox)
		_pve_ranked_dashboard.hide()
		main_menu_button.custom_minimum_size.x = 0.0
		main_menu_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if _bottom_lobby_action_grid != null:
			_bottom_lobby_action_grid.show()

		var team_buttons := blue_button.get_parent() as Control
		var insertion_index: int = (
			team_buttons.get_index() + 1 if team_buttons != null else 1
		)
		for control: Control in [
			_lobby_action_grid,
			map_selector,
			main_menu_button,
			_singleplayer_ranked_panel,
			roster_title,
			roster_columns,
		]:
			if control == null:
				continue
			team_vbox.move_child(
				control,
				mini(insertion_index, team_vbox.get_child_count() - 1)
			)
			insertion_index += 1
		if _bottom_lobby_action_grid != null:
			team_vbox.move_child(
				_bottom_lobby_action_grid,
				team_vbox.get_child_count() - 1
			)


func _find_ranked_info_popup_owner() -> Node:
	# Teamselection and ConnectionMenu are siblings under HUD in playfield.tscn.
	var hud: Node = get_parent()
	if hud != null:
		var connection_menu := hud.get_node_or_null("ConnectionMenu")
		if (
			connection_menu != null
			and connection_menu.has_method("_open_ranked_info_popup")
		):
			return connection_menu
	var tree_root := get_tree().current_scene
	if tree_root != null:
		var fallback := tree_root.find_child("ConnectionMenu", true, false)
		if fallback != null and fallback.has_method("_open_ranked_info_popup"):
			return fallback
	return null


func _open_ranked_info_popup_from_teamselection() -> void:
	var owner := _find_ranked_info_popup_owner()
	if owner != null:
		owner.call("_open_ranked_info_popup")


func _get_ranked_matchmaking_division_text(
	division_name: String,
	division: int
) -> String:
	var division_color: Color = FootballMatchManager.get_singleplayer_ranked_division_color(
		division
	)
	if FootballMatchManager.singleplayer_ranked_division_is_animated(division):
		# Use the same lightweight per-character glint that already works in the
		# Ranked info/mode screens. Avoid the old bold/outline combination that
		# caused stray glyphs; the glint itself is safe.
		return _build_ranked_glint_bbcode(division_name, division)
	return "[color=#%s]%s[/color]" % [
		division_color.to_html(false),
		division_name
	]


func _build_pve_ranked_party_formation_fields() -> void:
	var blue_box := team_one_roster.get_parent() as Control
	var red_box := team_two_roster.get_parent() as Control
	_build_pve_ranked_party_formation_field(
		FootballMatchManager.TEAM_BLUE,
		blue_box
	)
	_build_pve_ranked_party_formation_field(
		FootballMatchManager.TEAM_RED,
		red_box
	)


func _build_pve_ranked_party_formation_field(
	team: StringName,
	team_box: Control
) -> void:
	if team_box == null:
		return
	var team_key: String = str(team)
	if _pve_ranked_party_fields.has(team_key):
		return

	var field := Control.new()
	field.name = "PveRankedPartyFormation"
	field.custom_minimum_size = Vector2(0.0, 136.0)
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.mouse_filter = Control.MOUSE_FILTER_IGNORE
	field.clip_contents = true
	field.hide()
	team_box.add_child(field)
	_pve_ranked_party_fields[team_key] = field

	var slots: Array[RichTextLabel] = []
	var previews: Array[FootballCosmeticPreview] = []
	# PvE Ranked supports up to six players, so present the party as one wide row.
	# Fixed positions keep the formation stable when switching formats.
	var slot_x_positions: Array[float] = [0.07, 0.242, 0.414, 0.586, 0.758, 0.93]
	var text_center_y: float = 0.28
	var preview_center_y: float = 0.70
	var slot_width: float = 180.0
	var slot_height: float = 52.0
	for index in range(6):
		var center_x: float = slot_x_positions[index]
		var preview := FootballCosmeticPreview.new()
		preview.name = "PartyPreview%d" % (index + 1)
		preview.custom_minimum_size = PVE_RANKED_PARTY_PREVIEW_SIZE
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preview.set_preview_team(team)
		preview.anchor_left = center_x
		preview.anchor_right = center_x
		preview.anchor_top = preview_center_y
		preview.anchor_bottom = preview_center_y
		preview.offset_left = -PVE_RANKED_PARTY_PREVIEW_SIZE.x * 0.5
		preview.offset_right = PVE_RANKED_PARTY_PREVIEW_SIZE.x * 0.5
		preview.offset_top = -PVE_RANKED_PARTY_PREVIEW_SIZE.y * 0.5
		preview.offset_bottom = PVE_RANKED_PARTY_PREVIEW_SIZE.y * 0.5
		preview.hide()
		field.add_child(preview)
		previews.append(preview)

		var slot := RichTextLabel.new()
		slot.name = "PartySlot%d" % (index + 1)
		slot.bbcode_enabled = true
		slot.fit_content = false
		slot.scroll_active = false
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		slot.add_theme_font_size_override("normal_font_size", 13)
		slot.anchor_left = center_x
		slot.anchor_right = center_x
		slot.anchor_top = text_center_y
		slot.anchor_bottom = text_center_y
		slot.offset_left = -slot_width * 0.5
		slot.offset_right = slot_width * 0.5
		slot.offset_top = -slot_height * 0.5
		slot.offset_bottom = slot_height * 0.5
		field.add_child(slot)
		slots.append(slot)
	_pve_ranked_party_slot_labels[team_key] = slots
	_pve_ranked_party_slot_previews[team_key] = previews


func _sort_pve_ranked_party_entries(entries: Array) -> Array:
	var ordered: Array = entries.duplicate(true)
	for index in range(1, ordered.size()):
		var cursor: int = index
		while cursor > 0:
			var left: Dictionary = ordered[cursor - 1] as Dictionary
			var right: Dictionary = ordered[cursor] as Dictionary
			var left_slot: int = int(left.get("team_slot", 999))
			var right_slot: int = int(right.get("team_slot", 999))
			if left_slot <= right_slot:
				break
			var swap_value: Variant = ordered[cursor - 1]
			ordered[cursor - 1] = ordered[cursor]
			ordered[cursor] = swap_value
			cursor -= 1
	return ordered


func _format_pve_ranked_party_formation_slot(entry: Dictionary) -> String:
	if entry.is_empty():
		return (
			"[center][font_size=11][color=#52616d]OPEN SLOT[/color]"
			+ "[/font_size][/center]"
		)

	var player_name: String = _truncate_roster_text(
		str(entry.get("name", "Player")),
		18
	)
	player_name = _escape_roster_bbcode(player_name)
	var formatted_player_name: String = player_name
	if bool(entry.get("pve_ladder_champion", false)):
		formatted_player_name = _format_ladder_champion_name(player_name)
	elif bool(entry.get("battle_pass_complete", false)):
		formatted_player_name = _format_completed_pass_name(player_name)
	if int(entry.get("peer_id", 0)) == _get_current_host_peer_id():
		formatted_player_name = "[u]%s[/u]" % formatted_player_name

	var mmr: int = maxi(0, int(entry.get("mmr", 0)))
	var division: int = FootballMatchManager.get_singleplayer_ranked_division_for_mmr(
		mmr
	)
	var mmr_badge: String = _format_ranked_mmr_badge(mmr)
	var ready: bool = bool(entry.get("ready", false))
	var ready_text: String = "READY" if ready else "NOT READY"
	var ready_color: String = "71e99d" if ready else "798894"
	var ability_id: int = int(entry.get("ability", 0))
	var ability_text: String = ""
	if ability_id > 0 and ability_id < ABILITY_ICON_PATHS.size():
		ability_text = "  [img=18x18]%s[/img]" % ABILITY_ICON_PATHS[ability_id]

	return (
		"[center]"
		+ "[font_size=10][color=#%s]%s[/color][/font_size]\n"
		+ "[font_size=14]%s %s%s[/font_size]"
		+ "[/center]"
	) % [
		ready_color,
		ready_text,
		mmr_badge,
		formatted_player_name,
		ability_text
	]


func _refresh_pve_ranked_party_slot_preview(
	preview: FootballCosmeticPreview,
	entry: Dictionary,
	team: StringName
) -> void:
	if preview == null:
		return
	var preview_data: Dictionary = entry.get("cosmetic_preview", {}) as Dictionary
	if preview_data.is_empty():
		preview.hide()
		return
	var skin_id: String = str(preview_data.get(
		"skin_id",
		"player_skin.classic"
	))
	var skin_item: Dictionary = FootballCosmeticInventory.CATALOG.get(
		skin_id,
		FootballCosmeticInventory.CATALOG["player_skin.classic"]
	) as Dictionary
	var skin_color_index: int = int(preview_data.get(
		"skin_color_index",
		FootballCosmeticInventory.PLAYER_SKIN_ORIGINAL_COLOR
	))
	var team_primary_color_index: int = int(preview_data.get(
		"team_primary_color_index",
		0
	))
	preview.set_preview_team(team)
	preview.set_player_skin_team_color_indices(
		skin_color_index,
		skin_color_index
	)
	preview.set_team_primary_color_indices(
		team_primary_color_index,
		team_primary_color_index
	)
	preview.set_frame_palette_id(str(preview_data.get(
		"frame_palette_id",
		"frame_palette.classic_touch"
	)))
	preview.set_player_material_id(str(preview_data.get(
		"player_material_id",
		"player_material.matte"
	)))
	preview.set_preview_player_skin(skin_id, skin_item)
	preview.set_cosmetic(skin_id, skin_item)
	preview.show()


func _refresh_pve_ranked_party_formation() -> void:
	if (
		match_manager == null
		or not match_manager.singleplayer_ranked_mode
		or _singleplayer_ranked_snapshot.is_empty()
	):
		return
	var human_team: StringName = StringName(
		_singleplayer_ranked_snapshot.get("human_team", "blue")
	)
	var team_key: String = str(human_team)
	if not _pve_ranked_party_slot_labels.has(team_key):
		return
	var entries: Array = _sort_pve_ranked_party_entries(
		_get_pve_ranked_party_entries(_singleplayer_ranked_snapshot)
	)
	var slots: Array = _pve_ranked_party_slot_labels[team_key] as Array
	var previews: Array = _pve_ranked_party_slot_previews.get(team_key, []) as Array
	var selected_team_size: int = clampi(
		int(_singleplayer_ranked_snapshot.get("team_size", 1)),
		1,
		6
	)
	for index in range(6):
		var slot := slots[index] as RichTextLabel
		var preview: FootballCosmeticPreview = null
		if index < previews.size():
			preview = previews[index] as FootballCosmeticPreview
		if slot == null:
			if preview != null:
				preview.hide()
			continue
		# Only render formation positions that can actually exist in the
		# selected queue. 1v1 has one visible position, 2v2 has two, etc.
		# This prevents irrelevant OPEN SLOT placeholders from appearing.
		slot.visible = index < selected_team_size
		if not slot.visible:
			slot.text = ""
			if preview != null:
				preview.hide()
			continue
		if index < entries.size() and entries[index] is Dictionary:
			var entry := entries[index] as Dictionary
			slot.text = _format_pve_ranked_party_formation_slot(entry)
			_refresh_pve_ranked_party_slot_preview(preview, entry, human_team)
		else:
			slot.text = _format_pve_ranked_party_formation_slot({})
			if preview != null:
				preview.hide()


func _get_current_host_peer_id() -> int:
	if _last_roster_snapshot.has("host_peer_id"):
		var roster_host: int = int(_last_roster_snapshot.get("host_peer_id", 1))
		if roster_host > 0:
			return roster_host
	var fallback_host: int = 0
	for group_name in ["blue", "red", "spectators", "unassigned"]:
		var entries: Array = _last_roster_snapshot.get(group_name, [])
		for entry_value in entries:
			if not (entry_value is Dictionary):
				continue
			var entry: Dictionary = entry_value
			if bool(entry.get("cpu", false)):
				continue
			var peer_id: int = int(entry.get("peer_id", 0))
			if peer_id <= 0:
				continue
			if fallback_host <= 0 or peer_id < fallback_host:
				fallback_host = peer_id
	return fallback_host


func _get_pve_ranked_party_entries(snapshot: Dictionary) -> Array:
	if _last_roster_snapshot.is_empty():
		return []
	var human_team: String = str(snapshot.get("human_team", "blue")).to_lower()
	var entries: Array = _last_roster_snapshot.get(human_team, []) as Array
	var humans: Array = []
	for entry_variant: Variant in entries:
		if entry_variant is Dictionary:
			var entry := entry_variant as Dictionary
			if not bool(entry.get("cpu", false)):
				humans.append(entry)
	return humans


func _get_pve_ranked_party_target_mmr(snapshot: Dictionary) -> int:
	var highest_mmr: int = int(
		snapshot.get("matchmaking_mmr", snapshot.get("mmr", 0))
	)
	for entry_variant: Variant in _get_pve_ranked_party_entries(snapshot):
		var entry := entry_variant as Dictionary
		highest_mmr = maxi(highest_mmr, int(entry.get("mmr", highest_mmr)))
	return highest_mmr


func _refresh_singleplayer_ranked_matchmaking_card() -> void:
	if (
		_singleplayer_ranked_status_label == null
		or _singleplayer_ranked_snapshot.is_empty()
	):
		return
	var snapshot: Dictionary = _singleplayer_ranked_snapshot
	var local_mmr: int = int(snapshot.get("mmr", 0))
	var local_division: int = FootballMatchManager.get_singleplayer_ranked_division_for_mmr(
		local_mmr
	)
	var party_target_mmr: int = _get_pve_ranked_party_target_mmr(snapshot)
	var matchmaking_division: int = FootballMatchManager.get_singleplayer_ranked_division_for_mmr(
		party_target_mmr
	)
	if bool(snapshot.get("matchmaking_locked", false)):
		matchmaking_division = int(
			snapshot.get("matchmaking_division", matchmaking_division)
		)
		party_target_mmr = int(
			snapshot.get("matchmaking_mmr", party_target_mmr)
		)
	var division_name: String = FootballMatchManager.get_singleplayer_ranked_division_name(
		matchmaking_division
	)
	var division_color: Color = FootballMatchManager.get_singleplayer_ranked_division_color(
		matchmaking_division
	)
	var division_text: String = _get_ranked_matchmaking_division_text(
		division_name,
		matchmaking_division
	)

	var party_entries: Array = _get_pve_ranked_party_entries(snapshot)
	var party_count: int = maxi(1, party_entries.size())
	var ready_count: int = 0
	for entry_variant: Variant in party_entries:
		var entry := entry_variant as Dictionary
		if bool(entry.get("ready", false)):
			ready_count += 1
	if party_entries.is_empty() and _local_ready:
		ready_count = 1

	var team_size: int = int(snapshot.get("team_size", 1))
	var matchmaking_locked: bool = bool(
		snapshot.get("matchmaking_locked", false)
	)
	var phase_text: String = (
		"MATCH FOUND • STARTING"
		if matchmaking_locked
		else "OPPONENT LINEUP HIDDEN UNTIL THE PARTY LOCKS IN"
	)
	var change: int = int(snapshot.get("last_change", 0))
	var change_text: String = (
		"  •  LAST %+d" % change
		if change != 0
		else ""
	)

	_singleplayer_ranked_status_label.text = (
		"[left]"
		+ "[font_size=25]%s[/font_size]\n"
		+ "[font_size=14][color=#ffffff]YOUR MMR  %d%s[/color][/font_size]\n"
		+ "[font_size=14][color=#ffffff]PARTY RATING  %d[/color][/font_size]\n"
		+ "[font_size=13][color=#aeb7c6]Rating basis: highest-MMR party member"
		+ "  •  %dv%d  •  Ready %d/%d[/color][/font_size]\n"
		+ "[font_size=12][color=#7f8b9c]%s[/color][/font_size]"
		+ "[/left]"
	) % [
		division_text,
		local_mmr,
		change_text,
		party_target_mmr,
		team_size,
		team_size,
		ready_count,
		party_count,
		phase_text
	]

	if _singleplayer_ranked_progress_bar != null:
		var thresholds: Array[int] = (
			FootballMatchManager.SINGLEPLAYER_RANKED_DIVISION_THRESHOLDS
		)
		var division_index: int = clampi(
			local_division - 1,
			0,
			thresholds.size() - 1
		)
		var progress: float = 1.0
		if division_index + 1 < thresholds.size():
			var floor_mmr: int = thresholds[division_index]
			var next_mmr: int = thresholds[division_index + 1]
			progress = clampf(
				float(local_mmr - floor_mmr) / float(maxi(1, next_mmr - floor_mmr)),
				0.0,
				1.0
			)
		_singleplayer_ranked_progress_bar.value = progress
		_singleplayer_ranked_progress_bar.self_modulate = (
			FootballMatchManager.get_singleplayer_ranked_division_color(
				local_division
			)
		)

	var styled_division: int = int(
		_singleplayer_ranked_panel.get_meta("ranked_style_division", -1)
	)
	if styled_division != matchmaking_division:
		MenuStyler.style_panel(
			_singleplayer_ranked_panel,
			division_color,
			Color(0.018, 0.023, 0.038, 0.96)
		)
		_singleplayer_ranked_panel.set_meta(
			"ranked_style_division", matchmaking_division
		)


func _get_lobby_panel_widths(viewport_size: Vector2) -> Vector2:
	var compact: bool = viewport_size.y < 880.0 or viewport_size.x < 1500.0
	var very_compact: bool = viewport_size.y < 760.0 or viewport_size.x < 1260.0
	var team_width: float = 472.0 if very_compact else (500.0 if compact else 536.0)
	var side_width: float = 594.0 if very_compact else (672.0 if compact else 760.0)

	var pve_ranked_enabled: bool = bool(
		_singleplayer_ranked_snapshot.get(
			"enabled",
			match_manager != null and match_manager.singleplayer_ranked_mode
		)
	)
	if pve_ranked_enabled:
		# Draft owns ability selection, so PvE Ranked no longer needs the old
		# right-side ability panel. Give that entire space to the existing party
		# and team-selection content instead of leaving half the lobby empty.
		team_width += side_width
		side_width = 0.0

	return Vector2(team_width, side_width)


func _apply_lobby_panel_widths() -> void:
	if not is_inside_tree():
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var widths: Vector2 = _get_lobby_panel_widths(viewport_size)
	var team_vbox := lobby_title.get_parent() as VBoxContainer
	var team_panel: PanelContainer = null
	if _team_scroll != null:
		team_panel = _team_scroll.get_parent() as PanelContainer
	elif team_vbox != null:
		team_panel = team_vbox.get_parent() as PanelContainer
	if team_panel != null:
		team_panel.custom_minimum_size.x = widths.x
	if side_tabs != null:
		side_tabs.custom_minimum_size.x = widths.y
	_queue_pve_ranked_team_panel_visual_offset()


func _queue_pve_ranked_team_panel_visual_offset() -> void:
	if not is_inside_tree():
		return
	_pve_ranked_panel_offset_request_id += 1
	var request_id: int = _pve_ranked_panel_offset_request_id
	var content_row := side_tabs.get_parent() as HBoxContainer
	if content_row != null:
		# Let the shared HBox restore its normal child positions first. The small
		# PvE-only offset below is purely visual, so SideTabs/Abilities keeps the
		# exact same layout position.
		content_row.queue_sort()
	await get_tree().process_frame
	if request_id != _pve_ranked_panel_offset_request_id:
		return
	var team_vbox := lobby_title.get_parent() as VBoxContainer
	var team_panel: PanelContainer = null
	if _team_scroll != null:
		team_panel = _team_scroll.get_parent() as PanelContainer
	elif team_vbox != null:
		team_panel = team_vbox.get_parent() as PanelContainer
	if team_panel == null:
		return
	var pve_ranked_enabled: bool = bool(
		_singleplayer_ranked_snapshot.get(
			"enabled",
			match_manager != null and match_manager.singleplayer_ranked_mode
		)
	)
	if pve_ranked_enabled and not match_manager.champions_league_mode:
		team_panel.position += PVE_RANKED_TEAM_PANEL_VISUAL_OFFSET


func _apply_pve_ranked_team_scroll_mode(enabled: bool) -> void:
	if _team_scroll == null:
		return
	# The PvE Draft panel now uses the full lobby width, but compact displays can
	# still be shorter than the party/rank card. AUTO keeps every control
	# reachable without showing a scrollbar when the expanded panel already fits.
	_team_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_team_scroll.follow_focus = true
	if enabled:
		# Never inherit a previous Custom/Ladder scroll position when entering
		# PvE Ranked. With the unused rows hidden, the full ranked content fits.
		_team_scroll.scroll_vertical = 0


func _apply_singleplayer_ranked_lobby_layout(
	enabled: bool,
	snapshot: Dictionary
) -> void:
	if _halftime_mode:
		return
	_set_pve_ranked_dashboard_layout(enabled)
	_apply_pve_ranked_team_scroll_mode(enabled)
	var team_buttons := blue_button.get_parent() as Control
	var top_teams := team_one_roster.get_parent().get_parent() as HBoxContainer
	var blue_box := team_one_roster.get_parent() as Control
	var red_box := team_two_roster.get_parent() as Control
	var roster_gap := (
		top_teams.get_node_or_null("RosterGap") as Control
		if top_teams != null
		else null
	)
	var roster_title := find_child("RosterTitle", true, false) as Label
	var unassigned_box := unassigned_roster.get_parent() as Control
	var spectator_box := spectator_roster.get_parent() as Control
	var blue_header := (
		blue_box.get_node_or_null("Header") as Label
		if blue_box != null
		else null
	)
	var red_header := (
		red_box.get_node_or_null("Header") as Label
		if red_box != null
		else null
	)

	if not enabled:
		if team_buttons != null:
			team_buttons.show()
		leave_button.show()
		spectator_button.show()
		team_one_roster.show()
		team_two_roster.show()
		for formation_value: Variant in _pve_ranked_party_fields.values():
			var formation := formation_value as Control
			if formation != null:
				formation.hide()
		if blue_box != null:
			blue_box.custom_minimum_size.y = 84.0
			blue_box.show()
		if red_box != null:
			red_box.custom_minimum_size.y = 84.0
			red_box.show()
		if roster_gap != null:
			roster_gap.show()
		if unassigned_box != null:
			unassigned_box.show()
		if spectator_box != null:
			spectator_box.show()
		if roster_title != null:
			roster_title.text = "PLAYER ROSTER"
		if blue_header != null:
			blue_header.text = "BLUE"
		if red_header != null:
			red_header.text = "RED"
		main_menu_button.text = "BACK TO MAIN MENU"
		lobby_title.text = "MATCH LOBBY"
		return

	if team_buttons != null:
		team_buttons.hide()
	leave_button.hide()
	spectator_button.hide()
	if unassigned_box != null:
		unassigned_box.hide()
	if spectator_box != null:
		spectator_box.hide()
	if roster_gap != null:
		roster_gap.hide()
	if roster_title != null:
		roster_title.text = "YOUR PARTY • RANKED RATING"
	main_menu_button.text = "LEAVE MATCHMAKING"
	lobby_title.text = "PVE RANKED  •  MATCH LOBBY"

	var human_team: StringName = StringName(snapshot.get("human_team", "blue"))
	var human_box: Control = (
		blue_box
		if human_team == FootballMatchManager.TEAM_BLUE
		else red_box
	)
	var enemy_box: Control = (
		red_box
		if human_team == FootballMatchManager.TEAM_BLUE
		else blue_box
	)
	team_one_roster.hide()
	team_two_roster.hide()
	for formation_key_value: Variant in _pve_ranked_party_fields.keys():
		var formation_key: String = str(formation_key_value)
		var formation := _pve_ranked_party_fields[formation_key] as Control
		if formation != null:
			formation.visible = formation_key == str(human_team)
	if human_box != null:
		human_box.custom_minimum_size.y = 166.0
		human_box.show()
		human_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if enemy_box != null:
		enemy_box.hide()
	var human_header: Label = (
		blue_header
		if human_team == FootballMatchManager.TEAM_BLUE
		else red_header
	)
	if human_header != null:
		human_header.text = "YOUR PARTY"
	_refresh_pve_ranked_party_formation()


func _on_singleplayer_ranked_state_changed(snapshot: Dictionary) -> void:
	var enabled: bool = bool(snapshot.get("enabled", false))
	_singleplayer_ranked_snapshot = snapshot.duplicate(true)
	_apply_lobby_panel_widths()
	if _singleplayer_ranked_panel != null:
		_singleplayer_ranked_panel.visible = enabled
	if _singleplayer_ranked_info_button != null:
		_singleplayer_ranked_info_button.visible = enabled
	if enabled:
		_refresh_singleplayer_ranked_matchmaking_card()
	_apply_singleplayer_ranked_lobby_layout(enabled, snapshot)
	_apply_draft_lobby_layout(match_manager.champions_league_mode)
	if side_tabs != null:
		side_tabs.set_tab_hidden(
			1,
			not multiplayer.is_server() or enabled or match_manager.ladder_mode
		)
	if enabled:
		blue_button.disabled = true
		red_button.disabled = true
		leave_button.disabled = true
		spectator_button.disabled = true
		start_button.hide()
		if controller_support.using_controller:
			call_deferred("_ensure_valid_lobby_controller_focus")
	else:
		start_button.show()


func _build_compact_host_options_layout() -> void:
	var host_options := side_tabs.get_node_or_null(
		"HostOptions/Content"
	) as VBoxContainer
	if host_options == null:
		return
	var existing := host_options.get_node_or_null(
		"MatchRulesCard/MatchRulesGrid"
	)
	if existing != null:
		return
	var length_label := host_options.get_node_or_null("LengthLabel") as Label
	var goals_label := host_options.get_node_or_null("GoalsLabel") as Label
	if length_label == null or goals_label == null:
		return
	var rules_grid := GridContainer.new()
	rules_grid.name = "MatchRulesGrid"
	rules_grid.columns = 2
	rules_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rules_grid.add_theme_constant_override("h_separation", 10)
	rules_grid.add_theme_constant_override("v_separation", 5)
	var rules_card := PanelContainer.new()
	rules_card.name = "MatchRulesCard"
	rules_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	MenuStyler.style_panel(
		rules_card,
		Color(0.84, 0.72, 0.40),
		Color(0.018, 0.038, 0.027, 0.76)
	)
	host_options.add_child(rules_card)
	rules_card.add_child(rules_grid)
	var title_node := host_options.get_node_or_null("Title")
	if title_node != null:
		host_options.move_child(
			rules_card,
			mini(title_node.get_index() + 1, host_options.get_child_count() - 1)
		)
	length_label.text = "MATCH LENGTH"
	goals_label.text = "FIRST TO SCORE"
	length_label.add_theme_font_size_override("font_size", 12)
	goals_label.add_theme_font_size_override("font_size", 12)
	length_label.add_theme_color_override("font_color", Color(0.72, 0.74, 0.66))
	goals_label.add_theme_color_override("font_color", Color(0.72, 0.74, 0.66))
	length_label.reparent(rules_grid)
	match_minutes.reparent(rules_grid)
	goals_label.reparent(rules_grid)
	goals_to_win.reparent(rules_grid)
	match_minutes.custom_minimum_size = Vector2(132.0, 32.0)
	goals_to_win.custom_minimum_size = Vector2(132.0, 32.0)

	var cpu_card := host_options.get_node_or_null("CPUCountCard") as PanelContainer
	if cpu_card == null:
		var cpu_title := host_options.get_node_or_null("CPUTitle") as Label
		var blue_row := host_options.get_node_or_null("BlueCPURow") as HBoxContainer
		var red_row := host_options.get_node_or_null("RedCPURow") as HBoxContainer
		if cpu_title != null and blue_row != null and red_row != null:
			cpu_card = PanelContainer.new()
			cpu_card.name = "CPUCountCard"
			cpu_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			MenuStyler.style_panel(
				cpu_card,
				Color(0.84, 0.72, 0.40),
				Color(0.02, 0.036, 0.027, 0.78)
			)
			var cpu_content := VBoxContainer.new()
			cpu_content.name = "Content"
			cpu_content.add_theme_constant_override("separation", 6)
			cpu_card.add_child(cpu_content)
			host_options.add_child(cpu_card)
			cpu_title.reparent(cpu_content)
			if _cpu_division_row != null:
				_cpu_division_row.reparent(cpu_content)
			blue_row.reparent(cpu_content)
			red_row.reparent(cpu_content)
			var separator := host_options.get_node_or_null("CPUSeparator") as HSeparator
			if separator != null:
				separator.hide()
			host_options.move_child(
				cpu_card,
				mini(tournament_mode.get_index() + 1, host_options.get_child_count() - 1)
			)
			cpu_title.text = "CPU SETTINGS"
			cpu_title.add_theme_color_override("font_color", Color(0.92, 0.92, 0.94))
			cpu_title.add_theme_font_size_override("font_size", 14)


func _build_draft_mode_option() -> void:
	var host_options := side_tabs.get_node_or_null(
		"HostOptions/Content"
	) as VBoxContainer
	if host_options == null or _draft_mode_toggle != null:
		return
	_draft_mode_toggle = CheckButton.new()
	_draft_mode_toggle.name = "DraftMode"
	_draft_mode_toggle.text = "DRAFT  •  TWO-LEG CARD MODE"
	_draft_mode_toggle.tooltip_text = (
		"Three-minute legs with a five-card ability draft and a perk draft "
		+ "before each leg. Leg-one choices cannot repeat in leg two."
	)
	_draft_mode_toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_draft_mode_toggle.custom_minimum_size.y = 44.0
	_draft_mode_toggle.toggled.connect(_on_draft_option_toggled)
	MenuStyler.style_button(
		_draft_mode_toggle,
		Color(0.82, 0.52, 1.0),
		44.0
	)
	host_options.add_child(_draft_mode_toggle)
	var tournament_index := tournament_mode.get_index()
	host_options.move_child(
		_draft_mode_toggle,
		mini(tournament_index + 1, host_options.get_child_count() - 1)
	)


func _build_fun_mutator_options() -> void:
	var host_options := side_tabs.get_node_or_null(
		"HostOptions/Content"
	) as VBoxContainer
	if host_options == null or _fun_mutator_section != null:
		return
	_fun_mutator_section = PanelContainer.new()
	_fun_mutator_section.name = "FunMutatorsCard"
	_fun_mutator_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	MenuStyler.style_panel(
		_fun_mutator_section,
		Color(0.92, 0.48, 0.92),
		Color(0.035, 0.025, 0.045, 0.82)
	)
	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 6)
	_fun_mutator_section.add_child(content)
	var title := Label.new()
	title.text = "FUN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.64, 1.0))
	content.add_child(title)
	var note := Label.new()
	note.text = "Optional casual modifiers • Ranked always disables these"
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", 11)
	note.add_theme_color_override("font_color", Color(0.74, 0.72, 0.78))
	content.add_child(note)
	var grid := GridContainer.new()
	grid.name = "MutatorGrid"
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 5)
	content.add_child(grid)
	var definitions: Array[Dictionary] = [
		{"id": FootballMatchManager.FUN_LOW_FRICTION, "label": "Low Friction", "tip": "The ball rolls for much longer."},
		{"id": FootballMatchManager.FUN_HEAVY_BALL, "label": "Heavy Ball", "tip": "Makes the ball heavier, visibly larger, and gives it a larger collision hitbox."},
		{"id": FootballMatchManager.FUN_SMALL_GOALS, "label": "Small Goals", "tip": "Shrinks both goal mouths."},
		{"id": FootballMatchManager.FUN_NO_COOLDOWNS, "label": "No Cooldowns", "tip": "Abilities become ready again immediately after their active effect ends."},
		{"id": FootballMatchManager.FUN_FASTER_BALL, "label": "Faster Ball", "tip": "Every kick launches the ball faster and raises its speed cap."},
		{"id": FootballMatchManager.FUN_NO_WALLS, "label": "No Walls", "tip": "Disables arena and ball boundary collisions."},
		{"id": FootballMatchManager.FUN_ABILITY_DRAFT, "label": "Ability Draft", "tip": "Randomizes legal starting abilities when the match begins."},
		{"id": FootballMatchManager.FUN_DUPLICATE_ABILITIES, "label": "Duplicate Abilities", "tip": "Teammates may select the same ability."},
		{"id": FootballMatchManager.FUN_ROTATING_LOADOUTS, "label": "Rotating Loadouts", "tip": "Redrafts every player's ability throughout the match."},
		{"id": FootballMatchManager.FUN_DICTATOR_MBAPPE, "label": "Golden Striker", "tip": "Turns one CPU into the permanent Overdrive boss."},
		{"id": FootballMatchManager.FUN_SATORU_GOJO, "label": "Satoru Gojo", "tip": "Turns one CPU into the no-cooldown Iron Anchor boss."},
		{"id": FootballMatchManager.FUN_NEYMAR_JR, "label": "Neymar Jr", "tip": "Turns one CPU into the unlimited Elastic Step boss."},
		{"id": FootballMatchManager.FUN_ERLING_HAALAND, "label": "Erling Haaland", "tip": "Turns one CPU into the permanent Power Strike boss."},
		{"id": FootballMatchManager.FUN_MANUEL_NEUER, "label": "Manuel Neuer", "tip": "Turns one CPU into the sweeper-keeper boss with Goalkeeper's Reach + Dead Zone Pass."},
	]
	for definition: Dictionary in definitions:
		var mutator_id := StringName(definition.get("id", &""))
		var toggle := CheckButton.new()
		toggle.name = "Mutator_%s" % String(mutator_id)
		toggle.text = str(definition.get("label", "Mutator"))
		toggle.tooltip_text = str(definition.get("tip", ""))
		toggle.custom_minimum_size = Vector2(0.0, 38.0)
		toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		MenuStyler.style_button(toggle, Color(0.92, 0.48, 0.92), 38.0)
		toggle.toggled.connect(_on_fun_mutator_toggled.bind(mutator_id))
		grid.add_child(toggle)
		_fun_mutator_buttons[mutator_id] = toggle
	host_options.add_child(_fun_mutator_section)


func _on_fun_mutator_toggled(enabled: bool, mutator_id: StringName) -> void:
	if _syncing_host_options or not multiplayer.is_server():
		return
	var settings: Dictionary = match_manager.get_fun_mutators()
	settings[mutator_id] = enabled
	match_manager.update_fun_mutators(settings)


func _on_fun_mutators_changed(settings: Dictionary) -> void:
	_syncing_host_options = true
	for id_variant: Variant in _fun_mutator_buttons.keys():
		var mutator_id := StringName(id_variant)
		var toggle := _fun_mutator_buttons[mutator_id] as CheckButton
		if toggle != null:
			toggle.button_pressed = bool(settings.get(mutator_id, false))
			toggle.disabled = (
				match_manager.ranked_mode
				or match_manager.champions_league_mode
				or _halftime_mode
			)
	_syncing_host_options = false
	_update_current_settings_label()


func _build_compact_lobby_actions() -> void:
	var team_vbox := lobby_title.get_parent() as VBoxContainer
	if team_vbox == null:
		return

	# Primary match actions stay directly beneath the team join buttons.
	# READY remains in the left slot and START MATCH moves to the left slot directly below it.
	_lobby_action_grid = team_vbox.get_node_or_null(
		"LobbyActionGrid"
	) as GridContainer
	if _lobby_action_grid == null:
		_lobby_action_grid = GridContainer.new()
		_lobby_action_grid.name = "LobbyActionGrid"
		_lobby_action_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_lobby_action_grid.add_theme_constant_override("v_separation", 5)
		team_vbox.add_child(_lobby_action_grid)
	_lobby_action_grid.columns = 1
	_lobby_action_grid.add_theme_constant_override("h_separation", 0)

	var team_buttons := blue_button.get_parent()
	if team_buttons != null:
		team_vbox.move_child(
			_lobby_action_grid,
			mini(team_buttons.get_index() + 1, team_vbox.get_child_count() - 1)
		)

	for button in [ready_button, start_button]:
		if button.get_parent() != _lobby_action_grid:
			button.reparent(_lobby_action_grid)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 32.0

	# These used to reserve the right half of each row. Remove them now so
	# READY and START MATCH use the full lobby width.
	for spacer_name in ["ReadyRightSpacer", "StartRightSpacer"]:
		var spacer := _lobby_action_grid.get_node_or_null(spacer_name) as Control
		if spacer != null:
			spacer.queue_free()

	_lobby_action_grid.move_child(ready_button, 0)
	_lobby_action_grid.move_child(start_button, 1)

	# Spectate and Leave Team belong at the very bottom of the lobby panel.
	_bottom_lobby_action_grid = team_vbox.get_node_or_null(
		"BottomLobbyActionGrid"
	) as GridContainer
	if _bottom_lobby_action_grid == null:
		_bottom_lobby_action_grid = GridContainer.new()
		_bottom_lobby_action_grid.name = "BottomLobbyActionGrid"
		_bottom_lobby_action_grid.columns = 2
		_bottom_lobby_action_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_bottom_lobby_action_grid.add_theme_constant_override("h_separation", 6)
		_bottom_lobby_action_grid.add_theme_constant_override("v_separation", 5)
		team_vbox.add_child(_bottom_lobby_action_grid)

	for button in [spectator_button, leave_button]:
		if button.get_parent() != _bottom_lobby_action_grid:
			button.reparent(_bottom_lobby_action_grid)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 32.0

	main_menu_button.custom_minimum_size.y = 32.0

	var map_selector := team_vbox.get_node_or_null("MapSelector")
	if map_selector != null:
		team_vbox.move_child(
			map_selector,
			mini(_lobby_action_grid.get_index() + 1, team_vbox.get_child_count() - 1)
		)
		# Keep BACK TO MAIN MENU directly below map selection as before.
		team_vbox.move_child(
			main_menu_button,
			mini(map_selector.get_index() + 1, team_vbox.get_child_count() - 1)
		)

	# The bottom action row is deliberately last, after roster/status content.
	team_vbox.move_child(
		_bottom_lobby_action_grid,
		team_vbox.get_child_count() - 1
	)


func _ensure_team_panel_scroll() -> void:
	if _team_scroll != null:
		return
	var team_vbox := lobby_title.get_parent() as VBoxContainer
	if team_vbox == null:
		return
	var team_panel := team_vbox.get_parent() as PanelContainer
	if team_panel == null:
		return
	_team_scroll = ScrollContainer.new()
	_team_scroll.name = "TeamScroll"
	_team_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_team_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_team_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_team_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_team_scroll.scroll_deadzone = 6
	_team_scroll.follow_focus = true
	team_panel.add_child(_team_scroll)
	team_vbox.reparent(_team_scroll)
	team_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	team_vbox.custom_minimum_size.x = 0.0
	team_panel.clip_contents = true


func _style_side_tab_bar() -> void:
	var tab_bar: TabBar = side_tabs.get_tab_bar()
	if tab_bar == null:
		return

	tab_bar.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
	tab_bar.add_theme_color_override("font_selected_color", Color(0.98, 0.96, 0.88, 1.0))
	tab_bar.add_theme_color_override("font_unselected_color", Color(0.72, 0.74, 0.67, 0.98))
	tab_bar.add_theme_color_override("font_hovered_color", Color(1.0, 1.0, 1.0, 1.0))
	tab_bar.add_theme_color_override("font_disabled_color", Color(0.53, 0.56, 0.51, 0.95))
	tab_bar.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
	tab_bar.add_theme_constant_override("outline_size", 2)
	tab_bar.add_theme_font_size_override("font_size", 17)
	tab_bar.add_theme_constant_override("h_separation", 10)
	tab_bar.clip_tabs = false

	var selected := StyleBoxFlat.new()
	selected.bg_color = Color(0.034, 0.052, 0.041, 0.97)
	selected.border_color = Color(0.96, 0.96, 0.98, 0.94)
	selected.border_width_left = 2
	selected.border_width_top = 2
	selected.border_width_right = 2
	selected.border_width_bottom = 0
	selected.corner_radius_top_left = 16
	selected.corner_radius_top_right = 16
	selected.corner_radius_bottom_left = 0
	selected.corner_radius_bottom_right = 0
	selected.content_margin_left = 24
	selected.content_margin_right = 24
	selected.content_margin_top = 11
	selected.content_margin_bottom = 11
	selected.shadow_color = Color(1.0, 1.0, 1.0, 0.14)
	selected.shadow_size = 6
	selected.shadow_offset = Vector2(0, 1)

	var unselected := selected.duplicate() as StyleBoxFlat
	unselected.bg_color = Color(0.02, 0.03, 0.024, 0.92)
	unselected.border_color = Color(0.42, 0.46, 0.41, 0.66)
	unselected.shadow_color = Color(0.0, 0.0, 0.0, 0.12)
	unselected.shadow_size = 3

	var hovered := selected.duplicate() as StyleBoxFlat
	hovered.bg_color = Color(0.047, 0.069, 0.054, 0.96)
	hovered.border_color = Color(1.0, 1.0, 1.0, 0.98)
	hovered.shadow_color = Color(1.0, 1.0, 1.0, 0.16)
	hovered.shadow_size = 5

	tab_bar.add_theme_stylebox_override("tab_selected", selected)
	tab_bar.add_theme_stylebox_override("tab_unselected", unselected)
	tab_bar.add_theme_stylebox_override("tab_hovered", hovered)
	tab_bar.add_theme_stylebox_override("tab_disabled", unselected)

func _apply_responsive_layout() -> void:
	if not is_inside_tree():
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var compact: bool = viewport_size.y < 880.0 or viewport_size.x < 1500.0
	var very_compact: bool = viewport_size.y < 760.0 or viewport_size.x < 1260.0
	_compact_layout = compact

	var safe_height: float = maxf(460.0, viewport_size.y - 50.0)
	var target_height: float = minf(
		safe_height,
		610.0 if very_compact else (690.0 if compact else 760.0)
	)
	# Keep player names and their selected-ability icon on one row in the
	# two-team roster, including the compact 1152x648 virtual canvas.
	# PvE Ranked borrows a small amount of width from the side panel for its
	# party roster while keeping the total lobby footprint unchanged.
	var panel_widths: Vector2 = _get_lobby_panel_widths(viewport_size)
	var team_width: float = panel_widths.x
	var side_width: float = panel_widths.y
	var column_width: float = 190.0 if very_compact else (210.0 if compact else 232.0)
	var ability_height: float = 41.0 if very_compact else (45.0 if compact else 50.0)

	var content_row := side_tabs.get_parent() as HBoxContainer
	if content_row != null:
		content_row.add_theme_constant_override(
			"separation",
			12 if very_compact else (16 if compact else 20)
		)

	var team_vbox := lobby_title.get_parent() as VBoxContainer
	var team_panel: PanelContainer = null
	if _team_scroll != null:
		team_panel = _team_scroll.get_parent() as PanelContainer
	elif team_vbox != null:
		team_panel = team_vbox.get_parent() as PanelContainer
	if team_panel != null:
		team_panel.custom_minimum_size = Vector2(team_width, target_height)
		team_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if _team_scroll != null:
		_team_scroll.custom_minimum_size = Vector2(0.0, target_height)

	side_tabs.custom_minimum_size = Vector2(side_width, target_height)
	side_tabs.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_queue_pve_ranked_team_panel_visual_offset()
	if _pve_ranked_dashboard != null and _pve_ranked_dashboard.visible:
		var action_width: float = 280.0 if very_compact else (310.0 if compact else 340.0)
		var information_width: float = 500.0 if very_compact else (580.0 if compact else 680.0)
		_pve_ranked_action_panel.custom_minimum_size.x = action_width
		_pve_ranked_info_column.custom_minimum_size.x = information_width
		_pve_ranked_top_row.add_theme_constant_override(
			"separation",
			12 if very_compact else (16 if compact else 20)
		)
		main_menu_button.custom_minimum_size.x = 230.0 if very_compact else 270.0
	var host_scroll := side_tabs.get_node_or_null("HostOptions") as ScrollContainer
	if host_scroll != null:
		host_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		host_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		host_scroll.scroll_deadzone = 6
		var host_content := host_scroll.get_node_or_null("Content") as VBoxContainer
		if host_content != null:
			host_content.add_theme_constant_override("separation", 9 if compact else 11)

	var ability_panel := side_tabs.get_node_or_null("Abilities") as VBoxContainer
	if ability_panel != null:
		ability_panel.add_theme_constant_override("separation", 6 if compact else 8)
		var title := ability_panel.get_node_or_null("Title") as Label
		var description := ability_panel.get_node_or_null("Description") as Label
		if title != null:
			title.add_theme_font_size_override("font_size", 20 if compact else 23)
		if description != null:
			description.add_theme_font_size_override("font_size", 12 if compact else 13)
		var ability_scroll := ability_panel.get_node_or_null("AbilityScroll") as ScrollContainer
		if ability_scroll != null:
			ability_scroll.custom_minimum_size = Vector2(0.0, 0.0)
			ability_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	if _ability_columns != null:
		for child in _ability_columns.get_children():
			var column := child as VBoxContainer
			if column == null:
				continue
			column.custom_minimum_size.x = column_width
			column.add_theme_constant_override("separation", 7 if compact else 9)
			for column_child in column.get_children():
				var button := column_child as Button
				if button == null:
					continue
				button.custom_minimum_size = Vector2(column_width - 4.0, ability_height)
				button.add_theme_font_size_override("font_size", 12 if compact else 14)
				_apply_fixed_ability_button_layout(button)
				_fit_ability_button_text(button)

	if team_vbox != null:
		team_vbox.add_theme_constant_override("separation", 7 if compact else 9)
	lobby_title.add_theme_font_size_override("font_size", 20 if compact else 23)
	if _lobby_info_label != null:
		_lobby_info_label.add_theme_font_size_override("font_size", 11 if compact else 12)
		_lobby_info_label.max_lines_visible = 3

	for button in [
		blue_button,
		red_button,
		ready_button,
		start_button,
		spectator_button,
		leave_button,
		main_menu_button
	]:
		button.custom_minimum_size.y = 36.0 if very_compact else (40.0 if compact else 44.0)
		button.add_theme_font_size_override("font_size", 13 if compact else 14)

	var blue_roster_box := team_one_roster.get_parent() as Control
	var red_roster_box := team_two_roster.get_parent() as Control
	var roster_gap := team_one_roster.get_parent().get_parent().get_node_or_null(
		"RosterGap"
	) as Control
	var unassigned_box := unassigned_roster.get_parent() as Control
	var spectator_box := spectator_roster.get_parent() as Control
	if roster_gap != null:
		roster_gap.custom_minimum_size.x = 20.0 if compact else 24.0
	if blue_roster_box != null:
		blue_roster_box.custom_minimum_size.y = 86.0 if compact else 104.0
	if red_roster_box != null:
		red_roster_box.custom_minimum_size.y = 86.0 if compact else 104.0
	team_one_roster.custom_minimum_size.y = 58.0 if compact else 72.0
	team_two_roster.custom_minimum_size.y = 58.0 if compact else 72.0
	if unassigned_box != null:
		unassigned_box.custom_minimum_size.y = 52.0 if compact else 66.0
	unassigned_roster.custom_minimum_size.y = 30.0 if compact else 40.0
	if spectator_box != null:
		spectator_box.custom_minimum_size.y = 46.0 if compact else 54.0
	spectator_roster.custom_minimum_size.y = 24.0 if compact else 30.0

	if _map_select_button != null:
		var map_panel := _map_select_button.get_parent() as PanelContainer
		if map_panel != null:
			map_panel.custom_minimum_size.y = 50.0 if compact else 56.0
		_map_select_button.custom_minimum_size.y = 38.0 if compact else 42.0
	if _map_preview_scroll != null:
		_map_preview_scroll.custom_minimum_size.y = 404.0 if compact else 438.0
	for map_button in _map_buttons:
		map_button.custom_minimum_size = Vector2(184.0 if compact else 200.0, 94.0 if compact else 102.0)

	call_deferred("_position_lobby_cosmetic_shortcuts", compact)
	for shortcut_node in [_lobby_lootbox_button, _lobby_locker_button]:
		var shortcut_button := shortcut_node as Button
		if shortcut_button != null:
			shortcut_button.add_theme_constant_override(
				"icon_max_width", 22 if compact else 26
			)
	_update_lobby_cosmetic_shortcut_prompts(
		controller_support.using_controller,
		controller_support.get_prompt_family()
	)

	_style_side_tab_bar()


func _build_lobby_cosmetic_shortcuts() -> void:
	# Reuse the same CanvasLayer approach as the working cosmetic-menu/back-button
	# fix. This keeps the shortcuts above the lobby containers without letting a
	# clipped TeamPanel or SideTabs layout hide them.
	_lobby_shortcut_canvas_layer = get_node_or_null(
		"LobbyCosmeticShortcutCanvasLayer"
	) as CanvasLayer
	if _lobby_shortcut_canvas_layer == null:
		_lobby_shortcut_canvas_layer = CanvasLayer.new()
		_lobby_shortcut_canvas_layer.name = "LobbyCosmeticShortcutCanvasLayer"
		_lobby_shortcut_canvas_layer.layer = 70
		add_child(_lobby_shortcut_canvas_layer)

	_lobby_shortcut_row = _lobby_shortcut_canvas_layer.get_node_or_null(
		"LobbyCosmeticShortcuts"
	) as HBoxContainer
	if _lobby_shortcut_row == null:
		_lobby_shortcut_row = HBoxContainer.new()
		_lobby_shortcut_row.name = "LobbyCosmeticShortcuts"
		_lobby_shortcut_row.set_anchors_preset(Control.PRESET_TOP_LEFT)
		_lobby_shortcut_row.add_theme_constant_override("separation", 8)
		_lobby_shortcut_row.mouse_filter = Control.MOUSE_FILTER_PASS
		_lobby_shortcut_canvas_layer.add_child(_lobby_shortcut_row)

	_lobby_lootbox_button = _lobby_shortcut_row.get_node_or_null("Lootbox") as Button
	if _lobby_lootbox_button == null:
		_lobby_lootbox_button = Button.new()
		_lobby_lootbox_button.name = "Lootbox"
		_lobby_lootbox_button.tooltip_text = "LT / L2 • Open Lootbox"
		_lobby_lootbox_button.icon = LOBBY_LOOTBOX_ICON
		_lobby_lootbox_button.expand_icon = true
		_lobby_lootbox_button.mouse_filter = Control.MOUSE_FILTER_STOP
		_lobby_lootbox_button.focus_mode = Control.FOCUS_ALL
		_lobby_lootbox_button.add_theme_constant_override("icon_max_width", 26)
		_lobby_lootbox_button.custom_minimum_size = Vector2(46.0, 46.0)
		_lobby_shortcut_row.add_child(_lobby_lootbox_button)
		_lobby_lootbox_button.pressed.connect(_open_lobby_lootbox)

	_lobby_locker_button = _lobby_shortcut_row.get_node_or_null("Locker") as Button
	if _lobby_locker_button == null:
		_lobby_locker_button = Button.new()
		_lobby_locker_button.name = "Locker"
		_lobby_locker_button.tooltip_text = "RT / R2 • Open Locker"
		_lobby_locker_button.icon = LOBBY_LOCKER_ICON
		_lobby_locker_button.expand_icon = true
		_lobby_locker_button.mouse_filter = Control.MOUSE_FILTER_STOP
		_lobby_locker_button.focus_mode = Control.FOCUS_ALL
		_lobby_locker_button.add_theme_constant_override("icon_max_width", 26)
		_lobby_locker_button.custom_minimum_size = Vector2(46.0, 46.0)
		_lobby_shortcut_row.add_child(_lobby_locker_button)
		_lobby_locker_button.pressed.connect(_open_lobby_locker)

	_lobby_lootbox_prompt_icon = _ensure_lobby_shortcut_prompt_icon(
		_lobby_lootbox_button,
		"TriggerPrompt"
	)
	_lobby_locker_prompt_icon = _ensure_lobby_shortcut_prompt_icon(
		_lobby_locker_button,
		"TriggerPrompt"
	)

	# Container geometry settles at the end of the frame, so position after layout.
	call_deferred("_position_lobby_cosmetic_shortcuts", _compact_layout)

	# The Locker/Lootbox screens must not share the Teamselection canvas with
	# TeamPanel, SideTabs, ScrollContainers, or shortcut overlays. Those controls
	# can otherwise still win GUI hit-testing even when the popup is drawn above
	# them. A dedicated CanvasLayer gives the cosmetic menus their own input layer.
	_lobby_cosmetic_menu_layer = get_node_or_null(
		"LobbyCosmeticMenuLayer"
	) as CanvasLayer
	if _lobby_cosmetic_menu_layer == null:
		_lobby_cosmetic_menu_layer = CanvasLayer.new()
		_lobby_cosmetic_menu_layer.name = "LobbyCosmeticMenuLayer"
		_lobby_cosmetic_menu_layer.layer = 80
		add_child(_lobby_cosmetic_menu_layer)

	_lobby_lootbox_menu = _lobby_cosmetic_menu_layer.get_node_or_null(
		"LobbyLootboxMenu"
	) as FootballBattlePassMenu
	if _lobby_lootbox_menu == null:
		_lobby_lootbox_menu = BATTLE_PASS_MENU_SCRIPT.new() as FootballBattlePassMenu
		_lobby_lootbox_menu.name = "LobbyLootboxMenu"
		_lobby_cosmetic_menu_layer.add_child(_lobby_lootbox_menu)
		_lobby_lootbox_menu.closed.connect(_on_lobby_lootbox_closed)

	_lobby_locker_menu = _lobby_cosmetic_menu_layer.get_node_or_null(
		"LobbyLockerMenu"
	) as FootballLockerMenu
	if _lobby_locker_menu == null:
		_lobby_locker_menu = LOCKER_MENU_SCRIPT.new() as FootballLockerMenu
		_lobby_locker_menu.name = "LobbyLockerMenu"
		_lobby_cosmetic_menu_layer.add_child(_lobby_locker_menu)
		_lobby_locker_menu.closed.connect(_on_lobby_locker_closed)

	_style_lobby_cosmetic_shortcuts()


func _position_lobby_cosmetic_shortcuts(compact: bool) -> void:
	if _lobby_shortcut_row == null:
		return

	# The shortcut CanvasLayer already uses viewport space, so anchor directly to
	# the viewport's top-right. The abilities panel occupies the right side of the
	# lobby, making this stable at 16:9 without depending on container global rects.
	var shortcut_size: float = 40.0 if compact else 46.0
	var lootbox_width: float = shortcut_size
	var locker_width: float = shortcut_size
	if _lobby_lootbox_button != null:
		lootbox_width = maxf(shortcut_size, _lobby_lootbox_button.custom_minimum_size.x)
	if _lobby_locker_button != null:
		locker_width = maxf(shortcut_size, _lobby_locker_button.custom_minimum_size.x)
	var row_width: float = lootbox_width + locker_width + 8.0
	var right_margin: float = 18.0 if compact else 22.0
	var top_margin: float = 12.0 if compact else 16.0

	_lobby_shortcut_row.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_lobby_shortcut_row.offset_left = -row_width - right_margin
	_lobby_shortcut_row.offset_right = -right_margin
	_lobby_shortcut_row.offset_top = top_margin
	_lobby_shortcut_row.offset_bottom = top_margin + shortcut_size


func _on_lobby_input_method_changed(
	using_controller: bool,
	family: StringName
) -> void:
	_update_lobby_cosmetic_shortcut_prompts(using_controller, family)
	if using_controller and visible:
		call_deferred("_ensure_valid_lobby_controller_focus")


func _ensure_lobby_shortcut_prompt_icon(
	button: Button,
	node_name: String
) -> TextureRect:
	if button == null:
		return null
	var prompt_icon := button.get_node_or_null(node_name) as TextureRect
	if prompt_icon == null:
		prompt_icon = TextureRect.new()
		prompt_icon.name = node_name
		prompt_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		prompt_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		prompt_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		button.add_child(prompt_icon)
	_prepare_lobby_shortcut_prompt_icon(prompt_icon)
	return prompt_icon


func _prepare_lobby_shortcut_prompt_icon(prompt_icon: TextureRect) -> void:
	if prompt_icon == null:
		return
	if _lobby_controller_prompt_coverage_material == null:
		_lobby_controller_prompt_coverage_material = ShaderMaterial.new()
		_lobby_controller_prompt_coverage_material.shader = (
			CONTROLLER_PROMPT_COVERAGE_SHADER
		)
	# Match the in-game HUD exactly: preserve the original family-specific
	# controller art and strengthen only its tiny on-screen coverage.
	prompt_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	prompt_icon.material = _lobby_controller_prompt_coverage_material


func _layout_lobby_shortcut_prompt_icon(
	prompt_icon: TextureRect,
	compact: bool
) -> void:
	if prompt_icon == null:
		return
	var prompt_size: float = 18.0 if compact else 20.0
	prompt_icon.anchor_left = 1.0
	prompt_icon.anchor_top = 0.5
	prompt_icon.anchor_right = 1.0
	prompt_icon.anchor_bottom = 0.5
	prompt_icon.offset_left = -prompt_size - 5.0
	prompt_icon.offset_top = -prompt_size * 0.5
	prompt_icon.offset_right = -5.0
	prompt_icon.offset_bottom = prompt_size * 0.5


func _update_lobby_cosmetic_shortcut_prompts(
	using_controller: bool,
	family: StringName
) -> void:
	var shortcut_height: float = 40.0 if _compact_layout else 46.0
	# The normal lobby icon remains on the left and the real trigger glyph sits
	# beside it, like the gameplay HUD. No textual L2/R2 is drawn anymore.
	var controller_width: float = 58.0 if _compact_layout else 64.0
	var lootbox_prompt_text := ""
	var locker_prompt_text := ""
	if using_controller:
		match family:
			FootballControllerSupport.FAMILY_XINPUT:
				lootbox_prompt_text = "LT"
				locker_prompt_text = "RT"
			FootballControllerSupport.FAMILY_NINTENDO:
				lootbox_prompt_text = "ZL"
				locker_prompt_text = "ZR"
			_:
				lootbox_prompt_text = "L2"
				locker_prompt_text = "R2"

	var lootbox_prompt_texture: Texture2D = null
	var locker_prompt_texture: Texture2D = null
	if using_controller:
		lootbox_prompt_texture = controller_support.get_controller_axis_icon(
			JOY_AXIS_TRIGGER_LEFT
		)
		locker_prompt_texture = controller_support.get_controller_axis_icon(
			JOY_AXIS_TRIGGER_RIGHT
		)

	if _lobby_lootbox_prompt_icon != null:
		_prepare_lobby_shortcut_prompt_icon(_lobby_lootbox_prompt_icon)
		_layout_lobby_shortcut_prompt_icon(
			_lobby_lootbox_prompt_icon,
			_compact_layout
		)
		_lobby_lootbox_prompt_icon.texture = lootbox_prompt_texture
		_lobby_lootbox_prompt_icon.visible = (
			using_controller and lootbox_prompt_texture != null
		)
	if _lobby_locker_prompt_icon != null:
		_prepare_lobby_shortcut_prompt_icon(_lobby_locker_prompt_icon)
		_layout_lobby_shortcut_prompt_icon(
			_lobby_locker_prompt_icon,
			_compact_layout
		)
		_lobby_locker_prompt_icon.texture = locker_prompt_texture
		_lobby_locker_prompt_icon.visible = (
			using_controller and locker_prompt_texture != null
		)

	if _lobby_lootbox_button != null:
		_lobby_lootbox_button.text = (
			lootbox_prompt_text
			if using_controller and lootbox_prompt_texture == null
			else ""
		)
		_lobby_lootbox_button.tooltip_text = (
			"%s • Open Lootbox" % lootbox_prompt_text
			if using_controller
			else "Open Lootbox"
		)
		_lobby_lootbox_button.custom_minimum_size = Vector2(
			controller_width if using_controller else shortcut_height,
			shortcut_height
		)
		_lobby_lootbox_button.icon_alignment = (
			HORIZONTAL_ALIGNMENT_LEFT
			if using_controller
			else HORIZONTAL_ALIGNMENT_CENTER
		)
		_lobby_lootbox_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _lobby_locker_button != null:
		_lobby_locker_button.text = (
			locker_prompt_text
			if using_controller and locker_prompt_texture == null
			else ""
		)
		_lobby_locker_button.tooltip_text = (
			"%s • Open Locker" % locker_prompt_text
			if using_controller
			else "Open Locker"
		)
		_lobby_locker_button.custom_minimum_size = Vector2(
			controller_width if using_controller else shortcut_height,
			shortcut_height
		)
		_lobby_locker_button.icon_alignment = (
			HORIZONTAL_ALIGNMENT_LEFT
			if using_controller
			else HORIZONTAL_ALIGNMENT_CENTER
		)
		_lobby_locker_button.alignment = HORIZONTAL_ALIGNMENT_CENTER

	call_deferred("_position_lobby_cosmetic_shortcuts", _compact_layout)


func _style_lobby_cosmetic_shortcuts() -> void:
	if _lobby_lootbox_button != null:
		MenuStyler.style_button(_lobby_lootbox_button, Color(0.95, 0.76, 0.30), 38.0)
	if _lobby_locker_button != null:
		MenuStyler.style_button(_lobby_locker_button, Color(0.42, 0.78, 0.92), 38.0)


func _on_teamselection_visibility_changed() -> void:
	_refresh_lobby_cosmetic_shortcut_visibility()
	if visible:
		call_deferred("_position_lobby_cosmetic_shortcuts", _compact_layout)
		if controller_support.using_controller:
			call_deferred("_ensure_valid_lobby_controller_focus")
	else:
		_reset_lobby_trigger_shortcuts()


func _is_lobby_cosmetic_shortcut_context() -> bool:
	# These buttons live on a separate CanvasLayer, so they do not inherit the
	# normal lobby's visibility hierarchy. Be deliberately strict: they are only
	# valid while the actual pre-game Teamselection screen is the active menu.
	if (
		not _lobby_cosmetic_shortcuts_allowed
		or not visible
		or not is_visible_in_tree()
		or _halftime_mode
	):
		return false
	# Do not let the independent CanvasLayer appear during the Teamselection
	# fade-in/fade-out. This was one source of buttons floating over other menus.
	if modulate.a < 0.95:
		return false
	if match_manager == null or match_manager.game_has_started:
		return false
	if network_manager == null or network_manager.current_mode in [
		NetworkManager.NetworkMode.NONE,
		NetworkManager.NetworkMode.FREEPLAY
	]:
		return false
	if _map_overlay != null and _map_overlay.visible:
		return false
	if _lobby_cosmetic_menu_is_open():
		return false
	if _has_external_lobby_menu_or_modal():
		return false
	return true


func _has_external_lobby_menu_or_modal() -> bool:
	var hud := get_parent()
	if hud == null:
		return false

	# ConnectionMenu is the main/singleplayer/multiplayer/options shell. During
	# transitions it can remain visible for a few frames while Teamselection is
	# already being shown. The cosmetic CanvasLayer must never draw above it.
	var connection_menu := hud.get_node_or_null("ConnectionMenu") as Control
	if (
		connection_menu != null
		and connection_menu.is_visible_in_tree()
		and connection_menu.modulate.a > 0.05
	):
		return true

	# Ranked info/singleplayer/Steam popups are Window nodes owned by
	# ConnectionMenu. A PopupPanel can remain visible even while its parent
	# Control is hidden, so check those windows explicitly as well.
	if connection_menu != null:
		for child: Node in connection_menu.get_children():
			var window := child as Window
			if window != null and window.visible:
				return true

	return false


func _refresh_lobby_cosmetic_shortcut_visibility() -> void:
	_set_lobby_cosmetic_shortcuts_visible(true)


func _set_lobby_cosmetic_shortcuts_visible(show_shortcuts: bool) -> void:
	var should_show: bool = (
		show_shortcuts and _is_lobby_cosmetic_shortcut_context()
	)
	if _lobby_shortcut_row != null:
		_lobby_shortcut_row.visible = should_show
	for shortcut_button in [_lobby_lootbox_button, _lobby_locker_button]:
		var button := shortcut_button as Button
		if button != null:
			button.disabled = not should_show


func _open_lobby_lootbox() -> void:
	if _lobby_lootbox_menu == null:
		return
	_remember_lobby_focus_before_cosmetic()
	_set_lobby_cosmetic_shortcuts_visible(false)
	_lobby_lootbox_menu.open_menu()


func _open_lobby_locker() -> void:
	if _lobby_locker_menu == null:
		return
	_remember_lobby_focus_before_cosmetic()
	_set_lobby_cosmetic_shortcuts_visible(false)
	_lobby_locker_menu.open_locker()


func _on_lobby_lootbox_closed() -> void:
	_refresh_lobby_cosmetic_shortcut_visibility()
	_sync_lobby_trigger_shortcuts_from_physical_state()
	call_deferred("_restore_lobby_focus_after_cosmetic")


func _on_lobby_locker_closed() -> void:
	_refresh_lobby_cosmetic_shortcut_visibility()
	_sync_lobby_trigger_shortcuts_from_physical_state()
	call_deferred("_restore_lobby_focus_after_cosmetic")


func _remember_lobby_focus_before_cosmetic() -> void:
	_lobby_focus_before_cosmetic = null
	var focus_owner := get_viewport().gui_get_focus_owner()
	if focus_owner == null:
		return
	if focus_owner in [_lobby_lootbox_button, _lobby_locker_button]:
		return
	if is_ancestor_of(focus_owner):
		_lobby_focus_before_cosmetic = focus_owner


func _restore_lobby_focus_after_cosmetic() -> void:
	if not visible or not controller_support.using_controller:
		_lobby_focus_before_cosmetic = null
		return
	var target := _lobby_focus_before_cosmetic
	_lobby_focus_before_cosmetic = null
	if (
		target != null
		and is_instance_valid(target)
		and target.is_visible_in_tree()
		and target.focus_mode != Control.FOCUS_NONE
	):
		var target_button := target as BaseButton
		if target_button == null or not target_button.disabled:
			target.grab_focus()
			return
	_grab_default_lobby_controller_focus()


func _grab_default_lobby_controller_focus() -> void:
	if (
		side_tabs != null
		and side_tabs.current_tab == 1
		and not side_tabs.is_tab_hidden(1)
		and match_minutes != null
		and match_minutes.is_visible_in_tree()
	):
		match_minutes.grab_focus()
		return
	if not ability_buttons.is_empty():
		for ability_button: Button in ability_buttons:
			if (
				ability_button != null
				and ability_button.is_visible_in_tree()
				and not ability_button.disabled
			):
				ability_button.grab_focus()
				return
	if blue_button != null and blue_button.is_visible_in_tree() and not blue_button.disabled:
		blue_button.grab_focus()


func _ensure_valid_lobby_controller_focus() -> void:
	if (
		not visible
		or not is_visible_in_tree()
		or not controller_support.using_controller
		or _lobby_cosmetic_menu_is_open()
		or (_map_overlay != null and _map_overlay.visible)
	):
		return

	var focus_owner := get_viewport().gui_get_focus_owner() as Control
	if (
		focus_owner != null
		and is_instance_valid(focus_owner)
		and is_ancestor_of(focus_owner)
		and focus_owner.is_visible_in_tree()
		and focus_owner.focus_mode != Control.FOCUS_NONE
	):
		var focused_button := focus_owner as BaseButton
		if focused_button == null or not focused_button.disabled:
			return

	# PvE Ranked hides/disables the Blue/Red join buttons after the session has
	# already started. Previously the controller focus stayed on that now-hidden
	# Blue button, leaving the player with no navigable focus at all. READY is the
	# most natural entry point; if roster state has not enabled it yet, use the
	# first available ability and try again when roster data arrives.
	if match_manager != null and match_manager.singleplayer_ranked_mode:
		if (
			ready_button != null
			and ready_button.is_visible_in_tree()
			and not ready_button.disabled
		):
			ready_button.grab_focus()
			return
		for ability_button: Button in ability_buttons:
			if (
				ability_button != null
				and ability_button.is_visible_in_tree()
				and not ability_button.disabled
			):
				ability_button.grab_focus()
				return

	_grab_default_lobby_controller_focus()


func _sync_lobby_trigger_shortcuts_from_physical_state() -> void:
	var device_id: int = controller_support.active_device_id
	if device_id < 0:
		_reset_lobby_trigger_shortcuts()
		return
	_lobby_left_trigger_down = (
		Input.get_joy_axis(device_id, JOY_AXIS_TRIGGER_LEFT)
		>= LOBBY_COSMETIC_TRIGGER_THRESHOLD
	)
	_lobby_right_trigger_down = (
		Input.get_joy_axis(device_id, JOY_AXIS_TRIGGER_RIGHT)
		>= LOBBY_COSMETIC_TRIGGER_THRESHOLD
	)


func _build_network_lobby_controls() -> void:
	var team_vbox := lobby_title.get_parent() as VBoxContainer
	if team_vbox != null:
		_lobby_info_label = team_vbox.get_node_or_null(
			"NetworkLobbyInfo"
		) as Label
		if _lobby_info_label == null:
			_lobby_info_label = Label.new()
			_lobby_info_label.name = "NetworkLobbyInfo"
			_lobby_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_lobby_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_lobby_info_label.add_theme_font_size_override("font_size", 11)
			_lobby_info_label.add_theme_color_override(
				"font_color", Color(0.58, 0.74, 0.84)
			)
			team_vbox.add_child(_lobby_info_label)
			team_vbox.move_child(
				_lobby_info_label,
				mini(lobby_title.get_index() + 1, team_vbox.get_child_count() - 1)
			)

	var host_options := side_tabs.get_node_or_null(
		"HostOptions/Content"
	) as VBoxContainer
	if host_options == null:
		return
	var kick_row := host_options.get_node_or_null("KickPlayerRow") as HBoxContainer
	if kick_row == null:
		kick_row = HBoxContainer.new()
		kick_row.name = "KickPlayerRow"
		kick_row.add_theme_constant_override("separation", 8)
		host_options.add_child(kick_row)
		var current_index: int = current_settings_label.get_index()
		host_options.move_child(kick_row, mini(current_index, host_options.get_child_count() - 1))
	var kick_label := kick_row.get_node_or_null("Label") as Label
	if kick_label == null:
		kick_label = Label.new()
		kick_label.name = "Label"
		kick_label.text = "REMOVE PLAYER"
		kick_label.custom_minimum_size = Vector2(105.0, 0.0)
		kick_row.add_child(kick_label)
	_kick_player_selector = kick_row.get_node_or_null("Player") as OptionButton
	if _kick_player_selector == null:
		_kick_player_selector = OptionButton.new()
		_kick_player_selector.name = "Player"
		_kick_player_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_kick_player_selector.custom_minimum_size = Vector2(150.0, 34.0)
		kick_row.add_child(_kick_player_selector)
	_kick_player_button = kick_row.get_node_or_null("Kick") as Button
	if _kick_player_button == null:
		_kick_player_button = Button.new()
		_kick_player_button.name = "Kick"
		_kick_player_button.text = "KICK"
		_kick_player_button.custom_minimum_size = Vector2(72.0, 34.0)
		kick_row.add_child(_kick_player_button)
		_kick_player_button.pressed.connect(_on_kick_player_pressed)
	MenuStyler.style_button(_kick_player_button, Color(1.0, 0.34, 0.3), 34.0)
	_refresh_kick_player_options()
	_refresh_network_lobby_info()


func _on_kick_player_pressed() -> void:
	if not multiplayer.is_server() or _kick_player_selector == null:
		return
	var peer_id: int = _kick_player_selector.get_selected_id()
	if peer_id <= 0:
		status_label.text = "Choose a player to remove."
		return
	if network_manager.kick_peer(peer_id):
		status_label.text = "Removing player from lobby..."
	else:
		status_label.text = "Could not remove that player."


func _refresh_kick_player_options() -> void:
	if _kick_player_selector == null or _kick_player_button == null:
		return
	_kick_player_selector.clear()
	_kick_player_selector.add_item("Select player...", 0)
	var host_peer_id: int = _get_current_host_peer_id()
	for group_name in ["red", "blue", "spectators", "unassigned"]:
		var entries: Array = _last_roster_snapshot.get(group_name, [])
		for entry_value in entries:
			if not (entry_value is Dictionary):
				continue
			var entry: Dictionary = entry_value
			var peer_id: int = int(entry.get("peer_id", 0))
			if (
				peer_id <= 0
				or peer_id == host_peer_id
				or bool(entry.get("cpu", false))
			):
				continue
			var suffix: String = ""
			if group_name == "spectators":
				suffix = "  [Spectator]"
			elif group_name == "red" or group_name == "blue":
				suffix = "  [%s]" % group_name.capitalize()
			_kick_player_selector.add_item(
				str(entry.get("name", "Player")) + suffix,
				peer_id
			)
	var can_kick: bool = multiplayer.is_server() and _kick_player_selector.item_count > 1
	_kick_player_selector.disabled = not can_kick
	_kick_player_button.disabled = not can_kick


func _roster_has_ladder_champion() -> bool:
	for group_name in ["red", "blue", "spectators", "unassigned"]:
		var entries: Array = _last_roster_snapshot.get(group_name, [])
		for entry_value in entries:
			if (
				entry_value is Dictionary
				and bool(
					(entry_value as Dictionary).get(
						"pve_ladder_champion",
						false
					)
				)
			):
				return true
	return false


func _process(delta: float) -> void:
	# Shortcut visibility depends on sibling menus/PopupPanels that do not emit
	# Teamselection visibility_changed. Re-evaluate the tiny visibility predicate
	# so the independent top-right CanvasLayer can never become stale.
	if _lobby_shortcut_row != null:
		var should_show_shortcuts: bool = _is_lobby_cosmetic_shortcut_context()
		if _lobby_shortcut_row.visible != should_show_shortcuts:
			_set_lobby_cosmetic_shortcuts_visible(should_show_shortcuts)

	if (
		match_manager == null
		or _last_roster_snapshot.is_empty()
		or not is_visible_in_tree()
		or (
			not match_manager.singleplayer_ranked_mode
			and not _roster_has_ladder_champion()
		)
	):
		_ranked_roster_animation_accum = 0.0
		return
	_ranked_roster_animation_accum += delta
	if _ranked_roster_animation_accum < 0.09:
		return
	_ranked_roster_animation_accum = 0.0
	_refresh_roster_text_only()
	if match_manager.singleplayer_ranked_mode:
		_refresh_pve_ranked_party_formation()
		_refresh_singleplayer_ranked_matchmaking_card()
	_refresh_pve_ranked_party_formation()


func _on_latency_snapshot_updated(snapshot: Dictionary) -> void:
	_latency_snapshot = snapshot.duplicate(true)
	if not _last_roster_snapshot.is_empty():
		_refresh_roster_text_only()
	_refresh_network_lobby_info()


func _on_lobby_metadata_changed(_metadata: Dictionary) -> void:
	_refresh_network_lobby_info()


func _refresh_roster_text_only() -> void:
	team_one_roster.text = _format_roster(
		_last_roster_snapshot.get("blue", []), true
	)
	team_two_roster.text = _format_roster(
		_last_roster_snapshot.get("red", []), true
	)
	unassigned_roster.text = _format_roster(
		_last_roster_snapshot.get("unassigned", [])
	)
	spectator_roster.text = _format_roster(
		_last_roster_snapshot.get("spectators", [])
	)


func _refresh_network_lobby_info() -> void:
	if _lobby_info_label == null:
		return
	if network_manager.current_mode != NetworkManager.NetworkMode.STEAM:
		_lobby_info_label.hide()
		return
	_lobby_info_label.show()
	var summary: Dictionary = network_manager.get_current_lobby_summary()
	if summary.is_empty():
		_lobby_info_label.text = "STEAM LOBBY"
		return
	var local_peer_id: int = multiplayer.get_unique_id()
	var ping_text: String = "HOST"
	if not multiplayer.is_server():
		var local_latency: Dictionary = _latency_snapshot.get(local_peer_id, {})
		var ping_ms: int = int(local_latency.get("ping", 0))
		var jitter_ms: int = int(local_latency.get("jitter", 0))
		ping_text = (
			"%d ms" % ping_ms
			if jitter_ms < 20
			else "%d ms  •  jitter %d" % [ping_ms, jitter_ms]
		)
	_lobby_info_label.text = (
		"%s  •  %s  •  %s  •  %s  •  %dm / first to %d  •  %s"
		% [
			str(summary.get("name", "Steam Lobby")),
			str(summary.get("visibility", "Public")),
			str(summary.get("state", "waiting")).to_upper(),
			str(summary.get("map", "Map 1")),
			int(summary.get("match_minutes", 0)),
			int(summary.get("goals_to_win", 0)),
			ping_text
		]
	)


func _apply_menu_styling() -> void:
	var team_panel := get_node_or_null(
		"CenterContainer/ContentRow/TeamPanel"
	) as PanelContainer
	MenuStyler.style_panel(
		team_panel,
		Color(0.84, 0.72, 0.40),
		Color(0.014, 0.036, 0.024, 0.70)
	)
	MenuStyler.style_tabs(side_tabs, Color(0.84, 0.72, 0.40))

	for node in find_children("*", "Button", true, false):
		MenuStyler.style_button(
			node as Button,
			Color(0.5, 0.66, 0.72),
			34.0
		)
	MenuStyler.style_button(blue_button, Color(0.28, 0.62, 1.0), 38.0)
	MenuStyler.style_button(red_button, Color(1.0, 0.3, 0.34), 38.0)
	MenuStyler.style_button(ready_button, Color(0.28, 1.0, 0.52), 38.0)
	MenuStyler.style_button(
		main_menu_button,
		Color(1.0, 0.38, 0.34),
		36.0
	)
	MenuStyler.style_button(start_button, Color(1.0, 0.76, 0.22), 38.0)
	MenuStyler.style_button(
		spectator_button,
		Color(0.62, 0.68, 0.82),
		35.0
	)
	for ability_id in range(ability_buttons.size()):
		MenuStyler.style_button(
			ability_buttons[ability_id],
			_get_ability_role_color(ability_id),
			35.0
		)
		_apply_fixed_ability_button_layout(
			ability_buttons[ability_id]
		)
	var roster_title := lobby_title.get_parent().get_node_or_null(
		"RosterTitle"
	) as Label
	MenuStyler.style_heading(lobby_title, Color(0.98, 0.96, 0.88))
	MenuStyler.style_heading(roster_title, Color(0.94, 0.94, 0.96))
	_on_tournament_mode_changed(match_manager.tournament_mode)
	MenuStyler.apply_premium_design(self, &"lobby")
	_style_lobby_cosmetic_shortcuts()
	_contain_clipped_button_effects(main_menu_button)
	# The shared skin intentionally owns the base button style. Re-apply the
	# icon-safe margins afterwards so names never sit underneath their icon.
	for ability_id in range(ability_buttons.size()):
		var ability_button := ability_buttons[ability_id]
		MenuStyler.style_ability_role_button(
			ability_button,
			_get_ability_role_color(ability_id)
		)
		_apply_fixed_ability_button_layout(ability_button)
		_fit_ability_button_text(ability_button)


## TeamPanel intentionally clips its responsive scrolling content. The shared
## button hover style normally draws a shadow outside the button rectangle,
## which made the full-width bottom button look sliced at both edges. Keep the
## same hover colours and border while containing its decoration to the actual
## clickable rectangle.
func _contain_clipped_button_effects(button: Button) -> void:
	if button == null:
		return
	for state: StringName in [&"hover", &"pressed", &"focus"]:
		var current_style := button.get_theme_stylebox(state) as StyleBoxFlat
		if current_style == null:
			continue
		var contained_style := current_style.duplicate() as StyleBoxFlat
		contained_style.shadow_size = 0
		contained_style.shadow_offset = Vector2.ZERO
		contained_style.expand_margin_left = 0.0
		contained_style.expand_margin_top = 0.0
		contained_style.expand_margin_right = 0.0
		contained_style.expand_margin_bottom = 0.0
		button.add_theme_stylebox_override(state, contained_style)


func _build_map_selector() -> void:
	var team_vbox := lobby_title.get_parent() as VBoxContainer
	if team_vbox == null or _map_select_button != null:
		return

	var selector_panel := PanelContainer.new()
	selector_panel.name = "MapSelector"
	selector_panel.custom_minimum_size = Vector2(0.0, 56.0)
	selector_panel.clip_contents = true
	MenuStyler.style_panel(
		selector_panel,
		Color(0.84, 0.72, 0.40),
		Color(0.012, 0.04, 0.026, 0.58)
	)
	_map_select_button = Button.new()
	_map_select_button.name = "SelectMapButton"
	_map_select_button.text = "SELECT MAP"
	_map_select_button.tooltip_text = "Choose the match map. Host only."
	MenuStyler.style_button(
		_map_select_button,
		Color(0.84, 0.72, 0.40),
		42.0
	)
	_map_select_button.pressed.connect(_open_map_selector)
	selector_panel.add_child(_map_select_button)
	team_vbox.add_child(selector_panel)
	var roster_title_node := team_vbox.get_node_or_null("RosterTitle")
	if roster_title_node != null:
		team_vbox.move_child(selector_panel, roster_title_node.get_index())

	_map_overlay = Control.new()
	_map_overlay.name = "MapSelectionOverlay"
	_map_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_map_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_map_overlay.z_index = 200
	_map_overlay.hide()
	add_child(_map_overlay)

	var dimmer := ColorRect.new()
	dimmer.name = "Dimmer"
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.0, 0.008, 0.012, 0.82)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	_map_overlay.add_child(dimmer)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	_map_overlay.add_child(center)

	var popup_panel := PanelContainer.new()
	popup_panel.name = "MapPreviewPanel"
	_map_popup_panel = popup_panel
	var viewport_size: Vector2 = get_viewport_rect().size
	var popup_width: float = maxf(760.0, minf(1760.0, viewport_size.x * 0.95))
	var card_width: float = maxf(250.0, (popup_width - 88.0) / 3.0)
	var card_height: float = clampf(viewport_size.y * 0.235, 160.0, 210.0)
	popup_panel.custom_minimum_size = Vector2(popup_width, 0.0)
	popup_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	MenuStyler.style_panel(
		popup_panel,
		Color(0.84, 0.72, 0.40),
		Color(0.012, 0.024, 0.018, 0.985)
	)
	center.add_child(popup_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup_panel.add_child(margin)

	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 10)
	margin.add_child(content)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	# Containers and labels in the header must never take mouse hover/clicks
	# away from the CLOSE button. Only the button itself receives mouse input.
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(header)
	var title := Label.new()
	title.text = "SELECT MAP"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", Color(0.92, 0.97, 1.0))
	header.add_child(title)

	# Reserve the normal header space. The visible CLOSE button itself lives on
	# a dedicated CanvasLayer, so no popup/grid/scroll Control can overlap or
	# steal mouse hover from any part of its rectangle.
	var close_spacer := Control.new()
	close_spacer.custom_minimum_size = Vector2(142.0, 42.0)
	close_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(close_spacer)

	_map_close_canvas_layer = CanvasLayer.new()
	_map_close_canvas_layer.name = "MapCloseCanvasLayer"
	_map_close_canvas_layer.layer = 1000
	_map_close_canvas_layer.visible = false
	add_child(_map_close_canvas_layer)

	_map_overlay_close_button = Button.new()
	_map_overlay_close_button.name = "CloseButton"
	_map_overlay_close_button.text = "CLOSE"
	_map_overlay_close_button.custom_minimum_size = Vector2(126.0, 42.0)
	_map_overlay_close_button.size = Vector2(126.0, 42.0)
	_map_overlay_close_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_map_overlay_close_button.focus_mode = Control.FOCUS_ALL
	_map_overlay_close_button.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	_map_overlay_close_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	# Do not apply UIMotion scaling to this one button. Keeping its transform at
	# exactly 1:1 guarantees the drawn rectangle and GUI hit rectangle coincide.
	_map_overlay_close_button.set_meta("_motion_ready", true)
	_map_overlay_close_button.set_meta("_menu_style_ready", true)
	MenuStyler.style_button(
		_map_overlay_close_button,
		Color(0.62, 0.68, 0.82),
		42.0
	)
	_map_overlay_close_button.pressed.connect(_on_map_close_pressed)
	_map_close_canvas_layer.add_child(_map_overlay_close_button)
	popup_panel.resized.connect(_position_map_close_button)
	get_viewport().size_changed.connect(_position_map_close_button)
	_position_map_close_button.call_deferred()

	var subtitle := Label.new()
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	subtitle.text = "Every card previews its own exact in-game background. Scroll for more maps."
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.62, 0.72, 0.79))
	content.add_child(subtitle)

	_map_preview_scroll = ScrollContainer.new()
	_map_preview_scroll.name = "MapPreviewScroll"
	_map_preview_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_map_preview_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_map_preview_scroll.follow_focus = true
	var four_row_height: float = 4.0 * card_height + 3.0 * 14.0
	var available_scroll_height: float = maxf(420.0, viewport_size.y * 0.72)
	_map_preview_scroll.custom_minimum_size = Vector2(0.0, minf(four_row_height, available_scroll_height))
	_map_preview_scroll.clip_contents = true
	content.add_child(_map_preview_scroll)

	_map_selector = GridContainer.new()
	_map_selector.name = "MapGrid"
	_map_selector.columns = 3
	_map_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map_selector.add_theme_constant_override("h_separation", 14)
	_map_selector.add_theme_constant_override("v_separation", 14)
	_map_preview_scroll.add_child(_map_selector)

	for index in range(FIELD_VARIANT_SCRIPT.get_variant_count()):
		var thumbnail := MAP_THUMBNAIL_SCRIPT.new() as Button
		thumbnail.set_meta("_menu_style_ready", true)
		thumbnail.set("variant_index", index)
		thumbnail.custom_minimum_size = Vector2(card_width, card_height)
		thumbnail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		thumbnail.tooltip_text = "Select Map %d" % (index + 1)
		thumbnail.pressed.connect(_on_map_variant_pressed.bind(index))
		thumbnail.focus_entered.connect(_on_map_card_focus_entered.bind(thumbnail))
		_map_selector.add_child(thumbnail)
		_map_buttons.append(thumbnail)

	_configure_map_grid_focus_neighbors()

	_refresh_map_selector_access()


func _configure_map_grid_focus_neighbors() -> void:
	# Never leave a directional focus edge unset. Godot falls back to automatic
	# focus search when a neighbor is empty, which can jump out of the map grid
	# (especially on an incomplete last row) and leave controller users with no
	# visible selected card. Clamp every direction to an actual map card instead.
	var button_count := _map_buttons.size()
	if button_count <= 0:
		return
	const COLUMN_COUNT := 3
	var last_row := (button_count - 1) / COLUMN_COUNT
	for index in range(button_count):
		var column := index % COLUMN_COUNT
		var row := index / COLUMN_COUNT
		var left_index := index
		var right_index := index
		var top_index := index
		var bottom_index := index

		if column > 0:
			left_index = index - 1
		if column < COLUMN_COUNT - 1 and index + 1 < button_count and (index + 1) / COLUMN_COUNT == row:
			right_index = index + 1
		if row > 0:
			top_index = (row - 1) * COLUMN_COUNT + column
			top_index = mini(top_index, button_count - 1)
		if row < last_row:
			# The final row may contain only one/two cards. Moving down from a
			# missing column lands on the nearest real card in that row.
			bottom_index = mini((row + 1) * COLUMN_COUNT + column, button_count - 1)

		var button := _map_buttons[index]
		button.focus_neighbor_left = button.get_path_to(_map_buttons[left_index])
		button.focus_neighbor_right = button.get_path_to(_map_buttons[right_index])
		button.focus_neighbor_top = button.get_path_to(_map_buttons[top_index])
		button.focus_neighbor_bottom = button.get_path_to(_map_buttons[bottom_index])


func _open_map_selector() -> void:
	if _map_overlay == null or _map_select_button == null:
		return
	if _map_select_button.disabled:
		return
	_map_overlay.show()
	if _map_close_canvas_layer != null:
		_map_close_canvas_layer.visible = true
	_position_map_close_button.call_deferred()
	var selected_index := posmod(
		match_manager.current_field_variant,
		maxi(1, _map_buttons.size())
	)
	if selected_index < _map_buttons.size():
		_map_buttons[selected_index].grab_focus.call_deferred()
		_on_map_card_focus_entered.call_deferred(_map_buttons[selected_index])


func _on_map_card_focus_entered(card: Control) -> void:
	if (
		_map_preview_scroll == null
		or card == null
		or not is_instance_valid(card)
		or not _map_preview_scroll.visible
	):
		return
	# Controller focus can move to a card below the visible rows even though the
	# GridContainer itself has the correct focus-neighbor path. Explicitly keep
	# the focused card inside the ScrollContainer viewport.
	_map_preview_scroll.ensure_control_visible(card)


func _position_map_close_button() -> void:
	if (
		_map_overlay_close_button == null
		or _map_popup_panel == null
		or not is_instance_valid(_map_overlay_close_button)
		or not is_instance_valid(_map_popup_panel)
	):
		return
	var popup_rect: Rect2 = _map_popup_panel.get_global_rect()
	# CanvasLayer coordinates are viewport/canvas coordinates. Use the popup's
	# actual global rect and keep the button in the original top-right header
	# position. No parent Control participates in this button's hit testing.
	_map_overlay_close_button.position = Vector2(
		popup_rect.end.x - 18.0 - 126.0,
		popup_rect.position.y + 16.0
	)
	_map_overlay_close_button.size = Vector2(126.0, 42.0)


func _on_map_close_pressed() -> void:
	_close_map_selector()



func _close_map_selector() -> void:
	if _map_overlay != null:
		_map_overlay.hide()
	if _map_close_canvas_layer != null:
		_map_close_canvas_layer.visible = false
	if (
		_map_select_button != null
		and _map_select_button.visible
		and not _map_select_button.disabled
	):
		_map_select_button.grab_focus.call_deferred()


func _refresh_map_selector_access() -> void:
	var locked := not multiplayer.is_server() or match_manager.game_has_started
	if _map_select_button != null:
		_map_select_button.disabled = locked
		var current_map_text := "Current: Map %d" % (match_manager.current_field_variant + 1)
		_map_select_button.tooltip_text = (
			current_map_text + " • Host only."
			if not multiplayer.is_server()
			else current_map_text + " • Choose the match map."
		)
	for map_button in _map_buttons:
		map_button.disabled = locked
	if locked and _map_overlay != null and _map_overlay.visible:
		_map_overlay.hide()
		if _map_close_canvas_layer != null:
			_map_close_canvas_layer.visible = false


func _on_map_variant_pressed(variant_index: int) -> void:
	if multiplayer.is_server() and not match_manager.game_has_started:
		match_manager.request_field_variant(variant_index)
		_close_map_selector()


func _on_field_variant_changed(variant_index: int) -> void:
	for index in range(_map_buttons.size()):
		var button: Button = _map_buttons[index]
		button.set("selected", index == variant_index)
	if _map_select_button != null:
		_map_select_button.tooltip_text = "Current: Map %d" % (variant_index + 1)
	_refresh_map_selector_access()


func _build_cpu_division_option() -> void:
	var host_options := side_tabs.get_node_or_null(
		"HostOptions/Content"
	) as VBoxContainer
	if host_options == null or _cpu_division_selector != null:
		return

	_cpu_division_row = HBoxContainer.new()
	_cpu_division_row.name = "CPUDivisionRow"
	_cpu_division_row.add_theme_constant_override("separation", 10)

	var label := Label.new()
	label.text = "CPU division"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cpu_division_row.add_child(label)

	_cpu_division_selector = OptionButton.new()
	_cpu_division_selector.name = "Division"
	_cpu_division_selector.custom_minimum_size = Vector2(190.0, 38.0)
	_cpu_division_selector.tooltip_text = (
		"Sets Custom Match CPU intelligence using the PvE Ranked divisions. "
		+ "Higher divisions unlock stronger reactions, execution and tactics."
	)
	for division in range(1, 7):
		_cpu_division_selector.add_item(
			FootballMatchManager.get_singleplayer_ranked_division_name(division).capitalize(),
			division
		)
	_cpu_division_selector.item_selected.connect(_on_cpu_division_selected)
	_cpu_division_row.add_child(_cpu_division_selector)

	var cpu_title := host_options.get_node_or_null("CPUTitle") as Control
	host_options.add_child(_cpu_division_row)
	if cpu_title != null:
		host_options.move_child(_cpu_division_row, cpu_title.get_index() + 1)


func _cpu_level_for_division(division: int) -> int:
	# Custom Match mirrors the PvE Ranked ladder.
	var level_range: Vector2i = FootballMatchManager.get_pve_ranked_intelligence_range(
		division
	)
	return int(round((float(level_range.x) + float(level_range.y)) * 0.5))


func _cpu_division_for_level(level: int) -> int:
	var safe_level: int = clampi(level, 1, FootballMatchManager.CPU_MAX_INTELLIGENCE)
	for division: int in range(1, 7):
		var level_range: Vector2i = FootballMatchManager.get_pve_ranked_intelligence_range(
			division
		)
		if safe_level >= level_range.x and safe_level <= level_range.y:
			return division
	# Legacy/custom INT 11-13 sits between Regionalliga and Bundesliga.
	return 4 if safe_level <= 16 else (5 if safe_level <= 19 else 6)


func _select_cpu_division_option(division: int) -> void:
	if _cpu_division_selector == null:
		return
	var target: int = clampi(division, 1, 6)
	for index in range(_cpu_division_selector.item_count):
		if _cpu_division_selector.get_item_id(index) == target:
			_cpu_division_selector.select(index)
			return


func _on_cpu_division_selected(_item_index: int) -> void:
	if (
		_syncing_host_options
		or not multiplayer.is_server()
		or _cpu_division_selector == null
	):
		return
	_selected_custom_cpu_division = clampi(
		_cpu_division_selector.get_selected_id(),
		1,
		6
	)
	match_manager.update_cpu_difficulty(
		_cpu_level_for_division(_selected_custom_cpu_division)
	)


func _on_cpu_difficulty_changed(level: int) -> void:
	# Preserve the explicitly selected league while syncing host options.
	if _cpu_level_for_division(_selected_custom_cpu_division) != level:
		_selected_custom_cpu_division = _cpu_division_for_level(level)
	_syncing_host_options = true
	_select_cpu_division_option(_selected_custom_cpu_division)
	_syncing_host_options = false
	_update_current_settings_label()


func _build_cpu_ability_options() -> void:
	var host_options := side_tabs.get_node_or_null(
		"HostOptions/Content"
	) as VBoxContainer
	if host_options == null:
		return
	_cpu_ability_title = Label.new()
	_cpu_ability_title.text = "CPU ABILITIES (Random or manual)"
	_cpu_ability_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	host_options.add_child(_cpu_ability_title)
	_cpu_ability_grid = GridContainer.new()
	_cpu_ability_grid.columns = 2
	_cpu_ability_grid.add_theme_constant_override("h_separation", 12)
	_cpu_ability_grid.add_theme_constant_override("v_separation", 4)
	host_options.add_child(_cpu_ability_grid)
	var settings_index := current_settings_label.get_index()
	host_options.move_child(_cpu_ability_title, settings_index)
	host_options.move_child(_cpu_ability_grid, settings_index + 1)
	for team_data in [
		{
			"name": "Blue",
			"color": Color(0.35, 0.68, 1.0),
			"list": _blue_cpu_ability_selectors,
			"rows": _blue_cpu_ability_rows
		},
		{
			"name": "Red",
			"color": Color(1.0, 0.35, 0.38),
			"list": _red_cpu_ability_selectors,
			"rows": _red_cpu_ability_rows
		}
	]:
		for slot in range(match_manager.max_players_per_team):
			var row := HBoxContainer.new()
			var label := Label.new()
			label.text = "%s CPU %d" % [team_data["name"], slot + 1]
			label.custom_minimum_size = Vector2(88.0, 0.0)
			label.add_theme_color_override("font_color", team_data["color"])
			row.add_child(label)
			var selector := OptionButton.new()
			selector.custom_minimum_size = Vector2(195.0, 0.0)
			selector.add_item("Random", CPU_RANDOM_OPTION_ID)
			for ability_id in range(FootballPlayer.ABILITY_COUNT + 1):
				if ability_id == FootballPlayer.ABILITY_META_VISION:
					continue
				selector.add_item(
					FootballPlayer.get_ability_name(ability_id),
					ability_id
				)
			row.add_child(selector)
			(team_data["list"] as Array).append(selector)
			(team_data["rows"] as Array).append(row)
			selector.item_selected.connect(
				_on_cpu_ability_option_selected
			)
			row.hide()
			_cpu_ability_grid.add_child(row)


func _read_cpu_ability_options(selectors: Array[OptionButton]) -> Array[int]:
	var values: Array[int] = []
	for selector in selectors:
		var selected_id := selector.get_selected_id()
		values.append(
			FootballMatchManager.CPU_ABILITY_RANDOM
			if selected_id == CPU_RANDOM_OPTION_ID
			else selected_id
		)
	return values


func _select_cpu_ability_option(selector: OptionButton, value: int) -> void:
	var target_id := (
		CPU_RANDOM_OPTION_ID
		if value == FootballMatchManager.CPU_ABILITY_RANDOM
		else value
	)
	for item_index in range(selector.item_count):
		if selector.get_item_id(item_index) == target_id:
			selector.select(item_index)
			return
	selector.select(0)


func _apply_ability_button_icon(
	button: Button,
	ability_id: int
) -> void:
	if (
		button == null
		or ability_id < 0
		or ability_id >= ABILITY_ICON_PATHS.size()
	):
		return

	var icon_path: String = ABILITY_ICON_PATHS[ability_id]
	if not ResourceLoader.exists(icon_path):
		push_warning(
			"Missing ability selection icon: %s" % icon_path
		)
		return

	var icon_texture := load(icon_path) as Texture2D
	if icon_texture == null:
		push_warning(
			"Ability selection icon could not be loaded: %s"
			% icon_path
		)
		return

	# Do not use Button.expand_icon. Long names and difficulty stars
	# otherwise consume the available width and shrink the icon.
	button.icon = null
	button.expand_icon = false
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.clip_text = true

	var icon_rect := button.get_node_or_null(
		"FixedAbilityIcon"
	) as TextureRect
	if icon_rect == null:
		icon_rect = TextureRect.new()
		icon_rect.name = "FixedAbilityIcon"
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_rect.focus_mode = Control.FOCUS_NONE
		icon_rect.anchor_left = 0.0
		icon_rect.anchor_right = 0.0
		icon_rect.anchor_top = 0.5
		icon_rect.anchor_bottom = 0.5
		icon_rect.offset_left = ABILITY_BUTTON_ICON_LEFT
		icon_rect.offset_right = (
			ABILITY_BUTTON_ICON_LEFT
			+ ABILITY_BUTTON_ICON_SIZE
		)
		icon_rect.offset_top = -ABILITY_BUTTON_ICON_SIZE * 0.5
		icon_rect.offset_bottom = ABILITY_BUTTON_ICON_SIZE * 0.5
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = (
			TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		)
		icon_rect.texture_filter = (
			CanvasItem.TEXTURE_FILTER_LINEAR
		)
		icon_rect.z_index = 1
		button.add_child(icon_rect)

	icon_rect.texture = icon_texture


func _apply_fixed_ability_button_layout(button: Button) -> void:
	if button == null:
		return

	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.clip_text = true

	for state_name in [
		"normal",
		"hover",
		"pressed",
		"disabled"
	]:
		var source_style := button.get_theme_stylebox(
			state_name
		)
		if source_style == null:
			continue
		var fixed_style := source_style.duplicate() as StyleBox
		if fixed_style == null:
			continue
		fixed_style.content_margin_left = (
			ABILITY_BUTTON_TEXT_LEFT_MARGIN
		)
		fixed_style.content_margin_right = (
			ABILITY_BUTTON_TEXT_RIGHT_MARGIN
		)
		button.add_theme_stylebox_override(
			state_name,
			fixed_style
		)


func _fit_ability_button_text(button: Button) -> void:
	if button == null:
		return

	var font_size: int = 12 if button.custom_minimum_size.x <= 190.0 else 14
	if button.text.length() >= 27:
		font_size = mini(font_size, 13)
	button.add_theme_font_size_override(
		"font_size",
		font_size
	)


func _build_compact_ability_grid() -> void:
	var abilities_panel := side_tabs.get_node_or_null(
		"Abilities"
	) as VBoxContainer
	if abilities_panel == null:
		return

	for header_name in [
		"AttackHeader",
		"PlaymakerHeader",
		"FlexibleHeader",
		"DefenseHeader"
	]:
		var header := abilities_panel.get_node_or_null(
			header_name
		) as Control
		if header != null:
			header.hide()

	var scroll := ScrollContainer.new()
	scroll.name = "AbilityScroll"
	scroll.custom_minimum_size = Vector2(0.0, 0.0)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	abilities_panel.add_child(scroll)

	_ability_columns = HBoxContainer.new()
	_ability_columns.name = "AbilityColumns"
	_ability_columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ability_columns.add_theme_constant_override(
		"separation",
		6
	)
	scroll.add_child(_ability_columns)

	_create_ability_column(
		"ATTACK",
		Color(1.0, 0.36, 0.30),
		FootballPlayer.get_ability_ids_for_role(
			FootballPlayer.ABILITY_ROLE_ATTACK
		)
	)
	_create_ability_column(
		"PLAYMAKER",
		Color(0.77, 0.43, 1.0),
		FootballPlayer.get_ability_ids_for_role(
			FootballPlayer.ABILITY_ROLE_PLAYMAKER
		)
	)

	var flexible_defense := _create_ability_column(
		"FLEXIBLE",
		Color(0.60, 0.94, 0.34),
		FootballPlayer.get_ability_ids_for_role(
			FootballPlayer.ABILITY_ROLE_FLEXIBLE
		)
	)
	_add_ability_column_header(
		flexible_defense,
		"DEFENSE",
		Color(0.24, 0.88, 0.66)
	)
	_add_ability_buttons_to_column(
		flexible_defense,
		FootballPlayer.get_ability_ids_for_role(
			FootballPlayer.ABILITY_ROLE_DEFENSE
		)
	)


func _build_ability_previews() -> void:
	_ability_preview = FootballAbilityPreviewCard.new()
	_ability_preview.name = "AbilityPreview"
	add_child(_ability_preview)
	for ability_id in range(ability_buttons.size()):
		_ability_preview.register_button(
			ability_buttons[ability_id],
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
	_ability_columns.add_child(column)
	_add_ability_column_header(column, title, color)
	_add_ability_buttons_to_column(column, ability_ids)
	return column


func _add_ability_column_header(
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


func _add_ability_buttons_to_column(
	column: VBoxContainer,
	ability_ids: Array
) -> void:
	for ability_value in ability_ids:
		var ability_id := int(ability_value)
		var button := ability_buttons[ability_id]
		button.reparent(column)
		button.custom_minimum_size = Vector2(200.0, 44.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 14)


func _configure_ability_focus_navigation() -> void:
	# The ability screen is visually three fixed columns. Relying on Godot's
	# automatic spatial focus could jump sideways around the PLAYMAKER and
	# FLEXIBLE/DEFENSE header break, which felt like Down was acting as Left/Right.
	# Wire the visual grid explicitly so D-pad/stick directions always match what
	# the player sees.
	var third_column: Array = FootballPlayer.get_ability_ids_for_role(
		FootballPlayer.ABILITY_ROLE_FLEXIBLE
	)
	third_column.append_array(
		FootballPlayer.get_ability_ids_for_role(
			FootballPlayer.ABILITY_ROLE_DEFENSE
		)
	)
	var columns: Array = [
		FootballPlayer.get_ability_ids_for_role(
			FootballPlayer.ABILITY_ROLE_ATTACK
		),
		FootballPlayer.get_ability_ids_for_role(
			FootballPlayer.ABILITY_ROLE_PLAYMAKER
		),
		third_column
	]

	for column_index in range(columns.size()):
		var column_ids: Array = columns[column_index]
		if column_ids.is_empty():
			continue
		for row_index in range(column_ids.size()):
			var ability_id := int(column_ids[row_index])
			if ability_id < 0 or ability_id >= ability_buttons.size():
				continue
			var button := ability_buttons[ability_id]
			button.focus_mode = Control.FOCUS_ALL

			var up_id := int(
				column_ids[(row_index - 1 + column_ids.size()) % column_ids.size()]
			)
			var down_id := int(
				column_ids[(row_index + 1) % column_ids.size()]
			)
			_set_focus_neighbor(
				button,
				SIDE_TOP,
				ability_buttons[up_id]
			)
			_set_focus_neighbor(
				button,
				SIDE_BOTTOM,
				ability_buttons[down_id]
			)

			var left_button := button
			if column_index > 0:
				var left_ids: Array = columns[column_index - 1]
				var left_row: int = _map_focus_row(
					row_index,
					column_ids.size(),
					left_ids.size()
				)
				left_button = ability_buttons[int(left_ids[left_row])]
			_set_focus_neighbor(button, SIDE_LEFT, left_button)

			var right_button := button
			if column_index < columns.size() - 1:
				var right_ids: Array = columns[column_index + 1]
				var right_row: int = _map_focus_row(
					row_index,
					column_ids.size(),
					right_ids.size()
				)
				right_button = ability_buttons[int(right_ids[right_row])]
			_set_focus_neighbor(button, SIDE_RIGHT, right_button)


func _map_focus_row(
	row_index: int,
	source_count: int,
	target_count: int
) -> int:
	if target_count <= 1 or source_count <= 1:
		return 0
	var normalized: float = float(row_index) / float(source_count - 1)
	return clampi(
		int(round(normalized * float(target_count - 1))),
		0,
		target_count - 1
	)


func _set_focus_neighbor(
	source: Control,
	side: int,
	target: Control
) -> void:
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


func get_local_player() -> FootballPlayer:
	return players_parent.get_node_or_null(
		str(multiplayer.get_unique_id())
	) as FootballPlayer


func _request_team(team: StringName, display_team: String) -> void:
	match_manager.request_join_team(team)
	status_label.text = ""


func _on_leave_team_pressed() -> void:
	match_manager.request_leave_team()
	status_label.text = ""


func _on_main_menu_pressed() -> void:
	_close_lobby_cosmetic_menus()
	status_label.text = "Leaving lobby..."
	main_menu_button.disabled = true
	network_manager.disconnect_game()


func _on_ready_button_pressed() -> void:
	match_manager.request_set_ready(not _local_ready)
	status_label.text = ""


func _on_ability_pressed(ability_id: int) -> void:
	match_manager.request_select_ability(ability_id)
	status_label.text = ""


func open_halftime_adjustments() -> void:
	if (
		not match_manager.tournament_halftime_active
		or match_manager.champions_league_mode
	):
		return
	_set_halftime_mode(true)
	side_tabs.current_tab = 0
	show()
	if controller_support.using_controller:
		ability_buttons[0].grab_focus.call_deferred()


func _on_halftime_return_pressed() -> void:
	if not _halftime_mode:
		return
	_close_lobby_cosmetic_menus()
	hide()
	var leaderboard := get_parent().get_node_or_null("Leaderboard")
	if leaderboard != null:
		leaderboard.call("show_halftime_scoreboard")


func _on_halftime_changed(active: bool, _seconds_remaining: int) -> void:
	_set_halftime_mode(active and not match_manager.champions_league_mode)
	if not active and visible and match_manager.game_has_started:
		hide()


func _set_halftime_mode(active: bool) -> void:
	_halftime_mode = active
	lobby_title.text = "HALFTIME ADJUSTMENTS" if active else "MATCH LOBBY"
	halftime_return_button.visible = active
	red_button.visible = not active
	blue_button.visible = not active
	leave_button.visible = not active
	main_menu_button.visible = not active
	spectator_button.visible = not active
	ready_button.visible = not active
	start_button.visible = not active
	_set_lobby_cosmetic_shortcuts_visible(not active)
	if active:
		_close_lobby_cosmetic_menus()
	match_minutes.editable = not active
	goals_to_win.editable = not active
	tournament_mode.disabled = (
		active
		or match_manager.ranked_mode
		or match_manager.champions_league_mode
	)
	if _draft_mode_toggle != null:
		_draft_mode_toggle.disabled = active
	_on_fun_mutators_changed(match_manager.get_fun_mutators())
	blue_cpu_count.editable = not active
	red_cpu_count.editable = not active
	for selector in _blue_cpu_ability_selectors:
		selector.disabled = active and not multiplayer.is_server()
	for selector in _red_cpu_ability_selectors:
		selector.disabled = active and not multiplayer.is_server()
	if active:
		status_label.text = (
			"Choose a Game 2 ability. Random CPUs have reviewed Game 1."
		)


func _on_ability_selection_result(
	success: bool,
	_ability_id: int,
	message: String
) -> void:
	# A successful pick is already obvious from the highlighted card.
	# Keep this line available only for useful rejection feedback.
	status_label.text = "" if success else message
	if not success:
		UIMotion.pulse(
			status_label,
			Vector2(1.03, 1.03),
			0.18
		)


func _on_ready_state_result(
	_success: bool,
	_ready_state: bool,
	_message: String
) -> void:
	status_label.text = ""


func _on_start_button_pressed() -> void:
	match_manager.request_start_match()
	status_label.text = ""


func _on_match_option_value_changed(_value: float) -> void:
	if _syncing_host_options or not multiplayer.is_server():
		return
	match_manager.update_match_settings(
		float(match_minutes.value) * 60.0,
		int(goals_to_win.value)
	)


func _on_tournament_option_toggled(enabled: bool) -> void:
	if _syncing_host_options or not multiplayer.is_server():
		return
	match_manager.update_tournament_mode(enabled)


func _on_draft_option_toggled(enabled: bool) -> void:
	if _syncing_host_options or not multiplayer.is_server():
		return
	match_manager.configure_draft_session(enabled)


func _on_cpu_count_changed(_value: float) -> void:
	if _syncing_host_options or not multiplayer.is_server():
		return
	match_manager.update_cpu_settings(
		int(blue_cpu_count.value),
		int(red_cpu_count.value)
	)


func _on_cpu_ability_option_selected(_item_index: int) -> void:
	if _syncing_host_options or not multiplayer.is_server():
		return
	match_manager.update_cpu_ability_preferences(
		_read_cpu_ability_options(_blue_cpu_ability_selectors),
		_read_cpu_ability_options(_red_cpu_ability_selectors)
	)


func _on_match_settings_changed(
	seconds: float,
	goal_limit: int
) -> void:
	_syncing_host_options = true
	match_minutes.value = seconds / 60.0
	goals_to_win.value = goal_limit
	_syncing_host_options = false
	_update_current_settings_label()


func _on_cpu_settings_changed(
	blue_count: int,
	red_count: int
) -> void:
	_syncing_host_options = true
	blue_cpu_count.value = blue_count
	red_cpu_count.value = red_count
	_syncing_host_options = false
	_update_current_settings_label()


func _update_current_settings_label() -> void:
	var mode_text := "single match"
	if match_manager.champions_league_mode:
		mode_text = "Draft card mode"
	elif match_manager.ranked_mode:
		mode_text = "ranked rules"
	elif tournament_mode.button_pressed:
		mode_text = "2-game aggregate"
	var active_fun_count: int = 0
	for enabled_variant: Variant in match_manager.get_fun_mutators().values():
		if bool(enabled_variant):
			active_fun_count += 1
	var cpu_division_name: String = (
		FootballMatchManager.get_singleplayer_ranked_division_name(
			_selected_custom_cpu_division
		).capitalize()
	)
	current_settings_label.text = (
		"Current: %.1f min | First to %d | %s\nCPU %s B%d/R%d | Fun %d"
		% [
			match_manager.regulation_seconds / 60.0,
			match_manager.goals_to_win,
			mode_text,
			cpu_division_name,
			int(blue_cpu_count.value),
			int(red_cpu_count.value),
			active_fun_count
		]
	)


func _on_tournament_mode_changed(enabled: bool) -> void:
	_syncing_host_options = true
	tournament_mode.button_pressed = enabled and not match_manager.ranked_mode
	_syncing_host_options = false
	_update_current_settings_label()


func _on_ranked_mode_changed(enabled: bool) -> void:
	tournament_mode.disabled = (
		enabled
		or match_manager.champions_league_mode
		or _halftime_mode
	)
	_on_fun_mutators_changed(match_manager.get_fun_mutators())
	_update_current_settings_label()


func _on_champions_league_mode_changed(enabled: bool) -> void:
	_syncing_host_options = true
	if _draft_mode_toggle != null:
		_draft_mode_toggle.button_pressed = enabled
	tournament_mode.disabled = enabled or _halftime_mode
	_apply_draft_lobby_layout(enabled)
	_syncing_host_options = false
	_update_current_settings_label()


func _on_draft_state_changed(snapshot: Dictionary) -> void:
	if bool(snapshot.get("active", false)):
		_lobby_cosmetic_shortcuts_allowed = false
		_close_lobby_cosmetic_menus()
		hide()


func _apply_draft_lobby_layout(enabled: bool) -> void:
	if side_tabs == null:
		return
	var pve_ranked_draft: bool = (
		enabled
		and match_manager != null
		and match_manager.singleplayer_ranked_mode
	)
	side_tabs.visible = not pve_ranked_draft
	side_tabs.set_tab_hidden(0, enabled)
	if enabled and not pve_ranked_draft:
		side_tabs.current_tab = 1
	if pve_ranked_draft:
		lobby_title.text = "PVE RANKED  •  MATCH LOBBY"
	else:
		lobby_title.text = (
			"DRAFT  •  TWO-LEG CARD MODE"
			if enabled
			else "TEAM SELECTION"
		)
	var host_options := side_tabs.get_node_or_null("HostOptions/Content") as VBoxContainer
	if host_options == null:
		return
	for child in host_options.get_children():
		if child is CanvasItem:
			(child as CanvasItem).visible = (
				not enabled
				or child.name in [
					&"Title", &"DraftMode", &"CPUCountCard", &"CPUTitle",
					&"BlueCPURow", &"RedCPURow"
				]
			)
	var cpu_card := host_options.get_node_or_null("CPUCountCard") as CanvasItem
	if cpu_card != null:
		cpu_card.visible = true
	var title := host_options.get_node_or_null("Title") as Label
	if title != null:
		title.visible = true
		title.text = "HOST BOT SETUP" if enabled else "HOST OPTIONS"
	_apply_lobby_panel_widths()


func _on_cpu_ability_preferences_changed(
	blue_preferences: Array,
	red_preferences: Array
) -> void:
	_syncing_host_options = true
	for index in range(_blue_cpu_ability_selectors.size()):
		var value := FootballMatchManager.CPU_ABILITY_RANDOM
		if index < blue_preferences.size():
			value = int(blue_preferences[index])
		_select_cpu_ability_option(_blue_cpu_ability_selectors[index], value)
	for index in range(_red_cpu_ability_selectors.size()):
		var value := FootballMatchManager.CPU_ABILITY_RANDOM
		if index < red_preferences.size():
			value = int(red_preferences[index])
		_select_cpu_ability_option(_red_cpu_ability_selectors[index], value)
	_syncing_host_options = false


func _on_team_join_result(
	_success: bool,
	_team: StringName
) -> void:
	status_label.text = ""


func _on_match_start_result(
	success: bool,
	message: String
) -> void:
	status_label.text = message
	if not success:
		show()


func _update_cpu_ability_row_visibility(
	blue_entries: Array,
	red_entries: Array
) -> void:
	_set_cpu_team_rows_visible(
		_blue_cpu_ability_rows,
		blue_entries
	)
	_set_cpu_team_rows_visible(
		_red_cpu_ability_rows,
		red_entries
	)


func _set_cpu_team_rows_visible(
	rows: Array[Control],
	entries: Array
) -> void:
	var occupied_cpu_slots: Dictionary = {}
	for entry in entries:
		if entry is Dictionary and bool(entry.get("cpu", false)):
			occupied_cpu_slots[int(entry.get("team_slot", -1))] = true
	for slot in range(rows.size()):
		rows[slot].visible = occupied_cpu_slots.has(slot)


func _on_roster_details_changed(roster: Dictionary) -> void:
	_last_roster_snapshot = roster.duplicate(true)
	if match_manager != null and match_manager.singleplayer_ranked_mode:
		_refresh_singleplayer_ranked_matchmaking_card()
		_refresh_pve_ranked_party_formation()
	var red_entries: Array = roster.get("red", [])
	var blue_entries: Array = roster.get("blue", [])
	var unassigned_entries: Array = roster.get("unassigned", [])
	var spectator_entries: Array = roster.get("spectators", [])
	_update_cpu_ability_row_visibility(
		blue_entries,
		red_entries
	)

	team_one_roster.text = _format_roster(blue_entries, true)
	team_two_roster.text = _format_roster(red_entries, true)
	unassigned_roster.text = _format_roster(unassigned_entries)
	spectator_roster.text = _format_roster(spectator_entries)

	var maximum := match_manager.max_players_per_team
	var player := get_local_player()
	var current_team: StringName = &""
	var current_ability := FootballPlayer.ABILITY_NONE

	if player != null:
		current_team = player.team
		current_ability = player.selected_ability
	var is_playing_team := current_team in [&"blue", &"red"]

	_local_ready = _get_local_ready(
		blue_entries,
		red_entries
	)
	blue_button.text = "Join Blue (%d/%d)" % [
		blue_entries.size(),
		maximum
	]
	red_button.text = "Join Red (%d/%d)" % [
		red_entries.size(),
		maximum
	]

	blue_button.disabled = (
		blue_entries.size() >= maximum
		and current_team != &"blue"
	)
	red_button.disabled = (
		red_entries.size() >= maximum
		and current_team != &"red"
	)
	if match_manager.ladder_mode:
		blue_button.disabled = (
			match_manager.ladder_human_team != FootballMatchManager.TEAM_BLUE
		)
		red_button.disabled = (
			match_manager.ladder_human_team != FootballMatchManager.TEAM_RED
		)
	if match_manager.singleplayer_ranked_mode:
		blue_button.disabled = true
		red_button.disabled = true
	leave_button.disabled = current_team == &""
	var spectator_limit: int = match_manager.max_spectators
	spectator_button.text = "Spectate (%d/%d)" % [
		spectator_entries.size(), spectator_limit
	]
	spectator_button.disabled = (
		current_team == FootballMatchManager.TEAM_SPECTATOR
		or (
			spectator_entries.size() >= spectator_limit
			and current_team != FootballMatchManager.TEAM_SPECTATOR
		)
	)
	if match_manager.singleplayer_ranked_mode:
		leave_button.disabled = true
		spectator_button.disabled = true
	ready_button.disabled = not is_playing_team
	ready_button.text = (
		"CANCEL READY"
		if _local_ready
		else (
			"READY FOR MATCH"
			if match_manager.singleplayer_ranked_mode
			else "READY UP"
		)
	)
	ready_button.add_theme_color_override(
		"font_color",
		Color(0.45, 1.0, 0.55)
		if _local_ready
		else Color.WHITE
	)
	if (
		match_manager.singleplayer_ranked_mode
		and controller_support.using_controller
	):
		call_deferred("_ensure_valid_lobby_controller_focus")

	var roster_ready := _roster_can_start(
		blue_entries,
		red_entries
	)
	start_button.disabled = (
		not multiplayer.is_server()
		or not roster_ready
	)
	start_button.text = (
		"START MATCH"
		if roster_ready
		else "WAITING FOR PLAYERS"
	)
	start_button.visible = not match_manager.singleplayer_ranked_mode
	_refresh_kick_player_options()
	_refresh_network_lobby_info()

	var team_entries: Array = []
	if current_team == &"blue":
		team_entries = blue_entries
	elif current_team == &"red":
		team_entries = red_entries

	for index in range(ability_buttons.size()):
		var ability_id := index
		var owner := _get_ability_owner(
			team_entries,
			ability_id
		)
		var owner_peer_id := int(owner.get("peer_id", 0))
		var selected_by_local := (
			current_ability == ability_id
			or (
				ability_id != FootballPlayer.ABILITY_NONE
				and owner_peer_id
				== multiplayer.get_unique_id()
			)
		)
		var random_cpu_can_yield := _halftime_random_cpu_can_yield(
			owner,
			current_team
		)
		var taken_by_other := (
			not owner.is_empty()
			and owner_peer_id
			!= multiplayer.get_unique_id()
			and not random_cpu_can_yield
		)
		var button := ability_buttons[index]
		button.disabled = (
			not is_playing_team
			or (
				ability_id != FootballPlayer.ABILITY_NONE
				and taken_by_other
			)
		)
		button.text = FootballPlayer.get_ability_name(ability_id)
		if ability_id != FootballPlayer.ABILITY_NONE:
			button.text += "  %s" % (
				_get_difficulty_stars(ability_id)
			)
		var availability_text := "Available"
		if not is_playing_team:
			availability_text = "Join a team first"
		elif selected_by_local:
			availability_text = "Equipped by you"
			button.text += "    [✓]"
		elif taken_by_other:
			availability_text = "Unavailable - already equipped"
		elif random_cpu_can_yield:
			availability_text = "Available - Random CPU will adapt"
		_fit_ability_button_text(button)
		_apply_ability_availability_color(
			button,
			ability_id,
			not is_playing_team,
			selected_by_local,
			taken_by_other
		)
		if index < _base_ability_tooltips.size():
			button.tooltip_text = (
				_base_ability_tooltips[index]
				+ "\nStatus: "
				+ availability_text
			)
			if _ability_preview != null:
				_ability_preview.set_button_details(
					button,
					button.tooltip_text
				)


func _halftime_random_cpu_can_yield(
	owner: Dictionary,
	team: StringName
) -> bool:
	if (
		not _halftime_mode
		or owner.is_empty()
		or not bool(owner.get("cpu", false))
	):
		return false
	var slot := int(owner.get("team_slot", -1))
	var preferences := (
		match_manager.blue_cpu_ability_preferences
		if team == FootballMatchManager.TEAM_BLUE
		else match_manager.red_cpu_ability_preferences
	)
	return (
		slot >= 0
		and slot < preferences.size()
		and int(preferences[slot])
		== FootballMatchManager.CPU_ABILITY_RANDOM
	)


func _get_ability_owner(
	entries: Array,
	ability_id: int
) -> Dictionary:
	if ability_id == FootballPlayer.ABILITY_NONE:
		return {}
	for entry in entries:
		if not (entry is Dictionary):
			continue
		if int(entry.get("ability", 0)) == ability_id:
			return entry as Dictionary
	return {}


func _apply_ability_availability_color(
	button: Button,
	ability_id: int,
	needs_team: bool,
	selected_by_local: bool,
	taken_by_other: bool
) -> void:
	var color := _get_ability_role_color(ability_id)
	if needs_team:
		color = Color(0.55, 0.57, 0.62)
	elif selected_by_local:
		color = Color(1.0, 0.86, 0.28)
	elif taken_by_other:
		color = Color(0.92, 0.38, 0.42)

	button.add_theme_color_override("font_color", color)
	button.add_theme_color_override(
		"font_hover_color",
		color.lightened(0.16)
	)
	button.add_theme_color_override(
		"font_disabled_color",
		color.darkened(0.16)
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


func _get_ability_difficulty(ability_id: int) -> int:
	match ability_id:
		FootballPlayer.ABILITY_BURST_DRIBBLE:
			return burst_dribble_difficulty
		FootballPlayer.ABILITY_QUICK_TRIGGER:
			return curve_shot_difficulty
		FootballPlayer.ABILITY_POWER_STRIKE:
			return power_strike_difficulty
		FootballPlayer.ABILITY_OVERDRIVE:
			return overdrive_difficulty
		FootballPlayer.ABILITY_HEEL_TURN:
			return heel_turn_difficulty
		FootballPlayer.ABILITY_ENFORCER:
			return enforcer_difficulty
		FootballPlayer.ABILITY_GOALKEEPER_REACH:
			return goalkeeper_reach_difficulty
		FootballPlayer.ABILITY_TIME_SKIP_PASS:
			return time_skip_pass_difficulty
		FootballPlayer.ABILITY_DIRECT_FINISH:
			return direct_finish_difficulty
		FootballPlayer.ABILITY_ELASTIC_STEP:
			return elastic_step_difficulty
		FootballPlayer.ABILITY_META_VISION:
			return meta_vision_difficulty
		FootballPlayer.ABILITY_COPYCAT:
			return copycat_difficulty
		FootballPlayer.ABILITY_REFLEX_BLOCK:
			return reflex_block_difficulty
		FootballPlayer.ABILITY_IRON_ANCHOR:
			return iron_anchor_difficulty
		FootballPlayer.ABILITY_BLIND_SPOT:
			return blind_spot_difficulty
		FootballPlayer.ABILITY_BOOGIE_WOOGIE:
			return boogie_woogie_difficulty
		FootballPlayer.ABILITY_ECHO:
			return echo_difficulty
		FootballPlayer.ABILITY_RETURN_TAG:
			return return_tag_difficulty
		FootballPlayer.ABILITY_BREAKAWAY:
			return breakaway_difficulty
		FootballPlayer.ABILITY_SNAPBACK:
			return snapback_difficulty
		FootballPlayer.ABILITY_SIDE_SWIPE:
			return side_swipe_difficulty
		FootballPlayer.ABILITY_NUTMEG:
			return nutmeg_difficulty
		FootballPlayer.ABILITY_DECOY_RUN:
			return decoy_run_difficulty
		_:
			return 0


func _get_difficulty_stars(ability_id: int) -> String:
	var difficulty := clampi(
		_get_ability_difficulty(ability_id),
		1,
		3
	)
	return (
		"\u2605".repeat(difficulty)
		+ "\u2606".repeat(3 - difficulty)
	)


func _get_difficulty_name(ability_id: int) -> String:
	match clampi(_get_ability_difficulty(ability_id), 1, 3):
		1:
			return "Easy"
		2:
			return "Medium"
		_:
			return "Hard"


func _append_difficulty_to_tooltip(
	button: Button,
	ability_id: int
) -> void:
	if (
		button == null
		or ability_id == FootballPlayer.ABILITY_NONE
	):
		return

	button.tooltip_text += "\nDifficulty: %s  %s" % [
		_get_difficulty_stars(ability_id),
		_get_difficulty_name(ability_id)
	]


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


func _get_local_ready(
	blue_entries: Array,
	red_entries: Array
) -> bool:
	var local_peer_id := multiplayer.get_unique_id()
	for entry in blue_entries + red_entries:
		if (
			entry is Dictionary
			and int(entry.get("peer_id", 0)) == local_peer_id
		):
			return bool(entry.get("ready", false))
	return false


func _roster_can_start(
	blue_entries: Array,
	red_entries: Array
) -> bool:
	if (
		blue_entries.size() < match_manager.min_players_per_team
		or red_entries.size() < match_manager.min_players_per_team
	):
		return false

	for entry in blue_entries + red_entries:
		if (
			not (entry is Dictionary)
			or not bool(entry.get("ready", false))
		):
			return false
	return true


func _format_roster(
	entries: Array,
	show_ready: bool = false
) -> String:
	if entries.is_empty():
		return "[center]- None -[/center]"

	var names: PackedStringArray = []
	for entry in entries:
		if entry is Dictionary:
			var player_name := _truncate_roster_text(
				str(entry.get("name", "Player")),
				13 if show_ready else 28
			)
			player_name = _escape_roster_bbcode(player_name)
			var formatted_player_name: String = player_name
			if bool(entry.get("pve_ladder_champion", false)):
				formatted_player_name = _format_ladder_champion_name(player_name)
			elif bool(entry.get("battle_pass_complete", false)):
				formatted_player_name = _format_completed_pass_name(player_name)
			var ability_id := int(entry.get("ability", 0))
			var host_peer_id: int = _get_current_host_peer_id()
			var is_lobby_host: bool = (
				not bool(entry.get("cpu", false))
				and int(entry.get("peer_id", 0)) == host_peer_id
			)
			if is_lobby_host:
				formatted_player_name = "[u]%s[/u]" % formatted_player_name
			var mmr_prefix := ""
			if match_manager.singleplayer_ranked_mode and entry.has("mmr"):
				mmr_prefix = _format_ranked_mmr_badge(
					int(entry.get("mmr", 0))
				) + " "
			var line := mmr_prefix + formatted_player_name
			if show_ready:
				var ready_mark := (
					"✓" if bool(entry.get("ready", false)) else "○"
				)
				line = "%s %s%s" % [
					ready_mark,
					mmr_prefix,
					formatted_player_name
				]
			var peer_id: int = int(entry.get("peer_id", 0))
			if not bool(entry.get("cpu", false)) and peer_id > 0:
				var latency: Dictionary = _latency_snapshot.get(peer_id, {})
				var ping_ms: int = int(latency.get("ping", -1))
				if ping_ms >= 0:
					line += "  [color=#7ca6bc]%dms[/color]" % ping_ms
			if (
				ability_id > 0
				and ability_id < ABILITY_ICON_PATHS.size()
			):
				line += " [img=22x22]%s[/img]" % (
					ABILITY_ICON_PATHS[ability_id]
				)
			names.append("[center]%s[/center]" % line)
		else:
			names.append(
				"[center]%s[/center]" % _escape_roster_bbcode(
					_truncate_roster_text(str(entry), 28)
				)
			)
	return "\n".join(names)


func _format_ranked_mmr_badge(mmr: int) -> String:
	var safe_mmr: int = maxi(0, mmr)
	var division: int = FootballMatchManager.get_singleplayer_ranked_division_for_mmr(
		safe_mmr
	)
	var division_color: Color = FootballMatchManager.get_singleplayer_ranked_division_color(
		division
	)
	var outline_color: Color = division_color.darkened(0.62)
	var digits_text := str(safe_mmr)
	if not FootballMatchManager.singleplayer_ranked_division_is_animated(division):
		return (
			"[outline_size=2][outline_color=#%s][color=#%s][%s]"
			+ "[/color][/outline_color][/outline_size]"
		) % [
			outline_color.to_html(false),
			division_color.to_html(false),
			digits_text
		]
	var prefix_body := _build_ranked_glint_bbcode(digits_text, division)
	return (
		"[outline_size=2][outline_color=#%s][color=#%s][[/color]%s[color=#%s]][/color][/outline_color][/outline_size]"
	) % [
		outline_color.to_html(false),
		division_color.to_html(false),
		prefix_body,
		division_color.to_html(false)
	]


func _build_ranked_glint_bbcode(value: String, division: int) -> String:
	var base_color: Color = FootballMatchManager.get_singleplayer_ranked_division_color(
		division
	)
	var shine_color: Color = FootballMatchManager.get_singleplayer_ranked_division_shine_color(
		division
	)
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


func _get_ranked_ui_display_color(division: int) -> Color:
	var base_color: Color = FootballMatchManager.get_singleplayer_ranked_division_color(
		division
	)
	if not FootballMatchManager.singleplayer_ranked_division_is_animated(division):
		return base_color
	var shine_color: Color = FootballMatchManager.get_singleplayer_ranked_division_shine_color(
		division
	)
	var t: float = float(Time.get_ticks_msec()) / 1000.0
	var shine_amount: float = 0.5 + 0.5 * sin(t * TAU / 1.72)
	return base_color.lerp(shine_color, shine_amount)


func _format_ladder_champion_name(player_name: String) -> String:
	# Prestige reward for clearing the full 12-match no-loss PvE Ladder.
	# Uses the same traveling per-character highlight idea as the Champions
	# League division, but with an unmistakable warm-gold palette.
	var base_color := Color("e4ad2d")
	var shine_color := Color("fff4ad")
	var t: float = float(Time.get_ticks_msec()) / 1000.0
	var char_count: int = maxi(1, player_name.length())
	var travel: float = 1.42
	var center: float = fposmod(t / travel, 1.0) * 1.90 - 0.45
	var body := ""
	for index in range(char_count):
		var ratio: float = (
			float(index) / float(maxi(1, char_count - 1))
			if char_count > 1
			else 0.5
		)
		var distance: float = abs(ratio - center)
		var intensity: float = clampf(
			1.0 - distance / 0.46,
			0.0,
			1.0
		)
		intensity = intensity * intensity * (3.0 - 2.0 * intensity)
		var char_color: Color = base_color.lerp(shine_color, intensity)
		body += "[color=#%s]%s[/color]" % [
			char_color.to_html(false),
			player_name.substr(index, 1)
		]
	return (
		"[outline_size=2][outline_color=#5b3a08]"
		+ body
		+ "[/outline_color][/outline_size]"
	)


func _format_completed_pass_name(player_name: String) -> String:
	return (
		"[outline_size=3][outline_color=#704400]"
		+ "[color=#e8aa25][pulse color=#fff4ad freq=1.25 ease=-2.0]"
		+ player_name
		+ "[/pulse][/color][/outline_color][/outline_size]"
	)


func _truncate_roster_text(
	value: String,
	maximum_characters: int
) -> String:
	var safe_limit := maxi(2, maximum_characters)
	if value.length() <= safe_limit:
		return value
	return value.left(safe_limit - 1) + "…"


func _escape_roster_bbcode(value: String) -> String:
	return value.replace("[", "(").replace("]", ")")


func _close_lobby_cosmetic_menus() -> void:
	if _lobby_lootbox_menu != null:
		_lobby_lootbox_menu.hide()
	if _lobby_locker_menu != null:
		_lobby_locker_menu.hide()
	_refresh_lobby_cosmetic_shortcut_visibility()


func _on_session_started() -> void:
	_lobby_cosmetic_shortcuts_allowed = false
	_close_lobby_cosmetic_menus()
	if (
		network_manager.current_mode
		== NetworkManager.NetworkMode.FREEPLAY
	):
		hide()
		return
	_lobby_cosmetic_shortcuts_allowed = true
	UIMotion.show_control(self, 0.28)
	_refresh_lobby_cosmetic_shortcut_visibility()
	_local_ready = false
	main_menu_button.disabled = false
	status_label.text = "Choose a team, then ready up."
	start_button.disabled = not multiplayer.is_server()
	side_tabs.set_tab_hidden(
		1,
		not multiplayer.is_server()
		or match_manager.ladder_mode
		or match_manager.singleplayer_ranked_mode
	)
	_apply_draft_lobby_layout(match_manager.champions_league_mode)
	_on_ladder_state_changed(match_manager.get_ladder_snapshot())
	_on_singleplayer_ranked_state_changed(
		match_manager.get_singleplayer_ranked_snapshot()
	)
	_refresh_map_selector_access()
	if multiplayer.is_server():
		match_manager.refresh_cpu_players()
	_latency_snapshot = network_manager.get_latency_snapshot()
	_refresh_network_lobby_info()
	if controller_support.using_controller:
		if match_manager.singleplayer_ranked_mode:
			call_deferred("_ensure_valid_lobby_controller_focus")
		else:
			blue_button.grab_focus.call_deferred()


func _on_session_ended() -> void:
	_lobby_cosmetic_shortcuts_allowed = false
	_close_lobby_cosmetic_menus()
	_local_ready = false
	main_menu_button.disabled = false
	_apply_draft_lobby_layout(false)
	UIMotion.hide_control(self)


func _on_match_started() -> void:
	_lobby_cosmetic_shortcuts_allowed = false
	_close_lobby_cosmetic_menus()
	_refresh_map_selector_access()
	UIMotion.hide_control(self)


func _on_freeplay_started() -> void:
	_lobby_cosmetic_shortcuts_allowed = false
	_close_lobby_cosmetic_menus()
	hide()


func _on_match_ended(winning_team: StringName) -> void:
	_lobby_cosmetic_shortcuts_allowed = false
	_close_lobby_cosmetic_menus()
	# The final scoreboard owns the screen until the local player
	# presses Back to Lobby.
	hide()
	var winner := "Blue" if winning_team == &"blue" else "Red"
	status_label.text = "%s won. Choose a team when ready." % winner


func _on_match_cancelled() -> void:
	_lobby_cosmetic_shortcuts_allowed = true
	# A cancelled PvE Ranked match must restore the exact ranked pre-game
	# dashboard, not merely reveal the generic Teamselection control that was
	# left underneath the match. This became especially obvious in 5v5 because
	# the large-team match presentation fully owns the screen while playing.
	if match_manager.singleplayer_ranked_mode:
		_on_singleplayer_ranked_state_changed(
			match_manager.get_singleplayer_ranked_snapshot()
		)
	UIMotion.show_control(self, 0.28)
	_refresh_lobby_cosmetic_shortcut_visibility()
	_refresh_map_selector_access()
	status_label.text = (
		"Match cancelled. Ready up when you want to queue again."
		if match_manager.singleplayer_ranked_mode
		else "The host cancelled the match."
	)
	if controller_support.using_controller:
		call_deferred("_ensure_valid_lobby_controller_focus")


func _on_results_dismissed() -> void:
	_lobby_cosmetic_shortcuts_allowed = true
	UIMotion.show_control(self, 0.28)
	_refresh_lobby_cosmetic_shortcut_visibility()
	_refresh_map_selector_access()
	if controller_support.using_controller:
		call_deferred("_ensure_valid_lobby_controller_focus")


func _on_side_tab_changed(tab_index: int) -> void:
	if _ability_preview != null:
		_ability_preview.hide_preview()
	var tab := side_tabs.get_tab_control(tab_index)
	if tab != null:
		UIMotion.show_control(tab, 0.18, Vector2(0.985, 0.985))
	if not controller_support.using_controller:
		return
	if tab_index == 0 and not ability_buttons.is_empty():
		ability_buttons[0].grab_focus.call_deferred()
	elif tab_index == 1 and not side_tabs.is_tab_hidden(1):
		match_minutes.grab_focus.call_deferred()



func _input(event: InputEvent) -> void:
	# The ability grid lives on the right side of Team Selection while the
	# important lobby actions live on the left. Godot's automatic spatial focus
	# cannot reliably bridge those two separate containers, so controller users
	# could get trapped inside the ability columns. Handle only that container
	# boundary explicitly; normal D-pad/stick navigation inside each container
	# remains untouched.
	if (
		visible
		and controller_support.using_controller
		and not _lobby_cosmetic_menu_is_open()
		and (_map_overlay == null or not _map_overlay.visible)
	):
		# Force vertical navigation to stay inside the visual ability column.
		# Godot's spatial focus can otherwise choose a nearer button from the
		# neighboring column (for example Dead Zone Pass -> Enforcer) even though
		# the intended next row is Meta Vision directly below it.
		if _handle_ability_grid_vertical_focus(event):
			get_viewport().set_input_as_handled()
			return
		if _handle_ability_lobby_focus_bridge(event):
			get_viewport().set_input_as_handled()
			return

	if _map_overlay == null or not _map_overlay.visible:
		return
	if event.is_action_pressed(&"ui_cancel"):
		_close_map_selector()
		get_viewport().set_input_as_handled()


func _handle_ability_grid_vertical_focus(event: InputEvent) -> bool:
	var direction: int = 0
	if event.is_action_pressed(&"ui_up"):
		direction = -1
	elif event.is_action_pressed(&"ui_down"):
		direction = 1
	if direction == 0:
		return false

	var focus_owner := get_viewport().gui_get_focus_owner() as Button
	if focus_owner == null:
		return false

	var third_column: Array = FootballPlayer.get_ability_ids_for_role(
		FootballPlayer.ABILITY_ROLE_FLEXIBLE
	)
	third_column.append_array(
		FootballPlayer.get_ability_ids_for_role(
			FootballPlayer.ABILITY_ROLE_DEFENSE
		)
	)
	var columns: Array = [
		FootballPlayer.get_ability_ids_for_role(
			FootballPlayer.ABILITY_ROLE_ATTACK
		),
		FootballPlayer.get_ability_ids_for_role(
			FootballPlayer.ABILITY_ROLE_PLAYMAKER
		),
		third_column
	]

	for column_ids_variant: Variant in columns:
		var column_ids: Array = column_ids_variant as Array
		var current_row: int = -1
		for row_index in range(column_ids.size()):
			var ability_id := int(column_ids[row_index])
			if ability_id < 0 or ability_id >= ability_buttons.size():
				continue
			if ability_buttons[ability_id] == focus_owner:
				current_row = row_index
				break
		if current_row < 0:
			continue

		# Walk only this column and skip anything that is genuinely unavailable.
		# Wrapping matches the previous explicit focus-neighbor behavior.
		for step in range(1, column_ids.size() + 1):
			var target_row: int = posmod(
				current_row + direction * step,
				column_ids.size()
			)
			var target_id := int(column_ids[target_row])
			if target_id < 0 or target_id >= ability_buttons.size():
				continue
			var target := ability_buttons[target_id]
			if (
				target != null
				and target.is_visible_in_tree()
				and not target.disabled
				and target.focus_mode != Control.FOCUS_NONE
			):
				target.grab_focus()
				return true
		return true

	return false


func _handle_ability_lobby_focus_bridge(event: InputEvent) -> bool:
	var focus_owner := get_viewport().gui_get_focus_owner() as Control
	if focus_owner == null:
		return false

	var first_column_buttons := _get_first_ability_column_buttons()
	if event.is_action_pressed(&"ui_left") and focus_owner in first_column_buttons:
		var exit_target := _get_preferred_lobby_action_focus()
		if exit_target != null:
			exit_target.grab_focus()
			return true

	var action_chain := _get_visible_lobby_action_focus_chain()
	var action_index: int = action_chain.find(focus_owner)
	if action_index < 0:
		return false

	if event.is_action_pressed(&"ui_right"):
		var ability_target := _get_first_visible_ability_button(first_column_buttons)
		if ability_target != null:
			ability_target.grab_focus()
			return true

	# Make READY -> map/start -> leave/back deterministic on controller. Do not
	# wrap at the ends: Up from the first action and Down from the last action are
	# left to normal spatial navigation so team-selection controls remain reachable.
	var direction: int = 0
	if event.is_action_pressed(&"ui_up"):
		direction = -1
	elif event.is_action_pressed(&"ui_down"):
		direction = 1
	if direction == 0:
		return false
	var next_index: int = action_index + direction
	if next_index < 0 or next_index >= action_chain.size():
		return false
	action_chain[next_index].grab_focus()
	return true


func _get_first_ability_column_buttons() -> Array[Button]:
	var result: Array[Button] = []
	for ability_value in FootballPlayer.get_ability_ids_for_role(
		FootballPlayer.ABILITY_ROLE_ATTACK
	):
		var ability_id := int(ability_value)
		if ability_id < 0 or ability_id >= ability_buttons.size():
			continue
		var button := ability_buttons[ability_id]
		if button != null:
			result.append(button)
	return result


func _get_first_visible_ability_button(
	candidates: Array[Button]
) -> Button:
	for button: Button in candidates:
		if (
			button != null
			and button.is_visible_in_tree()
			and not button.disabled
			and button.focus_mode != Control.FOCUS_NONE
		):
			return button
	return null


func _get_visible_lobby_action_focus_chain() -> Array[Control]:
	var chain: Array[Control] = []
	for control: Control in [
		ready_button,
		start_button,
		_map_select_button,
		main_menu_button,
		spectator_button,
		leave_button,
		halftime_return_button,
	]:
		if control == null or not control.is_visible_in_tree():
			continue
		if control.focus_mode == Control.FOCUS_NONE:
			continue
		var button := control as BaseButton
		if button != null and button.disabled:
			continue
		chain.append(control)
	return chain


func _get_preferred_lobby_action_focus() -> Control:
	var chain := _get_visible_lobby_action_focus_chain()
	if chain.is_empty():
		return null
	# READY is intentionally first in the chain. In modes where READY is hidden
	# or disabled, this naturally falls through to START / SELECT MAP / BACK.
	return chain[0]


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not controller_support.using_controller:
		return

	# Modal cosmetic menus own B/Circle themselves. The lobby used to keep
	# receiving the same Back press underneath them and could steal it by
	# jumping focus to the Blue Team button, producing inconsistent behavior.
	if _lobby_cosmetic_menu_is_open():
		return

	if _handle_lobby_cosmetic_trigger_shortcut(event):
		get_viewport().set_input_as_handled()
		return

	var button_event := event as InputEventJoypadButton
	if (
		button_event != null
		and button_event.pressed
		and controller_support.is_controller_event_assigned(button_event)
	):
		# LB/RB (L1/R1) are reserved for real tabs/categories. They are no
		# longer generic focus-prev/focus-next inputs, so D-pad/left stick own
		# spatial menu navigation everywhere.
		if button_event.button_index == JOY_BUTTON_LEFT_SHOULDER:
			if _cycle_side_tab(-1):
				get_viewport().set_input_as_handled()
				return
		elif button_event.button_index == JOY_BUTTON_RIGHT_SHOULDER:
			if _cycle_side_tab(1):
				get_viewport().set_input_as_handled()
				return

	if event.is_action_pressed(&"ui_cancel"):
		if _halftime_mode:
			_on_halftime_return_pressed()
		elif (
			side_tabs != null
			and side_tabs.current_tab != 0
			and not side_tabs.is_tab_hidden(0)
		):
			# Standard Back semantics: leave Host Options for the primary
			# Abilities tab. At the root lobby B/Circle deliberately does not
			# teleport focus or trigger a destructive leave action.
			side_tabs.current_tab = 0
		get_viewport().set_input_as_handled()


func _cycle_side_tab(direction: int) -> bool:
	if side_tabs == null or direction == 0:
		return false
	var tab_count: int = side_tabs.get_tab_count()
	if tab_count <= 1:
		return false
	var current: int = side_tabs.current_tab
	for offset in range(1, tab_count + 1):
		var candidate: int = posmod(
			current + direction * offset,
			tab_count
		)
		if side_tabs.is_tab_hidden(candidate) or side_tabs.is_tab_disabled(candidate):
			continue
		side_tabs.current_tab = candidate
		return candidate != current
	return false


func _handle_lobby_cosmetic_trigger_shortcut(event: InputEvent) -> bool:
	var motion := event as InputEventJoypadMotion
	if (
		motion == null
		or not controller_support.is_controller_event_assigned(motion)
		or motion.axis not in [
			JOY_AXIS_TRIGGER_LEFT,
			JOY_AXIS_TRIGGER_RIGHT
		]
	):
		return false

	var pressed: bool = (
		motion.axis_value >= LOBBY_COSMETIC_TRIGGER_THRESHOLD
	)
	if motion.axis == JOY_AXIS_TRIGGER_LEFT:
		var just_pressed: bool = pressed and not _lobby_left_trigger_down
		_lobby_left_trigger_down = pressed
		if just_pressed and _can_open_lobby_cosmetic_shortcut():
			_open_lobby_lootbox()
			return true
		return false

	var just_pressed: bool = pressed and not _lobby_right_trigger_down
	_lobby_right_trigger_down = pressed
	if just_pressed and _can_open_lobby_cosmetic_shortcut():
		_open_lobby_locker()
		return true
	return false


func _can_open_lobby_cosmetic_shortcut() -> bool:
	return (
		_is_lobby_cosmetic_shortcut_context()
		and _lobby_shortcut_row != null
		and _lobby_shortcut_row.visible
	)


func _lobby_cosmetic_menu_is_open() -> bool:
	return (
		(_lobby_lootbox_menu != null and _lobby_lootbox_menu.visible)
		or (_lobby_locker_menu != null and _lobby_locker_menu.visible)
	)


func _reset_lobby_trigger_shortcuts() -> void:
	_lobby_left_trigger_down = false
	_lobby_right_trigger_down = false
