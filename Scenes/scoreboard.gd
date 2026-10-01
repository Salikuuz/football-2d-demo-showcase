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
const MATCH_TIMER_COUNTDOWN_SOUND_PATH := "res://Audio/match_timer_countdown_tick.wav"
const MATCH_PHASE_SOUND_PATH := "res://Audio/sfx_overtime.wav"
const WHISTLE_SOUND_PATH := "res://goalsound.mp3"
const COUNTDOWN_NORMAL_PITCH_SCALE: float = 1.0
const COUNTDOWN_HIGH_PITCH_SCALE: float = 1.45
const RESET_BALL_KEY := KEY_F4


@export var match_manager: FootballMatchManager
@export var network_manager: NetworkManager

@onready var blue_score_label: Label = (
	$PanelContainer/VBox/MainRow/BlueCard/BlueInfo/BlueScoreLabel
)
@onready var red_score_label: Label = (
	$PanelContainer/VBox/MainRow/RedCard/RedInfo/RedScoreLabel
)
@onready var aggregate_score_label: Label = (
	$PanelContainer/VBox/TournamentBar/AggregateScoreLabel
)
@onready var tournament_bar: PanelContainer = (
	$PanelContainer/VBox/TournamentBar
)
@onready var scoreboard_panel: PanelContainer = $PanelContainer
@onready var blue_score_card: PanelContainer = (
	$PanelContainer/VBox/MainRow/BlueCard
)
@onready var red_score_card: PanelContainer = (
	$PanelContainer/VBox/MainRow/RedCard
)
@onready var timer_label: Label = (
	$PanelContainer/VBox/MainRow/CenterCard/Center/TimerLabel
)
@onready var phase_label: Label = (
	$PanelContainer/VBox/MainRow/CenterCard/Center/PhaseLabel
)
@onready var overtime_label: Label = (
	$PanelContainer/VBox/OvertimeLabel
)
@onready var match_state_label: Label = (
	$PanelContainer/VBox/MatchStateLabel
)
@onready var announcement_label: Label = $AnnouncementLabel
@onready var countdown_label: Label = $CountdownLabel
@onready var final_countdown_label: Label = $FinalCountdownLabel
@onready var cancel_match_button: Button = $SessionButtons/CancelMatchButton
@onready var skip_halftime_button: Button = (
	$SessionButtons/SkipHalftimeButton
)

var _was_overtime: bool = false
var _match_active: bool = false
var _last_display_seconds: int = 0
var _last_timer_overtime: bool = false
var _tournament_enabled: bool = false
var _tournament_sudden_death: bool = false
var _tiebreak_phase: StringName = &""
var _extra_time_period: int = 0
var _penalty_red_score: int = 0
var _penalty_blue_score: int = 0
var _penalty_red_attempts: int = 0
var _penalty_blue_attempts: int = 0
var _penalty_turn: StringName = &""
var _penalty_attempt_active: bool = false
var _leg_red_score: int = 0
var _leg_blue_score: int = 0
var _displayed_red_score: int = 0
var _displayed_blue_score: int = 0
var _leader_shine_elapsed: float = 0.0
var _scoreboard_visibility_tween: Tween
var _scoreboard_should_be_visible: bool = false
var _team_intro_overlay: Control
var _team_intro_band: PanelContainer
var _team_intro_blue_column: VBoxContainer
var _team_intro_red_column: VBoxContainer
var _team_intro_blue_list: VBoxContainer
var _team_intro_red_list: VBoxContainer
var _team_intro_mode_label: Label
var _team_intro_title_label: Label
var _team_intro_context_label: Label
var _team_intro_vs_label: Label
var _team_intro_skip_hint: Label
var _team_intro_tween: Tween
var _team_intro_max_players_per_side: int = 1
var _team_intro_roster_scale: float = 1.0
var _final_countdown_audio: AudioStreamPlayer
var _match_phase_audio: AudioStreamPlayer
var _match_end_audio: AudioStreamPlayer
var _halftime_sound_active: bool = false
var _last_tiebreak_sound_phase: StringName = &""
var _last_countdown_sound_second: int = -1
var _last_kickoff_countdown_message: String = ""
var _team_lineup_layer: Control
var _blue_lineup_panel: PanelContainer
var _red_lineup_panel: PanelContainer
var _blue_lineup_list: HBoxContainer
var _red_lineup_list: HBoxContainer
var _team_lineup_signature: String = ""
var _team_lineup_refresh_elapsed: float = 0.0
var _ability_icon_cache: Array[Texture2D] = []
var _blue_score_fill: Polygon2D
var _blue_score_shadow: Polygon2D
var _blue_score_edge: Line2D
var _red_score_fill: Polygon2D
var _red_score_shadow: Polygon2D
var _red_score_edge: Line2D

const COMPACT_SCOREBOARD_SCALE := Vector2(0.45, 0.45)
const TEAM_LINEUP_REFRESH_SECONDS: float = 0.25
const TEAM_LINEUP_SCOREBOARD_HALF_WIDTH: float = 166.5
const TEAM_LINEUP_GAP: float = 8.0
const TEAM_LINEUP_PANEL_WIDTH: float = 156.0
const TEAM_LINEUP_TILE_SIZE: float = 34.0
const TEAM_LINEUP_ABILITY_ICON_SIZE: float = 28.0
const LEADER_SHINE_SPEED: float = 3.2


func _ready() -> void:
	if match_manager == null or network_manager == null:
		push_error("Scoreboard references are incomplete.")
		return

	_remove_legacy_reset_ball_button()

	match_manager.score_changed.connect(_on_score_changed)
	match_manager.tournament_score_changed.connect(
		_on_tournament_score_changed
	)
	match_manager.timer_changed.connect(_on_timer_changed)
	match_manager.announcement_changed.connect(
		_on_announcement_changed
	)
	match_manager.countdown_changed.connect(_on_countdown_changed)
	match_manager.team_introduction_changed.connect(
		_on_team_introduction_changed
	)
	match_manager.halftime_changed.connect(_on_halftime_changed)
	match_manager.tournament_tiebreak_changed.connect(
		_on_tournament_tiebreak_changed
	)
	match_manager.match_started.connect(_on_match_started)
	match_manager.match_ended.connect(_on_match_ended)
	match_manager.match_cancelled.connect(_on_match_cancelled)
	match_manager.results_dismissed.connect(
		_on_results_dismissed
	)
	network_manager.session_started.connect(_on_session_started)
	network_manager.session_ended.connect(_on_session_ended)

	cancel_match_button.pressed.connect(
		match_manager.request_cancel_match
	)
	skip_halftime_button.pressed.connect(
		match_manager.request_skip_halftime
	)
	cancel_match_button.hide()
	skip_halftime_button.hide()
	scoreboard_panel.hide()
	match_state_label.hide()
	final_countdown_label.hide()
	_build_team_introduction_overlay()
	_build_final_countdown_audio()
	_build_match_state_audio()
	_apply_scoreboard_styling()
	# Build these after the shared HUD theme pass so its generous general-purpose
	# panel margins do not override the compact two-row lineup margins.
	_build_team_lineups()
	MenuStyler.install_click_sounds(self)
	UIMotion.prepare_buttons(self)
	_on_tournament_score_changed(
		match_manager.tournament_leg_red_goals,
		match_manager.tournament_leg_blue_goals,
		match_manager.red_score,
		match_manager.blue_score,
		match_manager.tournament_leg,
		match_manager.tournament_mode,
		match_manager.tournament_sudden_death
	)

	_on_score_changed(
		match_manager.red_score,
		match_manager.blue_score
	)
	_on_timer_changed(
		int(ceil(match_manager.regulation_time_remaining)),
		match_manager.is_overtime
	)
	_on_announcement_changed("")
	_on_countdown_changed("")
	_on_halftime_changed(
		match_manager.tournament_halftime_active,
		match_manager.tournament_halftime_remaining
	)
	_on_tournament_tiebreak_changed(
		match_manager.tournament_tiebreak_phase,
		match_manager.tournament_extra_time_period,
		match_manager.penalty_red_score,
		match_manager.penalty_blue_score,
		match_manager.penalty_red_attempts,
		match_manager.penalty_blue_attempts,
		match_manager.penalty_turn,
		match_manager.penalty_attempt_active
	)


