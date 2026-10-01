extends Control


const AI_TRAINING_CURATOR_NAME: String = "salikuu"
const DRAFT_LEADERBOARD_PANEL_SCRIPT: Script = preload(
	"res://Scenes/champions_league_leaderboard_panel.gd"
)


class LeaderboardStatIcon extends Control:
	const GOALS: StringName = &"goals"
	const SAVES: StringName = &"saves"
	const PASSES: StringName = &"passes"
	const VALUE: StringName = &"value"

	var stat_kind: StringName = GOALS
	var icon_color: Color = Color(0.84, 1.0, 0.93)

	func _draw() -> void:
		var center := size * 0.5
		var ink := Color(0.025, 0.07, 0.08, 1.0)
		match stat_kind:
			GOALS:
				draw_circle(center, 9.0, icon_color)
				draw_arc(center, 9.0, 0.0, TAU, 18, ink, 1.5, true)
				draw_circle(center, 3.0, ink)
				draw_line(center + Vector2(-7.0, -2.0), center + Vector2(-3.0, -5.0), ink, 1.2, true)
				draw_line(center + Vector2(7.0, -2.0), center + Vector2(3.0, -5.0), ink, 1.2, true)
			SAVES:
				var shield := PackedVector2Array([
					center + Vector2(0.0, -10.0), center + Vector2(9.0, -5.0),
					center + Vector2(7.0, 6.0), center + Vector2(0.0, 11.0),
					center + Vector2(-7.0, 6.0), center + Vector2(-9.0, -5.0)
				])
				draw_colored_polygon(shield, icon_color)
				draw_polyline(PackedVector2Array([shield[0], shield[1], shield[2], shield[3], shield[4], shield[5], shield[0]]), ink, 1.5, true)
				draw_line(center + Vector2(-4.0, 0.0), center + Vector2(-1.0, 4.0), ink, 1.5, true)
				draw_line(center + Vector2(-1.0, 4.0), center + Vector2(5.0, -4.0), ink, 1.5, true)
			PASSES:
				draw_circle(center + Vector2(-8.0, 0.0), 2.1, icon_color)
				draw_circle(center + Vector2(-2.0, 0.0), 2.1, icon_color)
				draw_line(center + Vector2(2.0, 0.0), center + Vector2(9.0, 0.0), icon_color, 2.0, true)
				draw_colored_polygon(PackedVector2Array([center + Vector2(10.5, 0.0), center + Vector2(5.5, -4.5), center + Vector2(5.5, 4.5)]), icon_color)
			VALUE:
				var star := PackedVector2Array()
				for index in range(10):
					var angle := -PI * 0.5 + float(index) * PI / 5.0
					var radius := 10.0 if index % 2 == 0 else 4.5
					star.append(center + Vector2(cos(angle), sin(angle)) * radius)
				draw_colored_polygon(star, icon_color)
				draw_polyline(PackedVector2Array([star[0], star[1], star[2], star[3], star[4], star[5], star[6], star[7], star[8], star[9], star[0]]), ink, 1.4, true)


class ProgressLootboxIcon extends Control:
	var lootbox_ready: bool = false

	func _draw() -> void:
		var center: Vector2 = size * 0.5
		var glow: Color = Color(0.55, 1.0, 0.24) if lootbox_ready else Color(0.62, 0.68, 0.72)
		var dark: Color = Color(0.025, 0.035, 0.04, 0.96)
		var box_points := PackedVector2Array([
			center + Vector2(-15.0, -6.0),
			center + Vector2(0.0, -14.0),
			center + Vector2(15.0, -6.0),
			center + Vector2(15.0, 10.0),
			center + Vector2(0.0, 17.0),
			center + Vector2(-15.0, 10.0),
		])
		draw_colored_polygon(box_points, Color(glow.r, glow.g, glow.b, 0.22))
		draw_polyline(PackedVector2Array([
			box_points[0], box_points[1], box_points[2], box_points[3],
			box_points[4], box_points[5], box_points[0]
		]), glow, 2.2, true)
		draw_line(box_points[0], center, glow, 1.6, true)
		draw_line(box_points[2], center, glow, 1.6, true)
		draw_line(center, box_points[4], glow, 1.6, true)
		draw_circle(center, 4.0, glow if lootbox_ready else dark)


@export var match_manager: FootballMatchManager

@onready var controller_support := get_node(
	"/root/ControllerSupport"
) as FootballControllerSupport
@export_category("MVP Scoring")
@export var mvp_points_per_goal: int = 8
@export var mvp_points_per_save: int = 2
@export var mvp_points_per_pass: int = 1

@onready var background: ColorRect = $Background
@onready var leaderboard_panel: PanelContainer = $Background/Center/Panel
@onready var title_label: Label = $Background/Center/Panel/VBox/Title
@onready var winner_label: Label = $Background/Center/Panel/VBox/Winner
@onready var mvp_panel: PanelContainer = (
	$Background/Center/Panel/VBox/MVPPanel
)
@onready var mvp_name_label: Label = (
	$Background/Center/Panel/VBox/MVPPanel/VBox/Name
)
@onready var mvp_stats_label: Label = (
	$Background/Center/Panel/VBox/MVPPanel/VBox/Stats
)
@onready var teams_row: VBoxContainer = (
	$Background/Center/Panel/VBox/TeamsRow
)
@onready var blue_card: PanelContainer = (
	$Background/Center/Panel/VBox/TeamsRow/BlueCard
)
@onready var red_card: PanelContainer = (
	$Background/Center/Panel/VBox/TeamsRow/RedCard
)
@onready var versus_label: Label = (
	$Background/Center/Panel/VBox/TeamsRow/Versus
)
@onready var blue_heading: Label = (
	$Background/Center/Panel/VBox/TeamsRow/BlueCard/BlueSection/Heading
)
@onready var blue_grid: GridContainer = (
	$Background/Center/Panel/VBox/TeamsRow/BlueCard/BlueSection/Grid
)
@onready var red_heading: Label = (
	$Background/Center/Panel/VBox/TeamsRow/RedCard/RedSection/Heading
)
@onready var red_grid: GridContainer = (
	$Background/Center/Panel/VBox/TeamsRow/RedCard/RedSection/Grid
)
@onready var hint_label: Label = $Background/Center/Panel/VBox/Hint
@onready var adjust_abilities_button: Button = (
	$Background/Center/Panel/VBox/AdjustAbilitiesButton
)
@onready var back_button: Button = (
	$Background/Center/Panel/VBox/BackButton
)

var _entries: Array = []
var _end_mode: bool = false
var _live_visible: bool = false
var _halftime_mode: bool = false
var _halftime_seconds_remaining: int = 0
var _halftime_adjusting: bool = false
var _mvp_peer_id: int = 0
var _training_recording_dialog: ConfirmationDialog
var _compact_layout: bool = false
var _base_leaderboard_style: StyleBoxFlat
var _ranked_animation_accum: float = 0.0
var _base_mvp_style: StyleBoxFlat
var _base_blue_card_style: StyleBoxFlat
var _base_red_card_style: StyleBoxFlat
var _results_layout: HBoxContainer
var _progress_card: PanelContainer
var _progress_level_label: Label
var _progress_bar: ProgressBar
var _progress_xp_label: Label
var _progress_gain_label: Label
var _progress_lootbox_icon: ProgressLootboxIcon
var _progress_lootbox_label: Label
var _progress_tween: Tween
var _battle_pass: FootballBattlePass
var _draft_wins_panel: PanelContainer


