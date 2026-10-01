class_name ChampionsLeagueDraftPanel
extends CanvasLayer


const CARD_SCENE: PackedScene = preload("res://Scenes/champions_league_card.tscn")
const PULSE_SOUND: AudioStream = preload("res://menuopen.mp3")

var manager: FootballMatchManager
var _hand: Array[int] = []
var _kind: StringName = FootballMatchManager.DRAFT_KIND_ABILITY
var _viewer_team: StringName = FootballMatchManager.TEAM_RED
var _selected: int = -1
var _last_seconds: int = -1
var _pulse_played: bool = false
var _cards: Array[ChampionsLeagueCard] = []
var _pulse_audio: AudioStreamPlayer
var _draft_was_active: bool = false
var _overlay_generation: int = 0
var _summary_mode: bool = false
var _summary_ability_id: int = -1
var _summary_perk_id: int = -1

@onready var pause_snapshot: TextureRect = $Control/PauseSnapshot
@onready var timer_label: Label = $Control/CenterContainer/VBoxContainer/TimerLabel
@onready var title_label: Label = $Control/CenterContainer/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $Control/CenterContainer/VBoxContainer/SubtitleLabel
@onready var card_container: HBoxContainer = $Control/CenterContainer/VBoxContainer/CardContainer
@onready var team_picks: VBoxContainer = $Control/CenterContainer/VBoxContainer/TeamPicksDisplay


func _ready() -> void:
	if manager == null:
		manager = get_tree().root.find_child("MatchManager", true, false) as FootballMatchManager
	if manager == null:
		push_error("Draft panel could not find MatchManager.")
		queue_free()
		return
	_pulse_audio = AudioStreamPlayer.new()
	_pulse_audio.stream = PULSE_SOUND
	_pulse_audio.volume_db = -8.0
	add_child(_pulse_audio)
	manager.draft_state_changed.connect(_on_draft_state_changed)
	card_container.add_theme_constant_override("separation", 28)
	set_process(true)
	hide()


func _on_draft_state_changed(snapshot: Dictionary) -> void:
	var active: bool = bool(snapshot.get("active", false))
	if not active:
		_draft_was_active = false
		_overlay_generation += 1
		hide()
		_clear_pause_snapshot()
		return
	if not _draft_was_active:
		_draft_was_active = true
		_overlay_generation += 1
		_hide_menu_layers_for_draft()
		if DisplayServer.get_name() == "headless":
			show()
		else:
			hide()
			_show_after_clean_background_frame(_overlay_generation)
	var stage := StringName(snapshot.get("stage", FootballMatchManager.DRAFT_STAGE_NONE))
	var incoming_kind := StringName(snapshot.get("kind", FootballMatchManager.DRAFT_KIND_ABILITY))
	var seconds: int = int(snapshot.get("seconds", 0))
	var review_active: bool = bool(snapshot.get("review", false))
	var ability_pick: int = int(snapshot.get("ability_pick", -1))
	var perk_pick: int = int(snapshot.get("perk_pick", -1))
	var stage_text := "LEG 1" if stage == FootballMatchManager.DRAFT_STAGE_LEG_ONE else "LEG 2"
	_selected = int(snapshot.get("selected", -1))
	var show_summary := (
		incoming_kind == FootballMatchManager.DRAFT_KIND_PERK
		and ability_pick >= 0
		and perk_pick > 0
		and (_selected >= 0 or review_active)
	)
	if show_summary:
		title_label.text = "YOUR DRAFT PICKS"
		subtitle_label.text = (
			"LOCKED IN  •  MATCH STARTING"
			if review_active
			else "LOCKED IN  •  WAITING FOR THE OTHER PLAYERS"
		)
		timer_label.text = (
			"MATCH STARTS IN  •  %02d" % seconds
			if review_active
			else "%s  •  %02d" % [stage_text, seconds]
		)
	else:
		var kind_text := "PERK DRAFT" if incoming_kind == FootballMatchManager.DRAFT_KIND_PERK else "ABILITY DRAFT"
		title_label.text = kind_text
		subtitle_label.text = (
			"REVEAL YOUR PERKS  •  CLICK AGAIN TO LOCK YOUR PICK"
			if incoming_kind == FootballMatchManager.DRAFT_KIND_PERK
			else "REVEAL YOUR HAND  •  CLICK AGAIN TO CHOOSE FOR %s" % stage_text
		)
		timer_label.text = "%s  •  %02d" % [stage_text, seconds]
	if seconds > 5:
		_pulse_played = false
	if review_active and _pulse_audio.playing:
		_pulse_audio.stop()
	if seconds <= 5 and seconds != _last_seconds and not review_active:
		_pulse_audio.pitch_scale = (
			1.0 + float(5 - seconds) * 0.08
		) * 1.70
		_pulse_audio.play()
		_pulse_played = true
	_last_seconds = seconds
	var incoming_team := StringName(snapshot.get("team", FootballMatchManager.TEAM_RED))
	if show_summary:
		team_picks.hide()
		if (
			not _summary_mode
			or ability_pick != _summary_ability_id
			or perk_pick != _summary_perk_id
			or incoming_team != _viewer_team
		):
			_summary_mode = true
			_summary_ability_id = ability_pick
			_summary_perk_id = perk_pick
			_viewer_team = incoming_team
			_rebuild_summary_cards()
		return
	team_picks.show()
	_summary_mode = false
	_summary_ability_id = -1
	_summary_perk_id = -1
	var incoming_hand: Array[int] = []
	for value: Variant in snapshot.get("hand", []) as Array:
		incoming_hand.append(int(value))
	if incoming_hand != _hand or incoming_kind != _kind or incoming_team != _viewer_team:
		_kind = incoming_kind
		_viewer_team = incoming_team
		_hand = incoming_hand
		_rebuild_cards()
	else:
		_refresh_card_states()
	_rebuild_team_picks(snapshot.get("picks", []) as Array)