func _process(delta: float) -> void:
	_update_leading_team_shine(delta)
	if _team_lineup_layer != null and _team_lineup_layer.visible:
		_team_lineup_refresh_elapsed += delta
		if _team_lineup_refresh_elapsed >= TEAM_LINEUP_REFRESH_SECONDS:
			_team_lineup_refresh_elapsed = 0.0
			refresh_team_lineups()


func _build_team_lineups() -> void:
	_ability_icon_cache.clear()
	for icon_path: String in ABILITY_ICON_PATHS:
		var icon_texture: Texture2D
		if ResourceLoader.exists(icon_path):
			icon_texture = load(icon_path) as Texture2D
		_ability_icon_cache.append(icon_texture)

	_team_lineup_layer = Control.new()
	_team_lineup_layer.name = "TeamLineups"
	_team_lineup_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_team_lineup_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_team_lineup_layer)

	_blue_lineup_panel = _build_team_lineup_panel(
		"BlueTeamLineup",
		Color(0.28, 0.68, 1.0)
	)
	_red_lineup_panel = _build_team_lineup_panel(
		"RedTeamLineup",
		Color(1.0, 0.28, 0.34)
	)
	_blue_lineup_list = _blue_lineup_panel.get_node(
		"Margin/Players"
	) as HBoxContainer
	_red_lineup_list = _red_lineup_panel.get_node(
		"Margin/Players"
	) as HBoxContainer
	# Roster slots grow outward from the scoreboard. Blue is mirrored because
	# its nearest slot is the strip's right edge; Red starts from its left edge.
	_blue_lineup_list.alignment = BoxContainer.ALIGNMENT_END
	_red_lineup_list.alignment = BoxContainer.ALIGNMENT_BEGIN
	_team_lineup_layer.add_child(_blue_lineup_panel)
	_team_lineup_layer.add_child(_red_lineup_panel)
	# The shared premium-theme watcher styles nodes when they enter the tree.
	# Restore the intentionally tighter lineup boxes after that watcher runs.
	_apply_compact_lineup_panel_style(
		_blue_lineup_panel,
		Color(0.28, 0.68, 1.0)
	)
	_apply_compact_lineup_panel_style(
		_red_lineup_panel,
		Color(1.0, 0.28, 0.34)
	)
	get_viewport().size_changed.connect(_layout_team_lineups)
	_layout_team_lineups()
	_team_lineup_layer.hide()


func _build_team_lineup_panel(
	panel_name: String,
	team_color: Color
) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = panel_name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.custom_minimum_size = Vector2(TEAM_LINEUP_PANEL_WIDTH, 40.0)
	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 5)
	margin.add_theme_constant_override("margin_right", 5)
	margin.add_theme_constant_override("margin_top", 3)
	margin.add_theme_constant_override("margin_bottom", 3)
	panel.add_child(margin)
	var players := HBoxContainer.new()
	players.name = "Players"
	players.alignment = BoxContainer.ALIGNMENT_CENTER
	players.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	players.add_theme_constant_override("separation", 4)
	margin.add_child(players)
	return panel


func _apply_compact_lineup_panel_style(
	panel: PanelContainer,
	_team_color: Color
) -> void:
	# The individual ability tiles already carry the team-color identity. Keep
	# the roster itself visually open like Counter-Strike instead of wrapping
	# the whole strip in another dark box and colored outline.
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.set_border_width_all(0)
	style.set_corner_radius_all(0)
	style.content_margin_left = 0.0
	style.content_margin_top = 0.0
	style.content_margin_right = 0.0
	style.content_margin_bottom = 0.0
	style.shadow_size = 0
	panel.add_theme_stylebox_override("panel", style)
	var margin := panel.get_node_or_null("Margin") as MarginContainer
	if margin != null:
		margin.add_theme_constant_override("margin_left", 5)
		margin.add_theme_constant_override("margin_right", 5)
		margin.add_theme_constant_override("margin_top", 3)
		margin.add_theme_constant_override("margin_bottom", 3)
	var players := panel.get_node_or_null("Margin/Players") as HBoxContainer
	if players != null:
		players.add_theme_constant_override("separation", 4)


func _layout_team_lineups() -> void:
	if _blue_lineup_panel == null or _red_lineup_panel == null:
		return
	var viewport_width: float = get_viewport_rect().size.x
	var inner_edge: float = TEAM_LINEUP_SCOREBOARD_HALF_WIDTH + TEAM_LINEUP_GAP
	var visible_player_count := 0
	if _blue_lineup_list != null:
		visible_player_count = maxi(visible_player_count, _blue_lineup_list.get_child_count())
	if _red_lineup_list != null:
		visible_player_count = maxi(visible_player_count, _red_lineup_list.get_child_count())
	var roster_content_width := (
		10.0
		+ float(visible_player_count) * TEAM_LINEUP_TILE_SIZE
		+ float(maxi(0, visible_player_count - 1)) * 4.0
	)
	var requested_lineup_width := maxf(TEAM_LINEUP_PANEL_WIDTH, roster_content_width)
	var lineup_width: float = minf(
		requested_lineup_width,
		maxf(112.0, viewport_width * 0.5 - inner_edge - 10.0)
	)
	_blue_lineup_panel.offset_left = -inner_edge - lineup_width
	_blue_lineup_panel.offset_right = -inner_edge
	_blue_lineup_panel.offset_top = 3.0
	_blue_lineup_panel.offset_bottom = 43.0
	_red_lineup_panel.offset_left = inner_edge
	_red_lineup_panel.offset_right = inner_edge + lineup_width
	_red_lineup_panel.offset_top = 3.0
	_red_lineup_panel.offset_bottom = 43.0


func refresh_team_lineups() -> void:
	if _blue_lineup_list == null or _red_lineup_list == null:
		return
	var blue_players: Array[FootballPlayer] = []
	var red_players: Array[FootballPlayer] = []
	for player: FootballPlayer in match_manager.blue_players:
		if is_instance_valid(player):
			blue_players.append(player)
	for player: FootballPlayer in match_manager.red_players:
		if is_instance_valid(player):
			red_players.append(player)
	blue_players.sort_custom(_team_lineup_player_precedes)
	red_players.sort_custom(_team_lineup_player_precedes)
	var new_signature := _team_lineup_signature_for(blue_players, red_players)
	if new_signature == _team_lineup_signature:
		return
	_team_lineup_signature = new_signature
	_populate_team_lineup(_blue_lineup_list, blue_players, &"blue")
	_populate_team_lineup(_red_lineup_list, red_players, &"red")
	_layout_team_lineups.call_deferred()


func _team_lineup_player_precedes(
	left: FootballPlayer,
	right: FootballPlayer
) -> bool:
	if left.team_slot != right.team_slot:
		return left.team_slot < right.team_slot
	return left.owner_peer_id < right.owner_peer_id


func _team_lineup_signature_for(
	blue_players: Array[FootballPlayer],
	red_players: Array[FootballPlayer]
) -> String:
	var parts: PackedStringArray = []
	for player: FootballPlayer in blue_players + red_players:
		parts.append("%d:%s:%d:%s" % [
			player.owner_peer_id,
			str(player.team),
			player.selected_ability,
			player.display_name,
		])
	return "|".join(parts)


func _make_roster_icon_tile(
	player: FootballPlayer,
	team_color: Color
) -> PanelContainer:
	var tile := PanelContainer.new()
	tile.name = "Player_%d" % player.owner_peer_id
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.custom_minimum_size = Vector2.ONE * TEAM_LINEUP_TILE_SIZE
	_apply_roster_icon_tile_style(
		tile,
		team_color,
		player.owner_peer_id == multiplayer.get_unique_id()
	)

	var center := CenterContainer.new()
	center.name = "Center"
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(center)
	var icon := TextureRect.new()
	icon.name = "AbilityIcon"
	icon.custom_minimum_size = Vector2.ONE * TEAM_LINEUP_ABILITY_ICON_SIZE
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var ability_id: int = clampi(
		player.selected_ability,
		FootballPlayer.ABILITY_NONE,
		FootballPlayer.ABILITY_COUNT
	)
	if ability_id < _ability_icon_cache.size():
		icon.texture = _ability_icon_cache[ability_id]
	if player.is_satoru_gojo() and ability_id == FootballPlayer.ABILITY_POWER_STRIKE:
		icon.modulate = Color(0.77, 0.36, 1.0, 1.0)
	center.add_child(icon)
	return tile


