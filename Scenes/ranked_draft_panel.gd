class_name FootballRankedDraftPanel
extends Control



const TRANSITION_SWIPE_SOUND_PATH := "res://menuopen.mp3"

var match_manager: FootballMatchManager
var ability_icon_paths: Array[String] = []

var _snapshot: Dictionary = {}
var _last_phase: StringName = &""
var _last_transition_serial: int = -1
var _transition_exit_serial: int = -1
var _transition_tween: Tween
var _panel: PanelContainer
var _title: Label
var _phase_label: Label
var _timer_label: Label
var _instruction_label: Label
var _transition_lane: Control
var _transition_card: PanelContainer
var _transition_title: Label
var _transition_subtitle: Label
var _transition_audio: AudioStreamPlayer
var _draft_body: HBoxContainer
var _enemy_title: Label
var _enemy_picks: HBoxContainer
var _team_title: Label
var _team_picks: HBoxContainer
var _vote_summary: Label
var _status_label: Label
var _blue_protect: Label
var _blue_ban: Label
var _red_protect: Label
var _red_ban: Label
var _ability_grid: GridContainer
var _ability_buttons: Array[Button] = []


func setup(
	manager: FootballMatchManager,
	icon_paths: Array[String]
) -> void:
	match_manager = manager
	ability_icon_paths = icon_paths.duplicate()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 480
	_build_interface()
	if match_manager == null:
		push_error("Ranked draft panel requires a match manager.")
		hide()
		return
	match_manager.ranked_draft_changed.connect(_on_ranked_draft_changed)
	match_manager.ability_selection_result.connect(_on_selection_result)
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()
	hide()