func _ready() -> void:
	if match_manager == null:
		push_error("Leaderboard MatchManager was not assigned.")
		return

	_battle_pass = get_node_or_null("/root/BattlePass") as FootballBattlePass
	_build_progression_card()
	_draft_wins_panel = DRAFT_LEADERBOARD_PANEL_SCRIPT.new() as PanelContainer
	_draft_wins_panel.set("manager", match_manager)
	var content_column := title_label.get_parent() as VBoxContainer
	content_column.add_child(_draft_wins_panel)
	content_column.move_child(
		_draft_wins_panel,
		hint_label.get_index()
	)
	_draft_wins_panel.hide()
	if _battle_pass != null:
		_battle_pass.match_xp_awarded.connect(_on_match_xp_awarded)
	hide()
	back_button.pressed.connect(_on_back_pressed)
	adjust_abilities_button.pressed.connect(_on_adjust_abilities_pressed)
	adjust_abilities_button.focus_mode = Control.FOCUS_ALL
	back_button.focus_mode = Control.FOCUS_ALL
	controller_support.input_method_changed.connect(
		_on_input_method_changed
	)
	match_manager.leaderboard_changed.connect(
		_on_leaderboard_changed
	)
	match_manager.score_changed.connect(_on_score_changed)
	match_manager.match_results_ready.connect(
		_on_match_results_ready
	)
	match_manager.match_started.connect(_on_match_started)
	match_manager.freeplay_started.connect(_on_match_started)
	match_manager.match_cancelled.connect(_on_match_cancelled)
	match_manager.halftime_changed.connect(_on_halftime_changed)
	_ensure_leaderboard_input()
	_apply_leaderboard_styling()
	# Keep the team tables together and place the match summary beneath them,
	# matching the familiar stacked competitive-scoreboard reading order.
	var leaderboard_vbox := teams_row.get_parent() as VBoxContainer
	if leaderboard_vbox != null:
		leaderboard_vbox.move_child(mvp_panel, teams_row.get_index() + 1)
	MenuStyler.install_click_sounds(self)
	_apply_responsive_layout()
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_rebuild_table()


func _apply_leaderboard_styling() -> void:
	MenuStyler._apply_frosted_material(
		background,
		Color(0.008, 0.023, 0.015, 1.0)
	)
	MenuStyler.style_panel(
		leaderboard_panel,
		Color(0.34, 0.86, 0.72),
		Color(0.008, 0.03, 0.038, 0.86)
	)
	MenuStyler.style_panel(
		mvp_panel,
		Color(1.0, 0.76, 0.2),
		Color(0.12, 0.085, 0.018, 0.9)
	)
	MenuStyler.style_heading(
		title_label,
		Color(0.45, 0.96, 0.72)
	)
	MenuStyler.style_button(
		adjust_abilities_button,
		Color(0.62, 0.48, 1.0),
		42.0
	)
	MenuStyler.style_button(
		back_button,
		Color(0.3, 0.9, 0.62),
		42.0
	)
	MenuStyler.apply_premium_design(self, &"results")
	_base_leaderboard_style = _copy_flat_panel_style(leaderboard_panel)
	_base_mvp_style = _copy_flat_panel_style(mvp_panel)
	_base_blue_card_style = _copy_flat_panel_style(blue_card)
	_base_red_card_style = _copy_flat_panel_style(red_card)


func _get_result_team_size() -> int:
	if not _end_mode:
		return 0
	var blue_count: int = 0
	var red_count: int = 0
	for value in _entries:
		if value is not Dictionary:
			continue
		var entry := value as Dictionary
		match StringName(entry.get("team", &"")):
			&"blue":
				blue_count += 1
			&"red":
				red_count += 1
	return maxi(blue_count, red_count)


func _get_end_table_row_height() -> float:
	if not _end_mode:
		return 25.0 if _compact_layout else 32.0
	var team_size: int = _get_result_team_size()
	if team_size >= 6:
		return 12.0 if _compact_layout else 14.0
	if team_size >= 5:
		return 16.0 if _compact_layout else 18.0
	return 18.0 if _compact_layout else 21.0


func _get_end_table_font_size(default_end_size: int) -> int:
	if not _end_mode:
		return default_end_size
	var team_size: int = _get_result_team_size()
	if team_size >= 6:
		return maxi(8, default_end_size - 3)
	if team_size >= 5:
		return maxi(9, default_end_size - 1)
	return default_end_size


func _apply_responsive_layout() -> void:
	if not is_inside_tree():
		return
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var result_scale: float = 0.64 if _end_mode else 1.0
	leaderboard_panel.custom_minimum_size.x = clampf(
		viewport_size.x * (0.58 if _end_mode else 0.80) * result_scale,
		500.0 if _end_mode else 680.0,
		720.0 if _end_mode else 1040.0
	)
	var compact: bool = viewport_size.y < 800.0 or viewport_size.x < 1280.0
	_compact_layout = compact
	var result_team_size: int = _get_result_team_size()
	var large_result: bool = _end_mode and result_team_size >= 5
	var six_result: bool = _end_mode and result_team_size >= 6
	if _draft_wins_panel != null and _draft_wins_panel.has_method("set_compact_layout"):
		_draft_wins_panel.call("set_compact_layout", six_result)
	if _results_layout != null:
		_results_layout.add_theme_constant_override(
			"separation", 8 if viewport_size.x < 900.0 else 16
		)
	if _progress_card != null:
		_progress_card.custom_minimum_size.x = (
			160.0 if viewport_size.x < 900.0 else 225.0
		)
	var content_vbox := title_label.get_parent() as VBoxContainer
	if content_vbox != null:
		content_vbox.add_theme_constant_override(
			"separation",
			(
				2 if six_result
				else 3 if large_result
				else (3 if compact else 7) if _end_mode
				else (5 if compact else 13)
			)
		)
	if teams_row != null:
		teams_row.custom_minimum_size.y = (
			140.0 if six_result
			else 172.0 if large_result
			else (180.0 if compact else 235.0) if _end_mode
			else (300.0 if compact else 390.0)
		)
		teams_row.add_theme_constant_override(
			"separation",
			0 if six_result else 2 if _end_mode else (3 if compact else 6)
		)
	var blue_section := blue_grid.get_parent() as VBoxContainer
	var red_section := red_grid.get_parent() as VBoxContainer
	if blue_section != null:
		blue_section.add_theme_constant_override(
			"separation", 1 if six_result else 6
		)
	if red_section != null:
		red_section.add_theme_constant_override(
			"separation", 1 if six_result else 6
		)
	versus_label.custom_minimum_size.y = (
		10.0 if six_result else 13.0 if large_result else 16.0 if _end_mode else 22.0
	)
	var grid_gap: int = 1 if six_result else 2 if large_result else 3 if compact else 5
	blue_grid.add_theme_constant_override("h_separation", grid_gap)
	blue_grid.add_theme_constant_override("v_separation", grid_gap)
	red_grid.add_theme_constant_override("h_separation", grid_gap)
	red_grid.add_theme_constant_override("v_separation", grid_gap)
	mvp_panel.custom_minimum_size.y = (
		32.0 if six_result
		else 40.0 if large_result
		else (44.0 if compact else 56.0) if _end_mode
		else (64.0 if compact else 93.0)
	)
	adjust_abilities_button.custom_minimum_size.y = (
		21.0 if six_result else 24.0 if large_result else (27.0 if compact else 30.0)
	) if _end_mode else (34.0 if compact else 42.0)
	back_button.custom_minimum_size.y = (
		21.0 if six_result else 24.0 if large_result else (27.0 if compact else 30.0)
	) if _end_mode else (34.0 if compact else 42.0)
	title_label.add_theme_font_size_override(
		"font_size",
		16 if six_result else 17 if large_result else (18 if compact else 23) if _end_mode else (26 if compact else 34)
	)
	winner_label.add_theme_font_size_override(
		"font_size",
		20 if six_result else 22 if large_result else (24 if compact else 31) if _end_mode else (34 if compact else 45)
	)
	blue_heading.add_theme_font_size_override(
		"font_size",
		11 if six_result else 12 if large_result else (14 if compact else 16) if _end_mode else (18 if compact else 24)
	)
	red_heading.add_theme_font_size_override(
		"font_size",
		11 if six_result else 12 if large_result else (14 if compact else 16) if _end_mode else (18 if compact else 24)
	)
	mvp_name_label.add_theme_font_size_override(
		"font_size", 14 if six_result else 15 if large_result else 17 if _end_mode else 26
	)
	mvp_stats_label.add_theme_font_size_override(
		"font_size", 8 if six_result else 9 if large_result else 10 if _end_mode else 14
	)
	hint_label.add_theme_font_size_override(
		"font_size",
		9 if large_result else (10 if compact else 11) if _end_mode else (12 if compact else 14)
	)
	_apply_end_mode_panel_presentation()