func _apply_roster_icon_tile_style(
	tile: PanelContainer,
	team_color: Color,
	is_local_player: bool
) -> void:
	var tile_style := StyleBoxFlat.new()
	# Keep the team identity on the outline, but use the same dark/translucent
	# surface language as the compact scoreboard cells. The old team-tinted 12%
	# fill became almost transparent against bright pitches.
	tile_style.bg_color = Color(0.012, 0.017, 0.02, 0.94)
	tile_style.border_color = Color(team_color, 0.96)
	tile_style.set_border_width_all(2)
	tile_style.set_corner_radius_all(4)
	tile_style.content_margin_left = 2.0
	tile_style.content_margin_top = 2.0
	tile_style.content_margin_right = 2.0
	tile_style.content_margin_bottom = 2.0
	if is_local_player:
		tile_style.border_color = team_color.lightened(0.32)
		tile_style.set_border_width_all(3)
	tile.add_theme_stylebox_override("panel", tile_style)


func _populate_team_lineup(
	container: HBoxContainer,
	players: Array[FootballPlayer],
	team: StringName
) -> void:
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()
	var team_color := (
		Color(0.28, 0.68, 1.0)
		if team == &"blue"
		else Color(1.0, 0.28, 0.34)
	)
	var display_players: Array[FootballPlayer] = players.duplicate()
	if team == &"blue":
		display_players.reverse()
	for player: FootballPlayer in display_players:
		var tile := _make_roster_icon_tile(player, team_color)
		container.add_child(tile)
		_apply_roster_icon_tile_style(
			tile,
			team_color,
			player.owner_peer_id == multiplayer.get_unique_id()
		)


func _remove_legacy_reset_ball_button() -> void:
	var button := get_node_or_null("SessionButtons/ResetBallButton") as Button
	if button == null:
		return
	var parent: Node = button.get_parent()
	if parent != null:
		parent.remove_child(button)
	button.queue_free()


func _input(event: InputEvent) -> void:
	if (
		_team_intro_overlay != null
		and _team_intro_overlay.visible
		and match_manager != null
		and multiplayer.is_server()
		and _is_team_intro_skip_input(event)
	):
		match_manager.request_skip_team_introduction()
		get_viewport().set_input_as_handled()
		return
	if event is not InputEventKey:
		return
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if (
		key_event.alt_pressed
		or key_event.ctrl_pressed
		or key_event.shift_pressed
		or key_event.meta_pressed
	):
		return
	if (
		key_event.keycode != RESET_BALL_KEY
		and key_event.physical_keycode != RESET_BALL_KEY
	):
		return
	if match_manager == null or not multiplayer.is_server():
		return

	var did_reset: bool = false
	if match_manager.freeplay_active:
		did_reset = match_manager.reset_freeplay_ball()
	elif (
		match_manager.game_has_started
		and not match_manager.goal_replay_active
		and not match_manager.tournament_halftime_active
	):
		did_reset = match_manager.reset_ball_by_host()

	if did_reset:
		get_viewport().set_input_as_handled()


func _apply_scoreboard_styling() -> void:
	MenuStyler._apply_frosted_material(
		scoreboard_panel,
		Color(0.008, 0.026, 0.016, 1.0)
	)
	MenuStyler.style_button(
		cancel_match_button,
		Color(1.0, 0.28, 0.34),
		42.0
	)
	MenuStyler.style_button(
		skip_halftime_button,
		Color(1.0, 0.72, 0.18),
		42.0
	)
	MenuStyler.style_heading(
		overtime_label,
		Color(1.0, 0.7, 0.18)
	)
	MenuStyler.style_heading(
		match_state_label,
		Color(1.0, 0.82, 0.22)
	)
	MenuStyler.apply_premium_design(self, &"hud")
	_apply_compact_match_hud_style()
	# Keep the destructive control compact and unmistakable after the shared
	# theme pass, which otherwise restores generic white button text.
	cancel_match_button.add_theme_font_size_override("font_size", 28)
	cancel_match_button.add_theme_color_override(
		"font_color", Color(1.0, 0.28, 0.34)
	)
	cancel_match_button.add_theme_color_override(
		"font_hover_color", Color(1.0, 0.5, 0.54)
	)
	cancel_match_button.add_theme_color_override(
		"font_pressed_color", Color(1.0, 0.18, 0.24)
	)


func _apply_compact_match_hud_style() -> void:
	var blue_team_label := get_node_or_null(
		"PanelContainer/VBox/MainRow/BlueCard/BlueInfo/BlueTeamLabel"
	) as Label
	var red_team_label := get_node_or_null(
		"PanelContainer/VBox/MainRow/RedCard/RedInfo/RedTeamLabel"
	) as Label
	var main_row := get_node_or_null(
		"PanelContainer/VBox/MainRow"
	) as HBoxContainer
	var center_card := get_node_or_null(
		"PanelContainer/VBox/MainRow/CenterCard"
	) as PanelContainer
	var center_stack := get_node_or_null(
		"PanelContainer/VBox/MainRow/CenterCard/Center"
	) as VBoxContainer
	if blue_team_label != null:
		blue_team_label.hide()
	if red_team_label != null:
		red_team_label.hide()
	if main_row != null:
		main_row.custom_minimum_size.y = 84.0
		# The reference HUD is one continuous strip: colored score tabs overlap
		# the central clock by a few source pixels instead of floating apart.
		main_row.add_theme_constant_override("separation", -10)
		main_row.alignment = BoxContainer.ALIGNMENT_CENTER

	# Match the roster's small top inset so the two HUD pieces share one
	# horizontal baseline rather than the scoreboard hugging the screen edge.
	scoreboard_panel.offset_left = -370.0
	scoreboard_panel.offset_right = 370.0
	scoreboard_panel.offset_top = 3.0
	scoreboard_panel.offset_bottom = 96.0
	scoreboard_panel.pivot_offset = Vector2(370.0, 0.0)

	# A slim black carrier behind the score tabs recreates the compact broadcast
	# scoreboard silhouette from the supplied reference.
	var outer := StyleBoxFlat.new()
	outer.bg_color = Color(0.004, 0.006, 0.008, 0.94)
	outer.border_color = Color(0.12, 0.14, 0.16, 0.36)
	outer.border_width_top = 1
	outer.border_width_bottom = 1
	outer.border_width_left = 0
	outer.border_width_right = 0
	outer.set_corner_radius_all(0)
	outer.content_margin_left = 0.0
	outer.content_margin_top = 0.0
	outer.content_margin_right = 0.0
	outer.content_margin_bottom = 0.0
	outer.shadow_color = Color(0.0, 0.0, 0.0, 0.48)
	outer.shadow_size = 5
	scoreboard_panel.add_theme_stylebox_override("panel", outer)

	blue_score_card.custom_minimum_size = Vector2(220.0, 84.0)
	red_score_card.custom_minimum_size = Vector2(220.0, 84.0)
	blue_score_card.z_index = 1
	red_score_card.z_index = 1
	if center_card != null:
		center_card.custom_minimum_size = Vector2(300.0, 84.0)
		center_card.z_index = 3

	# The actual colored surfaces are polygons so their lower edges taper like
	# the scoreboard in the reference instead of remaining plain rectangles.
	var transparent_card := StyleBoxFlat.new()
	transparent_card.bg_color = Color.TRANSPARENT
	transparent_card.border_color = Color.TRANSPARENT
	transparent_card.set_border_width_all(0)
	transparent_card.set_corner_radius_all(0)
	transparent_card.content_margin_left = 0.0
	transparent_card.content_margin_top = 0.0
	transparent_card.content_margin_right = 0.0
	transparent_card.content_margin_bottom = 0.0
	blue_score_card.add_theme_stylebox_override("panel", transparent_card)
	red_score_card.add_theme_stylebox_override("panel", transparent_card.duplicate())

	if center_card != null:
		var clock_style := StyleBoxFlat.new()
		clock_style.bg_color = Color(0.008, 0.011, 0.013, 0.985)
		clock_style.border_color = Color(0.34, 0.40, 0.43, 0.30)
		clock_style.border_width_top = 1
		clock_style.border_width_bottom = 1
		clock_style.border_width_left = 0
		clock_style.border_width_right = 0
		clock_style.set_corner_radius_all(0)
		clock_style.shadow_color = Color(0.0, 0.0, 0.0, 0.36)
		clock_style.shadow_size = 3
		center_card.add_theme_stylebox_override("panel", clock_style)

	_ensure_score_tab_geometry()

	blue_score_label.add_theme_font_size_override("font_size", 58)
	red_score_label.add_theme_font_size_override("font_size", 58)
	blue_score_label.add_theme_color_override("font_color", Color(0.98, 0.99, 1.0))
	red_score_label.add_theme_color_override("font_color", Color(1.0, 0.98, 0.98))
	blue_score_label.add_theme_constant_override("outline_size", 5)
	red_score_label.add_theme_constant_override("outline_size", 5)
	timer_label.add_theme_font_size_override("font_size", 31)
	timer_label.add_theme_color_override("font_color", Color(0.96, 0.98, 0.96))
	phase_label.add_theme_font_size_override("font_size", 11)
	phase_label.add_theme_color_override("font_color", Color(0.72, 0.78, 0.78))
	phase_label.custom_minimum_size.y = 12.0
	if center_stack != null:
		center_stack.add_theme_constant_override("separation", -3)
		# Aggregate belongs inside the central clock module; this keeps tournament
		# info readable without growing a separate full-width strip underneath.
		if tournament_bar.get_parent() != center_stack:
			tournament_bar.reparent(center_stack, false)
		center_stack.move_child(tournament_bar, center_stack.get_child_count() - 1)

	var aggregate_style := StyleBoxFlat.new()
	aggregate_style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	aggregate_style.border_color = Color(0.0, 0.0, 0.0, 0.0)
	aggregate_style.set_border_width_all(0)
	aggregate_style.set_corner_radius_all(0)
	aggregate_style.content_margin_left = 3.0
	aggregate_style.content_margin_top = 0.0
	aggregate_style.content_margin_right = 3.0
	aggregate_style.content_margin_bottom = 0.0
	tournament_bar.add_theme_stylebox_override("panel", aggregate_style)
	tournament_bar.custom_minimum_size.y = 11.0
	aggregate_score_label.add_theme_font_size_override("font_size", 10)
	aggregate_score_label.add_theme_color_override(
		"font_color", Color(0.94, 0.77, 0.30)
	)