func _build_interface() -> void:
	var dimmer := ColorRect.new()
	dimmer.name = "DraftDimmer"
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.012, 0.012, 0.016, 0.96)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(center)

	_panel = PanelContainer.new()
	_panel.name = "RankedDraftCard"
	_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	MenuStyler.style_panel(
		_panel,
		Color(0.94, 0.94, 0.98),
		Color(0.045, 0.045, 0.052, 0.96)
	)
	center.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	_panel.add_child(margin)

	var root := VBoxContainer.new()
	root.name = "DraftContent"
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	root.add_child(header)
	_title = Label.new()
	_title.text = "RANKED ABILITY DRAFT"
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.add_theme_font_size_override("font_size", 30)
	_title.add_theme_color_override("font_color", Color(0.98, 0.98, 1.0))
	header.add_child(_title)
	_timer_label = Label.new()
	_timer_label.text = "00"
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.custom_minimum_size.x = 76.0
	_timer_label.add_theme_font_size_override("font_size", 30)
	_timer_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.28))
	header.add_child(_timer_label)

	_phase_label = Label.new()
	_phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_phase_label.add_theme_font_size_override("font_size", 18)
	_phase_label.add_theme_color_override("font_color", Color(0.82, 0.82, 0.86))
	root.add_child(_phase_label)

	_transition_lane = Control.new()
	_transition_lane.name = "PhaseIntroductionLane"
	_transition_lane.custom_minimum_size.y = 112.0
	_transition_lane.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_transition_lane.clip_contents = true
	root.add_child(_transition_lane)
	_transition_card = PanelContainer.new()
	_transition_card.name = "PhaseIntroduction"
	MenuStyler.style_panel(
		_transition_card,
		Color(1.0, 0.76, 0.26),
		Color(0.075, 0.065, 0.045, 0.98)
	)
	_transition_lane.add_child(_transition_card)
	_transition_card.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_transition_lane.resized.connect(_sync_transition_card_size)
	var transition_content := VBoxContainer.new()
	transition_content.name = "PhaseIntroductionContent"
	transition_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	transition_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	transition_content.alignment = BoxContainer.ALIGNMENT_CENTER
	transition_content.add_theme_constant_override("separation", 7)
	_transition_card.add_child(transition_content)
	_transition_title = Label.new()
	_transition_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_transition_title.add_theme_font_size_override("font_size", 28)
	_transition_title.add_theme_color_override("font_color", Color(1.0, 0.80, 0.30))
	transition_content.add_child(_transition_title)
	_transition_subtitle = Label.new()
	_transition_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_transition_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_transition_subtitle.add_theme_font_size_override("font_size", 16)
	_transition_subtitle.add_theme_color_override("font_color", Color(0.94, 0.94, 0.96))
	transition_content.add_child(_transition_subtitle)
	_transition_lane.hide()
	_sync_transition_card_size.call_deferred()

	_transition_audio = AudioStreamPlayer.new()
	_transition_audio.name = "PhaseTransitionAudio"
	_transition_audio.volume_db = -14.0
	if ResourceLoader.exists(TRANSITION_SWIPE_SOUND_PATH):
		_transition_audio.stream = load(TRANSITION_SWIPE_SOUND_PATH) as AudioStream
	add_child(_transition_audio)

	_enemy_title = Label.new()
	_enemy_title.text = "OPPONENT PICKS • HIDDEN UNTIL THE DRAFT CLOSES"
	_enemy_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_enemy_title.add_theme_font_size_override("font_size", 13)
	_enemy_title.add_theme_color_override("font_color", Color(1.0, 0.46, 0.50))
	root.add_child(_enemy_title)
	_enemy_picks = HBoxContainer.new()
	_enemy_picks.alignment = BoxContainer.ALIGNMENT_CENTER
	_enemy_picks.add_theme_constant_override("separation", 8)
	root.add_child(_enemy_picks)

	_draft_body = HBoxContainer.new()
	_draft_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_draft_body.add_theme_constant_override("separation", 12)
	root.add_child(_draft_body)
	_draft_body.add_child(_build_team_vote_card(FootballMatchManager.TEAM_BLUE))

	var center_column := VBoxContainer.new()
	center_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_column.add_theme_constant_override("separation", 7)
	_draft_body.add_child(center_column)
	_instruction_label = Label.new()
	_instruction_label.text = "Select an icon to vote or lock your hidden pick"
	_instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_instruction_label.add_theme_font_size_override("font_size", 14)
	_instruction_label.add_theme_color_override("font_color", Color(0.72, 0.72, 0.76))
	center_column.add_child(_instruction_label)

	var scroll := ScrollContainer.new()
	scroll.name = "AbilityScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	center_column.add_child(scroll)
	_ability_grid = GridContainer.new()
	_ability_grid.columns = 7
	_ability_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ability_grid.add_theme_constant_override("h_separation", 8)
	_ability_grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(_ability_grid)
	_build_ability_buttons()

	_vote_summary = Label.new()
	_vote_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vote_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_vote_summary.add_theme_font_size_override("font_size", 13)
	_vote_summary.add_theme_color_override("font_color", Color(0.76, 0.76, 0.80))
	center_column.add_child(_vote_summary)
	_draft_body.add_child(_build_team_vote_card(FootballMatchManager.TEAM_RED))

	_team_title = Label.new()
	_team_title.text = "YOUR TEAM PICKS"
	_team_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_team_title.add_theme_font_size_override("font_size", 13)
	_team_title.add_theme_color_override("font_color", Color(0.48, 0.92, 0.68))
	root.add_child(_team_title)
	_team_picks = HBoxContainer.new()
	_team_picks.alignment = BoxContainer.ALIGNMENT_CENTER
	_team_picks.add_theme_constant_override("separation", 8)
	root.add_child(_team_picks)

	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 13)
	_status_label.add_theme_color_override("font_color", Color(0.84, 0.84, 0.88))
	root.add_child(_status_label)