func _build_progression_card() -> void:
	var center := leaderboard_panel.get_parent() as CenterContainer
	if center == null:
		return
	_results_layout = HBoxContainer.new()
	_results_layout.name = "ResultsLayout"
	_results_layout.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(_results_layout)
	leaderboard_panel.reparent(_results_layout)

	_progress_card = PanelContainer.new()
	_progress_card.name = "PostMatchProgress"
	_progress_card.custom_minimum_size = Vector2(225.0, 0.0)
	_progress_card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_results_layout.add_child(_progress_card)
	MenuStyler.style_panel(
		_progress_card,
		Color(0.72, 0.58, 1.0),
		Color(0.025, 0.025, 0.04, 0.78)
	)

	var column := VBoxContainer.new()
	column.name = "ProgressContent"
	column.add_theme_constant_override("separation", 8)
	_progress_card.add_child(column)

	var heading := Label.new()
	heading.text = "YOUR PROGRESS"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 18)
	heading.add_theme_color_override("font_color", Color(0.86, 0.78, 1.0))
	column.add_child(heading)

	_progress_level_label = Label.new()
	_progress_level_label.name = "LevelLabel"
	_progress_level_label.text = "LEVEL 0"
	_progress_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress_level_label.add_theme_font_size_override("font_size", 29)
	_progress_level_label.add_theme_color_override("font_color", Color.WHITE)
	_progress_level_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	_progress_level_label.add_theme_constant_override("outline_size", 4)
	column.add_child(_progress_level_label)

	_progress_gain_label = Label.new()
	_progress_gain_label.name = "XPGainLabel"
	_progress_gain_label.text = "+0 XP"
	_progress_gain_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress_gain_label.add_theme_font_size_override("font_size", 17)
	_progress_gain_label.add_theme_color_override("font_color", Color(0.65, 1.0, 0.43))
	column.add_child(_progress_gain_label)

	_progress_bar = ProgressBar.new()
	_progress_bar.name = "XPProgress"
	_progress_bar.custom_minimum_size = Vector2(0.0, 16.0)
	_progress_bar.min_value = 0.0
	_progress_bar.max_value = float(FootballBattlePass.XP_PER_TIER)
	_progress_bar.show_percentage = false
	column.add_child(_progress_bar)

	_progress_xp_label = Label.new()
	_progress_xp_label.name = "XPLabel"
	_progress_xp_label.text = "0 / %d XP" % FootballBattlePass.XP_PER_TIER
	_progress_xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress_xp_label.add_theme_font_size_override("font_size", 13)
	_progress_xp_label.add_theme_color_override("font_color", Color(0.78, 0.82, 0.86))
	column.add_child(_progress_xp_label)

	var divider := HSeparator.new()
	column.add_child(divider)

	var lootbox_row := VBoxContainer.new()
	lootbox_row.name = "LootboxStatus"
	lootbox_row.alignment = BoxContainer.ALIGNMENT_CENTER
	lootbox_row.add_theme_constant_override("separation", 3)
	column.add_child(lootbox_row)

	_progress_lootbox_icon = ProgressLootboxIcon.new()
	_progress_lootbox_icon.name = "LootboxIcon"
	_progress_lootbox_icon.custom_minimum_size = Vector2(42.0, 42.0)
	_progress_lootbox_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	lootbox_row.add_child(_progress_lootbox_icon)

	_progress_lootbox_label = Label.new()
	_progress_lootbox_label.name = "LootboxLabel"
	_progress_lootbox_label.text = "NEXT LOOTBOX"
	_progress_lootbox_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_progress_lootbox_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress_lootbox_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_progress_lootbox_label.add_theme_font_size_override("font_size", 13)
	lootbox_row.add_child(_progress_lootbox_label)
	_progress_card.hide()


func _on_match_xp_awarded(
	earned_xp: int,
	previous_xp: int,
	current_xp: int,
	previous_level: int,
	current_level: int,
	previous_lootboxes: int,
	current_lootboxes: int
) -> void:
	if not _end_mode or _progress_card == null:
		return
	_start_progression_reveal(
		earned_xp,
		previous_xp,
		current_xp,
		previous_level,
		current_level,
		previous_lootboxes,
		current_lootboxes
	)


func _start_progression_reveal(
	earned_xp: int,
	previous_xp: int,
	current_xp: int,
	previous_level: int,
	current_level: int,
	previous_lootboxes: int,
	current_lootboxes: int
) -> void:
	if _progress_tween != null and _progress_tween.is_valid():
		_progress_tween.kill()
	_progress_card.show()
	_progress_card.modulate.a = 0.0
	_progress_card.scale = Vector2(0.96, 0.96)
	_progress_card.pivot_offset = _progress_card.size * 0.5
	_progress_gain_label.text = "+%d XP" % earned_xp
	_set_progress_display(previous_xp)
	_update_lootbox_status(current_xp, previous_lootboxes, current_lootboxes)

	_progress_tween = create_tween()
	_progress_tween.set_trans(Tween.TRANS_QUAD)
	_progress_tween.set_ease(Tween.EASE_OUT)
	_progress_tween.set_parallel(true)
	_progress_tween.tween_property(_progress_card, "modulate:a", 1.0, 0.22)
	_progress_tween.tween_property(_progress_card, "scale", Vector2.ONE, 0.22)
	_progress_tween.tween_method(_set_progress_display, previous_xp, current_xp, 1.15)
	_progress_tween.chain()
	if current_level > previous_level:
		_progress_tween.tween_property(
			_progress_level_label, "modulate", Color(1.0, 0.84, 0.25), 0.10
		)
		_progress_tween.tween_property(
			_progress_level_label, "scale", Vector2(1.12, 1.12), 0.10
		)
		_progress_tween.tween_property(
			_progress_level_label, "scale", Vector2.ONE, 0.18
		)
	_progress_tween.tween_callback(
		_finish_progression_reveal.bind(current_level, previous_level)
	)