func _ensure_score_tab_geometry() -> void:
	_blue_score_shadow = _score_tab_polygon(
		blue_score_card,
		"ScoreTabShadow",
		Color(0.0, 0.0, 0.0, 0.58),
		-4
	)
	_blue_score_fill = _score_tab_polygon(
		blue_score_card,
		"ScoreTabFill",
		Color(0.025, 0.29, 0.61, 0.99),
		-3
	)
	_blue_score_edge = _score_tab_edge(
		blue_score_card,
		"ScoreTabEdge",
		Color(0.16, 0.55, 0.92, 0.86),
		-2
	)
	_red_score_shadow = _score_tab_polygon(
		red_score_card,
		"ScoreTabShadow",
		Color(0.0, 0.0, 0.0, 0.58),
		-4
	)
	_red_score_fill = _score_tab_polygon(
		red_score_card,
		"ScoreTabFill",
		Color(0.52, 0.025, 0.055, 0.99),
		-3
	)
	_red_score_edge = _score_tab_edge(
		red_score_card,
		"ScoreTabEdge",
		Color(0.82, 0.12, 0.17, 0.84),
		-2
	)
	# Keep the geometry before the existing label container in tree draw order.
	# This makes the tab visible above the black carrier while scores stay on top.
	blue_score_card.move_child(_blue_score_shadow, 0)
	blue_score_card.move_child(_blue_score_fill, 1)
	blue_score_card.move_child(_blue_score_edge, 2)
	red_score_card.move_child(_red_score_shadow, 0)
	red_score_card.move_child(_red_score_fill, 1)
	red_score_card.move_child(_red_score_edge, 2)
	if not blue_score_card.resized.is_connected(_refresh_score_tab_geometry):
		blue_score_card.resized.connect(_refresh_score_tab_geometry)
	if not red_score_card.resized.is_connected(_refresh_score_tab_geometry):
		red_score_card.resized.connect(_refresh_score_tab_geometry)
	_refresh_score_tab_geometry.call_deferred()


func _score_tab_polygon(
	card: PanelContainer,
	node_name: String,
	color: Color,
	z: int
) -> Polygon2D:
	var polygon := card.get_node_or_null(node_name) as Polygon2D
	if polygon == null:
		polygon = Polygon2D.new()
		polygon.name = node_name
		card.add_child(polygon)
	polygon.show_behind_parent = false
	polygon.color = color
	polygon.z_index = 0
	return polygon


func _score_tab_edge(
	card: PanelContainer,
	node_name: String,
	color: Color,
	z: int
) -> Line2D:
	var edge := card.get_node_or_null(node_name) as Line2D
	if edge == null:
		edge = Line2D.new()
		edge.name = node_name
		edge.closed = true
		edge.antialiased = true
		card.add_child(edge)
	edge.show_behind_parent = false
	edge.default_color = color
	edge.width = 2.0
	edge.z_index = 0
	return edge


func _refresh_score_tab_geometry() -> void:
	_update_score_tab_geometry(
		blue_score_card,
		_blue_score_fill,
		_blue_score_shadow,
		_blue_score_edge,
		true
	)
	_update_score_tab_geometry(
		red_score_card,
		_red_score_fill,
		_red_score_shadow,
		_red_score_edge,
		false
	)


func _update_score_tab_geometry(
	card: PanelContainer,
	fill: Polygon2D,
	shadow: Polygon2D,
	edge: Line2D,
	left_side: bool
) -> void:
	if card == null or fill == null or shadow == null or edge == null:
		return
	var width := maxf(1.0, card.size.x)
	var height := maxf(1.0, card.size.y)
	var points := PackedVector2Array()
	if left_side:
		points = PackedVector2Array([
			Vector2(16.0, 0.0),
			Vector2(width, 0.0),
			Vector2(width - 12.0, height),
			Vector2(28.0, height),
		])
	else:
		points = PackedVector2Array([
			Vector2(0.0, 0.0),
			Vector2(width - 16.0, 0.0),
			Vector2(width - 28.0, height),
			Vector2(12.0, height),
		])
	fill.polygon = points
	shadow.polygon = PackedVector2Array([
		points[0] + Vector2(0.0, 7.0),
		points[1] + Vector2(0.0, 7.0),
		points[2] + Vector2(0.0, 7.0),
		points[3] + Vector2(0.0, 7.0),
	])
	edge.points = PackedVector2Array([
		points[0], points[1], points[2], points[3]
	])


func _on_score_changed(
	red_score: int,
	blue_score: int
) -> void:
	var displayed_red := _leg_red_score if _tournament_enabled else red_score
	var displayed_blue := _leg_blue_score if _tournament_enabled else blue_score
	_displayed_red_score = displayed_red
	_displayed_blue_score = displayed_blue
	blue_score_label.text = str(displayed_blue)
	red_score_label.text = str(displayed_red)
	_reset_leading_team_shine()
	UIMotion.pulse(blue_score_label, Vector2(1.1, 1.1), 0.2)
	UIMotion.pulse(red_score_label, Vector2(1.1, 1.1), 0.2)


func _on_tournament_score_changed(
	leg_red_score: int,
	leg_blue_score: int,
	aggregate_red_score: int,
	aggregate_blue_score: int,
	leg: int,
	enabled: bool,
	sudden_death: bool
) -> void:
	_leg_red_score = leg_red_score
	_leg_blue_score = leg_blue_score
	_tournament_enabled = enabled
	_tournament_sudden_death = sudden_death
	_displayed_red_score = leg_red_score if enabled else aggregate_red_score
	_displayed_blue_score = leg_blue_score if enabled else aggregate_blue_score
	_reset_leading_team_shine()
	aggregate_score_label.text = (
		"AGG  %d  —  %d" % [aggregate_blue_score, aggregate_red_score]
	)
	tournament_bar.visible = enabled
	if _tiebreak_phase == &"":
		phase_label.text = "LEG %d" % leg if enabled else ""
		phase_label.visible = enabled