func _build_team_vote_card(team: StringName) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size.x = 218.0
	var accent := Color(0.30, 0.66, 1.0) if team == FootballMatchManager.TEAM_BLUE else Color(1.0, 0.34, 0.42)
	MenuStyler.style_panel(card, accent, Color(0.06, 0.06, 0.07, 0.90))
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	card.add_child(content)
	var heading := Label.new()
	heading.text = "BLUE TEAM" if team == FootballMatchManager.TEAM_BLUE else "RED TEAM"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 18)
	heading.add_theme_color_override("font_color", accent)
	content.add_child(heading)
	var protect := Label.new()
	protect.text = "PROTECT\n—"
	protect.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	protect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	protect.add_theme_font_size_override("font_size", 14)
	protect.add_theme_color_override("font_color", Color(0.42, 0.94, 0.62))
	content.add_child(protect)
	var ban := Label.new()
	ban.text = "BAN\n—"
	ban.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ban.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ban.add_theme_font_size_override("font_size", 14)
	ban.add_theme_color_override("font_color", Color(1.0, 0.42, 0.48))
	content.add_child(ban)
	if team == FootballMatchManager.TEAM_BLUE:
		_blue_protect = protect
		_blue_ban = ban
	else:
		_red_protect = protect
		_red_ban = ban
	return card


