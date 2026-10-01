class_name FootballMobileWebControls
extends Control


@export var match_manager: FootballMatchManager
@export var players_parent: Node2D

const JOYSTICK_RADIUS: float = 76.0
const JOYSTICK_KNOB_RADIUS: float = 31.0
const JOYSTICK_DEADZONE: float = 0.13
const TOUCH_EDGE_INSET: float = 34.0
const CONTROL_ALPHA_IDLE: float = 0.48
const CONTROL_ALPHA_ACTIVE: float = 0.82

const MOVE_LEFT: StringName = &"move_left"
const MOVE_RIGHT: StringName = &"move_right"
const MOVE_UP: StringName = &"move_up"
const MOVE_DOWN: StringName = &"move_down"

var _touch_runtime: bool = false
var _mobile_web_build: bool = false
var _next_mobile_ai_profile_scan_msec: int = 0
var _joystick_touch_id: int = -1
var _joystick_origin := Vector2.ZERO
var _joystick_value := Vector2.ZERO
var _button_touches: Dictionary = {}
var _action_touch_counts: Dictionary = {}
var _mobile_hud_configured: bool = false
var _replay_skip_sent: bool = false
var _last_replay_active: bool = false
var _last_local_controls_enabled: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Gameplay touch is handled from raw viewport input instead of GUI routing.
	# This prevents HUD Controls from swallowing iPhone multitouch events before
	# the joystick/action overlay sees them.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	_mobile_web_build = OS.has_feature("mobile_web")
	_touch_runtime = _is_touch_web_runtime()
	visible = false
	if _mobile_web_build:
		_configure_mobile_match_ai()
		call_deferred("_refresh_mobile_ai_profile", true)
	if not _touch_runtime:
		# Keep a very light process tick on the Mobile Web export so CPUs spawned
		# later still receive the mobile AI profile, even when the demo is opened
		# from a non-touch browser for testing.
		set_process(_mobile_web_build)
		set_process_input(false)
		return

	# Menu Controls benefit from touch-to-mouse emulation, but gameplay cannot keep
	# it enabled because the desktop left-mouse binding is Shoot. The visibility
	# refresh below turns emulation off while the multitouch gameplay overlay is
	# active, then restores it for menus/pause screens.
	Input.emulate_mouse_from_touch = true
	set_process(true)
	set_process_input(true)
	resized.connect(queue_redraw)
	call_deferred("_refresh_visibility")


func _process(_delta: float) -> void:
	if _mobile_web_build:
		_refresh_mobile_ai_profile()
	if not _touch_runtime:
		return
	var replay_active := (
		match_manager != null and match_manager.goal_replay_active
	)
	var controls_enabled := _local_controls_enabled()
	if replay_active != _last_replay_active:
		_release_all_touch_actions()
		if not replay_active:
			_replay_skip_sent = false
		_last_replay_active = replay_active
		queue_redraw()
	if controls_enabled != _last_local_controls_enabled:
		if not controls_enabled:
			_release_all_touch_actions()
		_last_local_controls_enabled = controls_enabled
		queue_redraw()
	_refresh_visibility()


func _configure_mobile_match_ai() -> void:
	if match_manager == null:
		return
	# The shared sequence planner is one of the largest high-level team lookahead
	# systems. No mobile CPU needs it, so shut it off centrally as well as on each
	# controller. Desktop/native builds never execute this mobile-only script path.
	match_manager.cpu_team_sequence_planner_enabled = false


func _refresh_mobile_ai_profile(force: bool = false) -> void:
	if not _mobile_web_build or players_parent == null:
		return
	var now_msec := Time.get_ticks_msec()
	if not force and now_msec < _next_mobile_ai_profile_scan_msec:
		return
	# CPUs can be created after this HUD node. A sub-second scan is effectively
	# free for a 12-player roster and guarantees late/replaced bots get profiled.
	_next_mobile_ai_profile_scan_msec = now_msec + 750
	for child: Node in players_parent.get_children():
		var player := child as FootballPlayer
		if player == null or not player.cpu_controlled:
			continue
		var controller := player.get_node_or_null("CPUController")
		if controller == null or controller.has_meta("mobile_web_ai_profile"):
			continue
		_apply_mobile_ai_profile(controller)
		controller.set_meta("mobile_web_ai_profile", true)