func _on_timer_changed(
	display_seconds: int,
	overtime: bool
) -> void:
	_last_display_seconds = display_seconds
	_last_timer_overtime = overtime

	var minutes := display_seconds / 60
	var seconds := display_seconds % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]
	if _tiebreak_phase == &"":
		overtime_label.text = "OVERTIME - GOLDEN GOAL"
		overtime_label.self_modulate = Color.WHITE
		overtime_label.visible = overtime
	if overtime and not _was_overtime:
		UIMotion.pulse(
			overtime_label,
			Vector2(1.08, 1.08),
			0.24
		)
		_play_match_phase_sound(1.0, -9.0)
	_was_overtime = overtime
	_refresh_final_countdown()


func _on_tournament_tiebreak_changed(
	phase: StringName,
	extra_time_period: int,
	penalty_red_score: int,
	penalty_blue_score: int,
	penalty_red_attempts: int,
	penalty_blue_attempts: int,
	penalty_turn: StringName,
	penalty_attempt_active: bool
) -> void:
	if phase != _last_tiebreak_sound_phase and not phase.is_empty():
		match phase:
			FootballMatchManager.TIEBREAK_EXTRA_TIME:
				_play_match_phase_sound(1.0, -9.0)
			FootballMatchManager.TIEBREAK_EXTRA_BREAK:
				_play_whistle_sound(-23.0)
			FootballMatchManager.TIEBREAK_PENALTIES:
				_play_match_phase_sound(1.08, -8.5)
	_last_tiebreak_sound_phase = phase
	_tiebreak_phase = phase
	_extra_time_period = extra_time_period
	_penalty_red_score = penalty_red_score
	_penalty_blue_score = penalty_blue_score
	_penalty_red_attempts = penalty_red_attempts
	_penalty_blue_attempts = penalty_blue_attempts
	_penalty_turn = penalty_turn
	_penalty_attempt_active = penalty_attempt_active
	match phase:
		FootballMatchManager.TIEBREAK_EXTRA_TIME:
			phase_label.text = "ET %d/2" % extra_time_period
			phase_label.show()
			overtime_label.text = "TWO-PERIOD EXTRA TIME"
			overtime_label.self_modulate = Color.WHITE
			overtime_label.show()
			tournament_bar.show()
		FootballMatchManager.TIEBREAK_EXTRA_BREAK:
			phase_label.text = "ET BREAK"
			phase_label.show()
			overtime_label.text = (
				"EXTRA TIME STARTING SOON"
				if extra_time_period <= 0
				else "PERIOD 2 STARTING SOON"
			)
			overtime_label.self_modulate = Color.WHITE
			overtime_label.show()
			tournament_bar.show()
		FootballMatchManager.TIEBREAK_PENALTIES:
			phase_label.text = "PENS"
			phase_label.show()
			_displayed_blue_score = penalty_blue_score
			_displayed_red_score = penalty_red_score
			blue_score_label.text = str(penalty_blue_score)
			red_score_label.text = str(penalty_red_score)
			_reset_leading_team_shine()
			aggregate_score_label.text = (
				"PENS %d (%d)-(%d) %d"
				% [
					penalty_blue_score,
					penalty_blue_attempts,
					penalty_red_attempts,
					penalty_red_score
				]
			)
			var turn_name := "BLUE" if penalty_turn == &"blue" else "RED"
			overtime_label.text = (
				"%s TAKING" % turn_name
				if penalty_attempt_active
				else "%s UP NEXT" % turn_name
			)
			overtime_label.self_modulate = Color.WHITE
			overtime_label.show()
			tournament_bar.show()
		_:
			overtime_label.visible = _last_timer_overtime
			_on_tournament_score_changed(
				match_manager.tournament_leg_red_goals,
				match_manager.tournament_leg_blue_goals,
				match_manager.red_score,
				match_manager.blue_score,
				match_manager.tournament_leg,
				match_manager.tournament_mode,
				match_manager.tournament_sudden_death
			)
			_on_score_changed(match_manager.red_score, match_manager.blue_score)


func _reset_leading_team_shine() -> void:
	_leader_shine_elapsed = 0.0
	if blue_score_card != null:
		blue_score_card.self_modulate = Color.WHITE
	if red_score_card != null:
		red_score_card.self_modulate = Color.WHITE


func _update_leading_team_shine(delta: float) -> void:
	if blue_score_card == null or red_score_card == null:
		return
	if _displayed_blue_score == _displayed_red_score:
		if blue_score_card.self_modulate != Color.WHITE:
			blue_score_card.self_modulate = Color.WHITE
		if red_score_card.self_modulate != Color.WHITE:
			red_score_card.self_modulate = Color.WHITE
		return
	_leader_shine_elapsed += delta * LEADER_SHINE_SPEED
	var pulse := 0.5 + 0.5 * sin(_leader_shine_elapsed)
	if _displayed_blue_score > _displayed_red_score:
		blue_score_card.self_modulate = Color(
			0.86 + pulse * 0.14,
			0.94 + pulse * 0.06,
			1.0,
			1.0
		)
		red_score_card.self_modulate = Color.WHITE
	else:
		red_score_card.self_modulate = Color(
			1.0,
			0.84 + pulse * 0.16,
			0.86 + pulse * 0.14,
			1.0
		)
		blue_score_card.self_modulate = Color.WHITE


func _refresh_final_countdown() -> void:
	var should_show := (
		_match_active
		and not _last_timer_overtime
		and _last_display_seconds > 0
		and _last_display_seconds <= 10
	)
	if not should_show:
		final_countdown_label.hide()
		_last_countdown_sound_second = -1
		return

	var new_text := str(_last_display_seconds)
	var changed := final_countdown_label.text != new_text
	var new_second := _last_countdown_sound_second != _last_display_seconds
	final_countdown_label.text = new_text
	final_countdown_label.show()
	if new_second:
		_play_final_countdown_tick(_last_display_seconds)
	if changed:
		UIMotion.pulse(
			final_countdown_label,
			Vector2(1.16, 1.16),
			0.18
		)


func _build_final_countdown_audio() -> void:
	_final_countdown_audio = AudioStreamPlayer.new()
	_final_countdown_audio.name = "FinalCountdownTickAudio"
	_final_countdown_audio.bus = &"Master"
	_final_countdown_audio.volume_db = -7.5
	var stream: AudioStream = load(MATCH_TIMER_COUNTDOWN_SOUND_PATH) as AudioStream
	if stream == null:
		push_warning(
			"Final countdown sound could not be loaded: %s"
			% MATCH_TIMER_COUNTDOWN_SOUND_PATH
		)
	else:
		_final_countdown_audio.stream = stream
	add_child(_final_countdown_audio)


func _build_match_state_audio() -> void:
	_match_phase_audio = _create_match_state_audio_player(
		"MatchPhaseAudio",
		MATCH_PHASE_SOUND_PATH,
		-10.0
	)
	_match_end_audio = _create_match_state_audio_player(
		"MatchWhistleAudio",
		WHISTLE_SOUND_PATH,
		-16.5
	)


func _create_match_state_audio_player(
	player_name: String,
	stream_path: String,
	volume_db: float
) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.bus = &"Master"
	player.volume_db = volume_db
	if ResourceLoader.exists(stream_path, "AudioStream"):
		player.stream = load(stream_path) as AudioStream
	else:
		push_warning("Match-state sound could not be loaded: %s" % stream_path)
	add_child(player)
	return player


func _play_match_phase_sound(pitch: float = 1.0, volume_db: float = -10.0) -> void:
	if _match_phase_audio == null or _match_phase_audio.stream == null:
		return
	_match_phase_audio.stop()
	_match_phase_audio.pitch_scale = pitch
	_match_phase_audio.volume_db = volume_db
	_match_phase_audio.play()


func _play_whistle_sound(volume_db: float = -16.5) -> void:
	if _match_end_audio == null or _match_end_audio.stream == null:
		return
	_match_end_audio.stop()
	_match_end_audio.pitch_scale = 1.0
	_match_end_audio.volume_db = volume_db
	_match_end_audio.play()


func _play_match_end_sound() -> void:
	_play_whistle_sound(-21.0)