func _build_ability_buttons() -> void:
	var ordered_ids: Array[int] = []
	for role in [
		FootballPlayer.ABILITY_ROLE_ATTACK,
		FootballPlayer.ABILITY_ROLE_PLAYMAKER,
		FootballPlayer.ABILITY_ROLE_FLEXIBLE,
		FootballPlayer.ABILITY_ROLE_DEFENSE
	]:
		for ability_id in range(FootballPlayer.ABILITY_NONE + 1, FootballPlayer.ABILITY_COUNT + 1):
			if FootballPlayer.get_ability_role(ability_id) == role:
				ordered_ids.append(ability_id)
	for ability_id in ordered_ids:
		var button := Button.new()
		button.name = "RankedAbility%d" % ability_id
		button.custom_minimum_size = Vector2(66.0, 60.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.tooltip_text = "%s\n%s" % [
			FootballPlayer.get_ability_name(ability_id),
			FootballPlayer.get_ability_description(ability_id)
		]
		button.add_theme_constant_override("icon_max_width", 42)
		button.expand_icon = true
		if ability_id < ability_icon_paths.size() and ResourceLoader.exists(ability_icon_paths[ability_id]):
			button.icon = load(ability_icon_paths[ability_id]) as Texture2D
		MenuStyler.style_ability_role_button(button, _role_color(ability_id))
		button.pressed.connect(_on_ability_pressed.bind(ability_id))
		button.set_meta("ability_id", ability_id)
		_ability_grid.add_child(button)
		_ability_buttons.append(button)


func _on_ranked_draft_changed(snapshot: Dictionary) -> void:
	_snapshot = snapshot.duplicate(true)
	if not bool(_snapshot.get("active", false)):
		hide()
		return
	show()
	_refresh_from_snapshot()
	if (
		StringName(_snapshot.get("phase", &""))
		!= FootballMatchManager.RANKED_DRAFT_TRANSITION
		and not _ability_buttons.is_empty()
		and not controller_support_is_mouse_only()
	):
		_ability_buttons[0].grab_focus.call_deferred()


func _refresh_from_snapshot() -> void:
	var stage := StringName(_snapshot.get("stage", &""))
	var phase := StringName(_snapshot.get("phase", &""))
	var turn_team := StringName(_snapshot.get("turn_team", &""))
	var viewer_team := StringName(_snapshot.get("viewer_team", &""))
	var waiting_for_choices := bool(
		_snapshot.get("waiting_for_choices", false)
	)
	if phase != _last_phase:
		_status_label.text = ""
		_last_phase = phase
	_title.text = "RANKED DRAFT • %s" % _stage_name(stage)
	_timer_label.text = (
		"WAIT"
		if waiting_for_choices
		else "%02d" % int(_snapshot.get("seconds", 0))
	)
	_phase_label.text = _phase_text(phase, turn_team, viewer_team)
	var is_transition := phase == FootballMatchManager.RANKED_DRAFT_TRANSITION
	var phase_serial := int(_snapshot.get("phase_serial", -1))
	_transition_lane.visible = is_transition
	_transition_card.visible = is_transition
	_enemy_title.visible = not is_transition
	_enemy_picks.visible = not is_transition
	_draft_body.visible = not is_transition
	_team_title.visible = not is_transition
	_team_picks.visible = not is_transition
	if is_transition:
		_transition_title.text = str(_snapshot.get("transition_title", "NEXT PHASE"))
		_transition_subtitle.text = str(_snapshot.get("transition_subtitle", "Get ready."))
		if phase_serial != _last_transition_serial:
			_last_transition_serial = phase_serial
			_transition_exit_serial = -1
			_play_transition_entrance.call_deferred(phase_serial)
	else:
		_reset_transition_visual()
	_instruction_label.text = _instruction_text(phase)
	var protected := _snapshot.get("protected", {}) as Dictionary
	var banned := _snapshot.get("banned_for", {}) as Dictionary
	_blue_protect.text = "PROTECT\n%s" % _ability_name(int(protected.get(FootballMatchManager.TEAM_BLUE, 0)))
	_red_protect.text = "PROTECT\n%s" % _ability_name(int(protected.get(FootballMatchManager.TEAM_RED, 0)))
	_blue_ban.text = "BANNED FOR BLUE\n%s" % _ability_name(int(banned.get(FootballMatchManager.TEAM_BLUE, 0)))
	_red_ban.text = "BANNED FOR RED\n%s" % _ability_name(int(banned.get(FootballMatchManager.TEAM_RED, 0)))
	_refresh_pick_rows(viewer_team)
	_refresh_vote_summary(viewer_team)
	_refresh_ability_access(viewer_team, phase, turn_team)


func _refresh_pick_rows(viewer_team: StringName) -> void:
	_clear_children(_enemy_picks)
	_clear_children(_team_picks)
	var phase := StringName(_snapshot.get("phase", &""))
	var show_preferences := phase != FootballMatchManager.RANKED_DRAFT_PICK
	var picks: Array = _snapshot.get("picks", []) as Array
	for value in picks:
		if value is not Dictionary:
			continue
		var entry := value as Dictionary
		var team := StringName(entry.get("team", &""))
		var row := _team_picks if team == viewer_team else _enemy_picks
		row.add_child(
			_build_pick_chip(entry, team == viewer_team, show_preferences)
		)
	_enemy_title.text = (
		(
			"OPPONENT INTENTIONS • HIDDEN"
			if show_preferences
			else "OPPONENT PICKS • HIDDEN UNTIL THE DRAFT CLOSES"
		)
		if viewer_team in [FootballMatchManager.TEAM_BLUE, FootballMatchManager.TEAM_RED]
		else "TEAM CHOICES • HIDDEN"
	)
	_team_title.text = (
		"YOUR TEAM INTENTIONS • NOT FINAL"
		if show_preferences
		else "YOUR TEAM PICKS"
	)


func _build_pick_chip(
	entry: Dictionary,
	reveal: bool,
	show_preference: bool
) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(128.0, 48.0)
	var team := StringName(entry.get("team", &""))
	var accent := Color(0.30, 0.66, 1.0) if team == FootballMatchManager.TEAM_BLUE else Color(1.0, 0.34, 0.42)
	MenuStyler.style_panel(chip, accent, Color(0.07, 0.07, 0.08, 0.94))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	chip.add_child(row)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(34.0, 34.0)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var ability_id := int(
		entry.get("preference", -2)
		if show_preference
		else entry.get("ability", -2)
	)
	var has_choice := bool(
		entry.get("preferred", false)
		if show_preference
		else entry.get("picked", false)
	)
	if reveal and ability_id >= 0 and ability_id < ability_icon_paths.size() and ResourceLoader.exists(ability_icon_paths[ability_id]):
		icon.texture = load(ability_icon_paths[ability_id]) as Texture2D
	icon.material = null
	row.add_child(icon)
	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.text = _truncate_name(str(entry.get("name", "Player")))
	if not reveal:
		label.text += "  ?"
	elif not has_choice:
		label.text += "  …"
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.93, 0.93, 0.96))
	row.add_child(label)
	return chip