func _apply_mobile_ai_profile(controller: Node) -> void:
	# Mobile keeps the reliable 60 Hz movement/physics/execution layer, but uses a
	# deliberately cheaper tactical brain. INT 10 also avoids the expensive elite
	# branches while still producing competent basic football.
	controller.set("skill_level_override", 10)
	controller.set("perfect_execution_mode", false)
	controller.set("decision_interval", 0.14)
	controller.set("decision_interval_jitter", 0.012)
	controller.set("high_tempo_thinking_enabled", false)
	controller.set("high_tempo_extra_pass_plans", 0)
	controller.set("high_tempo_extra_goal_samples", 0)

	# Expensive advisory/coordination layers are unnecessary for the phone demo.
	# Their normal legacy football fallbacks remain active.
	controller.set("hybrid_tactical_policy_enabled", false)
	controller.set("hybrid_team_size_checkpoints_enabled", false)
	controller.set("value_attacking_planner_enabled", false)
	controller.set("shared_team_sequence_enabled", false)
	controller.set("opponent_ability_awareness_enabled", false)
	controller.set("shared_ability_team_plan_enabled", false)
	controller.set("cpu_first_touch_enabled", false)
	controller.set("live_shot_retarget_enabled", false)
	controller.set("pre_shot_reader_enabled", false)

	# Preserve the existing large-team spacing/anti-swarm system, but reuse its
	# cached answers longer so support players do fewer repeated spatial scans.
	controller.set("large_team_shape_cache_seconds", 0.42)
	controller.set("large_team_second_ball_cache_seconds", 0.18)
	controller.set("large_team_release_pass_scan_seconds", 0.18)
	controller.set("pass_request_minimum_interval", 3.5)
	controller.set("pass_request_maximum_interval", 6.0)


func _refresh_visibility() -> void:
	if not _touch_runtime:
		return
	var should_show := _has_local_human_in_active_match()
	# Prevent generic taps from becoming left-click/Shoot while playing. Normal
	# Control nodes in menus/pause screens get mouse-style tap compatibility back
	# as soon as this gameplay overlay hides.
	Input.emulate_mouse_from_touch = not should_show
	if should_show != visible:
		if not should_show:
			_release_all_touch_actions()
		visible = should_show
		queue_redraw()
	if should_show and not _mobile_hud_configured:
		_configure_mobile_hud_once()


func _has_local_human_in_active_match() -> bool:
	if (
		match_manager == null
		or players_parent == null
		or not match_manager.game_has_started
		or get_tree().paused
	):
		return false
	return _get_local_human_player() != null


func _get_local_human_player() -> FootballPlayer:
	if players_parent == null:
		return null
	var local_peer_id := multiplayer.get_unique_id()
	for child: Node in players_parent.get_children():
		var player := child as FootballPlayer
		if player == null:
			continue
		if (
			not player.cpu_controlled
			and player.owner_peer_id == local_peer_id
			and (player.team == &"red" or player.team == &"blue")
		):
			return player
	return null


func _local_controls_enabled() -> bool:
	var player := _get_local_human_player()
	return player != null and player.controls_enabled


func _input(event: InputEvent) -> void:
	if not visible:
		return

	# Read touch directly from the viewport. On mobile Web, relying on
	# Control._gui_input() is fragile because any HUD Control above/under this
	# overlay can win the GUI hit test and consume one finger of a multitouch
	# gesture. Raw screen events keep joystick + buttons reliable together.
	var touch := event as InputEventScreenTouch
	if touch != null:
		if touch.pressed:
			_on_touch_pressed(touch.index, touch.position)
		else:
			_on_touch_released(touch.index)
		get_viewport().set_input_as_handled()
		return

	var drag := event as InputEventScreenDrag
	if drag != null:
		_on_touch_dragged(drag.index, drag.position)
		get_viewport().set_input_as_handled()