func _play_final_countdown_tick(seconds_left: int) -> void:
	if (
		_final_countdown_audio == null
		or _final_countdown_audio.stream == null
		or seconds_left <= 0
		or seconds_left > 10
		or seconds_left == _last_countdown_sound_second
	):
		return
	_last_countdown_sound_second = seconds_left
	# Use the same clear high cue as kickoff GO for every one of the last ten
	# seconds. This makes the match-ending countdown audible over play.
	_final_countdown_audio.pitch_scale = COUNTDOWN_HIGH_PITCH_SCALE
	_final_countdown_audio.play()


func _on_announcement_changed(message: String) -> void:
	announcement_label.text = message
	if message.is_empty():
		UIMotion.hide_control(announcement_label)
	else:
		UIMotion.show_control(
			announcement_label,
			0.2,
			Vector2(0.88, 0.88)
		)


func _on_countdown_changed(message: String) -> void:
	countdown_label.text = message
	if message.is_empty():
		_last_kickoff_countdown_message = ""
		UIMotion.hide_control(countdown_label, 0.12)
	else:
		_play_kickoff_countdown_tick(message)
		UIMotion.show_control(
			countdown_label,
			0.16,
			Vector2(0.7, 0.7)
		)
		UIMotion.pulse(
			countdown_label,
			Vector2(1.18, 1.18),
			0.22
		)


func _play_kickoff_countdown_tick(message: String) -> void:
	# Kickoff/reset countdown emits 3, 2, 1, then GO. Re-use one sound stream,
	# reserving the clearly higher pitch for the moment play is released.
	if message == _last_kickoff_countdown_message:
		return
	if message == "GO":
		_last_kickoff_countdown_message = message
		if _final_countdown_audio == null or _final_countdown_audio.stream == null:
			return
		_final_countdown_audio.stop()
		_final_countdown_audio.pitch_scale = COUNTDOWN_HIGH_PITCH_SCALE
		_final_countdown_audio.play()
		return
	if not message.is_valid_int():
		return
	var number: int = int(message)
	if number <= 0 or number > maxi(1, match_manager.countdown_seconds):
		return
	_last_kickoff_countdown_message = message
	if _final_countdown_audio == null or _final_countdown_audio.stream == null:
		return
	_final_countdown_audio.pitch_scale = COUNTDOWN_NORMAL_PITCH_SCALE
	_final_countdown_audio.play()


func _build_team_introduction_overlay() -> void:
	_team_intro_overlay = Control.new()
	_team_intro_overlay.name = "TeamIntroduction"
	_team_intro_overlay.z_index = 95
	_team_intro_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_team_intro_overlay.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	add_child(_team_intro_overlay)

	var dimmer := ColorRect.new()
	dimmer.color = Color(0.003, 0.008, 0.012, 0.82)
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_team_intro_overlay.add_child(dimmer)

	_team_intro_band = PanelContainer.new()
	_team_intro_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_team_intro_band.anchor_left = 0.01
	_team_intro_band.anchor_top = 0.025
	_team_intro_band.anchor_right = 0.99
	_team_intro_band.anchor_bottom = 0.975
	_team_intro_overlay.add_child(_team_intro_band)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.012, 0.018, 0.028, 0.96)
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = Color(0.72, 0.76, 0.88, 0.42)
	panel_style.corner_radius_top_left = 18
	panel_style.corner_radius_top_right = 18
	panel_style.corner_radius_bottom_left = 18
	panel_style.corner_radius_bottom_right = 18
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.75)
	panel_style.shadow_size = 26
	_team_intro_band.add_theme_stylebox_override("panel", panel_style)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	_team_intro_band.add_child(margin)

	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)

	_team_intro_mode_label = Label.new()
	_team_intro_mode_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_team_intro_mode_label.add_theme_font_size_override("font_size", 24)
	_team_intro_mode_label.add_theme_color_override(
		"font_color", Color(0.82, 0.69, 1.0)
	)
	_team_intro_mode_label.add_theme_constant_override("outline_size", 6)
	_team_intro_mode_label.add_theme_color_override(
		"font_outline_color", Color(0.0, 0.0, 0.0, 0.9)
	)
	_team_intro_mode_label.text = "MATCHUP"
	_team_intro_mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(_team_intro_mode_label)

	var title := Label.new()
	_team_intro_title_label = title
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.97, 0.98, 1.0))
	title.add_theme_color_override(
		"font_outline_color", Color(0.0, 0.0, 0.0, 0.95)
	)
	title.add_theme_constant_override("outline_size", 8)
	title.text = "MATCHUP OVERVIEW"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)

	_team_intro_context_label = Label.new()
	_team_intro_context_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_team_intro_context_label.add_theme_font_size_override("font_size", 18)
	_team_intro_context_label.add_theme_color_override(
		"font_color", Color(0.68, 0.75, 0.88)
	)
	_team_intro_context_label.text = "1V1"
	_team_intro_context_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(_team_intro_context_label)

	var teams_row := HBoxContainer.new()
	teams_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	teams_row.alignment = BoxContainer.ALIGNMENT_CENTER
	teams_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	teams_row.add_theme_constant_override("separation", 8)
	content.add_child(teams_row)

	_team_intro_blue_list = _build_team_intro_column(
		teams_row,
		"BLUE TEAM",
		Color(0.35, 0.72, 1.0)
	)

	_team_intro_blue_column = _team_intro_blue_list.get_parent() as VBoxContainer

	_team_intro_vs_label = Label.new()
	_team_intro_vs_label.custom_minimum_size = Vector2(86.0, 0.0)
	_team_intro_vs_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_team_intro_vs_label.add_theme_font_size_override("font_size", 66)
	_team_intro_vs_label.add_theme_color_override("font_color", Color.WHITE)
	_team_intro_vs_label.add_theme_color_override(
		"font_outline_color",
		Color(0.0, 0.0, 0.0, 0.95)
	)
	_team_intro_vs_label.add_theme_constant_override("outline_size", 11)
	_team_intro_vs_label.text = "VS"
	_team_intro_vs_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_team_intro_vs_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_team_intro_vs_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	teams_row.add_child(_team_intro_vs_label)

	_team_intro_red_list = _build_team_intro_column(
		teams_row,
		"RED TEAM",
		Color(1.0, 0.35, 0.4)
	)
	_team_intro_red_column = _team_intro_red_list.get_parent() as VBoxContainer

	_team_intro_skip_hint = Label.new()
	_team_intro_skip_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_team_intro_skip_hint.add_theme_font_size_override("font_size", 14)
	_team_intro_skip_hint.add_theme_color_override(
		"font_color", Color(0.62, 0.66, 0.75)
	)
	_team_intro_skip_hint.text = "HOST  •  CLICK OR PRESS A BUTTON TO CONTINUE"
	_team_intro_skip_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(_team_intro_skip_hint)
	get_viewport().size_changed.connect(_layout_team_introduction)
	_layout_team_introduction()
	_team_intro_overlay.hide()


func _build_team_intro_column(
	parent: Control,
	title_text: String,
	team_color: Color
) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(360.0, 0.0)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 10)
	parent.add_child(column)

	var title := Label.new()
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", team_color)
	title.add_theme_color_override(
		"font_outline_color",
		Color(0.0, 0.0, 0.0, 0.95)
	)
	title.add_theme_constant_override("outline_size", 7)
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)

	var player_list := VBoxContainer.new()
	player_list.custom_minimum_size = Vector2(0.0, 300.0)
	player_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	player_list.alignment = BoxContainer.ALIGNMENT_CENTER
	player_list.add_theme_constant_override("separation", 8)
	column.add_child(player_list)
	return player_list