func _refresh_vote_summary(viewer_team: StringName) -> void:
	var phase := StringName(_snapshot.get("phase", &""))
	if bool(_snapshot.get("waiting_for_choices", false)):
		var missing_names: Array[String] = []
		for value in _snapshot.get("picks", []) as Array:
			if value is Dictionary:
				var entry := value as Dictionary
				if not bool(entry.get("picked", false)):
					missing_names.append(
						_truncate_name(str(entry.get("name", "Player")))
					)
		_vote_summary.text = "WAITING FOR:  " + ", ".join(missing_names)
		return
	if phase == FootballMatchManager.RANKED_DRAFT_TRANSITION:
		_vote_summary.text = "Read the next phase, then prepare your choice."
		return
	if phase == FootballMatchManager.RANKED_DRAFT_PREFERENCE:
		_vote_summary.text = "Your preference is visible only to teammates and can be changed until time expires."
		return
	var votes := _snapshot.get("votes", {}) as Dictionary
	if votes.is_empty():
		_vote_summary.text = "Your team votes appear here during your turn."
		return
	var names_by_peer: Dictionary = {}
	for value in _snapshot.get("picks", []) as Array:
		if value is Dictionary:
			var entry := value as Dictionary
			names_by_peer[int(entry.get("peer_id", 0))] = str(entry.get("name", "Player"))
	var lines: Array[String] = []
	for peer_value in votes.keys():
		var peer_id := int(peer_value)
		lines.append("%s → %s" % [
			_truncate_name(str(names_by_peer.get(peer_id, "Teammate"))),
			_ability_name(int(votes[peer_value]))
		])
	_vote_summary.text = "TEAM VOTES:  " + "   •   ".join(lines)


func _refresh_ability_access(viewer_team: StringName, phase: StringName, turn_team: StringName) -> void:
	var previous := _snapshot.get("previous_used", {}) as Dictionary
	var previous_for_team: Array = previous.get(viewer_team, []) as Array
	var banned := _snapshot.get("banned_for", {}) as Dictionary
	var protected := _snapshot.get("protected", {}) as Dictionary
	var own_ban := int(banned.get(viewer_team, FootballPlayer.ABILITY_NONE))
	var target_team := FootballMatchManager.TEAM_RED if viewer_team == FootballMatchManager.TEAM_BLUE else FootballMatchManager.TEAM_BLUE
	var target_previous: Array = previous.get(target_team, []) as Array
	var target_protected := int(protected.get(target_team, FootballPlayer.ABILITY_NONE))
	var teammate_picks: Dictionary = {}
	for value in _snapshot.get("picks", []) as Array:
		if value is not Dictionary:
			continue
		var entry := value as Dictionary
		if (
			StringName(entry.get("team", &"")) == viewer_team
			and bool(entry.get("picked", false))
			and int(entry.get("peer_id", 0)) != multiplayer.get_unique_id()
		):
			teammate_picks[int(entry.get("ability", FootballPlayer.ABILITY_NONE))] = true
	for button in _ability_buttons:
		var ability_id := int(button.get_meta("ability_id", FootballPlayer.ABILITY_NONE))
		var legal := viewer_team in [FootballMatchManager.TEAM_BLUE, FootballMatchManager.TEAM_RED]
		if phase == FootballMatchManager.RANKED_DRAFT_PREFERENCE:
			legal = legal and ability_id not in previous_for_team
		elif phase == FootballMatchManager.RANKED_DRAFT_PICK:
			legal = legal and ability_id not in previous_for_team and ability_id != own_ban and not teammate_picks.has(ability_id)
		else:
			legal = legal and viewer_team == turn_team
			if phase == FootballMatchManager.RANKED_DRAFT_PROTECT:
				legal = legal and ability_id not in previous_for_team
			elif phase == FootballMatchManager.RANKED_DRAFT_BAN:
				legal = legal and ability_id not in target_previous and ability_id != target_protected
			else:
				legal = false
		button.disabled = not legal
		button.modulate = Color.WHITE if legal else Color(0.42, 0.42, 0.45, 0.72)