func _set_progress_display(total_xp_value: int) -> void:
	if _battle_pass == null:
		return
	var maximum_xp: int = _battle_pass.get_max_level() * FootballBattlePass.XP_PER_TIER
	var safe_total: int = clampi(total_xp_value, 0, maximum_xp)
	var display_level: int = mini(
		_battle_pass.get_max_level(),
		safe_total / FootballBattlePass.XP_PER_TIER
	)
	var level_xp: int = (
		FootballBattlePass.XP_PER_TIER
		if display_level >= _battle_pass.get_max_level()
		else safe_total % FootballBattlePass.XP_PER_TIER
	)
	_progress_level_label.text = "LEVEL %d" % display_level
	_progress_bar.value = float(level_xp)
	_progress_xp_label.text = "%d / %d XP" % [
		level_xp,
		FootballBattlePass.XP_PER_TIER,
	]


func _update_lootbox_status(
	current_xp: int,
	previous_lootboxes: int,
	current_lootboxes: int
) -> void:
	var newly_available: int = maxi(0, current_lootboxes - previous_lootboxes)
	var ready: bool = current_lootboxes > 0
	_progress_lootbox_icon.lootbox_ready = ready
	_progress_lootbox_icon.queue_redraw()
	_progress_lootbox_label.add_theme_color_override(
		"font_color",
		Color(0.58, 1.0, 0.24) if ready else Color(0.72, 0.76, 0.8)
	)
	if newly_available > 0:
		_progress_lootbox_label.text = "NEW LOOTBOX\nAVAILABLE!"
	elif ready:
		_progress_lootbox_label.text = "LOOTBOX READY\n%d AVAILABLE" % current_lootboxes
	else:
		var xp_into_level: int = current_xp % FootballBattlePass.XP_PER_TIER
		var xp_remaining: int = FootballBattlePass.XP_PER_TIER - xp_into_level
		_progress_lootbox_label.text = "NEXT LOOTBOX\n%d XP TO GO" % xp_remaining


func _finish_progression_reveal(current_level: int, previous_level: int) -> void:
	if current_level > previous_level:
		_progress_gain_label.text = "LEVEL UP!  %s" % _progress_gain_label.text


func _copy_flat_panel_style(panel: PanelContainer) -> StyleBoxFlat:
	var style := panel.get_theme_stylebox("panel") as StyleBoxFlat
	return style.duplicate() as StyleBoxFlat if style != null else null


func _apply_end_mode_panel_presentation() -> void:
	var opacity_reduction: float = 0.15 if _end_mode else 0.0
	var six_result: bool = _end_mode and _get_result_team_size() >= 6
	_apply_panel_style(
		leaderboard_panel,
		_base_leaderboard_style,
		opacity_reduction,
		6.0 if six_result else 10.0
	)
	_apply_panel_style(
		mvp_panel,
		_base_mvp_style,
		opacity_reduction,
		4.0 if six_result else 8.0
	)
	_apply_panel_style(
		blue_card,
		_base_blue_card_style,
		opacity_reduction,
		4.0 if six_result else 9.0
	)
	_apply_panel_style(
		red_card,
		_base_red_card_style,
		opacity_reduction,
		4.0 if six_result else 9.0
	)
	var frosted := background.material as ShaderMaterial
	if frosted != null:
		frosted.set_shader_parameter(
			"glass_opacity",
			MenuStyler.PANEL_ALPHA - opacity_reduction
		)


func _apply_panel_style(
	panel: PanelContainer,
	base_style: StyleBoxFlat,
	opacity_reduction: float,
	compact_margin: float
) -> void:
	if panel == null or base_style == null:
		return
	var style := base_style.duplicate() as StyleBoxFlat
	style.bg_color.a = maxf(0.0, style.bg_color.a - opacity_reduction)
	if _end_mode:
		style.content_margin_left = compact_margin
		style.content_margin_top = compact_margin
		style.content_margin_right = compact_margin
		style.content_margin_bottom = compact_margin
	panel.add_theme_stylebox_override("panel", style)


func _process(delta: float) -> void:
	if (
		visible
		and match_manager != null
		and match_manager.singleplayer_ranked_mode
	):
		_ranked_animation_accum += delta
		if _ranked_animation_accum >= 0.09:
			_ranked_animation_accum = 0.0
			_rebuild_table()
	else:
		_ranked_animation_accum = 0.0

	if _end_mode:
		return

	var should_show := (
		(_halftime_mode and not _halftime_adjusting)
		or (
			match_manager != null
			and match_manager.game_has_started
			and not match_manager.freeplay_active
			and controller_support.is_resilient_action_pressed(&"leaderboard")
		)
	)
	if should_show == _live_visible:
		return

	_live_visible = should_show
	if should_show:
		title_label.text = (
			"FIRST LEG SCOREBOARD"
			if _halftime_mode
			else "MATCH LEADERBOARD"
		)
		winner_label.hide()
		mvp_panel.hide()
		if _halftime_mode:
			_update_halftime_hint()
			adjust_abilities_button.visible = _halftime_ability_adjustments_allowed()
			back_button.text = _halftime_skip_button_text()
			back_button.visible = multiplayer.is_server()
		else:
			adjust_abilities_button.hide()
			hint_label.text = "Release [ %s ] to close" % (
				controller_support.get_action_prompt(&"leaderboard")
			)
			back_button.hide()
		_rebuild_table()
		show()
		if _halftime_mode:
			_queue_menu_focus(true)
	else:
		hide()


func _on_leaderboard_changed(entries: Array) -> void:
	_entries = entries.duplicate(true)
	if visible:
		_rebuild_table()


func _on_score_changed(_red_score: int, _blue_score: int) -> void:
	if visible:
		_rebuild_table()