func _layout_team_introduction() -> void:
	if (
		_team_intro_band == null
		or _team_intro_blue_column == null
		or _team_intro_red_column == null
	):
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	var roster_scale := clampf(_team_intro_roster_scale, 0.65, 1.0)
	var max_players := maxi(1, _team_intro_max_players_per_side)
	var goal_banner_size := FootballGoalReplayBanner.presentation_size(
		viewport_size
	)
	# The original presentation size works well through 3v3. Four-, five- and
	# six-player teams need denser cards so the entire matchup stays visible
	# instead of pushing the last player below the viewport.
	var usable_width := viewport_size.x * 0.98 - 24.0
	var maximum_column_width := maxf(
		260.0,
		(usable_width - _team_intro_vs_label.custom_minimum_size.x - 16.0) * 0.5
	)
	var width_scale := (
		0.86 if max_players >= 5
		else 0.93 if max_players == 4
		else 1.0
	)
	var column_width := minf(
		goal_banner_size.x * width_scale,
		maximum_column_width
	)
	_team_intro_blue_column.custom_minimum_size.x = column_width
	_team_intro_red_column.custom_minimum_size.x = column_width

	var list_separation := maxi(3, roundi(8.0 * roster_scale))
	var vertical_list_budget := viewport_size.y * (0.61 if max_players >= 4 else 0.67)
	var fit_card_height := (
		vertical_list_budget - float(max_players - 1) * float(list_separation)
	) / float(max_players)
	var card_height := clampf(
		minf(goal_banner_size.y * roster_scale, fit_card_height),
		58.0,
		goal_banner_size.y
	)

	for player_list in [_team_intro_blue_list, _team_intro_red_list]:
		if player_list == null:
			continue
		player_list.add_theme_constant_override("separation", list_separation)
		for card in player_list.get_children():
			if card is Control:
				(card as Control).custom_minimum_size.y = card_height

	for column in [_team_intro_blue_column, _team_intro_red_column]:
		if column == null:
			continue
		column.add_theme_constant_override(
			"separation",
			maxi(5, roundi(10.0 * roster_scale))
		)
		if column.get_child_count() > 0 and column.get_child(0) is Label:
			(column.get_child(0) as Label).add_theme_font_size_override(
				"font_size",
				maxi(21, roundi(28.0 * roster_scale))
			)

	if _team_intro_mode_label != null:
		_team_intro_mode_label.add_theme_font_size_override(
			"font_size", maxi(19, roundi(24.0 * roster_scale))
		)
	if _team_intro_title_label != null:
		_team_intro_title_label.add_theme_font_size_override(
			"font_size", maxi(32, roundi(42.0 * roster_scale))
		)
	if _team_intro_context_label != null:
		_team_intro_context_label.add_theme_font_size_override(
			"font_size", maxi(15, roundi(18.0 * roster_scale))
		)
	if _team_intro_vs_label != null:
		_team_intro_vs_label.add_theme_font_size_override(
			"font_size", maxi(48, roundi(66.0 * roster_scale))
		)
	if _team_intro_skip_hint != null:
		_team_intro_skip_hint.add_theme_font_size_override(
			"font_size", maxi(11, roundi(14.0 * roster_scale))
		)


func _team_intro_scale_for_player_count(player_count: int) -> float:
	if player_count >= 6:
		return 0.65
	if player_count == 5:
		return 0.72
	if player_count == 4:
		return 0.84
	return 1.0


func _on_team_introduction_changed(
	team: StringName,
	player_names: Array
) -> void:
	if _team_intro_overlay == null:
		return
	if _team_intro_tween != null:
		_team_intro_tween.kill()

	if team != &"versus":
		_hide_team_introduction()
		return

	var blue_names: Array = []
	var red_names: Array = []
	if player_names.size() >= 1 and player_names[0] is Array:
		blue_names = player_names[0]
	if player_names.size() >= 2 and player_names[1] is Array:
		red_names = player_names[1]
	_team_intro_max_players_per_side = maxi(
		1,
		maxi(blue_names.size(), red_names.size())
	)
	_team_intro_roster_scale = _team_intro_scale_for_player_count(
		_team_intro_max_players_per_side
	)
	var context: Dictionary = {}
	if player_names.size() >= 3 and player_names[2] is Dictionary:
		context = player_names[2] as Dictionary
	var accent: Color = context.get("accent", Color(0.82, 0.69, 1.0)) as Color
	_team_intro_mode_label.text = str(context.get("mode_title", "MATCHUP"))
	_team_intro_mode_label.add_theme_color_override("font_color", accent)
	_team_intro_context_label.text = str(context.get("context", ""))
	_team_intro_skip_hint.visible = (
		multiplayer.is_server()
		and bool(context.get("host_can_skip", true))
	)
	_populate_team_intro_list(_team_intro_blue_list, blue_names, &"blue")
	_populate_team_intro_list(_team_intro_red_list, red_names, &"red")
	_layout_team_introduction()

	_team_intro_overlay.modulate.a = 1.0
	_team_intro_overlay.show()
	_team_intro_band.modulate.a = 0.0
	_team_intro_band.scale = Vector2(0.97, 0.97)
	_team_intro_band.pivot_offset = _team_intro_band.size * 0.5
	_team_intro_blue_column.modulate.a = 0.0
	_team_intro_red_column.modulate.a = 0.0
	_team_intro_vs_label.modulate.a = 0.0
	_team_intro_vs_label.scale = Vector2(0.62, 0.62)
	_team_intro_vs_label.pivot_offset = _team_intro_vs_label.size * 0.5
	_team_intro_tween = create_tween().set_parallel(true)
	_team_intro_tween.set_trans(Tween.TRANS_QUART)
	_team_intro_tween.set_ease(Tween.EASE_OUT)
	_team_intro_tween.tween_property(
		_team_intro_band,
		"modulate:a",
		1.0,
		0.22
	)
	_team_intro_tween.tween_property(
		_team_intro_band,
		"scale",
		Vector2.ONE,
		0.3
	)
	_team_intro_tween.tween_property(
		_team_intro_blue_column, "modulate:a", 1.0, 0.26
	).set_delay(0.1)
	_team_intro_tween.tween_property(
		_team_intro_red_column, "modulate:a", 1.0, 0.26
	).set_delay(0.1)
	_team_intro_tween.tween_property(
		_team_intro_vs_label, "modulate:a", 1.0, 0.18
	).set_delay(0.28)
	_team_intro_tween.tween_property(
		_team_intro_vs_label, "scale", Vector2.ONE, 0.3
	).set_delay(0.28).set_trans(Tween.TRANS_BACK)


func _populate_team_intro_list(
	player_list: VBoxContainer,
	players: Array,
	team: StringName
) -> void:
	for child in player_list.get_children():
		player_list.remove_child(child)
		child.queue_free()

	if players.is_empty():
		var empty_label := _build_team_intro_name_label("NO PLAYERS")
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		player_list.add_child(empty_label)
		return

	for entry in players:
		if not entry is Dictionary:
			continue
		var details: Dictionary = entry
		var player_name := str(details.get("name", "Player")).strip_edges()
		if player_name.is_empty():
			player_name = "Player"
		details["name"] = player_name
		player_list.add_child(_build_team_intro_player_card(details, team))


