class_name FootballControllerSupport
extends Node


signal input_method_changed(using_controller: bool, family: StringName)
signal bindings_changed
signal controller_list_changed
signal active_controller_changed(device_id: int, display_name: String)
signal calibration_started(device_id: int, duration: float)
signal calibration_finished(success: bool, message: String)

const FAMILY_AUTO: StringName = &"auto"
const FAMILY_XINPUT: StringName = &"xinput"
const FAMILY_DUALSENSE: StringName = &"dualsense"
const FAMILY_NINTENDO: StringName = &"nintendo"
const FAMILY_GENERIC: StringName = &"generic"

const DEVICE_SCAN_INTERVAL_SECONDS: float = 0.20
const STICK_ACTIVITY_THRESHOLD: float = 0.72
const STICK_EVENT_ACTIVITY_THRESHOLD: float = 0.24
const TRIGGER_ACTIVITY_THRESHOLD: float = 0.28
const ACTIVITY_BUTTON_SCAN_COUNT: int = 32
const INPUT_ACTIVITY_LOG_INTERVAL_MSEC: int = 30000
const RAW_INPUT_FALLBACK_LOG_INTERVAL_MSEC: int = 10000
const LOCAL_CONTROLLER_LOGICAL_ID: StringName = &"local_player_controller"
const PROFILE_SETTINGS_PATH: String = "user://controller_profiles.cfg"
const DEFAULT_LEFT_STICK_DEADZONE: float = 0.18
const DEFAULT_RIGHT_STICK_DEADZONE: float = 0.18
const DEFAULT_TRIGGER_DEADZONE: float = 0.10
const CALIBRATION_SECONDS: float = 2.0
const CALIBRATION_MARGIN: float = 0.04
const CONTROLLER_DATABASE_PATH: String = (
	"res://ControllerMappings/gamecontrollerdb.txt"
)
const XINPUT_BUTTON_ICON_PATHS: Dictionary = {
	JOY_BUTTON_A: "res://Assets/controller_prompts/xbox/a.svg",
	JOY_BUTTON_B: "res://Assets/controller_prompts/xbox/b.svg",
	JOY_BUTTON_X: "res://Assets/controller_prompts/xbox/x.svg",
	JOY_BUTTON_Y: "res://Assets/controller_prompts/xbox/y.svg",
	JOY_BUTTON_BACK: "res://Assets/controller_prompts/xbox/view.svg",
	JOY_BUTTON_START: "res://Assets/controller_prompts/xbox/menu.svg",
	JOY_BUTTON_LEFT_SHOULDER: "res://Assets/controller_prompts/xbox/lb.svg",
	JOY_BUTTON_RIGHT_SHOULDER: "res://Assets/controller_prompts/xbox/rb.svg",
	JOY_BUTTON_LEFT_STICK: "res://Assets/controller_prompts/xbox/ls.svg",
	JOY_BUTTON_RIGHT_STICK: "res://Assets/controller_prompts/xbox/rs.svg",
	JOY_BUTTON_DPAD_UP: "res://Assets/controller_prompts/xbox/dpad_up.svg",
	JOY_BUTTON_DPAD_DOWN: "res://Assets/controller_prompts/xbox/dpad_down.svg",
	JOY_BUTTON_DPAD_LEFT: "res://Assets/controller_prompts/xbox/dpad_left.svg",
	JOY_BUTTON_DPAD_RIGHT: "res://Assets/controller_prompts/xbox/dpad_right.svg"
}
const XINPUT_AXIS_ICON_PATHS: Dictionary = {
	JOY_AXIS_LEFT_X: "res://Assets/controller_prompts/xbox/left_stick.svg",
	JOY_AXIS_LEFT_Y: "res://Assets/controller_prompts/xbox/left_stick.svg",
	JOY_AXIS_RIGHT_X: "res://Assets/controller_prompts/xbox/right_stick.svg",
	JOY_AXIS_RIGHT_Y: "res://Assets/controller_prompts/xbox/right_stick.svg",
	JOY_AXIS_TRIGGER_LEFT: "res://Assets/controller_prompts/xbox/lt.svg",
	JOY_AXIS_TRIGGER_RIGHT: "res://Assets/controller_prompts/xbox/rt.svg"
}
const PLAYSTATION_BUTTON_ICON_PATHS: Dictionary = {
	JOY_BUTTON_A: "res://Assets/controller_prompts/playstation/cross.svg",
	JOY_BUTTON_B: "res://Assets/controller_prompts/playstation/circle.svg",
	JOY_BUTTON_X: "res://Assets/controller_prompts/playstation/square.svg",
	JOY_BUTTON_Y: "res://Assets/controller_prompts/playstation/triangle.svg",
	JOY_BUTTON_BACK: "res://Assets/controller_prompts/playstation/share.svg",
	JOY_BUTTON_START: "res://Assets/controller_prompts/playstation/options.svg",
	JOY_BUTTON_LEFT_SHOULDER: "res://Assets/controller_prompts/playstation/l1.svg",
	JOY_BUTTON_RIGHT_SHOULDER: "res://Assets/controller_prompts/playstation/r1.svg",
	JOY_BUTTON_LEFT_STICK: "res://Assets/controller_prompts/playstation/l3.svg",
	JOY_BUTTON_RIGHT_STICK: "res://Assets/controller_prompts/playstation/r3.svg",
	JOY_BUTTON_DPAD_UP: "res://Assets/controller_prompts/playstation/dpad_up.svg",
	JOY_BUTTON_DPAD_DOWN: "res://Assets/controller_prompts/playstation/dpad_down.svg",
	JOY_BUTTON_DPAD_LEFT: "res://Assets/controller_prompts/playstation/dpad_left.svg",
	JOY_BUTTON_DPAD_RIGHT: "res://Assets/controller_prompts/playstation/dpad_right.svg"
}
const PLAYSTATION_AXIS_ICON_PATHS: Dictionary = {
	JOY_AXIS_LEFT_X: "res://Assets/controller_prompts/playstation/left_stick.svg",
	JOY_AXIS_LEFT_Y: "res://Assets/controller_prompts/playstation/left_stick.svg",
	JOY_AXIS_RIGHT_X: "res://Assets/controller_prompts/playstation/right_stick.svg",
	JOY_AXIS_RIGHT_Y: "res://Assets/controller_prompts/playstation/right_stick.svg",
	JOY_AXIS_TRIGGER_LEFT: "res://Assets/controller_prompts/playstation/l2.svg",
	JOY_AXIS_TRIGGER_RIGHT: "res://Assets/controller_prompts/playstation/r2.svg"
}
const CUSTOM_MAPPING_PATHS: Array[String] = [
	CONTROLLER_DATABASE_PATH,
	"res://controller_mappings.txt",
	"user://controller_mappings.txt"
]

const MOVEMENT_ACTIONS: Array[StringName] = [
	&"move_left",
	&"move_right",
	&"move_up",
	&"move_down"
]

const UI_CONTROLLER_ACTIONS: Array[StringName] = [
	&"ui_accept",
	&"ui_cancel",
	&"ui_up",
	&"ui_down",
	&"ui_left",
	&"ui_right",
	&"ui_focus_prev",
	&"ui_focus_next"
]

const CONTROLLER_ACTIONS: Array[StringName] = [
	&"shoot",
	&"ability",
	&"soft_pass",
	&"request_pass",
	&"quick_chat",
	&"leaderboard"
]

const DEFAULT_BUTTON_BINDINGS: Dictionary = {
	&"ability": JOY_BUTTON_X,
	&"soft_pass": JOY_BUTTON_A,
	&"request_pass": JOY_BUTTON_DPAD_RIGHT,
	&"quick_chat": JOY_BUTTON_DPAD_UP,
	&"leaderboard": JOY_BUTTON_BACK
}

var using_controller: bool = false
var active_device_id: int = -1
var prompt_family_override: StringName = FAMILY_AUTO
var device_prompt_family_override: StringName = FAMILY_AUTO
var movement_uses_right_stick: bool = false
var _controller_icon_cache: Dictionary = {}
var _known_devices: Array[int] = []
var _device_scan_remaining: float = 0.0
var _device_identity_cache: Dictionary = {}
var _device_connection_sequence: Dictionary = {}
var _next_connection_sequence: int = 1
var _last_input_log_msec_by_device: Dictionary = {}
var _input_event_count_by_device: Dictionary = {}
var _last_rejected_log_msec_by_device: Dictionary = {}
# Raw joypad fallback state. Godot can still deliver InputEventJoypad* events
# in edge cases where the InputMap action state fails to refresh after a
# hot-plug/reconnect. Gameplay consumes these pulses as a second path instead
# of requiring a scene change or a fixed runtime device ID.
var _raw_action_down: Dictionary = {}
var _raw_press_generation: Dictionary = {}
var _raw_release_generation: Dictionary = {}
var _raw_consumed_press_generation: Dictionary = {}
var _raw_consumed_release_generation: Dictionary = {}
var _raw_generation_counter: int = 0
var _last_raw_fallback_log_msec: int = -RAW_INPUT_FALLBACK_LOG_INTERVAL_MSEC
## Stable local assignment state. active_device_id is only the temporary Godot
## transport ID currently satisfying this logical assignment.
var assigned_controller_identity: Dictionary = {}
var assigned_controller_aliases: Array[String] = []
var controller_assignment_unavailable: bool = false
var _unavailable_previous_device_id: int = -1
var _devices_present_when_assignment_lost: Array[int] = []
var _reconnect_candidate_devices: Array[int] = []
var left_stick_deadzone: float = DEFAULT_LEFT_STICK_DEADZONE
var right_stick_deadzone: float = DEFAULT_RIGHT_STICK_DEADZONE
var trigger_deadzone: float = DEFAULT_TRIGGER_DEADZONE
var preferred_controller_profile: String = ""
var manual_controller_assignment: bool = false
var _profile_settings := ConfigFile.new()
var _profile_persistence_enabled: bool = false
var _loaded_profile_key: String = ""
var _loading_profile: bool = false
var _baseline_bindings: Dictionary = {}
var _baseline_movement_uses_right_stick: bool = false
var _baseline_device_prompt_family_override: StringName = FAMILY_AUTO
var _baseline_left_stick_deadzone: float = DEFAULT_LEFT_STICK_DEADZONE
var _baseline_right_stick_deadzone: float = DEFAULT_RIGHT_STICK_DEADZONE
var _baseline_trigger_deadzone: float = DEFAULT_TRIGGER_DEADZONE
var _calibration_active: bool = false
var _calibration_device: int = -1
var _calibration_remaining: float = 0.0
var _calibration_left_max: float = 0.0
var _calibration_right_max: float = 0.0
var _calibration_trigger_max: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.has_environment("THEODORE_RL_V2_HEADLESS"):
		set_process(false)
		set_process_input(false)
		return
	_load_custom_controller_mappings()
	_profile_settings.load(PROFILE_SETTINGS_PATH)
	preferred_controller_profile = str(
		_profile_settings.get_value("selection", "preferred_profile", "")
	)
	manual_controller_assignment = not preferred_controller_profile.is_empty()
	if manual_controller_assignment:
		assigned_controller_aliases.append(preferred_controller_profile)
		controller_assignment_unavailable = true
	_ensure_controller_actions()
	_ensure_ui_navigation_actions()
	_apply_deadzones()
	if not Input.joy_connection_changed.is_connected(
		_on_joy_connection_changed
	):
		Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_refresh_connected_devices(false, "startup")
	_apply_controller_device_filter(_controller_binding_device_id())
	_log_controller_lifecycle("startup", -1, "initial inventory")
	call_deferred("_refresh_connected_devices", false, "startup deferred")