func _on_ability_pressed(ability_id: int) -> void:
	if match_manager != null:
		match_manager.request_ranked_draft_choice(ability_id)


func _on_selection_result(success: bool, ability_id: int, message: String) -> void:
	if not visible:
		return
	_status_label.text = message
	_status_label.add_theme_color_override(
		"font_color",
		Color(0.48, 0.94, 0.66) if success else Color(1.0, 0.42, 0.46)
	)
	if success and ability_id > FootballPlayer.ABILITY_NONE:
		_status_label.text += "  %s" % FootballPlayer.get_ability_name(ability_id)


func _apply_responsive_layout() -> void:
	if _panel == null:
		return
	var viewport_size := get_viewport_rect().size
	_panel.custom_minimum_size = Vector2(
		clampf(viewport_size.x * 0.90, 1040.0, 1540.0),
		clampf(viewport_size.y * 0.90, 620.0, 900.0)
	)
	var compact := viewport_size.y < 800.0 or viewport_size.x < 1400.0
	_ability_grid.columns = 6 if compact else 7
	for button in _ability_buttons:
		button.custom_minimum_size = Vector2(58.0, 50.0) if compact else Vector2(66.0, 60.0)
	_title.add_theme_font_size_override("font_size", 24 if compact else 30)


func _phase_text(phase: StringName, turn_team: StringName, viewer_team: StringName) -> String:
	if bool(_snapshot.get("waiting_for_choices", false)):
		return "FINAL PICKS • WAITING FOR EVERY PLAYER"
	if phase == FootballMatchManager.RANKED_DRAFT_TRANSITION:
		return "NEXT PHASE • READ THE RULES"
	if phase == FootballMatchManager.RANKED_DRAFT_PREFERENCE:
		return "PREFERRED ABILITY • TEAM-PRIVATE • NOT A FINAL PICK"
	if phase == FootballMatchManager.RANKED_DRAFT_PICK:
		return "HIDDEN PICK • choose a legal ability before time expires"
	var action := "PROTECT" if phase == FootballMatchManager.RANKED_DRAFT_PROTECT else "BAN"
	var team_name := "BLUE" if turn_team == FootballMatchManager.TEAM_BLUE else "RED"
	return "%s TEAM %s VOTE%s" % [
		team_name,
		action,
		" • YOUR TURN" if viewer_team == turn_team else ""
	]


func _instruction_text(phase: StringName) -> String:
	if bool(_snapshot.get("waiting_for_choices", false)):
		return "The match will begin as soon as every active player locks an ability."
	match phase:
		FootballMatchManager.RANKED_DRAFT_TRANSITION:
			return "Choices are paused during the introduction."
		FootballMatchManager.RANKED_DRAFT_PREFERENCE:
			return "Choose what you want to play so teammates can plan their Protect and Ban votes."
		FootballMatchManager.RANKED_DRAFT_PICK:
			return "Lock your final ability. Teammates can see it; opponents cannot."
		FootballMatchManager.RANKED_DRAFT_PROTECT:
			return "Vote to protect one intended ability from the opponent's ban."
		FootballMatchManager.RANKED_DRAFT_BAN:
			return "Vote to ban one unprotected opponent ability."
	return "Waiting for the next Ranked phase."