func _build_team_intro_player_card(
	details: Dictionary,
	team: StringName
) -> Control:
	var team_color := (
		Color(1.0, 0.27, 0.34) if team == &"red"
		else Color(0.25, 0.65, 1.0)
	)
	var card := Control.new()
	card.name = "PlayerBannerCard"
	var viewport_height := get_viewport_rect().size.y
	var ui_scale := clampf(_team_intro_roster_scale, 0.65, 1.0)
	card.custom_minimum_size = Vector2(
		0.0,
		FootballGoalReplayBanner.presentation_size(
			Vector2(get_viewport_rect().size.x, viewport_height)
		).y * ui_scale
	)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.clip_contents = true

	var banner := FootballGoalReplayBanner.new()
	banner.name = "BannerArt"
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.show_shadow = false
	banner.show_text_overlay = false
	banner.draw_inset = 0.0
	banner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	banner.set_presentation(
		str(details.get("banner_id", "player_banner.classic")),
		team,
		int(details.get("banner_color_index", -1))
	)
	card.add_child(banner)

	var shade := ColorRect.new()
	shade.name = "TextShade"
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.color = Color(0.005, 0.008, 0.014, 0.58)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.add_child(shade)

	var margin := MarginContainer.new()
	margin.name = "TextMargin"
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", maxi(9, roundi(16.0 * ui_scale)))
	margin.add_theme_constant_override("margin_top", maxi(4, roundi(8.0 * ui_scale)))
	margin.add_theme_constant_override("margin_right", maxi(8, roundi(13.0 * ui_scale)))
	margin.add_theme_constant_override("margin_bottom", maxi(4, roundi(8.0 * ui_scale)))
	card.add_child(margin)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", maxi(5, roundi(10.0 * ui_scale)))
	margin.add_child(row)

	var identity := VBoxContainer.new()
	identity.mouse_filter = Control.MOUSE_FILTER_IGNORE
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.alignment = BoxContainer.ALIGNMENT_CENTER
	identity.add_theme_constant_override("separation", 0)
	row.add_child(identity)

	var name_label := _build_team_intro_name_label(
		str(details.get("name", "Player")),
		team_color,
		ui_scale
	)
	name_label.name = "PlayerName"
	identity.add_child(name_label)

	var subtitle := str(details.get("subtitle", "")).strip_edges()
	var boss := bool(details.get("boss", false))
	if boss and subtitle.is_empty():
		subtitle = "ELITE PLAYER ENEMY"
	if not subtitle.is_empty():
		var subtitle_label := Label.new()
		subtitle_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		subtitle_label.add_theme_font_size_override(
			"font_size", maxi(9, roundi(12.0 * ui_scale))
		)
		subtitle_label.add_theme_color_override(
			"font_color", Color(0.78, 0.81, 0.88)
		)
		subtitle_label.text = subtitle.to_upper().left(34)
		subtitle_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		identity.add_child(subtitle_label)

	var status := "ELITE BOSS" if boss else (
		"RANKED CPU" if bool(details.get("cpu", false)) else "PLAYER"
	)
	var mmr := int(details.get("mmr", -1))
	if mmr >= 0:
		status += "  •  %d MMR" % mmr
	var status_label := Label.new()
	status_label.custom_minimum_size.x = maxf(84.0, 118.0 * ui_scale)
	status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_label.add_theme_font_size_override(
		"font_size", maxi(9, roundi(12.0 * ui_scale))
	)
	status_label.add_theme_color_override(
		"font_color",
		Color(1.0, 0.82, 0.34) if boss else team_color.lightened(0.2)
	)
	status_label.text = status
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(status_label)
	return card


func _build_team_intro_name_label(
	player_name: String,
	name_color: Color = Color.WHITE,
	ui_scale: float = 1.0
) -> Label:
	var name_label := Label.new()
	name_label.custom_minimum_size = Vector2(
		0.0,
		maxf(22.0, 30.0 * ui_scale)
	)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.add_theme_font_size_override(
		"font_size", maxi(15, roundi(21.0 * ui_scale))
	)
	name_label.add_theme_color_override("font_color", name_color)
	name_label.add_theme_color_override(
		"font_outline_color",
		Color(0.0, 0.0, 0.0, 0.9)
	)
	name_label.add_theme_constant_override("outline_size", 5)
	name_label.text = player_name
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return name_label


func _is_team_intro_skip_input(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		return mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT
	if event is InputEventJoypadButton:
		return (event as InputEventJoypadButton).pressed
	if event is InputEventKey:
		var key_event := event as InputEventKey
		return (
			key_event.pressed
			and not key_event.echo
			and key_event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]
		)
	return false


func _hide_team_introduction() -> void:
	if _team_intro_overlay == null or not _team_intro_overlay.visible:
		return
	if _team_intro_tween != null:
		_team_intro_tween.kill()
	_team_intro_tween = create_tween().set_parallel(true)
	_team_intro_tween.set_trans(Tween.TRANS_QUAD)
	_team_intro_tween.set_ease(Tween.EASE_IN)
	_team_intro_tween.tween_property(
		_team_intro_band,
		"scale",
		Vector2(0.96, 0.96),
		0.16
	)
	_team_intro_tween.tween_property(
		_team_intro_overlay,
		"modulate:a",
		0.0,
		0.2
	)
	_team_intro_tween.chain().tween_callback(
		func() -> void:
			_team_intro_overlay.hide()
			_team_intro_overlay.modulate.a = 1.0
	)
func _on_halftime_changed(active: bool, seconds_remaining: int) -> void:
	if not active:
		_halftime_sound_active = false
		match_state_label.text = ""
		match_state_label.hide()
		skip_halftime_button.hide()
		return
	if not _halftime_sound_active:
		_halftime_sound_active = true
		_play_whistle_sound(-23.0)
	match_state_label.text = "RANKED DRAFT  •  GAME 2" if match_manager.ranked_mode else "BREAK  •  GAME 2 IN %02d" % seconds_remaining
	UIMotion.show_control(
		match_state_label,
		0.12,
		Vector2(0.96, 0.96)
	)
	if multiplayer.is_server() and not match_manager.ranked_mode:
		UIMotion.show_control(skip_halftime_button, 0.12)
	else:
		skip_halftime_button.hide()


func _on_match_started() -> void:
	_match_active = true
	_last_countdown_sound_second = -1
	_halftime_sound_active = false
	_last_tiebreak_sound_phase = &""
	match_state_label.text = ""
	match_state_label.hide()
	_set_scoreboard_panel_visible(true)
	_refresh_final_countdown()
	if multiplayer.is_server():
		UIMotion.show_control(cancel_match_button)
	else:
		cancel_match_button.hide()
		skip_halftime_button.hide()


func _on_match_ended(winning_team: StringName) -> void:
	_match_active = false
	_last_countdown_sound_second = -1
	_play_match_end_sound()
	_hide_team_introduction()
	final_countdown_label.hide()
	var winner := "BLUE" if winning_team == &"blue" else "RED"
	match_state_label.text = "MATCH OVER - %s WINS" % winner
	UIMotion.show_control(
		match_state_label,
		0.24,
		Vector2(0.86, 0.86)
	)
	_set_scoreboard_panel_visible(false)
	UIMotion.hide_control(cancel_match_button)
	UIMotion.hide_control(skip_halftime_button)


func _on_match_cancelled() -> void:
	_match_active = false
	_last_countdown_sound_second = -1
	_hide_team_introduction()
	final_countdown_label.hide()
	match_state_label.text = "MATCH CANCELLED"
	UIMotion.show_control(match_state_label)
	_set_scoreboard_panel_visible(false)
	UIMotion.hide_control(announcement_label)
	UIMotion.hide_control(countdown_label)
	UIMotion.hide_control(cancel_match_button)
	UIMotion.hide_control(skip_halftime_button)


func _on_session_started() -> void:
	_match_active = false
	_last_countdown_sound_second = -1
	_hide_team_introduction()
	final_countdown_label.hide()
	UIMotion.hide_control(cancel_match_button)
	UIMotion.hide_control(skip_halftime_button)
	_set_scoreboard_panel_visible(false)

func _on_session_ended() -> void:
	_match_active = false
	_last_countdown_sound_second = -1
	_hide_team_introduction()
	final_countdown_label.hide()
	UIMotion.hide_control(cancel_match_button)
	UIMotion.hide_control(skip_halftime_button)
	_set_scoreboard_panel_visible(false)
	UIMotion.hide_control(announcement_label)
	UIMotion.hide_control(countdown_label)
	UIMotion.hide_control(match_state_label)
	match_state_label.text = ""


func _on_results_dismissed() -> void:
	pass

func _set_scoreboard_panel_visible(should_show: bool) -> void:
	_scoreboard_should_be_visible = should_show
	if _team_lineup_layer != null:
		_team_lineup_layer.visible = should_show
		if should_show:
			_team_lineup_signature = ""
			refresh_team_lineups()
	if _scoreboard_visibility_tween != null:
		_scoreboard_visibility_tween.kill()
	scoreboard_panel.scale = COMPACT_SCOREBOARD_SCALE
	if should_show:
		scoreboard_panel.modulate.a = 0.0
		scoreboard_panel.show()
	_scoreboard_visibility_tween = create_tween()
	_scoreboard_visibility_tween.set_trans(Tween.TRANS_QUAD)
	_scoreboard_visibility_tween.set_ease(
		Tween.EASE_OUT if should_show else Tween.EASE_IN
	)
	_scoreboard_visibility_tween.tween_property(
		scoreboard_panel,
		"modulate:a",
		1.0 if should_show else 0.0,
		0.18
	)
	if not should_show:
		_scoreboard_visibility_tween.tween_callback(
			func() -> void:
				if not _scoreboard_should_be_visible:
					scoreboard_panel.hide()
					scoreboard_panel.modulate.a = 1.0
					scoreboard_panel.scale = COMPACT_SCOREBOARD_SCALE
		)