func _on_match_results_ready(
	winning_team: StringName,
	entries: Array
) -> void:
	_entries = entries.duplicate(true)
	_end_mode = true
	_live_visible = false
	_halftime_mode = false
	_halftime_adjusting = false
	_halftime_seconds_remaining = 0
	adjust_abilities_button.hide()
	title_label.text = "FINAL SCOREBOARD"
	var winner := "BLUE" if winning_team == &"blue" else "RED"
	winner_label.text = "%s WINS" % winner
	winner_label.modulate = (
		Color(0.35, 0.65, 1.0)
		if winning_team == &"blue"
		else Color(1.0, 0.35, 0.35)
	)
	winner_label.show()
	_show_match_mvp(winning_team)
	hint_label.text = "Match complete"
	back_button.text = "Back to Lobby"
	_draft_wins_panel.hide()
	if match_manager.champions_league_mode:
		var draft_wins: Dictionary = match_manager.get_draft_wins_snapshot()
		title_label.text = "DRAFT • TWO-LEG RESULT"
		hint_label.text = (
			"YOUR DRAFT WINS  •  OVERALL %d  •  1V1 %d  •  2V2 %d"
			+ "  •  4V4 %d  •  5V5 %d  •  6V6 %d"
		) % [
			int(draft_wins.get("overall", 0)),
			int(draft_wins.get("1v1", 0)),
			int(draft_wins.get("2v2", 0)),
			int(draft_wins.get("4v4", 0)),
			int(draft_wins.get("5v5", 0)),
			int(draft_wins.get("6v6", 0)),
		]
		_draft_wins_panel.show()
		_draft_wins_panel.call("refresh")
	elif match_manager.ladder_mode:
		var ladder: Dictionary = match_manager.get_ladder_snapshot()
		var result: String = str(ladder.get("last_result", ""))
		title_label.text = "SEASONAL LADDER"
		if result == "lost":
			hint_label.text = "RUN LOST • THE LADDER RESTARTS AT RUNG 1"
			back_button.text = "Restart Ladder"
		elif result == "cleared":
			hint_label.text = "SEASON CLEARED • A NEW RUN AWAITS"
			back_button.text = "Start New Run"
		else:
			hint_label.text = "RUNG CLEARED • NEXT: %d/%d" % [
				int(ladder.get("rung", 1)),
				int(ladder.get("max_rung", 12))
			]
			back_button.text = "Continue Climb"
	elif match_manager.singleplayer_ranked_mode:
		var ranked: Dictionary = (
			match_manager.get_singleplayer_ranked_snapshot()
		)
		var mmr_change: int = int(ranked.get("last_change", 0))
		title_label.text = "PvE RANKED RESULT"
		hint_label.text = (
			"DIVISION %d • %s  |  %d MMR  |  %+d"
			% [
				int(ranked.get("division", 1)),
				str(ranked.get("division_name", "KREISLIGA")),
				int(ranked.get("mmr", 0)),
				mmr_change
			]
		)
		back_button.text = "Queue Next Match"
	back_button.show()
	_show_progression_snapshot()
	_apply_responsive_layout()
	_rebuild_table()
	show()
	_show_training_recording_prompt.call_deferred()
	_queue_menu_focus(false)


func _show_progression_snapshot() -> void:
	if _battle_pass == null or _progress_card == null:
		return
	if _progress_tween != null and _progress_tween.is_valid():
		_progress_tween.kill()
	_progress_card.show()
	_progress_card.modulate.a = 1.0
	_progress_card.scale = Vector2.ONE
	_progress_gain_label.text = "MATCH COMPLETE"
	_set_progress_display(_battle_pass.season_xp)
	var available_lootboxes: int = _battle_pass.get_available_lootboxes()
	_update_lootbox_status(
		_battle_pass.season_xp,
		available_lootboxes,
		available_lootboxes
	)


func _on_match_started() -> void:
	_close_training_recording_prompt()
	_reset_progression_card()
	_end_mode = false
	_live_visible = false
	_halftime_mode = false
	_halftime_adjusting = false
	_mvp_peer_id = 0
	adjust_abilities_button.hide()
	mvp_panel.hide()
	if _draft_wins_panel != null:
		_draft_wins_panel.hide()
	_apply_responsive_layout()
	hide()


func _on_match_cancelled() -> void:
	_close_training_recording_prompt()
	_reset_progression_card()
	_end_mode = false
	_live_visible = false
	_halftime_mode = false
	_halftime_adjusting = false
	_mvp_peer_id = 0
	adjust_abilities_button.hide()
	mvp_panel.hide()
	if _draft_wins_panel != null:
		_draft_wins_panel.hide()
	_apply_responsive_layout()
	hide()


func _on_back_pressed() -> void:
	if _halftime_mode:
		if multiplayer.is_server():
			match_manager.request_skip_halftime()
		return
	if not _end_mode:
		return

	_end_mode = false
	_reset_progression_card()
	hide()
	match_manager.dismiss_match_results()


func _reset_progression_card() -> void:
	if _progress_tween != null and _progress_tween.is_valid():
		_progress_tween.kill()
	_progress_tween = null
	if _progress_card != null:
		_progress_card.hide()


func _show_training_recording_prompt() -> void:
	if (
		match_manager == null
		or not multiplayer.is_server()
		or not match_manager.has_method("has_pending_human_demonstration_recording")
		or not bool(match_manager.call("has_pending_human_demonstration_recording"))
	):
		return
	if not _is_local_ai_training_curator():
		# Other hosts must never see or retain Salikuu's private training prompt.
		# Resolve the pending host-side recording as discarded so it cannot leak
		# into a later match or unexpectedly appear after the lobby changes.
		if match_manager.has_method("resolve_pending_human_demonstration_recording"):
			match_manager.call("resolve_pending_human_demonstration_recording", false)
		return
	if _training_recording_dialog != null and is_instance_valid(_training_recording_dialog):
		return
	_training_recording_dialog = ConfirmationDialog.new()
	_training_recording_dialog.title = "Save AI Training Recording?"
	_training_recording_dialog.dialog_text = (
		"Save this match as AI training data?\n\n"
		+ "Save keeps the host's human gameplay for the next training run. "
		+ "Discard permanently ignores this match."
	)
	_training_recording_dialog.ok_button_text = "Save for AI"
	_training_recording_dialog.cancel_button_text = "Discard"
	_training_recording_dialog.exclusive = true
	_training_recording_dialog.confirmed.connect(_on_training_recording_choice.bind(true))
	_training_recording_dialog.canceled.connect(_on_training_recording_choice.bind(false))
	add_child(_training_recording_dialog)
	MenuStyler.style_button(_training_recording_dialog.get_ok_button(), Color(0.3, 0.9, 0.62), 22.0)
	MenuStyler.style_button(_training_recording_dialog.get_cancel_button(), Color(0.96, 0.38, 0.38), 22.0)
	_training_recording_dialog.popup_centered(Vector2i(580, 230))
	_training_recording_dialog.get_ok_button().grab_focus.call_deferred()


func _is_local_ai_training_curator() -> bool:
	if match_manager == null or not multiplayer.is_server():
		return false
	var local_player: FootballPlayer = match_manager._get_player(
		multiplayer.get_unique_id()
	)
	if local_player == null:
		return false
	return (
		local_player.display_name.strip_edges().to_lower()
		== AI_TRAINING_CURATOR_NAME
	)


func _on_training_recording_choice(save_recording: bool) -> void:
	if match_manager != null and match_manager.has_method("resolve_pending_human_demonstration_recording"):
		var result := match_manager.call(
			"resolve_pending_human_demonstration_recording", save_recording
		) as Dictionary
		hint_label.text = (
			"AI training recording saved."
			if save_recording and bool(result.get("ok", false))
			else "AI training recording discarded."
		)
	_close_training_recording_prompt()
	_queue_menu_focus(false)


func _close_training_recording_prompt() -> void:
	if _training_recording_dialog == null or not is_instance_valid(_training_recording_dialog):
		_training_recording_dialog = null
		return
	_training_recording_dialog.queue_free()
	_training_recording_dialog = null


func _on_adjust_abilities_pressed() -> void:
	if not _halftime_mode or not _halftime_ability_adjustments_allowed():
		return
	var team_selection := get_parent().get_node_or_null("Teamselection")
	if team_selection == null:
		return
	_halftime_adjusting = true
	_live_visible = false
	hide()
	team_selection.call("open_halftime_adjustments")