func _process(delta: float) -> void:
	if _calibration_active:
		_sample_deadzone_calibration(delta)
	_device_scan_remaining -= delta
	if _device_scan_remaining > 0.0:
		return
	_device_scan_remaining = DEVICE_SCAN_INTERVAL_SECONDS
	_refresh_connected_devices(false)
	_poll_controller_activity()


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		var button_event := event as InputEventJoypadButton
		if button_event.pressed:
			_record_controller_input(button_event.device, "button")
			_set_active_controller(button_event.device)
		# Releases are just as important as presses for the raw fallback. Do not
		# require a pressed event here or a hot-plugged held action can get stuck.
		_track_raw_gameplay_event(button_event)
		return
	if event is InputEventJoypadMotion:
		var motion_event := event as InputEventJoypadMotion
		if _joy_motion_is_meaningful(motion_event):
			_record_controller_input(motion_event.device, "axis")
			_set_active_controller(motion_event.device)
		# Track neutral trigger/axis events too. A trigger returning to zero is the
		# release edge for actions such as shoot and is intentionally not
		# "meaningful" enough to switch the active controller.
		_track_raw_gameplay_event(motion_event)
		return
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo:
			_set_keyboard_active()
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed:
			_set_keyboard_active()


func _ensure_controller_actions() -> void:
	for action in MOVEMENT_ACTIONS + CONTROLLER_ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.22)
	_apply_deadzones()
	if not _action_has_controller_event(&"shoot"):
		var trigger := InputEventJoypadMotion.new()
		trigger.device = _controller_binding_device_id()
		trigger.axis = JOY_AXIS_TRIGGER_RIGHT
		trigger.axis_value = 1.0
		InputMap.action_add_event(&"shoot", trigger)
	for action in DEFAULT_BUTTON_BINDINGS:
		if _action_has_controller_event(action):
			continue
		var button := InputEventJoypadButton.new()
		button.device = _controller_binding_device_id()
		button.button_index = int(DEFAULT_BUTTON_BINDINGS[action])
		InputMap.action_add_event(action, button)
	if not _movement_has_controller_events():
		set_movement_stick(false, false)


func set_controller_binding(
	action: StringName,
	event: InputEvent
) -> bool:
	if action not in CONTROLLER_ACTIONS:
		return false
	if not (
		event is InputEventJoypadButton
		or event is InputEventJoypadMotion
	):
		return false
	_remove_matching_controller_binding_from_other_actions(action, event)
	_erase_controller_events(action)
	var stored_event := event.duplicate() as InputEvent
	stored_event.device = _controller_binding_device_id()
	InputMap.action_add_event(action, stored_event)
	_apply_deadzones()
	_save_active_profile_if_ready()
	bindings_changed.emit()
	return true


func clear_controller_binding(action: StringName) -> void:
	if action not in CONTROLLER_ACTIONS:
		return
	_erase_controller_events(action)
	_save_active_profile_if_ready()
	bindings_changed.emit()


func reset_controller_bindings() -> void:
	for action in CONTROLLER_ACTIONS:
		_erase_controller_events(action)
	var trigger := InputEventJoypadMotion.new()
	trigger.device = _controller_binding_device_id()
	trigger.axis = JOY_AXIS_TRIGGER_RIGHT
	trigger.axis_value = 1.0
	InputMap.action_add_event(&"shoot", trigger)
	for action in DEFAULT_BUTTON_BINDINGS:
		var button := InputEventJoypadButton.new()
		button.device = _controller_binding_device_id()
		button.button_index = int(DEFAULT_BUTTON_BINDINGS[action])
		InputMap.action_add_event(action, button)
	set_movement_stick(false, false)
	left_stick_deadzone = DEFAULT_LEFT_STICK_DEADZONE
	right_stick_deadzone = DEFAULT_RIGHT_STICK_DEADZONE
	trigger_deadzone = DEFAULT_TRIGGER_DEADZONE
	_apply_deadzones()
	_save_active_profile_if_ready()
	bindings_changed.emit()


func set_movement_stick(use_right_stick: bool, notify: bool = true) -> void:
	movement_uses_right_stick = use_right_stick
	for action in MOVEMENT_ACTIONS:
		_erase_controller_events(action)
	var horizontal_axis := (
		JOY_AXIS_RIGHT_X if use_right_stick else JOY_AXIS_LEFT_X
	)
	var vertical_axis := (
		JOY_AXIS_RIGHT_Y if use_right_stick else JOY_AXIS_LEFT_Y
	)
	_add_axis_binding(&"move_left", horizontal_axis, -1.0)
	_add_axis_binding(&"move_right", horizontal_axis, 1.0)
	_add_axis_binding(&"move_up", vertical_axis, -1.0)
	_add_axis_binding(&"move_down", vertical_axis, 1.0)
	_apply_deadzones()
	if notify:
		_save_active_profile_if_ready()
		bindings_changed.emit()


func set_prompt_family_override(family: StringName) -> void:
	if family not in [
		FAMILY_AUTO,
		FAMILY_XINPUT,
		FAMILY_DUALSENSE,
		FAMILY_NINTENDO,
		FAMILY_GENERIC
	]:
		family = FAMILY_AUTO
	if prompt_family_override == family:
		return
	prompt_family_override = family
	input_method_changed.emit(using_controller, get_prompt_family())
	bindings_changed.emit()


func get_prompt_family() -> StringName:
	if prompt_family_override != FAMILY_AUTO:
		return prompt_family_override
	if device_prompt_family_override != FAMILY_AUTO:
		return device_prompt_family_override
	var device := _get_valid_active_device()
	if device < 0:
		return FAMILY_GENERIC
	return _detect_controller_family(device)


func get_controller_name() -> String:
	var device := _get_valid_active_device()
	return get_controller_display_name(device)


func get_connected_controller_ids() -> Array[int]:
	return _known_devices.duplicate()


func is_controller_device_assigned(device_id: int) -> bool:
	return (
		device_id >= 0
		and device_id == active_device_id
		and device_id in _known_devices
		and not controller_assignment_unavailable
	)


func is_controller_event_assigned(event: InputEvent) -> bool:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return is_controller_device_assigned(event.device)
	return false


func get_resilient_movement_vector() -> Vector2:
	# Keep the normal InputMap path for keyboard and for controllers when Godot's
	# action state is healthy. A direct joypad read is used only while the active
	# input method is a controller. This specifically covers the engine case where
	# raw joypad events survive a hot-plug but InputMap actions stay at zero.
	var mapped := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)
	if not using_controller:
		return mapped
	var raw := _get_best_raw_movement_vector()
	if raw.length_squared() <= 0.0001:
		return mapped
	if (raw - mapped).length_squared() >= 0.04:
		_log_raw_input_fallback("movement")
	# Direct per-device state is authoritative while a controller is active. It
	# also avoids wildcard InputMap state being polluted by a duplicated
	# physical/Steam-virtual representation of the same pad.
	return raw


func is_resilient_action_pressed(action: StringName) -> bool:
	if Input.is_action_pressed(action):
		return true
	return using_controller and bool(_raw_action_down.get(action, false))


func is_resilient_action_just_pressed(action: StringName) -> bool:
	var mapped_pressed := Input.is_action_just_pressed(action)
	# Always consume the raw edge so switching to keyboard cannot leave an old
	# controller pulse queued for a later frame. Only expose it while controller
	# input is the active method.
	var raw_pressed := _consume_raw_action_press(action)
	if not using_controller:
		raw_pressed = false
	if raw_pressed and not mapped_pressed:
		_log_raw_input_fallback("press:%s" % str(action))
	return mapped_pressed or raw_pressed


func is_resilient_action_just_released(action: StringName) -> bool:
	var mapped_released := Input.is_action_just_released(action)
	var raw_released := _consume_raw_action_release(action)
	if not using_controller:
		raw_released = false
	if raw_released and not mapped_released:
		_log_raw_input_fallback("release:%s" % str(action))
	return mapped_released or raw_released


