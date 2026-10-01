extends Control


@export var match_manager: FootballMatchManager
@export var wheel_radius: float = 205.0
@export var selection_dead_zone: float = 58.0

@onready var controller_support := get_node(
	"/root/ControllerSupport"
) as FootballControllerSupport

var _buttons: Array[Button] = []
var _selected_index: int = -1
var _wheel_open: bool = false
var _saved_mouse_position: Vector2
var _saved_mouse_mode: Input.MouseMode
var _instruction_label: Label
var _opened_with_controller: bool = false


func _ready() -> void:
	if match_manager == null:
		push_error("Quick chat MatchManager was not assigned.")
		return
	# Keep this lightweight controller/UI state machine alive while the
	# SceneTree is paused. The pause overlay can pause the tree from _input()
	# before this Control gets its normal _process() tick, so inheriting the
	# paused state can otherwise leave an open wheel in a stale state.
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	_build_wheel()
	var cosmetic_inventory := get_node_or_null(
		"/root/CosmeticInventory"
	) as FootballCosmeticInventory
	if cosmetic_inventory != null:
		cosmetic_inventory.loadout_changed.connect(
			_on_cosmetic_loadout_changed
		)
	MenuStyler.apply_premium_design(self, &"quick_chat")
	hide()
	resized.connect(_layout_wheel)


func _process(_delta: float) -> void:
	# The pause overlay runs in _input() and may pause the SceneTree before
	# ordinary Controls receive another process tick. Always close a transient
	# wheel while paused so its logical open state can never survive invisibly
	# behind the pause layer.
	if get_tree().paused:
		if _wheel_open:
			_close_wheel(false)
		return

	var can_chat := (
		match_manager != null
		and match_manager.game_has_started
		and not match_manager.freeplay_active
	)
	if not can_chat:
		if _wheel_open:
			_close_wheel(false)
		return

	if controller_support.is_resilient_action_just_pressed(&"quick_chat"):
		_open_wheel()
	if not _wheel_open:
		return

	# Self-heal any presentation-only hide without losing the active selection
	# state. This is intentionally local to the wheel; it never forces the HUD
	# CanvasLayer or any unrelated UI visible.
	if not visible:
		show()

	_update_selection()
	var quick_chat_released := (
		controller_support.is_resilient_action_just_released(&"quick_chat")
	)
	if quick_chat_released or Input.is_key_pressed(KEY_ESCAPE):
		_close_wheel(quick_chat_released)


func _build_wheel() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.008, 0.022, 0.014, 0.60)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	_instruction_label = Label.new()
	_instruction_label.text = "QUICK CHAT\nChoose a direction, then release"
	_instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_instruction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_instruction_label.add_theme_font_size_override("font_size", 22)
	_instruction_label.add_theme_color_override(
		"font_color",
		Color(0.96, 0.94, 0.86)
	)
	_instruction_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_instruction_label)

	for message: String in _get_local_quick_chat_messages():
		var button := Button.new()
		button.text = message
		button.custom_minimum_size = Vector2(220.0, 54.0)
		button.size = button.custom_minimum_size
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_theme_font_size_override("font_size", 20)
		add_child(button)
		_buttons.append(button)
	_layout_wheel()


func _get_local_quick_chat_messages() -> Array[String]:
	var inventory := get_node_or_null(
		"/root/CosmeticInventory"
	) as FootballCosmeticInventory
	if inventory != null:
		var equipped_messages: Array[String] = inventory.get_quick_chat_payloads()
		if not equipped_messages.is_empty():
			return equipped_messages
	return match_manager.quick_chat_messages.duplicate()


func _on_cosmetic_loadout_changed(slot: StringName, _item_id: String) -> void:
	if slot != FootballCosmeticInventory.SLOT_QUICK_CHAT:
		return
	var messages: Array[String] = _get_local_quick_chat_messages()
	for index: int in range(mini(_buttons.size(), messages.size())):
		_buttons[index].text = messages[index]


