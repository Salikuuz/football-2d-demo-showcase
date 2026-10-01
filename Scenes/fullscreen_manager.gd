extends Node


signal fullscreen_changed(enabled: bool)

const WINDOWED_SIZE := Vector2i(1920, 1080)
const GAME_CONTENT_SIZE := Vector2i(1152, 648)
const LIVE_MAX_RENDER_FPS: int = 240
const LIVE_PHYSICS_TPS: int = 60

var _saved_windowed_position := Vector2i.ZERO
var _saved_windowed_size := WINDOWED_SIZE
var _has_saved_windowed_geometry := false
# This is deliberately the source of truth instead of querying the OS on every
# F11 press. On Windows the DisplayServer mode can lag behind a mode change by a
# frame, which could make a second F11 press ask for fullscreen again.
var _requested_fullscreen := false
var _window_restore_generation := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.has_environment("THEODORE_RL_V2_HEADLESS"):
		set_process_input(false)
		return
	_configure_high_refresh_gameplay()
	_apply_game_content_scaling()
	_requested_fullscreen = _is_fullscreen_mode(
		DisplayServer.window_get_mode()
	)
	if _can_control_window() and not _requested_fullscreen:
		_remember_windowed_geometry()


func _configure_high_refresh_gameplay() -> void:
	# Render and simulation cadence are intentionally separate. The game can
	# present up to 240 rendered frames per second, while gameplay/AI stays on a
	# stable 60 Hz physics clock and Godot interpolates the visual transforms in
	# between. Running the whole simulation at 120/240 Hz multiplied every CPU,
	# RigidBody, ability and match-manager physics callback and caused team modes
	# such as 3v3 to become CPU-bound.
	Engine.max_fps = LIVE_MAX_RENDER_FPS
	Engine.physics_ticks_per_second = LIVE_PHYSICS_TPS
	# Keep interpolation enabled so 120/144/165/240 Hz displays still receive
	# smooth visual motion between the 60 authoritative simulation updates.
	# Remote replicas retain their existing custom per-frame network interpolation.
	get_tree().physics_interpolation = true


func _apply_game_content_scaling() -> void:
	# Fullscreen changes the physical window only. Keeping the original 16:9
	# virtual canvas prevents Camera2D and fixed world art from zooming out.
	var game_window := get_window()
	if game_window == null:
		return
	game_window.content_scale_size = GAME_CONTENT_SIZE
	game_window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	game_window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP


func _input(event: InputEvent) -> void:
	if not is_fullscreen_toggle_event(event):
		return
	toggle_fullscreen()
	get_viewport().set_input_as_handled()


func toggle_fullscreen() -> void:
	set_fullscreen(not _requested_fullscreen)


func set_fullscreen(enabled: bool) -> void:
	if not _can_control_window():
		return

	var actual_fullscreen := _is_fullscreen_mode(
		DisplayServer.window_get_mode()
	)
	if enabled == _requested_fullscreen and enabled == actual_fullscreen:
		return

	_requested_fullscreen = enabled
	_window_restore_generation += 1
	if enabled:
		_enter_fullscreen()
	else:
		_restore_windowed(_window_restore_generation)
	fullscreen_changed.emit(enabled)


func is_fullscreen_enabled() -> bool:
	return _requested_fullscreen


static func is_fullscreen_toggle_event(event: InputEvent) -> bool:
	var key_event := event as InputEventKey
	return (
		key_event != null
		and key_event.pressed
		and not key_event.echo
		and (
			key_event.keycode == KEY_F11
			or key_event.physical_keycode == KEY_F11
		)
	)


static func clamp_window_position(
	position: Vector2i,
	window_size: Vector2i,
	usable_rect: Rect2i
) -> Vector2i:
	if usable_rect.size.x <= 0 or usable_rect.size.y <= 0:
		return position
	var maximum_x := maxi(
		usable_rect.position.x,
		usable_rect.end.x - window_size.x
	)
	var maximum_y := maxi(
		usable_rect.position.y,
		usable_rect.end.y - window_size.y
	)
	return Vector2i(
		clampi(position.x, usable_rect.position.x, maximum_x),
		clampi(position.y, usable_rect.position.y, maximum_y)
	)


static func _is_fullscreen_mode(mode: DisplayServer.WindowMode) -> bool:
	return (
		mode == DisplayServer.WINDOW_MODE_FULLSCREEN
		or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	)


func _can_control_window() -> bool:
	# Browser/PWA sizing belongs to the browser and manifest. Asking the Web
	# DisplayServer to perform desktop F11/window geometry transitions can fail or
	# fight Safari's standalone canvas sizing.
	return DisplayServer.get_name() != "headless" and not OS.has_feature("web")


func _remember_windowed_geometry() -> void:
	_saved_windowed_position = DisplayServer.window_get_position()
	_saved_windowed_size = DisplayServer.window_get_size()
	_has_saved_windowed_geometry = true


func _enter_fullscreen() -> void:
	if not _is_fullscreen_mode(DisplayServer.window_get_mode()):
		_remember_windowed_geometry()

	# WINDOW_MODE_FULLSCREEN is already borderless fullscreen in Godot. The old
	# code also forced WINDOW_FLAG_BORDERLESS = true. On Windows that flag can
	# survive the mode transition and make WINDOW_MODE_WINDOWED still look like
	# fullscreen. Do not set it when entering fullscreen.
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _restore_windowed(generation: int) -> void:
	# Clear a potentially stale borderless flag first (including one left by an
	# older build), then request normal windowed mode.
	DisplayServer.window_set_flag(
		DisplayServer.WINDOW_FLAG_BORDERLESS,
		false
	)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	# DisplayServer mode changes can be asynchronous on desktop platforms. Apply
	# geometry on the deferred pass instead of while Windows is still switching.
	_finish_windowed_restore.bind(generation).call_deferred()


func _finish_windowed_restore(generation: int) -> void:
	if generation != _window_restore_generation or _requested_fullscreen:
		return

	# Reassert windowed mode after the deferred transition. This makes F11 a
	# reliable two-way toggle even on systems where the first request is delayed.
	DisplayServer.window_set_flag(
		DisplayServer.WINDOW_FLAG_BORDERLESS,
		false
	)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	var restore_size := (
		_saved_windowed_size
		if _has_saved_windowed_geometry
		else WINDOWED_SIZE
	)
	if restore_size.x <= 0 or restore_size.y <= 0:
		restore_size = WINDOWED_SIZE
	DisplayServer.window_set_size(restore_size)

	var screen := DisplayServer.window_get_current_screen()
	if screen < 0:
		screen = DisplayServer.get_primary_screen()
	var usable_rect := DisplayServer.screen_get_usable_rect(screen)
	var restore_position := (
		_saved_windowed_position
		if _has_saved_windowed_geometry
		else usable_rect.position
	)
	DisplayServer.window_set_position(
		clamp_window_position(
			restore_position,
			restore_size,
			usable_rect
		)
	)