func _get_best_raw_movement_vector() -> Vector2:
	var reported := _reported_controller_ids()
	if reported.is_empty():
		return Vector2.ZERO
	var candidate_devices: Array[int] = []
	if active_device_id in reported:
		candidate_devices.append(active_device_id)
	if not manual_controller_assignment:
		for device in reported:
			if device not in candidate_devices:
				candidate_devices.append(device)
	if candidate_devices.is_empty():
		return Vector2.ZERO

	var horizontal_axis := (
		JOY_AXIS_RIGHT_X if movement_uses_right_stick else JOY_AXIS_LEFT_X
	)
	var vertical_axis := (
		JOY_AXIS_RIGHT_Y if movement_uses_right_stick else JOY_AXIS_LEFT_Y
	)
	var best := Vector2.ZERO
	for device in candidate_devices:
		var sample := Vector2(
			Input.get_joy_axis(device, horizontal_axis),
			Input.get_joy_axis(device, vertical_axis)
		)
		sample = _apply_radial_deadzone(sample, get_movement_deadzone())
		if sample.length_squared() > best.length_squared():
			best = sample
	return best.limit_length(1.0)


func _apply_radial_deadzone(value: Vector2, deadzone: float) -> Vector2:
	var length := value.length()
	var safe_deadzone := clampf(deadzone, 0.0, 0.95)
	if length <= safe_deadzone or is_zero_approx(length):
		return Vector2.ZERO
	var scaled_length := clampf(
		(length - safe_deadzone) / maxf(0.001, 1.0 - safe_deadzone),
		0.0,
		1.0
	)
	return value / length * scaled_length


func _track_raw_gameplay_event(event: InputEvent) -> void:
	if not (event is InputEventJoypadButton or event is InputEventJoypadMotion):
		return
	# _set_active_controller() runs before this method for meaningful input. Once
	# an automatic assignment has healed, only the chosen representation feeds
	# button edges. In auto mode with no assignment yet, accepting the first live
	# event is intentional and mirrors the existing controller-selection policy.
	if active_device_id >= 0 and event.device != active_device_id:
		return
	if controller_assignment_unavailable and manual_controller_assignment:
		return
	for action in CONTROLLER_ACTIONS:
		var binding := get_controller_binding(action)
		if binding == null:
			continue
		if event is InputEventJoypadButton and binding is InputEventJoypadButton:
			var button_event := event as InputEventJoypadButton
			if button_event.button_index != (binding as InputEventJoypadButton).button_index:
				continue
			_set_raw_action_down(action, button_event.pressed)
		elif event is InputEventJoypadMotion and binding is InputEventJoypadMotion:
			var motion_event := event as InputEventJoypadMotion
			var motion_binding := binding as InputEventJoypadMotion
			if motion_event.axis != motion_binding.axis:
				continue
			var direction_sign := signf(motion_binding.axis_value)
			if is_zero_approx(direction_sign):
				direction_sign = 1.0
			var threshold := 0.20
			if InputMap.has_action(action):
				threshold = maxf(0.05, InputMap.action_get_deadzone(action))
			_set_raw_action_down(
				action,
				motion_event.axis_value * direction_sign >= threshold
			)


func _set_raw_action_down(action: StringName, down: bool) -> void:
	var was_down := bool(_raw_action_down.get(action, false))
	if was_down == down:
		return
	_raw_action_down[action] = down
	_raw_generation_counter += 1
	if down:
		_raw_press_generation[action] = _raw_generation_counter
	else:
		_raw_release_generation[action] = _raw_generation_counter


func _consume_raw_action_press(action: StringName) -> bool:
	var generation := int(_raw_press_generation.get(action, 0))
	if generation <= int(_raw_consumed_press_generation.get(action, 0)):
		return false
	_raw_consumed_press_generation[action] = generation
	return true


func _consume_raw_action_release(action: StringName) -> bool:
	var generation := int(_raw_release_generation.get(action, 0))
	if generation <= int(_raw_consumed_release_generation.get(action, 0)):
		return false
	_raw_consumed_release_generation[action] = generation
	return true


func _release_all_raw_actions() -> void:
	for action_variant in _raw_action_down.keys():
		var action := StringName(action_variant)
		if bool(_raw_action_down.get(action, false)):
			_set_raw_action_down(action, false)


func _log_raw_input_fallback(detail: String) -> void:
	var now_msec := Time.get_ticks_msec()
	if now_msec - _last_raw_fallback_log_msec < RAW_INPUT_FALLBACK_LOG_INTERVAL_MSEC:
		return
	_last_raw_fallback_log_msec = now_msec
	_log_controller_lifecycle(
		"raw-input-fallback",
		active_device_id,
		"InputMap missed live controller input; direct joypad path supplied %s" % detail
	)


func get_controller_display_name(device_id: int) -> String:
	if device_id < 0 or device_id not in _known_devices:
		return "No controller connected"
	if device_id not in _reported_controller_ids():
		var cached_identity: Dictionary = _device_identity_cache.get(device_id, {})
		return str(cached_identity.get("name", "Game Controller"))
	var mapped_name := Input.get_joy_name(device_id).strip_edges()
	var info := Input.get_joy_info(device_id)
	var raw_name := str(info.get("raw_name", "")).strip_edges()
	var display_name := mapped_name
	if display_name.is_empty():
		display_name = raw_name
	if display_name.is_empty():
		display_name = "Game Controller"
	if info.has("steam_input_index"):
		display_name += " via Steam Input"
	elif (
		not raw_name.is_empty()
		and raw_name.to_lower() != display_name.to_lower()
		and not display_name.to_lower().contains(raw_name.to_lower())
	):
		display_name += " (%s)" % raw_name
	return display_name


func get_controller_profile_key(device_id: int) -> String:
	if device_id < 0:
		return ""
	if device_id not in _reported_controller_ids():
		var cached_identity: Dictionary = _device_identity_cache.get(device_id, {})
		return str(cached_identity.get("profile_key", ""))
	var info := Input.get_joy_info(device_id)
	var serial := str(info.get("serial_number", "")).strip_edges().to_lower()
	var guid := Input.get_joy_guid(device_id).strip_edges().to_lower()
	var raw_name := str(info.get("raw_name", "")).strip_edges().to_lower()
	var mapped_name := Input.get_joy_name(device_id).strip_edges().to_lower()
	var vendor := str(info.get("vendor_id", info.get("vendor", "")))
	var product := str(info.get("product_id", info.get("product", "")))
	if guid == "__xinput_device__":
		guid = "xinput"
	# Prefer a hardware serial when Godot exposes one. This keeps two identical
	# pads from sharing a profile. Steam/XInput wrappers often hide the serial,
	# so the stable hardware/mapping signature remains the fallback.
	if not serial.is_empty():
		return "serial:%s|%s|%s" % [serial, vendor, product]
	return "%s|%s|%s|%s|%s" % [
		guid,
		vendor,
		product,
		raw_name,
		mapped_name
	]


func get_connected_controller_descriptors() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for device in _known_devices:
		var cached_identity: Dictionary = _device_identity_cache.get(device, {})
		var info: Dictionary = cached_identity.get("info", {})
		result.append({
			"device_id": device,
			"name": get_controller_display_name(device),
			"profile_key": get_controller_profile_key(device),
			"family": _detect_controller_family(device),
			"steam_input": info.has("steam_input_index"),
			"known_mapping": (
				Input.is_joy_known(device)
				if device in _reported_controller_ids()
				else false
			)
		})
	return result


func is_controller_selection_auto() -> bool:
	return not manual_controller_assignment


func select_auto_controller() -> void:
	manual_controller_assignment = false
	preferred_controller_profile = ""
	_profile_settings.set_value("selection", "preferred_profile", "")
	_profile_settings.save(PROFILE_SETTINGS_PATH)
	if active_device_id in _known_devices:
		_claim_logical_controller(active_device_id, false)
	else:
		_clear_logical_controller_assignment()
	_apply_controller_device_filter(_controller_binding_device_id())
	active_controller_changed.emit(active_device_id, get_controller_name())


func select_controller(device_id: int) -> bool:
	if device_id not in _known_devices:
		return false
	manual_controller_assignment = true
	preferred_controller_profile = get_controller_profile_key(device_id)
	_profile_settings.set_value(
		"selection",
		"preferred_profile",
		preferred_controller_profile
	)
	_profile_settings.save(PROFILE_SETTINGS_PATH)
	_claim_logical_controller(device_id, false)
	_set_active_controller(device_id, true)
	return true


func finish_profile_bootstrap() -> void:
	if _profile_persistence_enabled:
		return
	_capture_baseline_controller_settings()
	_profile_persistence_enabled = true
	_restore_preferred_device_if_available()
	apply_profile_for_active_device()
	_apply_controller_device_filter(_controller_binding_device_id())
	_apply_deadzones()


func is_profile_persistence_enabled() -> bool:
	return _profile_persistence_enabled


func apply_profile_for_active_device() -> void:
	var device := _get_valid_active_device()
	if device < 0:
		return
	var profile_key := get_controller_profile_key(device)
	if profile_key.is_empty():
		return
	var section := _profile_section(profile_key)

	_loading_profile = true
	_restore_baseline_controller_settings()
	if not _profile_settings.has_section(section):
		_loaded_profile_key = profile_key
		_loading_profile = false
		_apply_controller_device_filter(_controller_binding_device_id())
		_apply_deadzones()
		bindings_changed.emit()
		return
	left_stick_deadzone = clampf(
		float(
			_profile_settings.get_value(
				section,
				"left_stick_deadzone",
				left_stick_deadzone
			)
		),
		0.03,
		0.45
	)
	right_stick_deadzone = clampf(
		float(
			_profile_settings.get_value(
				section,
				"right_stick_deadzone",
				right_stick_deadzone
			)
		),
		0.03,
		0.45
	)
	trigger_deadzone = clampf(
		float(
			_profile_settings.get_value(
				section,
				"trigger_deadzone",
				trigger_deadzone
			)
		),
		0.01,
		0.40
	)
	device_prompt_family_override = StringName(
		str(
			_profile_settings.get_value(
				section,
				"prompt_family_override",
				str(device_prompt_family_override)
			)
		)
	)
	if device_prompt_family_override not in [
		FAMILY_AUTO, FAMILY_XINPUT, FAMILY_DUALSENSE, FAMILY_NINTENDO, FAMILY_GENERIC
	]:
		device_prompt_family_override = FAMILY_AUTO
	set_movement_stick(
		bool(
			_profile_settings.get_value(
				section,
				"movement_uses_right_stick",
				movement_uses_right_stick
			)
		),
		false
	)
	for action in CONTROLLER_ACTIONS:
		_load_profile_binding(section, action)
	_loaded_profile_key = profile_key
	_loading_profile = false
	_apply_controller_device_filter(_controller_binding_device_id())
	_apply_deadzones()
	bindings_changed.emit()