func _on_touch_pressed(touch_id: int, position: Vector2) -> void:
	if _is_portrait_layout():
		return

	var button := _button_at(position)
	if not button.is_empty():
		var action := StringName(button.get("action", &""))
		if action == &"pause":
			_send_pause_toggle()
			_button_touches[touch_id] = action
			queue_redraw()
			return
		if action == &"replay_skip":
			_request_replay_skip()
			_button_touches[touch_id] = action
			queue_redraw()
			return
		if not _local_controls_enabled():
			return
		if action != &"":
			_button_touches[touch_id] = action
			_press_touch_action(action)
			queue_redraw()
			return

	if match_manager != null and match_manager.goal_replay_active:
		return
	if not _local_controls_enabled():
		return

	# A floating joystick makes the same layout comfortable on small phones,
	# large iPhones, and tablets while still keeping the visual resting position
	# predictable. Only the lower-left play region can claim movement.
	if (
		_joystick_touch_id < 0
		and position.x <= size.x * 0.46
		and position.y >= size.y * 0.30
	):
		_joystick_touch_id = touch_id
		_joystick_origin = _clamp_joystick_origin(position)
		_update_joystick(position)
		queue_redraw()


func _on_touch_dragged(touch_id: int, position: Vector2) -> void:
	if touch_id == _joystick_touch_id:
		_update_joystick(position)
		queue_redraw()


func _on_touch_released(touch_id: int) -> void:
	if touch_id == _joystick_touch_id:
		_joystick_touch_id = -1
		_joystick_value = Vector2.ZERO
		_release_movement_actions()
		queue_redraw()
		return

	if not _button_touches.has(touch_id):
		return
	var action := StringName(_button_touches[touch_id])
	_button_touches.erase(touch_id)
	if action != &"pause" and action != &"replay_skip":
		_release_touch_action(action)
	queue_redraw()


func _press_touch_action(action: StringName) -> void:
	var count := int(_action_touch_counts.get(action, 0)) + 1
	_action_touch_counts[action] = count
	if count == 1:
		Input.action_press(action)


func _release_touch_action(action: StringName) -> void:
	var count := maxi(0, int(_action_touch_counts.get(action, 0)) - 1)
	if count <= 0:
		_action_touch_counts.erase(action)
		Input.action_release(action)
	else:
		_action_touch_counts[action] = count


func _update_joystick(position: Vector2) -> void:
	var delta := position - _joystick_origin
	var normalized := delta / JOYSTICK_RADIUS
	if normalized.length() > 1.0:
		normalized = normalized.normalized()
	var magnitude := normalized.length()
	if magnitude <= JOYSTICK_DEADZONE:
		_joystick_value = Vector2.ZERO
	else:
		var remapped := (
			(magnitude - JOYSTICK_DEADZONE)
			/ (1.0 - JOYSTICK_DEADZONE)
		)
		_joystick_value = normalized.normalized() * remapped
	_apply_joystick_actions()


func _apply_joystick_actions() -> void:
	_release_movement_actions()
	if _joystick_value.x < 0.0:
		Input.action_press(MOVE_LEFT, absf(_joystick_value.x))
	elif _joystick_value.x > 0.0:
		Input.action_press(MOVE_RIGHT, _joystick_value.x)
	if _joystick_value.y < 0.0:
		Input.action_press(MOVE_UP, absf(_joystick_value.y))
	elif _joystick_value.y > 0.0:
		Input.action_press(MOVE_DOWN, _joystick_value.y)


func _release_movement_actions() -> void:
	Input.action_release(MOVE_LEFT)
	Input.action_release(MOVE_RIGHT)
	Input.action_release(MOVE_UP)
	Input.action_release(MOVE_DOWN)