func show_halftime_scoreboard() -> void:
	if not _halftime_mode:
		return
	_halftime_adjusting = false
	_live_visible = true
	title_label.text = "FIRST LEG SCOREBOARD"
	adjust_abilities_button.visible = _halftime_ability_adjustments_allowed()
	back_button.text = _halftime_skip_button_text()
	back_button.visible = multiplayer.is_server()
	_update_halftime_hint()
	_rebuild_table()
	show()
	_queue_menu_focus(true)


func _unhandled_input(event: InputEvent) -> void:
	if (
		not visible
		or not controller_support.using_controller
		or not event.is_action_pressed(&"ui_cancel")
	):
		return
	if _end_mode:
		_on_back_pressed()
	elif _halftime_mode:
		_queue_menu_focus(_halftime_ability_adjustments_allowed())
	get_viewport().set_input_as_handled()


func _on_halftime_changed(
	active: bool,
	seconds_remaining: int
) -> void:
	if _end_mode:
		_halftime_mode = false
		_halftime_seconds_remaining = 0
		return
	_halftime_mode = active
	_halftime_seconds_remaining = maxi(0, seconds_remaining)
	if not active:
		_halftime_adjusting = false
		adjust_abilities_button.hide()
		if not _end_mode:
			_live_visible = false
			hide()
		return

	_end_mode = false
	if _halftime_adjusting:
		_update_halftime_hint()
		return
	_live_visible = true
	title_label.text = "FIRST LEG SCOREBOARD"
	winner_label.hide()
	mvp_panel.hide()
	back_button.text = _halftime_skip_button_text()
	back_button.visible = multiplayer.is_server()
	adjust_abilities_button.visible = _halftime_ability_adjustments_allowed()
	_update_halftime_hint()
	_rebuild_table()
	show()
	_queue_menu_focus(true)


func _on_input_method_changed(
	using_controller: bool,
	_family: StringName
) -> void:
	if not using_controller or not visible:
		return
	if _end_mode:
		_queue_menu_focus(false)
	elif _halftime_mode and not _halftime_adjusting:
		_queue_menu_focus(true)


func _queue_menu_focus(prefer_adjust_abilities: bool) -> void:
	_configure_menu_focus_neighbors()
	if not controller_support.using_controller:
		return
	_grab_menu_focus.call_deferred(prefer_adjust_abilities)


func _configure_menu_focus_neighbors() -> void:
	if adjust_abilities_button.visible and back_button.visible:
		var back_path: NodePath = adjust_abilities_button.get_path_to(back_button)
		var adjust_path: NodePath = back_button.get_path_to(adjust_abilities_button)
		adjust_abilities_button.focus_neighbor_top = back_path
		adjust_abilities_button.focus_neighbor_bottom = back_path
		adjust_abilities_button.focus_next = back_path
		adjust_abilities_button.focus_previous = back_path
		back_button.focus_neighbor_top = adjust_path
		back_button.focus_neighbor_bottom = adjust_path
		back_button.focus_next = adjust_path
		back_button.focus_previous = adjust_path
		return

	var no_neighbor := NodePath("")
	adjust_abilities_button.focus_neighbor_top = no_neighbor
	adjust_abilities_button.focus_neighbor_bottom = no_neighbor
	adjust_abilities_button.focus_next = no_neighbor
	adjust_abilities_button.focus_previous = no_neighbor
	back_button.focus_neighbor_top = no_neighbor
	back_button.focus_neighbor_bottom = no_neighbor
	back_button.focus_next = no_neighbor
	back_button.focus_previous = no_neighbor


func _grab_menu_focus(prefer_adjust_abilities: bool) -> void:
	if not visible or (not _end_mode and not _halftime_mode):
		return
	var target: Button = back_button
	if (
		prefer_adjust_abilities
		and adjust_abilities_button.visible
		and not adjust_abilities_button.disabled
	):
		target = adjust_abilities_button
	elif not back_button.visible or back_button.disabled:
		if adjust_abilities_button.visible and not adjust_abilities_button.disabled:
			target = adjust_abilities_button
		else:
			return
	if target.is_visible_in_tree():
		target.grab_focus()


func _update_halftime_hint() -> void:
	var transition_name := (
		"LEG 2 DRAFT STARTS"
		if match_manager != null and match_manager.champions_league_mode
		else "SECOND LEG STARTS"
	)
	hint_label.text = "%s IN %02d" % [
		transition_name,
		_halftime_seconds_remaining
	]


func _halftime_ability_adjustments_allowed() -> bool:
	return (
		match_manager != null
		and not match_manager.champions_league_mode
	)


func _halftime_skip_button_text() -> String:
	if match_manager != null and match_manager.champions_league_mode:
		return "Start Leg 2 Draft Now"
	return "Start Second Leg Now"


func _rebuild_table() -> void:
	blue_heading.text = "%d   BLUE" % match_manager.blue_score
	red_heading.text = "%d   RED" % match_manager.red_score
	_rebuild_team_grid(blue_grid, &"blue", Color(0.35, 0.65, 1.0))
	_rebuild_team_grid(red_grid, &"red", Color(1.0, 0.35, 0.35))


func _rebuild_team_grid(
	grid: GridContainer,
	player_team: StringName,
	team_color: Color
) -> void:
	for child in grid.get_children():
		child.queue_free()

	var player_width: float = 168.0 if _end_mode else 198.0
	var goal_width: float = 43.0 if _end_mode else 50.0
	var save_width: float = 43.0 if _end_mode else 50.0
	var pass_width: float = 48.0 if _end_mode else 56.0
	var value_width: float = 56.0 if _end_mode else 66.0
	_add_cell(grid, "PLAYER", Color.WHITE, player_width, true)
	_add_stat_header(grid, LeaderboardStatIcon.GOALS, goal_width, "Goals")
	_add_stat_header(grid, LeaderboardStatIcon.SAVES, save_width, "Saves")
	_add_stat_header(grid, LeaderboardStatIcon.PASSES, pass_width, "Completed passes")
	_add_stat_header(grid, LeaderboardStatIcon.VALUE, value_width, "Value points")

	var team_entries: Array[Dictionary] = []
	for value in _entries:
		if value is not Dictionary:
			continue
		var entry := value as Dictionary
		if StringName(entry.get("team", &"")) != player_team:
			continue
		team_entries.append(entry)
	team_entries.sort_custom(_is_better_value_entry)

	for entry in team_entries:
		var is_mvp := (
			_end_mode
			and int(entry.get("peer_id", 0)) == _mvp_peer_id
		)
		var display_name := str(entry.get("name", "Player"))
		if is_mvp:
			display_name += "  [MVP]"
		_add_player_entry_cell(
			grid,
			entry,
			is_mvp,
			player_width
		)
		_add_cell(
			grid,
			str(entry.get("goals", 0)),
			Color.WHITE,
			goal_width
		)
		_add_cell(
			grid,
			str(entry.get("saves", 0)),
			Color.WHITE,
			save_width
		)
		_add_cell(
			grid,
			str(entry.get("passes", 0)),
			Color.WHITE,
			pass_width
		)
		_add_cell(
			grid,
			str(_get_value_points(entry)),
			Color(1.0, 0.84, 0.28),
			value_width
		)

	if team_entries.is_empty():
		_add_cell(
			grid,
			"No players",
			Color(0.62, 0.62, 0.62),
			player_width
		)
		for column_index in range(4):
			_add_cell(
				grid,
				"-",
				Color(0.62, 0.62, 0.62),
				value_width
				if column_index == 3
				else pass_width
				if column_index == 2
				else goal_width
			)