func set_device_prompt_family_override(family: StringName) -> void:
	if family not in [
		FAMILY_AUTO, FAMILY_XINPUT, FAMILY_DUALSENSE, FAMILY_NINTENDO, FAMILY_GENERIC
	]:
		family = FAMILY_AUTO
	if device_prompt_family_override == family:
		return
	device_prompt_family_override = family
	_controller_icon_cache.clear()
	_save_active_profile_if_ready()
	input_method_changed.emit(using_controller, get_prompt_family())
	bindings_changed.emit()


func set_left_stick_deadzone(value: float) -> void:
	left_stick_deadzone = clampf(value, 0.03, 0.45)
	_apply_deadzones()
	_save_active_profile_if_ready()


func set_right_stick_deadzone(value: float) -> void:
	right_stick_deadzone = clampf(value, 0.03, 0.45)
	_apply_deadzones()
	_save_active_profile_if_ready()


func set_trigger_deadzone(value: float) -> void:
	trigger_deadzone = clampf(value, 0.01, 0.40)
	_apply_deadzones()
	_save_active_profile_if_ready()


func get_movement_deadzone() -> float:
	return (
		right_stick_deadzone
		if movement_uses_right_stick
		else left_stick_deadzone
	)


func start_deadzone_calibration(duration: float = CALIBRATION_SECONDS) -> bool:
	var device := _get_valid_active_device()
	if device < 0:
		calibration_finished.emit(false, "No controller is selected.")
		return false
	if active_device_id != device:
		_set_active_controller(device, true)
	_calibration_active = true
	_calibration_device = device
	_calibration_remaining = maxf(1.0, duration)
	_calibration_left_max = 0.0
	_calibration_right_max = 0.0
	_calibration_trigger_max = 0.0
	calibration_started.emit(device, _calibration_remaining)
	return true


func cancel_deadzone_calibration() -> void:
	if not _calibration_active:
		return
	_calibration_active = false
	_calibration_device = -1
	_calibration_remaining = 0.0
	calibration_finished.emit(false, "Calibration cancelled.")


func is_calibrating_deadzone() -> bool:
	return _calibration_active


func get_calibration_remaining() -> float:
	return maxf(0.0, _calibration_remaining)