func _process(_delta: float) -> void:
	_update_active_card_indicator()


func _update_active_card_indicator() -> void:
	if not visible or _summary_mode or _selected >= 0 or _cards.is_empty():
		for card: ChampionsLeagueCard in _cards:
			if is_instance_valid(card):
				card.set_indicator_active(false)
		return
	var active_card: ChampionsLeagueCard = null
	for card: ChampionsLeagueCard in _cards:
		if is_instance_valid(card) and card.is_pointer_hovered():
			active_card = card
			break
	if active_card == null:
		for card: ChampionsLeagueCard in _cards:
			if is_instance_valid(card) and card.has_focus():
				active_card = card
				break
	for card: ChampionsLeagueCard in _cards:
		if is_instance_valid(card):
			card.set_indicator_active(card == active_card)


func _rebuild_cards() -> void:
	for child in card_container.get_children():
		child.queue_free()
	_cards.clear()
	for index in range(_hand.size()):
		var card := CARD_SCENE.instantiate() as ChampionsLeagueCard
		var available_width := maxf(650.0, get_viewport().get_visible_rect().size.x - 70.0)
		var card_width := clampf((available_width - 112.0) / 5.0, 128.0, 188.0)
		var card_size := Vector2(
			card_width,
			306.0 if card_width < 160.0 else 330.0
		)
		var card_slot := Control.new()
		card_slot.name = "CardSlot%d" % index
		card_slot.custom_minimum_size = card_size
		card_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_container.add_child(card_slot)
		card.custom_minimum_size = card_size
		card.size = card_size
		card.set_card_data(_kind, _hand[index])
		card.set_team(_viewer_team)
		card.pressed.connect(_on_card_pressed.bind(card, _hand[index]))
		card.modulate.a = 0.0
		card.scale = Vector2(0.76, 0.76)
		card.rotation = 0.0
		card.pivot_offset = card_size * 0.5
		card_slot.add_child(card)
		card.set_revealed(false, true)
		_cards.append(card)
		var tween := create_tween()
		tween.set_parallel(true)
		var delay := float(index) * 0.13
		tween.tween_property(card, "modulate:a", 1.0, 0.24).set_delay(delay)
		tween.tween_property(card, "scale", Vector2.ONE, 0.36).set_delay(delay).set_trans(Tween.TRANS_BACK)
		tween.tween_property(card, "rotation", 0.0, 0.28).set_delay(delay).set_trans(Tween.TRANS_QUAD)
	_refresh_card_states()
	if not _cards.is_empty():
		_cards[0].grab_focus.call_deferred()