func _show_match_mvp(winning_team: StringName) -> void:
	var mvp := _find_match_mvp(winning_team)
	if mvp.is_empty():
		_mvp_peer_id = 0
		mvp_panel.hide()
		return

	_mvp_peer_id = int(mvp.get("peer_id", 0))
	var player_team := StringName(mvp.get("team", &""))
	var goals := int(mvp.get("goals", 0))
	var saves := int(mvp.get("saves", 0))
	var passes := int(mvp.get("passes", 0))
	var value_points := _get_value_points(mvp)
	mvp_name_label.text = str(mvp.get("name", "Player"))
	mvp_name_label.modulate = Color(0.94, 0.96, 0.98)
	mvp_stats_label.text = (
		"%s TEAM   |   %d GOALS   |   %d SAVES"
		+ "   |   %d PASSES   |   %d VALUE POINTS"
	) % [
		str(player_team).to_upper(),
		goals,
		saves,
		passes,
		value_points
	]
	mvp_panel.show()


func _find_match_mvp(
	winning_team: StringName
) -> Dictionary:
	var best: Dictionary = {}
	for value in _entries:
		if value is not Dictionary:
			continue
		var candidate := value as Dictionary
		if (
			best.is_empty()
			or _is_better_mvp_candidate(
				candidate,
				best,
				winning_team
			)
		):
			best = candidate
	return best


func _is_better_mvp_candidate(
	candidate: Dictionary,
	current: Dictionary,
	winning_team: StringName
) -> bool:
	var candidate_value := _get_value_points(candidate)
	var current_value := _get_value_points(current)
	if candidate_value != current_value:
		return candidate_value > current_value

	var candidate_goals := int(candidate.get("goals", 0))
	var current_goals := int(current.get("goals", 0))
	if candidate_goals != current_goals:
		return candidate_goals > current_goals

	var candidate_saves := int(candidate.get("saves", 0))
	var current_saves := int(current.get("saves", 0))
	if candidate_saves != current_saves:
		return candidate_saves > current_saves

	var candidate_passes := int(candidate.get("passes", 0))
	var current_passes := int(current.get("passes", 0))
	if candidate_passes != current_passes:
		return candidate_passes > current_passes

	var candidate_won := (
		StringName(candidate.get("team", &""))
		== winning_team
	)
	var current_won := (
		StringName(current.get("team", &""))
		== winning_team
	)
	if candidate_won != current_won:
		return candidate_won

	return str(candidate.get("name", "")).nocasecmp_to(
		str(current.get("name", ""))
	) < 0


func _get_value_points(entry: Dictionary) -> int:
	return (
		int(entry.get("goals", 0))
		* maxi(0, mvp_points_per_goal)
		+ int(entry.get("saves", 0))
		* maxi(0, mvp_points_per_save)
		+ int(entry.get("passes", 0))
		* maxi(0, mvp_points_per_pass)
	)



func _is_better_value_entry(
	candidate: Dictionary,
	current: Dictionary
) -> bool:
	var candidate_value := _get_value_points(candidate)
	var current_value := _get_value_points(current)
	if candidate_value != current_value:
		return candidate_value > current_value
	var candidate_goals := int(candidate.get("goals", 0))
	var current_goals := int(current.get("goals", 0))
	if candidate_goals != current_goals:
		return candidate_goals > current_goals
	var candidate_saves := int(candidate.get("saves", 0))
	var current_saves := int(current.get("saves", 0))
	if candidate_saves != current_saves:
		return candidate_saves > current_saves
	var candidate_passes := int(candidate.get("passes", 0))
	var current_passes := int(current.get("passes", 0))
	if candidate_passes != current_passes:
		return candidate_passes > current_passes
	return str(candidate.get("name", "")).nocasecmp_to(
		str(current.get("name", ""))
	) < 0


func _add_stat_header(
	grid: GridContainer,
	stat_kind: StringName,
	width: float,
	tooltip: String
) -> void:
	# Drawn icons avoid relying on an installed emoji/icon font. Those glyphs
	# were silently missing on some systems, leaving the leaderboard headers
	# blank or garbled.
	_add_cell(grid, "", Color.WHITE, width, true, tooltip)
	var cell := grid.get_child(-1) as PanelContainer
	if cell == null:
		return
	cell.tooltip_text = tooltip
	var icon := LeaderboardStatIcon.new()
	icon.name = (
		"GoalsIcon" if stat_kind == LeaderboardStatIcon.GOALS
		else "SavesIcon" if stat_kind == LeaderboardStatIcon.SAVES
		else "CompletedPassesIcon" if stat_kind == LeaderboardStatIcon.PASSES
		else "ValuePointsIcon"
	)
	icon.stat_kind = stat_kind
	icon.tooltip_text = tooltip
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cell.add_child(icon)


func _add_player_entry_cell(
	grid: GridContainer,
	entry: Dictionary,
	is_mvp: bool,
	width: float
) -> void:
	var cell := PanelContainer.new()
	var cell_height: float = _get_end_table_row_height()
	cell.custom_minimum_size = Vector2(width, cell_height)
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.size_flags_stretch_ratio = 3.2
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cell_style := StyleBoxFlat.new()
	var six_result: bool = _end_mode and _get_result_team_size() >= 6
	cell_style.content_margin_left = 5.0 if six_result else 6.0
	cell_style.content_margin_right = 5.0 if six_result else 6.0
	cell_style.content_margin_top = 0.5 if six_result else 2.0
	cell_style.content_margin_bottom = 0.5 if six_result else 2.0
	var row_index := int(float(grid.get_child_count()) / float(maxi(1, grid.columns)))
	var team_color := (
		Color(0.35, 0.65, 1.0)
		if grid == blue_grid
		else Color(1.0, 0.35, 0.35)
	)
	var fill_strength: float = 0.115 if row_index % 2 == 0 else 0.15
	cell_style.bg_color = Color(
		team_color.r * fill_strength,
		team_color.g * fill_strength,
		team_color.b * fill_strength,
		0.76
	)
	cell_style.set_border_width_all(1)
	cell_style.border_color = Color(team_color.r, team_color.g, team_color.b, 0.62)
	cell_style.border_width_left = 3
	cell_style.corner_radius_top_left = 6
	cell_style.corner_radius_top_right = 6
	cell_style.corner_radius_bottom_left = 6
	cell_style.corner_radius_bottom_right = 6
	grid.add_child(cell)
	cell.add_theme_stylebox_override("panel", cell_style)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 6)
	cell.add_child(row)

	var mmr: int = _lookup_ranked_mmr_for_entry(entry)
	if mmr >= 0:
		var prefix_label := RichTextLabel.new()
		prefix_label.bbcode_enabled = true
		prefix_label.fit_content = true
		prefix_label.scroll_active = false
		prefix_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		prefix_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		prefix_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		prefix_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		prefix_label.add_theme_font_size_override(
			"normal_font_size", _get_end_table_font_size(11) if _end_mode else 15
		)
		var division: int = FootballMatchManager.get_singleplayer_ranked_division_for_mmr(mmr)
		prefix_label.text = _format_ranked_mmr_badge(mmr)
		prefix_label.tooltip_text = FootballMatchManager.get_singleplayer_ranked_division_name(division)
		row.add_child(prefix_label)

	var name_label := Label.new()
	var display_name := str(entry.get("name", "Player"))
	if is_mvp:
		display_name += "  [MVP]"
	name_label.text = display_name
	name_label.tooltip_text = display_name
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override(
		"font_size", _get_end_table_font_size(11) if _end_mode else 15
	)
	name_label.add_theme_color_override("font_color", Color(0.94, 0.96, 0.98))
	name_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.82))
	name_label.add_theme_constant_override("outline_size", 2)
	row.add_child(name_label)