func get_live_input_snapshot(device_id: int = -1) -> Dictionary:
	var device := device_id
	if device < 0:
		device = _get_valid_active_device()
	if (
		device < 0
		or device not in _known_devices
		or device not in _reported_controller_ids()
	):
		return {}
	var family := _detect_controller_family(device)
	var left := Vector2(
		Input.get_joy_axis(device, JOY_AXIS_LEFT_X),
		Input.get_joy_axis(device, JOY_AXIS_LEFT_Y)
	)
	var right := Vector2(
		Input.get_joy_axis(device, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(device, JOY_AXIS_RIGHT_Y)
	)
	var lt := clampf(
		maxf(0.0, Input.get_joy_axis(device, JOY_AXIS_TRIGGER_LEFT)),
		0.0,
		1.0
	)
	var rt := clampf(
		maxf(0.0, Input.get_joy_axis(device, JOY_AXIS_TRIGGER_RIGHT)),
		0.0,
		1.0
	)
	var pressed: Array[String] = []
	for button_index in range(ACTIVITY_BUTTON_SCAN_COUNT):
		if Input.is_joy_button_pressed(device, button_index):
			pressed.append(_get_button_glyph(button_index, family))
	var info := Input.get_joy_info(device)
	return {
		"device_id": device,
		"name": get_controller_display_name(device),
		"family": family,
		"left_stick": left,
		"right_stick": right,
		"left_trigger": lt,
		"right_trigger": rt,
		"buttons": pressed,
		"steam_input": info.has("steam_input_index"),
		"known_mapping": Input.is_joy_known(device),
		"guid": Input.get_joy_guid(device),
		"raw_name": str(info.get("raw_name", ""))
	}


func _sample_deadzone_calibration(delta: float) -> void:
	if (
		_calibration_device < 0
		or _calibration_device not in _known_devices
		or _calibration_device not in _reported_controller_ids()
	):
		_calibration_active = false
		calibration_finished.emit(
			false,
			"Controller disconnected during calibration."
		)
		return
	var left := Vector2(
		Input.get_joy_axis(_calibration_device, JOY_AXIS_LEFT_X),
		Input.get_joy_axis(_calibration_device, JOY_AXIS_LEFT_Y)
	)
	var right := Vector2(
		Input.get_joy_axis(_calibration_device, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(_calibration_device, JOY_AXIS_RIGHT_Y)
	)
	_calibration_left_max = maxf(_calibration_left_max, left.length())
	_calibration_right_max = maxf(_calibration_right_max, right.length())
	_calibration_trigger_max = maxf(
		_calibration_trigger_max,
		maxf(
			maxf(
				0.0,
				Input.get_joy_axis(
					_calibration_device,
					JOY_AXIS_TRIGGER_LEFT
				)
			),
			maxf(
				0.0,
				Input.get_joy_axis(
					_calibration_device,
					JOY_AXIS_TRIGGER_RIGHT
				)
			)
		)
	)
	_calibration_remaining -= delta
	if _calibration_remaining > 0.0:
		return
	_calibration_active = false
	if maxf(_calibration_left_max, _calibration_right_max) > 0.45:
		calibration_finished.emit(
			false,
			"Calibration saw large stick movement. Release both sticks and try again."
		)
		return
	left_stick_deadzone = clampf(
		_calibration_left_max + CALIBRATION_MARGIN,
		0.08,
		0.35
	)
	right_stick_deadzone = clampf(
		_calibration_right_max + CALIBRATION_MARGIN,
		0.08,
		0.35
	)
	trigger_deadzone = clampf(
		_calibration_trigger_max + 0.03,
		0.05,
		0.25
	)
	_apply_deadzones()
	_save_active_profile_if_ready()
	calibration_finished.emit(
		true,
		"Calibration saved: LS %.0f%% • RS %.0f%% • Triggers %.0f%%" % [
			left_stick_deadzone * 100.0,
			right_stick_deadzone * 100.0,
			trigger_deadzone * 100.0
		]
	)


func _apply_deadzones() -> void:
	var movement_deadzone := get_movement_deadzone()
	for action in MOVEMENT_ACTIONS:
		if InputMap.has_action(action):
			InputMap.action_set_deadzone(action, movement_deadzone)
	if InputMap.has_action(&"shoot"):
		InputMap.action_set_deadzone(&"shoot", trigger_deadzone)


func _capture_baseline_controller_settings() -> void:
	_baseline_bindings.clear()
	for action in CONTROLLER_ACTIONS:
		var event := get_controller_binding(action)
		if event != null:
			var stored := event.duplicate() as InputEvent
			stored.device = -1
			_baseline_bindings[action] = stored
	_baseline_movement_uses_right_stick = movement_uses_right_stick
	_baseline_device_prompt_family_override = device_prompt_family_override
	_baseline_left_stick_deadzone = left_stick_deadzone
	_baseline_right_stick_deadzone = right_stick_deadzone
	_baseline_trigger_deadzone = trigger_deadzone


func _restore_baseline_controller_settings() -> void:
	left_stick_deadzone = _baseline_left_stick_deadzone
	right_stick_deadzone = _baseline_right_stick_deadzone
	trigger_deadzone = _baseline_trigger_deadzone
	device_prompt_family_override = _baseline_device_prompt_family_override
	set_movement_stick(_baseline_movement_uses_right_stick, false)
	for action in CONTROLLER_ACTIONS:
		_erase_controller_events(action)
		if not _baseline_bindings.has(action):
			continue
		var event := (_baseline_bindings[action] as InputEvent).duplicate() as InputEvent
		event.device = _controller_binding_device_id()
		InputMap.action_add_event(action, event)
	_apply_deadzones()


func _profile_section(profile_key: String) -> String:
	return "controller_%d" % absi(profile_key.hash())


func _save_active_profile_if_ready() -> void:
	if not _profile_persistence_enabled or _loading_profile:
		return
	var device := active_device_id
	if device < 0 or device not in _known_devices:
		if _known_devices.size() == 1:
			device = _known_devices[0]
		else:
			return
	_save_profile_for_device(device)


func _save_profile_for_device(device: int) -> void:
	var profile_key := get_controller_profile_key(device)
	if profile_key.is_empty():
		return
	var section := _profile_section(profile_key)
	_profile_settings.set_value(section, "profile_key", profile_key)
	_profile_settings.set_value(
		section,
		"display_name",
		get_controller_display_name(device)
	)
	_profile_settings.set_value(
		section,
		"prompt_family_override",
		str(device_prompt_family_override)
	)
	_profile_settings.set_value(
		section,
		"left_stick_deadzone",
		left_stick_deadzone
	)
	_profile_settings.set_value(
		section,
		"right_stick_deadzone",
		right_stick_deadzone
	)
	_profile_settings.set_value(
		section,
		"trigger_deadzone",
		trigger_deadzone
	)


	_profile_settings.set_value(
		section,
		"movement_uses_right_stick",
		movement_uses_right_stick
	)
	for action in CONTROLLER_ACTIONS:
		_save_profile_binding(section, action)
	_profile_settings.save(PROFILE_SETTINGS_PATH)
	_loaded_profile_key = profile_key


func _save_profile_binding(section: String, action: StringName) -> void:
	var event := get_controller_binding(action)
	var prefix := "binding_%s" % str(action)
	if event is InputEventJoypadButton:
		_profile_settings.set_value(section, prefix + "_kind", "button")
		_profile_settings.set_value(
			section,
			prefix + "_button",
			(event as InputEventJoypadButton).button_index
		)
	elif event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		_profile_settings.set_value(section, prefix + "_kind", "axis")
		_profile_settings.set_value(section, prefix + "_axis", motion.axis)
		_profile_settings.set_value(
			section,
			prefix + "_axis_value",
			motion.axis_value
		)
	else:
		_profile_settings.set_value(section, prefix + "_kind", "unbound")


func _load_profile_binding(section: String, action: StringName) -> void:
	var prefix := "binding_%s" % str(action)
	var kind_key := prefix + "_kind"
	if not _profile_settings.has_section_key(section, kind_key):
		return
	var kind := str(_profile_settings.get_value(section, kind_key, ""))
	if kind == "unbound":
		clear_controller_binding(action)
		return
	var event: InputEvent
	if kind == "button":
		var button := InputEventJoypadButton.new()
		button.button_index = int(
			_profile_settings.get_value(section, prefix + "_button", 0)
		)
		event = button
	elif kind == "axis":
		var motion := InputEventJoypadMotion.new()
		motion.axis = int(
			_profile_settings.get_value(section, prefix + "_axis", 0)
		)
		motion.axis_value = float(
			_profile_settings.get_value(
				section,
				prefix + "_axis_value",
				1.0
			)
		)
		event = motion
	if event != null:
		set_controller_binding(action, event)


func _restore_preferred_device_if_available() -> void:
	if not manual_controller_assignment or preferred_controller_profile.is_empty():
		return
	if active_device_id in _known_devices:
		return
	for device in _known_devices:
		if get_controller_profile_key(device) != preferred_controller_profile:
			continue
		if active_device_id == device:
			return
		_restore_logical_controller(device, "preferred-profile reconnect")
		return


func _controller_binding_device_id() -> int:
	# Godot's InputMap uses device -1 as ALL_DEVICES. Gameplay is intentionally
	# bound to the logical "any local gamepad" channel rather than to a transient
	# SDL/Steam/XInput device ID.
	#
	# This project has one local human input stream per client, so pinning actions
	# to active_device_id only creates a failure mode when SDL/Steam changes the
	# controller's runtime representation or reconnect ID.
	return -1


func _apply_controller_device_filter(_device_id: int) -> void:
	# IMPORTANT:
	# InputMap::ALL_DEVICES is -1 in Godot 4.7. Keep every joypad binding on
	# that wildcard permanently. active_device_id remains useful for prompts,
	# profiles and diagnostics, but it must never decide whether gameplay input
	# is accepted.
	var actions: Array[StringName] = []
	actions.append_array(MOVEMENT_ACTIONS)
	actions.append_array(CONTROLLER_ACTIONS)
	actions.append_array(UI_CONTROLLER_ACTIONS)
	for action in actions:
		if not InputMap.has_action(action):
			continue
		for event in InputMap.action_get_events(action):
			if not (
				event is InputEventJoypadButton
				or event is InputEventJoypadMotion
			):
				continue
			if event.device != -1:
				event.device = -1


func get_controller_debug_text(device_id: int = -1) -> String:
	var device := device_id
	if device < 0:
		device = _get_valid_active_device()
	if device < 0:
		return "No controller connected"
	if device not in _reported_controller_ids():
		return "device=%d %s (awaiting Godot inventory)" % [
			device,
			_device_identity_text(device)
		]
	var info := Input.get_joy_info(device)
	return "device=%d name=%s guid=%s known=%s info=%s" % [
		device,
		Input.get_joy_name(device),
		Input.get_joy_guid(device),
		str(Input.is_joy_known(device)),
		str(info)
	]


func get_action_prompt(
	action: StringName,
	force_controller: bool = false
) -> String:
	if force_controller or using_controller:
		return get_controller_binding_text(action)
	return get_keyboard_binding_text(action)


func get_keyboard_binding_text(action: StringName) -> String:
	if not InputMap.has_action(action):
		return "UNBOUND"
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			var result := key_event.as_text().replace(" (Physical)", "")
			return result.to_upper()
		if event is InputEventMouseButton:
			var mouse_event := event as InputEventMouseButton
			match mouse_event.button_index:
				MOUSE_BUTTON_LEFT:
					return "LMB"
				MOUSE_BUTTON_RIGHT:
					return "RMB"
				MOUSE_BUTTON_MIDDLE:
					return "MMB"
			return "MOUSE %d" % mouse_event.button_index
	return "UNBOUND"


func get_controller_binding_text(action: StringName) -> String:
	var event := get_controller_binding(action)
	if event == null:
		return "UNBOUND"
	if event is InputEventJoypadButton:
		return _get_button_glyph(
			(event as InputEventJoypadButton).button_index,
			get_prompt_family()
		)
	if event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		return _get_axis_glyph(
			motion.axis,
			motion.axis_value,
			get_prompt_family()
		)
	return "UNBOUND"


func get_controller_binding(action: StringName) -> InputEvent:
	if not InputMap.has_action(action):
		return null
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			return event
	return null


func get_movement_stick_text() -> String:
	return "RIGHT STICK" if movement_uses_right_stick else "LEFT STICK"


func get_prompt_family_text() -> String:
	match get_prompt_family():
		FAMILY_XINPUT:
			return "Xbox / XInput"
		FAMILY_DUALSENSE:
			return "PlayStation"
		FAMILY_NINTENDO:
			return "Nintendo"
	return "Gamepad"


func _claim_logical_controller(
	device_id: int,
	preserve_previous_aliases: bool
) -> void:
	_cache_device_identity(device_id)
	var identity: Dictionary = _device_identity_cache.get(device_id, {}).duplicate(true)
	var profile_key: String = str(identity.get("profile_key", ""))
	if not preserve_previous_aliases:
		assigned_controller_aliases.clear()
	if not profile_key.is_empty() and profile_key not in assigned_controller_aliases:
		assigned_controller_aliases.append(profile_key)
	assigned_controller_identity = identity
	controller_assignment_unavailable = false
	_unavailable_previous_device_id = -1
	_devices_present_when_assignment_lost.clear()
	_reconnect_candidate_devices.clear()


func _clear_logical_controller_assignment() -> void:
	assigned_controller_identity.clear()
	assigned_controller_aliases.clear()
	controller_assignment_unavailable = false
	_unavailable_previous_device_id = -1
	_devices_present_when_assignment_lost.clear()
	_reconnect_candidate_devices.clear()


func _mark_logical_controller_unavailable(
	disconnected_device: int,
	remaining_devices: Array[int]
) -> void:
	if assigned_controller_identity.is_empty():
		assigned_controller_identity = (
			_device_identity_cache.get(disconnected_device, {}).duplicate(true)
		)
	var old_profile: String = str(
		assigned_controller_identity.get("profile_key", "")
	)
	if not old_profile.is_empty() and old_profile not in assigned_controller_aliases:
		assigned_controller_aliases.append(old_profile)
	controller_assignment_unavailable = true
	_unavailable_previous_device_id = disconnected_device
	_devices_present_when_assignment_lost = remaining_devices.duplicate()
	_reconnect_candidate_devices.clear()


func _device_matches_logical_assignment(device_id: int) -> bool:
	var identity: Dictionary = _device_identity_cache.get(device_id, {})
	if identity.is_empty():
		return false
	var profile_key: String = str(identity.get("profile_key", ""))
	if not profile_key.is_empty() and profile_key in assigned_controller_aliases:
		return true
	var assigned_guid: String = str(
		assigned_controller_identity.get("guid", "")
	).to_lower()
	var candidate_guid: String = str(identity.get("guid", "")).to_lower()
	if (
		not assigned_guid.is_empty()
		and assigned_guid != "unknown"
		and assigned_guid != "__xinput_device__"
		and candidate_guid == assigned_guid
	):
		return true
	return false


func _can_restore_assignment_from_input(device_id: int) -> bool:
	if _device_matches_logical_assignment(device_id):
		return true
	if device_id in _devices_present_when_assignment_lost:
		return false
	if device_id not in _reconnect_candidate_devices:
		_reconnect_candidate_devices.append(device_id)
		_reconnect_candidate_devices.sort()
	return (
		_reconnect_candidate_devices.size() == 1
		and _reconnect_candidate_devices[0] == device_id
	)


func _restore_logical_controller(device_id: int, reason: String) -> void:
	var old_device: int = _unavailable_previous_device_id
	_claim_logical_controller(device_id, true)
	_log_controller_lifecycle(
		"assignment-restored",
		device_id,
		"logical=%s old_id=%d new_id=%d reason=%s"
		% [LOCAL_CONTROLLER_LOGICAL_ID, old_device, device_id, reason]
	)
	_set_active_controller(device_id, true)


func _log_rejected_controller_input(device_id: int, reason: String) -> void:
	var now_msec: int = Time.get_ticks_msec()
	var last_msec: int = int(
		_last_rejected_log_msec_by_device.get(
			device_id,
			-INPUT_ACTIVITY_LOG_INTERVAL_MSEC
		)
	)
	if now_msec - last_msec < INPUT_ACTIVITY_LOG_INTERVAL_MSEC:
		return
	_last_rejected_log_msec_by_device[device_id] = now_msec
	_log_controller_lifecycle("input-not-assigned", device_id, reason)


func _set_active_controller(device_id: int, force_emit: bool = false) -> void:
	if device_id < 0:
		return
	if device_id not in _known_devices:
		_known_devices.append(device_id)
		_known_devices.sort()
		_device_connection_sequence[device_id] = _next_connection_sequence
		_next_connection_sequence += 1
		_cache_device_identity(device_id)
		_log_controller_lifecycle(
			"input-before-inventory",
			device_id,
			"Godot delivered input before the connected-joypad snapshot"
		)
		controller_list_changed.emit()
	if controller_assignment_unavailable:
		if manual_controller_assignment:
			if not _can_restore_assignment_from_input(device_id):
				_log_rejected_controller_input(
					device_id,
					"manual assignment unavailable; gameplay still accepts wildcard joypad input"
				)
				return
			_restore_logical_controller(
				device_id,
				"manual assignment restored from live input"
			)
			return

		# In automatic mode, live input is stronger evidence than the stale
		# disconnect inventory. Steam Input can leave another representation of
		# the same physical controller already present, which the old
		# _devices_present_when_assignment_lost guard rejected forever.
		_restore_logical_controller(
			device_id,
			"automatic self-heal from live controller input"
		)
		return
	if assigned_controller_identity.is_empty():
		_claim_logical_controller(device_id, false)
	if manual_controller_assignment and not force_emit:
		if active_device_id in _known_devices and device_id != active_device_id:
			_log_rejected_controller_input(
				device_id,
				"manual logical assignment belongs to device %d" % active_device_id
			)
			return
	var previous_device := active_device_id
	var previous_family := get_prompt_family()
	var was_using_controller := using_controller
	active_device_id = device_id
	using_controller = true
	if previous_device != device_id and not force_emit:
		_claim_logical_controller(device_id, false)
	if previous_device != active_device_id:
		_apply_controller_device_filter(active_device_id)
		if _profile_persistence_enabled:
			apply_profile_for_active_device()
		active_controller_changed.emit(
			active_device_id,
			get_controller_display_name(active_device_id)
		)
		_log_controller_lifecycle(
			"active-changed",
			active_device_id,
			"previous=%d" % previous_device
		)
	var next_family := get_prompt_family()
	if (
		force_emit
		or not was_using_controller
		or previous_device != active_device_id
		or previous_family != next_family
	):
		input_method_changed.emit(true, next_family)
	if previous_family != next_family:
		bindings_changed.emit()


func _set_keyboard_active() -> void:
	if not using_controller:
		return
	using_controller = false
	_log_controller_lifecycle(
		"keyboard-active",
		active_device_id,
		"controller remains available"
	)
	input_method_changed.emit(false, get_prompt_family())


func _on_joy_connection_changed(device: int, connected: bool) -> void:
	if connected:
		_cache_device_identity(device)
	_log_controller_lifecycle(
		"connection-signal",
		device,
		"connected=%s" % str(connected)
	)
	var snapshot: Array[int] = []
	for connected_device in Input.get_connected_joypads():
		snapshot.append(int(connected_device))
	if connected and device not in snapshot:
		snapshot.append(device)
	elif not connected:
		snapshot.erase(device)
	_apply_connected_device_snapshot(
		snapshot,
		true,
		"joy_connection_changed"
	)
	call_deferred(
		"_refresh_connected_devices",
		true,
		"joy_connection_changed deferred"
	)


func _refresh_connected_devices(
	_print_changes: bool = false,
	source: String = "poll"
) -> void:
	var snapshot: Array[int] = []
	for device in Input.get_connected_joypads():
		snapshot.append(int(device))
	_apply_connected_device_snapshot(snapshot, _print_changes, source)


func _apply_connected_device_snapshot(
	devices: Array,
	_print_changes: bool = false,
	source: String = "snapshot"
) -> void:
	var current: Array[int] = []
	for device_variant in devices:
		var device := int(device_variant)
		if device < 0 or device in current:
			continue
		current.append(device)
	current.sort()

	var added: Array[int] = []
	for device in current:
		if device not in _known_devices:
			added.append(device)
	var removed: Array[int] = []
	for device in _known_devices:
		if device not in current:
			removed.append(device)

	for device in current:
		_cache_device_identity(device)
	for device in added:
		_device_connection_sequence[device] = _next_connection_sequence
		_next_connection_sequence += 1
	_known_devices = current
	var reconnect_candidates_snapshot: Array[int] = (
		_reconnect_candidate_devices.duplicate()
	)
	for candidate in reconnect_candidates_snapshot:
		if candidate not in _known_devices:
			_reconnect_candidate_devices.erase(candidate)

	# Inventory changes are rare and always useful when diagnosing a controller
	# that dies minutes into a match, including changes discovered by polling.
	for device in added:
		_log_controller_lifecycle("connected", device, "source=%s" % source)
	for device in removed:
		_log_controller_lifecycle("disconnected", device, "source=%s" % source)

	if active_device_id >= 0 and active_device_id not in _known_devices:
		var disconnected_active := active_device_id
		var previously_connected_remaining: Array[int] = current.duplicate()
		for added_device in added:
			previously_connected_remaining.erase(added_device)
		_mark_logical_controller_unavailable(
			disconnected_active,
			previously_connected_remaining
		)
		active_device_id = -1
		_release_all_raw_actions()
		_apply_controller_device_filter(_controller_binding_device_id())
		if using_controller:
			using_controller = false
			input_method_changed.emit(false, FAMILY_GENERIC)
		active_controller_changed.emit(-1, "No controller connected")
		_log_controller_lifecycle(
			"active-lost",
			disconnected_active,
			"logical=%s temporarily unavailable; InputMap remains on ALL_DEVICES for self-healing"
			% LOCAL_CONTROLLER_LOGICAL_ID
		)

	if controller_assignment_unavailable:
		for device in added:
			if device in _devices_present_when_assignment_lost:
				continue
			if device not in _reconnect_candidate_devices:
				_reconnect_candidate_devices.append(device)
		_reconnect_candidate_devices.sort()
		var exact_matches: Array[int] = []
		for device in _reconnect_candidate_devices:
			if (
				device in _known_devices
				and _device_matches_logical_assignment(device)
			):
				exact_matches.append(device)
		if exact_matches.size() == 1:
			_restore_logical_controller(
				exact_matches[0],
				"identity matched connection inventory"
			)

	if manual_controller_assignment:
		_restore_preferred_device_if_available()
		if active_device_id < 0:
			_apply_controller_device_filter(_controller_binding_device_id())

	if not added.is_empty() or not removed.is_empty():
		controller_list_changed.emit()


func _poll_controller_activity() -> void:
	# Raw _input events are authoritative for switching between live pads. State
	# polling is only a fallback after startup/disconnect; otherwise a duplicated
	# Steam physical/virtual device with stick drift or a held trigger can steal
	# the assignment every scan without producing a new event.
	if active_device_id in _known_devices:
		return
	if controller_assignment_unavailable and manual_controller_assignment:
		return
	var reported_devices: Array[int] = _reported_controller_ids()
	for device in _known_devices:
		if device not in reported_devices:
			continue
		for button_index in range(ACTIVITY_BUTTON_SCAN_COUNT):
			if Input.is_joy_button_pressed(device, button_index):
				_set_active_controller(device)
				return
		for axis in [
			JOY_AXIS_LEFT_X,
			JOY_AXIS_LEFT_Y,
			JOY_AXIS_RIGHT_X,
			JOY_AXIS_RIGHT_Y
		]:
			if absf(Input.get_joy_axis(device, axis)) >= STICK_ACTIVITY_THRESHOLD:
				_set_active_controller(device)
				return
		for trigger_axis in [JOY_AXIS_TRIGGER_LEFT, JOY_AXIS_TRIGGER_RIGHT]:
			if Input.get_joy_axis(device, trigger_axis) >= TRIGGER_ACTIVITY_THRESHOLD:
				_set_active_controller(device)
				return


func _joy_motion_is_meaningful(event: InputEventJoypadMotion) -> bool:
	if event.axis in [JOY_AXIS_TRIGGER_LEFT, JOY_AXIS_TRIGGER_RIGHT]:
		var trigger_threshold: float = TRIGGER_ACTIVITY_THRESHOLD
		if (
			active_device_id in _known_devices
			and event.device != active_device_id
		):
			trigger_threshold = STICK_ACTIVITY_THRESHOLD
		return event.axis_value >= trigger_threshold
	var threshold: float = STICK_EVENT_ACTIVITY_THRESHOLD
	if (
		active_device_id in _known_devices
		and event.device != active_device_id
	):
		# A second physical/Steam-virtual representation must show deliberate
		# movement before it can replace a healthy assignment; this rejects drift.
		threshold = STICK_ACTIVITY_THRESHOLD
	return absf(event.axis_value) >= threshold


func _get_valid_active_device() -> int:
	var reported_devices: Array[int] = _reported_controller_ids()
	if active_device_id in _known_devices and active_device_id in reported_devices:
		return active_device_id
	if manual_controller_assignment:
		for device in _known_devices:
			if (
				device in reported_devices
				and get_controller_profile_key(device)
				== preferred_controller_profile
			):
				return device
		return -1
	for device in _known_devices:
		if device in reported_devices:
			return device
	if not reported_devices.is_empty():
		return reported_devices[0]
	return -1


func _record_controller_input(device_id: int, input_kind: String) -> void:
	var count: int = int(_input_event_count_by_device.get(device_id, 0)) + 1
	_input_event_count_by_device[device_id] = count
	var now_msec: int = Time.get_ticks_msec()
	var last_log_msec: int = int(
		_last_input_log_msec_by_device.get(device_id, -INPUT_ACTIVITY_LOG_INTERVAL_MSEC)
	)
	if now_msec - last_log_msec < INPUT_ACTIVITY_LOG_INTERVAL_MSEC:
		return
	_last_input_log_msec_by_device[device_id] = now_msec
	_log_controller_lifecycle(
		"input-heartbeat",
		device_id,
		"kind=%s events=%d read_by_input_map=%s"
		% [input_kind, count, str(_controller_bindings_read_device(device_id))]
	)


func _controller_bindings_read_device(device_id: int) -> bool:
	var binding_devices: Array[int] = _controller_binding_device_summary()
	return -1 in binding_devices or device_id in binding_devices


func _controller_binding_device_summary() -> Array[int]:
	var devices: Array[int] = []
	var actions: Array[StringName] = []
	actions.append_array(MOVEMENT_ACTIONS)
	actions.append_array(CONTROLLER_ACTIONS)
	for action in actions:
		if not InputMap.has_action(action):
			continue
		for event in InputMap.action_get_events(action):
			if not (
				event is InputEventJoypadButton
				or event is InputEventJoypadMotion
			):
				continue
			if event.device not in devices:
				devices.append(event.device)
	devices.sort()
	return devices


func _cache_device_identity(device_id: int) -> void:
	if device_id < 0:
		return
	if device_id not in _reported_controller_ids():
		if not _device_identity_cache.has(device_id):
			_device_identity_cache[device_id] = {
				"name": "Unknown controller",
				"guid": "unknown",
				"info": {}
			}
		return
	var info: Dictionary = Input.get_joy_info(device_id)
	var name: String = Input.get_joy_name(device_id).strip_edges()
	var guid: String = Input.get_joy_guid(device_id).strip_edges()
	if name.is_empty():
		name = str(info.get("raw_name", "")).strip_edges()
	if name.is_empty():
		name = "Unknown controller"
	_device_identity_cache[device_id] = {
		"name": name,
		"guid": guid if not guid.is_empty() else "unknown",
		"info": info.duplicate(true),
		"profile_key": get_controller_profile_key(device_id)
	}


func _device_identity_text(device_id: int) -> String:
	var identity: Dictionary = _device_identity_cache.get(device_id, {})
	if identity.is_empty() and device_id >= 0:
		_cache_device_identity(device_id)
		identity = _device_identity_cache.get(device_id, {})
	if identity.is_empty():
		return "name=n/a guid=n/a info={}"
	return "name=%s guid=%s info=%s" % [
		str(identity.get("name", "Unknown controller")),
		str(identity.get("guid", "unknown")),
		str(identity.get("info", {}))
	]


func _reported_controller_ids() -> Array[int]:
	var result: Array[int] = []
	for device in Input.get_connected_joypads():
		result.append(int(device))
	result.sort()
	return result


func _log_controller_lifecycle(
	event_name: String,
	device_id: int,
	detail: String
) -> void:
	var local_peer_id: int = multiplayer.get_unique_id()
	var message_format: String = (
		"[Controller %s] %s device=%d %s reported=%s known=%s "
		+ "connection_order=%d active=%d using_controller=%s local_peer=%d logical=%s "
		+ "assignment_unavailable=%s aliases=%s input_map_devices=%s %s"
	)
	print(
		message_format % [
			Time.get_datetime_string_from_system(false, true),
			event_name,
			device_id,
			_device_identity_text(device_id),
			str(_reported_controller_ids()),
			str(_known_devices),
			int(_device_connection_sequence.get(device_id, -1)),
			active_device_id,
			str(using_controller),
			local_peer_id,
			str(LOCAL_CONTROLLER_LOGICAL_ID),
			str(controller_assignment_unavailable),
			str(assigned_controller_aliases),
			str(_controller_binding_device_summary()),
			detail
		]
	)


func _detect_controller_family(device_id: int) -> StringName:
	if device_id < 0:
		return FAMILY_GENERIC
	var reported: bool = device_id in _reported_controller_ids()
	var cached_identity: Dictionary = _device_identity_cache.get(device_id, {})
	var info: Dictionary = (
		Input.get_joy_info(device_id)
		if reported
		else cached_identity.get("info", {})
	)
	var guid: String = (
		Input.get_joy_guid(device_id).to_lower()
		if reported
		else str(cached_identity.get("guid", "")).to_lower()
	)
	var mapped_name: String = (
		Input.get_joy_name(device_id)
		if reported
		else str(cached_identity.get("name", ""))
	)
	var names := (
		mapped_name + " " + str(info.get("raw_name", ""))
	).to_lower()
	var vendor_id := int(info.get("vendor_id", 0))

	# Native USB vendor IDs are a useful signal when the mapped device name is
	# generic. Name checks still come first below for Steam/SCUF wrappers.
	if vendor_id == 0x054C:
		return FAMILY_DUALSENSE
	if vendor_id == 0x057E:
		return FAMILY_NINTENDO

	# Steam Input can expose a PlayStation/SCUF pad as virtual XInput. Prefer
	# the physical/raw device name for glyphs before falling back to XInput.
	for marker in [
		"dualsense",
		"dualshock",
		"playstation",
		"ps3",
		"ps4",
		"ps5",
		"sony",
		"wireless controller",
		"scuf reflex",
		"scuf impact",
		"scuf vantage",
		"infinity4ps"
	]:
		if names.contains(marker):
			return FAMILY_DUALSENSE
	for marker in [
		"nintendo",
		"switch",
		"joy-con",
		"joycon",
		"wii u"
	]:
		if names.contains(marker):
			return FAMILY_NINTENDO
	for marker in [
		"xbox",
		"xinput",
		"x-box",
		"x360",
		"360 controller",
		"scuf instinct",
		"scuf envision"
	]:
		if names.contains(marker):
			return FAMILY_XINPUT
	if vendor_id == 0x045E:
		return FAMILY_XINPUT
	if info.has("xinput_index") or guid == "__xinput_device__":
		return FAMILY_XINPUT
	return FAMILY_GENERIC


func _get_button_glyph(button_index: int, family: StringName) -> String:
	if family == FAMILY_XINPUT:
		match button_index:
			JOY_BUTTON_A:
				return "A"
			JOY_BUTTON_B:
				return "B"
			JOY_BUTTON_X:
				return "X"
			JOY_BUTTON_Y:
				return "Y"
			JOY_BUTTON_BACK:
				return "VIEW"
			JOY_BUTTON_START:
				return "MENU"
			JOY_BUTTON_LEFT_SHOULDER:
				return "LB"
			JOY_BUTTON_RIGHT_SHOULDER:
				return "RB"
			JOY_BUTTON_LEFT_STICK:
				return "LS"
			JOY_BUTTON_RIGHT_STICK:
				return "RS"
	elif family == FAMILY_DUALSENSE:
		match button_index:
			JOY_BUTTON_A:
				return "✕"
			JOY_BUTTON_B:
				return "○"
			JOY_BUTTON_X:
				return "□"
			JOY_BUTTON_Y:
				return "△"
			JOY_BUTTON_BACK:
				return "CREATE"
			JOY_BUTTON_START:
				return "OPTIONS"
			JOY_BUTTON_LEFT_SHOULDER:
				return "L1"
			JOY_BUTTON_RIGHT_SHOULDER:
				return "R1"
			JOY_BUTTON_LEFT_STICK:
				return "L3"
			JOY_BUTTON_RIGHT_STICK:
				return "R3"
	elif family == FAMILY_NINTENDO:
		match button_index:
			JOY_BUTTON_A:
				return "B"
			JOY_BUTTON_B:
				return "A"
			JOY_BUTTON_X:
				return "Y"
			JOY_BUTTON_Y:
				return "X"
			JOY_BUTTON_BACK:
				return "−"
			JOY_BUTTON_START:
				return "+"
			JOY_BUTTON_LEFT_SHOULDER:
				return "L"
			JOY_BUTTON_RIGHT_SHOULDER:
				return "R"
			JOY_BUTTON_LEFT_STICK:
				return "L STICK"
			JOY_BUTTON_RIGHT_STICK:
				return "R STICK"
	match button_index:
		JOY_BUTTON_DPAD_UP:
			return "D-PAD UP"
		JOY_BUTTON_DPAD_DOWN:
			return "D-PAD DOWN"
		JOY_BUTTON_DPAD_LEFT:
			return "D-PAD LEFT"
		JOY_BUTTON_DPAD_RIGHT:
			return "D-PAD RIGHT"
	return "BUTTON %d" % (button_index + 1)


func _get_axis_glyph(
	axis: int,
	axis_value: float,
	family: StringName
) -> String:
	match axis:
		JOY_AXIS_TRIGGER_LEFT:
			if family == FAMILY_XINPUT:
				return "LT"
			if family == FAMILY_NINTENDO:
				return "ZL"
			return "L2"
		JOY_AXIS_TRIGGER_RIGHT:
			if family == FAMILY_XINPUT:
				return "RT"
			if family == FAMILY_NINTENDO:
				return "ZR"
			return "R2"
		JOY_AXIS_LEFT_X:
			return "LEFT STICK RIGHT" if axis_value > 0.0 else "LEFT STICK LEFT"
		JOY_AXIS_LEFT_Y:
			return "LEFT STICK DOWN" if axis_value > 0.0 else "LEFT STICK UP"
		JOY_AXIS_RIGHT_X:
			return "RIGHT STICK RIGHT" if axis_value > 0.0 else "RIGHT STICK LEFT"
		JOY_AXIS_RIGHT_Y:
			return "RIGHT STICK DOWN" if axis_value > 0.0 else "RIGHT STICK UP"
	return "AXIS %d%s" % [axis + 1, "+" if axis_value > 0.0 else "-"]


func get_controller_binding_icon(action: StringName) -> Texture2D:
	var event := get_controller_binding(action)
	if event is InputEventJoypadButton:
		return get_controller_button_icon(
			(event as InputEventJoypadButton).button_index
		)
	if event is InputEventJoypadMotion:
		return get_controller_axis_icon(
			(event as InputEventJoypadMotion).axis
		)
	return null


func get_controller_button_icon(button_index: int) -> Texture2D:
	var family := get_prompt_family()
	if family == FAMILY_DUALSENSE:
		return get_ps5_button_icon(button_index)
	var key := "%s_button_%d" % [str(family), button_index]
	if _controller_icon_cache.has(key):
		return _controller_icon_cache[key] as Texture2D
	var texture: Texture2D = null
	if family == FAMILY_XINPUT:
		texture = _load_controller_prompt_icon(
			str(XINPUT_BUTTON_ICON_PATHS.get(button_index, ""))
		)
	if texture == null:
		texture = _make_controller_icon_texture(
			_make_controller_text_shape(_get_button_glyph(button_index, family))
		)
	_controller_icon_cache[key] = texture
	return texture


func get_controller_axis_icon(axis: int) -> Texture2D:
	var family := get_prompt_family()
	if family == FAMILY_DUALSENSE:
		return get_ps5_axis_icon(axis)
	var key := "%s_axis_%d" % [str(family), axis]
	if _controller_icon_cache.has(key):
		return _controller_icon_cache[key] as Texture2D
	var texture: Texture2D = null
	if family == FAMILY_XINPUT:
		texture = _load_controller_prompt_icon(
			str(XINPUT_AXIS_ICON_PATHS.get(axis, ""))
		)
	if texture != null:
		_controller_icon_cache[key] = texture
		return texture
	var label := "AXIS"
	match axis:
		JOY_AXIS_TRIGGER_LEFT:
			label = _get_axis_glyph(axis, 1.0, family)
		JOY_AXIS_TRIGGER_RIGHT:
			label = _get_axis_glyph(axis, 1.0, family)
		JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y:
			label = "LS"
		JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y:
			label = "RS"
	texture = _make_controller_icon_texture(
		_make_controller_text_shape(label)
	)
	_controller_icon_cache[key] = texture
	return texture


func get_ps5_button_icon(button_index: int) -> Texture2D:
	var key := "dualsense_button_%d" % button_index
	if _controller_icon_cache.has(key):
		return _controller_icon_cache[key] as Texture2D
	var texture := _load_controller_prompt_icon(
		str(PLAYSTATION_BUTTON_ICON_PATHS.get(button_index, ""))
	)
	if texture != null:
		_controller_icon_cache[key] = texture
		return texture
	var shape := ""
	match button_index:
		JOY_BUTTON_A:
			shape = '<path d="M14 14 L34 34 M34 14 L14 34" stroke="#66AFFF" stroke-width="4" stroke-linecap="round"/>'
		JOY_BUTTON_B:
			shape = '<circle cx="24" cy="24" r="12" fill="none" stroke="#FF667A" stroke-width="4"/>'
		JOY_BUTTON_X:
			shape = '<rect x="13" y="13" width="22" height="22" rx="2" fill="none" stroke="#FF79C9" stroke-width="4"/>'
		JOY_BUTTON_Y:
			shape = '<path d="M24 11 L37 35 H11 Z" fill="none" stroke="#69E59A" stroke-width="4" stroke-linejoin="round"/>'
		JOY_BUTTON_DPAD_UP:
			shape = _make_dpad_shape("up")
		JOY_BUTTON_DPAD_DOWN:
			shape = _make_dpad_shape("down")
		JOY_BUTTON_DPAD_LEFT:
			shape = _make_dpad_shape("left")
		JOY_BUTTON_DPAD_RIGHT:
			shape = _make_dpad_shape("right")
		_:
			shape = _make_controller_text_shape(
				_get_button_glyph(button_index, FAMILY_DUALSENSE)
			)
	texture = _make_controller_icon_texture(shape)
	_controller_icon_cache[key] = texture
	return texture


func get_ps5_axis_icon(axis: int) -> Texture2D:
	var key := "dualsense_axis_%d" % axis
	if _controller_icon_cache.has(key):
		return _controller_icon_cache[key] as Texture2D
	var texture := _load_controller_prompt_icon(
		str(PLAYSTATION_AXIS_ICON_PATHS.get(axis, ""))
	)
	if texture != null:
		_controller_icon_cache[key] = texture
		return texture
	var label := "AXIS"
	match axis:
		JOY_AXIS_TRIGGER_LEFT:
			label = "L2"
		JOY_AXIS_TRIGGER_RIGHT:
			label = "R2"
		JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y:
			label = "LS"
		JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y:
			label = "RS"
	texture = _make_controller_icon_texture(
		_make_controller_text_shape(label)
	)
	_controller_icon_cache[key] = texture
	return texture


func _load_controller_prompt_icon(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func _make_controller_icon_texture(shape: String) -> Texture2D:
	var svg := (
		'<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 48 48">'
		+ '<circle cx="24" cy="24" r="22" fill="#08131F" stroke="#DDEBFA" stroke-width="2"/>'
		+ shape
		+ '</svg>'
	)
	var image := Image.new()
	# The fallback is a runtime-rasterized SVG. Render it at 4x and build
	# mipmaps so an 18-24 px prompt remains smooth at 1080p instead of being
	# sampled from a tiny 48 px texture.
	if image.load_svg_from_string(svg, 4.0) != OK:
		return null
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


func _make_controller_text_shape(label: String) -> String:
	var safe_label := label.xml_escape()
	var font_size := 13 if safe_label.length() <= 3 else 8
	return (
		'<text x="24" y="28" text-anchor="middle" '
		+ 'font-family="Arial,sans-serif" font-size="%d" '
		+ 'font-weight="700" fill="#EEF6FF">%s</text>'
	) % [font_size, safe_label]


func _make_dpad_shape(direction: String) -> String:
	var rotation := 0
	match direction:
		"right":
			rotation = 90
		"down":
			rotation = 180
		"left":
			rotation = 270
	return (
		'<g transform="rotate(%d 24 24)">'
		+ '<path d="M24 10 L34 23 H28 V36 H20 V23 H14 Z" '
		+ 'fill="#DDEBFA"/></g>'
	) % rotation


func _ensure_ui_navigation_actions() -> void:
	# Standard controller menu navigation:
	# - D-pad + left stick move focus.
	# - A/Cross accepts, B/Circle goes back.
	# - LB/RB (L1/R1) are NOT generic focus-next/focus-previous buttons.
	#   Menus that actually have tabs handle shoulders explicitly so pressing
	#   down/up can never be confused with tab/focus traversal.
	_add_ui_button_binding(&"ui_accept", JOY_BUTTON_A)
	_add_ui_button_binding(&"ui_cancel", JOY_BUTTON_B)
	_add_ui_button_binding(&"ui_up", JOY_BUTTON_DPAD_UP)
	_add_ui_button_binding(&"ui_down", JOY_BUTTON_DPAD_DOWN)
	_add_ui_button_binding(&"ui_left", JOY_BUTTON_DPAD_LEFT)
	_add_ui_button_binding(&"ui_right", JOY_BUTTON_DPAD_RIGHT)
	_add_ui_axis_binding(&"ui_left", JOY_AXIS_LEFT_X, -1.0)
	_add_ui_axis_binding(&"ui_right", JOY_AXIS_LEFT_X, 1.0)
	_add_ui_axis_binding(&"ui_up", JOY_AXIS_LEFT_Y, -1.0)
	_add_ui_axis_binding(&"ui_down", JOY_AXIS_LEFT_Y, 1.0)

	# Remove old Theodore Ball shoulder bindings if they were installed by an
	# earlier version. Keyboard Tab/Shift+Tab and any non-controller bindings are
	# left untouched.
	_remove_ui_button_binding(&"ui_focus_prev", JOY_BUTTON_LEFT_SHOULDER)
	_remove_ui_button_binding(&"ui_focus_next", JOY_BUTTON_RIGHT_SHOULDER)


func _add_ui_button_binding(action: StringName, button_index: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for event in InputMap.action_get_events(action):
		if (
			event is InputEventJoypadButton
			and (event as InputEventJoypadButton).button_index
			== button_index
		):
			return
	var button := InputEventJoypadButton.new()
	button.device = _controller_binding_device_id()
	button.button_index = button_index
	InputMap.action_add_event(action, button)


func _add_ui_axis_binding(
	action: StringName,
	axis: int,
	axis_value: float
) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for event in InputMap.action_get_events(action):
		if not event is InputEventJoypadMotion:
			continue
		var motion := event as InputEventJoypadMotion
		if motion.axis == axis and signf(motion.axis_value) == signf(axis_value):
			return
	var motion := InputEventJoypadMotion.new()
	motion.device = _controller_binding_device_id()
	motion.axis = axis
	motion.axis_value = axis_value
	InputMap.action_add_event(action, motion)


func _remove_ui_button_binding(
	action: StringName,
	button_index: int
) -> void:
	if not InputMap.has_action(action):
		return
	for event in InputMap.action_get_events(action):
		if (
			event is InputEventJoypadButton
			and (event as InputEventJoypadButton).button_index == button_index
		):
			InputMap.action_erase_event(action, event)


func _action_has_controller_event(action: StringName) -> bool:
	return get_controller_binding(action) != null


func _movement_has_controller_events() -> bool:
	for action in [&"move_left", &"move_right", &"move_up", &"move_down"]:
		if not _action_has_controller_event(action):
			return false
	return true


func _erase_controller_events(action: StringName) -> void:
	if not InputMap.has_action(action):
		return
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			InputMap.action_erase_event(action, event)


func _remove_matching_controller_binding_from_other_actions(
	action: StringName,
	incoming: InputEvent
) -> void:
	for other_action in CONTROLLER_ACTIONS:
		if other_action == action:
			continue
		for existing in InputMap.action_get_events(other_action):
			if _controller_events_match(existing, incoming):
				InputMap.action_erase_event(other_action, existing)


func _controller_events_match(first: InputEvent, second: InputEvent) -> bool:
	if first is InputEventJoypadButton and second is InputEventJoypadButton:
		return (
			(first as InputEventJoypadButton).button_index
			== (second as InputEventJoypadButton).button_index
		)
	if first is InputEventJoypadMotion and second is InputEventJoypadMotion:
		var first_motion := first as InputEventJoypadMotion
		var second_motion := second as InputEventJoypadMotion
		return (
			first_motion.axis == second_motion.axis
			and signf(first_motion.axis_value)
			== signf(second_motion.axis_value)
		)
	return false


func _add_axis_binding(
	action: StringName,
	axis: int,
	axis_value: float
) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = _controller_binding_device_id()
	event.axis = axis
	event.axis_value = axis_value
	InputMap.action_add_event(action, event)


func _load_custom_controller_mappings() -> void:
	for path in CUSTOM_MAPPING_PATHS:
		if not FileAccess.file_exists(path):
			continue
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			continue
		while not file.eof_reached():
			var mapping := file.get_line().strip_edges()
			if mapping.is_empty() or mapping.begins_with("#"):
				continue
			Input.add_joy_mapping(mapping, true)


func _print_controller_detected(device: int) -> void:
	print("Controller detected: %s" % get_controller_debug_text(device))