func _rebuild_summary_cards() -> void:
	for child in card_container.get_children():
		child.queue_free()
	_cards.clear()
	var picks: Array[Dictionary] = [
		{
			"kind": FootballMatchManager.DRAFT_KIND_ABILITY,
			"id": _summary_ability_id,
		},
		{
			"kind": FootballMatchManager.DRAFT_KIND_PERK,
			"id": _summary_perk_id,
		},
	]
	for index in range(picks.size()):
		var pick: Dictionary = picks[index]
		var card := CARD_SCENE.instantiate() as ChampionsLeagueCard
		var card_size := Vector2(188.0, 330.0)
		var card_slot := Control.new()
		card_slot.name = "PickedCardSlot%d" % index
		card_slot.custom_minimum_size = card_size
		card_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_container.add_child(card_slot)
		card.custom_minimum_size = card_size
		card.size = card_size
		card.set_card_data(StringName(pick.get("kind", FootballMatchManager.DRAFT_KIND_ABILITY)), int(pick.get("id", -1)))
		card.set_team(_viewer_team)
		card.disabled = true
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.modulate.a = 0.0
		card.scale = Vector2(0.88, 0.88)
		card.rotation = 0.0
		card.pivot_offset = card_size * 0.5
		card_slot.add_child(card)
		card.set_revealed(true, true)
		card.set_selected(true)
		_cards.append(card)
		var tween := create_tween()
		tween.set_parallel(true)
		var delay := float(index) * 0.12
		tween.tween_property(card, "modulate:a", 1.0, 0.22).set_delay(delay)
		tween.tween_property(card, "scale", Vector2.ONE, 0.32).set_delay(delay).set_trans(Tween.TRANS_BACK)


func _hide_menu_layers_for_draft() -> void:
	if manager == null or manager.get_parent() == null:
		return
	for path: NodePath in [
		NodePath("HUD/Teamselection"),
		NodePath("HUD/ConnectionMenu"),
	]:
		var menu := manager.get_parent().get_node_or_null(path) as CanvasItem
		if menu != null:
			menu.hide()


func _show_after_clean_background_frame(generation: int) -> void:
	# Team selection and connection menus hide in the same signal dispatch that
	# opens the draft. Waiting for the next rendered frame prevents the snapshot
	# from freezing the previous lobby frame behind the cards.
	await RenderingServer.frame_post_draw
	if generation != _overlay_generation or not _draft_was_active:
		return
	_refresh_pause_snapshot()
	show()


func _refresh_pause_snapshot() -> void:
	if pause_snapshot == null:
		return
	# The dummy headless renderer has no readable viewport texture. Keeping this
	# path quiet also lets automated match-flow tests exercise the draft normally.
	if DisplayServer.get_name() == "headless":
		pause_snapshot.texture = null
		return
	var viewport_texture: ViewportTexture = get_viewport().get_texture()
	if viewport_texture == null:
		pause_snapshot.texture = null
		return
	var image: Image = viewport_texture.get_image()
	if image == null or image.is_empty():
		pause_snapshot.texture = null
		return
	var source_size: Vector2i = image.get_size()
	if source_size.x <= 0 or source_size.y <= 0:
		pause_snapshot.texture = null
		return
	# This is the same detached, low-resolution softening used by the pause menu.
	image.resize(
		maxi(1, source_size.x / 10),
		maxi(1, source_size.y / 10),
		Image.INTERPOLATE_LANCZOS
	)
	pause_snapshot.texture = ImageTexture.create_from_image(image)


func _clear_pause_snapshot() -> void:
	if pause_snapshot != null:
		pause_snapshot.texture = null


func _on_card_pressed(card: ChampionsLeagueCard, ability_id: int) -> void:
	if _selected >= 0:
		return
	if card != null and not card.is_revealed():
		card.set_revealed(true)
		return
	manager.request_draft_pick(ability_id)


func _refresh_card_states() -> void:
	for card: ChampionsLeagueCard in _cards:
		card.set_selected(card.ability_id == _selected)
		card.disabled = _selected >= 0
		card.visible = true
		if _selected >= 0:
			card.modulate.a = 1.0 if card.ability_id == _selected else 0.24
	_update_active_card_indicator()


func _rebuild_team_picks(entries: Array) -> void:
	for child in team_picks.get_children():
		child.queue_free()
	for value: Variant in entries:
		if value is not Dictionary:
			continue
		var entry := value as Dictionary
		if not bool(entry.get("picked", false)):
			continue
		var ability_id: int = int(entry.get("ability", -1))
		# Hidden/locked cards intentionally do not reveal which card was chosen.
		# They also no longer need a status line in the draft feed; only completed
		# revealed picks are useful information here.
		if ability_id < 0:
			continue
		var label := Label.new()
		var picked_name := (
			str(FootballMatchManager.get_draft_perk_definition(ability_id).get("name", "Perk"))
			if _kind == FootballMatchManager.DRAFT_KIND_PERK
			else FootballPlayer.get_ability_name(ability_id)
		)
		label.text = "%s picked %s" % [
			str(entry.get("name", "Teammate")),
			picked_name,
		]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		team_picks.add_child(label)