func _play_transition_entrance(phase_serial: int) -> void:
	if (
		not visible
		or not _transition_card.visible
		or int(_snapshot.get("phase_serial", -1)) != phase_serial
	):
		return
	if _transition_tween != null and _transition_tween.is_valid():
		_transition_tween.kill()
	_sync_transition_card_size()
	var travel_distance := maxf(
		_transition_lane.size.x,
		_transition_card.size.x
	) + 48.0
	_transition_card.position.x = -travel_distance
	_transition_card.scale = Vector2.ONE
	_transition_card.modulate = Color.WHITE
	_transition_title.modulate = Color.WHITE
	_play_transition_swipe_sound(false)
	_transition_tween = create_tween()
	_transition_tween.tween_property(
		_transition_card,
		"position:x",
		0.0,
		0.42
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	_transition_tween.tween_interval(4.0)
	_transition_tween.tween_callback(
		_play_transition_exit_if_current.bind(phase_serial)
	)


func _play_transition_exit_if_current(phase_serial: int) -> void:
	if (
		not visible
		or StringName(_snapshot.get("phase", &""))
		!= FootballMatchManager.RANKED_DRAFT_TRANSITION
		or int(_snapshot.get("phase_serial", -1)) != phase_serial
		or _transition_exit_serial == phase_serial
	):
		return
	_transition_exit_serial = phase_serial
	_play_transition_exit()


func _play_transition_exit() -> void:
	if not _transition_card.visible:
		return
	if _transition_tween != null and _transition_tween.is_valid():
		_transition_tween.kill()
	var travel_distance := maxf(
		_transition_lane.size.x,
		_transition_card.size.x
	) + 48.0
	_play_transition_swipe_sound(true)
	_transition_tween = create_tween()
	_transition_tween.tween_property(
		_transition_card,
		"position:x",
		travel_distance,
		0.42
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)


func _play_transition_swipe_sound(exiting: bool) -> void:
	if _transition_audio == null or _transition_audio.stream == null:
		return
	_transition_audio.stop()
	_transition_audio.pitch_scale = 0.94 if exiting else 1.04
	_transition_audio.volume_db = -16.0 if exiting else -14.0
	_transition_audio.play()


func _reset_transition_visual() -> void:
	if _transition_tween != null and _transition_tween.is_valid():
		_transition_tween.kill()
	_transition_tween = null
	_transition_card.position.x = 0.0
	_transition_card.scale = Vector2.ONE
	_transition_card.modulate = Color.WHITE
	_transition_title.modulate = Color.WHITE
	_sync_transition_card_size()


func _sync_transition_card_size() -> void:
	if _transition_lane == null or _transition_card == null:
		return
	var lane_size := _transition_lane.size
	if lane_size.x <= 0.0 or lane_size.y <= 0.0:
		return
	_transition_card.size = lane_size


func _stage_name(stage: StringName) -> String:
	match stage:
		FootballMatchManager.RANKED_STAGE_GAME_ONE:
			return "GAME 1"
		FootballMatchManager.RANKED_STAGE_GAME_TWO:
			return "GAME 2 • NEW ABILITIES REQUIRED"
		FootballMatchManager.RANKED_STAGE_EXTRA_TIME:
			return "EXTRA TIME • NEW ABILITIES REQUIRED"
	return "RANKED"


func _ability_name(ability_id: int) -> String:
	return "—" if ability_id <= FootballPlayer.ABILITY_NONE else FootballPlayer.get_ability_name(ability_id)


func _role_color(ability_id: int) -> Color:
	match FootballPlayer.get_ability_role(ability_id):
		FootballPlayer.ABILITY_ROLE_ATTACK:
			return Color(1.0, 0.42, 0.34)
		FootballPlayer.ABILITY_ROLE_PLAYMAKER:
			return Color(0.78, 0.48, 0.96)
		FootballPlayer.ABILITY_ROLE_FLEXIBLE:
			return Color(0.60, 0.90, 0.42)
	return Color(0.30, 0.68, 1.0)


func _clear_children(container: Container) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _truncate_name(value: String) -> String:
	return value if value.length() <= 13 else value.left(12) + "…"


func controller_support_is_mouse_only() -> bool:
	var controller_support := get_node_or_null("/root/ControllerSupport")
	return controller_support == null or not bool(controller_support.get("using_controller"))