func _release_all_touch_actions() -> void:
	_release_movement_actions()
	for action_variant: Variant in _action_touch_counts.keys():
		Input.action_release(StringName(action_variant))
	_action_touch_counts.clear()
	_button_touches.clear()
	_joystick_touch_id = -1
	_joystick_value = Vector2.ZERO


func _send_pause_toggle() -> void:
	if match_manager == null:
		return
	var pause_overlay := match_manager.get_node_or_null("IngamePauseOverlay")
	if pause_overlay != null and pause_overlay.has_method("request_mobile_toggle"):
		pause_overlay.call("request_mobile_toggle")


func _request_replay_skip() -> void:
	if (
		match_manager == null
		or not match_manager.goal_replay_active
		or _replay_skip_sent
	):
		return
	_replay_skip_sent = true
	match_manager.request_skip_goal_replay()


func _button_at(position: Vector2) -> Dictionary:
	for button: Dictionary in _button_layout():
		var center := button.get("center", Vector2.ZERO) as Vector2
		var radius := float(button.get("radius", 0.0))
		if center.distance_squared_to(position) <= radius * radius:
			return button
	return {}


func _button_layout() -> Array[Dictionary]:
	var w := size.x
	var h := size.y
	if match_manager != null and match_manager.goal_replay_active:
		return [
			{
				"action": &"replay_skip",
				"label": "VOTED" if _replay_skip_sent else "SKIP",
				"center": Vector2(w - 120.0, h - 105.0),
				"radius": 55.0,
				"accent": Color(0.36, 0.88, 1.0, 1.0),
			},
			{
				"action": &"pause",
				"label": "Ⅱ",
				"center": Vector2(w - 63.0, 55.0),
				"radius": 30.0,
				"accent": Color(0.92, 0.95, 1.0, 1.0),
			},
		]
	return [
		{
			"action": &"shoot",
			"label": "SHOT",
			"center": Vector2(w - 105.0, h - 100.0),
			"radius": 53.0,
			"accent": Color(1.0, 0.42, 0.28, 1.0),
		},
		{
			"action": &"ability",
			"label": "ABILITY",
			"center": Vector2(w - 168.0, h - 205.0),
			"radius": 43.0,
			"accent": Color(0.72, 0.46, 1.0, 1.0),
		},
		{
			"action": &"soft_pass",
			"label": "PASS",
			"center": Vector2(w - 230.0, h - 91.0),
			"radius": 43.0,
			"accent": Color(0.28, 0.82, 1.0, 1.0),
		},
		{
			"action": &"request_pass",
			"label": "CALL",
			"center": Vector2(w - 284.0, h - 181.0),
			"radius": 35.0,
			"accent": Color(0.38, 1.0, 0.64, 1.0),
		},
		{
			"action": &"pause",
			"label": "Ⅱ",
			"center": Vector2(w - 63.0, 55.0),
			"radius": 30.0,
			"accent": Color(0.92, 0.95, 1.0, 1.0),
		},
	]


func _draw() -> void:
	if not visible:
		return
	if _is_portrait_layout():
		_draw_rotate_prompt()
		return

	if match_manager == null or not match_manager.goal_replay_active:
		if _local_controls_enabled():
			_draw_joystick()
	for button: Dictionary in _button_layout():
		_draw_action_button(button)


func _draw_joystick() -> void:
	var center := (
		_joystick_origin
		if _joystick_touch_id >= 0
		else _default_joystick_center()
	)
	var idle_color := Color(0.025, 0.04, 0.055, CONTROL_ALPHA_IDLE)
	var ring_color := Color(0.82, 0.9, 1.0, 0.56)
	draw_circle(center, JOYSTICK_RADIUS, idle_color, true, -1.0, true)
	draw_arc(center, JOYSTICK_RADIUS, 0.0, TAU, 72, ring_color, 2.3, true)

	var knob_center := center + _joystick_value * (JOYSTICK_RADIUS - JOYSTICK_KNOB_RADIUS)
	var knob_alpha := CONTROL_ALPHA_ACTIVE if _joystick_touch_id >= 0 else 0.58
	draw_circle(
		knob_center,
		JOYSTICK_KNOB_RADIUS,
		Color(0.60, 0.78, 1.0, knob_alpha),
		true,
		-1.0,
		true
	)
	draw_arc(
		knob_center,
		JOYSTICK_KNOB_RADIUS,
		0.0,
		TAU,
		48,
		Color(0.9, 0.96, 1.0, 0.82),
		1.8,
		true
	)