func _layout_wheel() -> void:
	if _instruction_label == null:
		return
	var center := size * 0.5
	var available_radius := maxf(112.0, minf(size.x, size.y) * 0.30)
	var layout_radius := minf(wheel_radius, available_radius)
	var compact: bool = size.y < 800.0 or size.x < 1280.0
	var instruction_size := Vector2(300.0, 90.0) if compact else Vector2(360.0, 110.0)
	_instruction_label.position = center - instruction_size * 0.5
	_instruction_label.size = instruction_size
	_instruction_label.add_theme_font_size_override("font_size", 18 if compact else 22)
	var count := _buttons.size()
	for index in count:
		var angle := -PI * 0.5 + TAU * float(index) / maxf(1.0, count)
		var button := _buttons[index]
		button.custom_minimum_size = Vector2(190.0, 46.0) if compact else Vector2(220.0, 54.0)
		button.size = button.custom_minimum_size
		button.add_theme_font_size_override("font_size", 17 if compact else 20)
		button.position = (
			center
			+ Vector2.from_angle(angle) * layout_radius
			- button.size * 0.5
		)


func _open_wheel() -> void:
	if _buttons.is_empty():
		return
	_wheel_open = true
	_selected_index = -1
	_opened_with_controller = controller_support.using_controller
	_saved_mouse_position = get_viewport().get_mouse_position()
	_saved_mouse_mode = Input.mouse_mode
	_instruction_label.text = (
		"QUICK CHAT\n%s, then release [ %s ]"
		% [
			"Move the right stick"
			if _opened_with_controller
			else "Move the mouse",
			controller_support.get_action_prompt(&"quick_chat")
		]
	)
	if not _opened_with_controller:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	show()
	if not _opened_with_controller:
		Input.warp_mouse(size * 0.5)
	_update_button_visuals()


func _update_selection() -> void:
	var offset := get_viewport().get_mouse_position() - size * 0.5
	if _opened_with_controller:
		var controller_device: int = controller_support.active_device_id
		if not controller_support.is_controller_device_assigned(controller_device):
			if _selected_index != -1:
				_selected_index = -1
				_update_button_visuals()
			return
		offset = Vector2(
			Input.get_joy_axis(
				controller_device,
				JOY_AXIS_RIGHT_X
			),
			Input.get_joy_axis(
				controller_device,
				JOY_AXIS_RIGHT_Y
			)
		) * wheel_radius
	var next_index := -1
	var dead_zone := (
		0.38 * wheel_radius
		if _opened_with_controller
		else selection_dead_zone
	)
	if offset.length() >= dead_zone and not _buttons.is_empty():
		var normalized_angle := fposmod(offset.angle() + PI * 0.5, TAU)
		next_index = int(round(
			normalized_angle / TAU * _buttons.size()
		)) % _buttons.size()
	if next_index == _selected_index:
		return
	_selected_index = next_index
	_update_button_visuals()


func _update_button_visuals() -> void:
	for index in _buttons.size():
		var selected := index == _selected_index
		_buttons[index].modulate = (
			Color(1.0, 0.82, 0.28)
			if selected
			else Color(0.72, 0.8, 0.88)
		)
		_buttons[index].scale = (
			Vector2(1.08, 1.08) if selected else Vector2.ONE
		)


func force_close_without_send() -> void:
	# Used by modal overlays such as the pause menu. It is safe to call even
	# when the wheel is already closed and restores mouse state if needed.
	if _wheel_open:
		_close_wheel(false)
	elif visible:
		hide()


func _close_wheel(send_selection: bool) -> void:
	if send_selection and _selected_index >= 0:
		match_manager.request_quick_chat(_selected_index)
	_wheel_open = false
	hide()
	if not _opened_with_controller:
		Input.mouse_mode = _saved_mouse_mode
		if _saved_mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.warp_mouse(_saved_mouse_position)
	_opened_with_controller = false