func _lookup_ranked_mmr_for_entry(entry: Dictionary) -> int:
	if not (match_manager != null and match_manager.singleplayer_ranked_mode):
		return -1
	if entry.has("mmr"):
		return maxi(0, int(entry.get("mmr", 0)))
	var peer_id: int = int(entry.get("peer_id", 0))
	var player_team := StringName(entry.get("team", &""))
	var player_name := str(entry.get("name", ""))
	var players: Array = []
	if player_team == &"blue":
		players = match_manager.blue_players
	elif player_team == &"red":
		players = match_manager.red_players
	for value in players:
		var player := value as FootballPlayer
		if player == null:
			continue
		var peer_match: bool = peer_id > 0 and player.owner_peer_id == peer_id
		var name_match: bool = player.display_name == player_name
		if not peer_match and not name_match:
			continue
		if player.cpu_controlled:
			return maxi(0, int(player.get_meta("pve_ranked_mmr", match_manager.singleplayer_ranked_mmr)))
		var ranked_profile: Dictionary = match_manager._pve_ranked_player_profiles.get(
			player.owner_peer_id,
			{
				"mmr": match_manager.singleplayer_ranked_mmr
			}
		) as Dictionary
		return maxi(0, int(ranked_profile.get("mmr", match_manager.singleplayer_ranked_mmr)))
	return -1


func _get_ranked_ui_display_color(division: int) -> Color:
	var base_color: Color = FootballMatchManager.get_singleplayer_ranked_division_color(division)
	if not FootballMatchManager.singleplayer_ranked_division_is_animated(division):
		return base_color
	var shine_color: Color = FootballMatchManager.get_singleplayer_ranked_division_shine_color(division)
	var t: float = float(Time.get_ticks_msec()) / 1000.0
	var shine_amount: float = 0.5 + 0.5 * sin(t * TAU / 1.72)
	return base_color.lerp(shine_color, shine_amount)


func _format_ranked_mmr_badge(mmr: int) -> String:
	var safe_mmr: int = maxi(0, mmr)
	var division: int = FootballMatchManager.get_singleplayer_ranked_division_for_mmr(safe_mmr)
	var division_color: Color = FootballMatchManager.get_singleplayer_ranked_division_color(division)
	var outline_color: Color = division_color.darkened(0.62)
	var digits_text := str(safe_mmr)
	if not FootballMatchManager.singleplayer_ranked_division_is_animated(division):
		return (
			"[outline_size=2][outline_color=#%s][color=#%s][%s][/color][/outline_color][/outline_size]"
		) % [outline_color.to_html(false), division_color.to_html(false), digits_text]
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
		body += "[color=#%s]%s[/color]" % [char_color.to_html(false), value.substr(index, 1)]
	return body


func _add_cell(
	grid: GridContainer,
	text: String,
	color: Color,
	width: float,
	header: bool = false,
	header_tooltip: String = ""
) -> void:
	var cell := PanelContainer.new()
	var cell_height: float = _get_end_table_row_height()
	cell.custom_minimum_size = Vector2(width, cell_height)
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.size_flags_stretch_ratio = 3.2 if width > 150.0 else 1.0
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cell_style := StyleBoxFlat.new()
	var six_result: bool = _end_mode and _get_result_team_size() >= 6
	cell_style.content_margin_left = 5.0 if six_result else 6.0
	cell_style.content_margin_right = 5.0 if six_result else 6.0
	cell_style.content_margin_top = 0.5 if six_result else 2.0
	cell_style.content_margin_bottom = 0.5 if six_result else 2.0
	var row_index := int(
		float(grid.get_child_count()) / float(maxi(1, grid.columns))
	)
	var team_color := (
		Color(0.35, 0.65, 1.0)
		if grid == blue_grid
		else Color(1.0, 0.35, 0.35)
	)
	var fill_strength: float = (
		0.20 if header
		else 0.115 if row_index % 2 == 0
		else 0.15
	)
	cell_style.bg_color = (
		Color(
			team_color.r * fill_strength,
			team_color.g * fill_strength,
			team_color.b * fill_strength,
			0.90 if header else 0.76
		)
	)
	cell_style.set_border_width_all(1)
	cell_style.border_color = Color(
		team_color.r,
		team_color.g,
		team_color.b,
		0.58 if header else 0.38
	)
	cell_style.corner_radius_top_left = 6
	cell_style.corner_radius_top_right = 6
	cell_style.corner_radius_bottom_left = 6
	cell_style.corner_radius_bottom_right = 6
	if not header and width > 150.0:
		cell_style.border_width_left = 3
		cell_style.border_color = Color(
			team_color.r,
			team_color.g,
			team_color.b,
			0.62
		)
	grid.add_child(cell)
	# Apply this after entering the tree. The shared menu-style watcher also runs
	# on newly added panels; doing our team treatment last keeps dynamic table
	# cells blue/red instead of replacing them with the generic panel surface.
	cell.add_theme_stylebox_override("panel", cell_style)

	var label := Label.new()
	label.text = text
	label.tooltip_text = header_tooltip if not header_tooltip.is_empty() else text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_LEFT
		if width > 150.0
		else HORIZONTAL_ALIGNMENT_CENTER
	)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var cell_font_size: int = (
		_get_end_table_font_size(12) if not header_tooltip.is_empty()
		else _get_end_table_font_size(10) if header
		else _get_end_table_font_size(11)
	) if _end_mode else (19 if not header_tooltip.is_empty() else 13 if header else 15)
	label.add_theme_font_size_override("font_size", cell_font_size)
	label.add_theme_color_override(
		"font_color",
		Color(0.72, 1.0, 0.88) if header else color
	)
	label.add_theme_color_override(
		"font_outline_color",
		Color(0.0, 0.0, 0.0, 0.82)
	)
	label.add_theme_constant_override("outline_size", 2)
	cell.add_child(label)


func _ensure_leaderboard_input() -> void:
	if not InputMap.has_action("leaderboard"):
		InputMap.add_action("leaderboard")

	var has_tab := false
	for event in InputMap.action_get_events("leaderboard"):
		var key_event := event as InputEventKey
		if key_event == null:
			continue
		if (
			key_event.keycode == KEY_TAB
			or key_event.physical_keycode == KEY_TAB
		):
			has_tab = true
		elif (
			key_event.keycode == KEY_L
			or key_event.physical_keycode == KEY_L
		):
			# Migrate the temporary L fallback back to the intended Tab key.
			InputMap.action_erase_event("leaderboard", event)

	if has_tab:
		return

	var leaderboard_event := InputEventKey.new()
	leaderboard_event.physical_keycode = KEY_TAB
	InputMap.action_add_event("leaderboard", leaderboard_event)