func _draw_action_button(button: Dictionary) -> void:
	var action := StringName(button.get("action", &""))
	var center := button.get("center", Vector2.ZERO) as Vector2
	var radius := float(button.get("radius", 0.0))
	var accent := button.get("accent", Color.WHITE) as Color
	var active := int(_action_touch_counts.get(action, 0)) > 0
	var fill_alpha := CONTROL_ALPHA_ACTIVE if active else CONTROL_ALPHA_IDLE
	var fill := Color(0.02, 0.028, 0.042, fill_alpha)
	if active:
		fill = accent
		fill.a = 0.43
	draw_circle(center, radius, fill, true, -1.0, true)
	var outline := accent
	outline.a = 0.95 if active else 0.68
	draw_arc(center, radius, 0.0, TAU, 56, outline, 2.4 if active else 1.7, true)

	var label := str(button.get("label", ""))
	var font_size := 17 if radius >= 40.0 else 19
	if label == "ABILITY":
		font_size = 13
	_draw_centered_label(center, label, font_size, Color(0.97, 0.98, 1.0, 0.94))


func _draw_centered_label(
	center: Vector2,
	text: String,
	font_size: int,
	color: Color
) -> void:
	var font := get_theme_default_font()
	if font == null:
		return
	var text_size := font.get_string_size(
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size
	)
	var baseline := center + Vector2(
		-text_size.x * 0.5,
		text_size.y * 0.34
	)
	draw_string(
		font,
		baseline,
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		font_size,
		color
	)


func _draw_rotate_prompt() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.008, 0.012, 0.02, 0.94), true)
	var center := size * 0.5
	_draw_centered_label(center - Vector2(0.0, 24.0), "ROTATE DEVICE", 31, Color.WHITE)
	_draw_centered_label(
		center + Vector2(0.0, 22.0),
		"THEODORE BALL PLAYS IN LANDSCAPE",
		16,
		Color(0.72, 0.8, 0.9, 1.0)
	)


func _default_joystick_center() -> Vector2:
	return Vector2(
		maxf(122.0, TOUCH_EDGE_INSET + JOYSTICK_RADIUS),
		size.y - maxf(105.0, TOUCH_EDGE_INSET + JOYSTICK_RADIUS)
	)


func _clamp_joystick_origin(position: Vector2) -> Vector2:
	var minimum := Vector2(
		TOUCH_EDGE_INSET + JOYSTICK_RADIUS,
		TOUCH_EDGE_INSET + JOYSTICK_RADIUS
	)
	var maximum := Vector2(
		maxf(minimum.x, size.x * 0.46 - JOYSTICK_RADIUS),
		maxf(minimum.y, size.y - TOUCH_EDGE_INSET - JOYSTICK_RADIUS)
	)
	return Vector2(
		clampf(position.x, minimum.x, maximum.x),
		clampf(position.y, minimum.y, maximum.y)
	)


func _is_portrait_layout() -> bool:
	return size.y > size.x


func _configure_mobile_hud_once() -> void:
	_mobile_hud_configured = true
	# The desktop input-hint strip duplicates the on-screen touch controls and
	# consumes valuable phone space. Keep the actual ability icon/cooldown tile.
	var playfield := match_manager.get_parent() if match_manager != null else null
	if playfield == null:
		return
	var ability_hud := playfield.get_node_or_null("HUD/AbilityHUD") as Control
	if ability_hud != null and ability_hud.has_method("configure_for_mobile_web"):
		ability_hud.call("configure_for_mobile_web")


static func _is_touch_web_runtime() -> bool:
	return (
		OS.has_feature("web")
		and DisplayServer.is_touchscreen_available()
	)
