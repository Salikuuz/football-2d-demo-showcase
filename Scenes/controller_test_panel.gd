class_name FootballControllerTestPanel
extends Control


signal closed

var controller_support: FootballControllerSupport
var device_option: OptionButton
var status_label: Label
var glyph_option: OptionButton
var live_label: Label
var calibration_label: Label
var left_deadzone_slider: HSlider
var right_deadzone_slider: HSlider
var trigger_deadzone_slider: HSlider
var calibration_button: Button
var close_button: Button
var _selected_preview_device: int = -1
var _refreshing_ui: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	if controller_support == null:
		controller_support = get_node_or_null(
			"/root/ControllerSupport"
		) as FootballControllerSupport
	if controller_support != null:
		controller_support.controller_list_changed.connect(
			_refresh_device_list
		)
		controller_support.active_controller_changed.connect(
			_on_active_controller_changed
		)
		controller_support.bindings_changed.connect(_sync_profile_controls)
		controller_support.calibration_started.connect(
			_on_calibration_started
		)
		controller_support.calibration_finished.connect(
			_on_calibration_finished
		)
	_refresh_device_list()
	_sync_profile_controls()
	set_process(false)


func open_panel() -> void:
	show()
	_refresh_device_list()
	_sync_profile_controls()
	set_process(true)
	if device_option != null:
		device_option.call_deferred("grab_focus")


func close_panel() -> void:
	if controller_support != null and controller_support.is_calibrating_deadzone():
		controller_support.cancel_deadzone_calibration()
	hide()
	set_process(false)
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"ui_cancel"):
		close_panel()
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if not visible or controller_support == null:
		return
	_update_live_readout()
	if controller_support.is_calibrating_deadzone():
		calibration_label.text = (
			"Keep both sticks and triggers released... %.1fs"
			% controller_support.get_calibration_remaining()
		)


func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.008, 0.015, 0.011, 0.84)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	var viewport_size := get_viewport_rect().size
	panel.custom_minimum_size = Vector2(
		clampf(viewport_size.x * 0.72, 460.0, 700.0),
		minf(510.0, maxf(390.0, viewport_size.y - 56.0))
	)
	MenuStyler.style_panel(panel, Color(0.84, 0.72, 0.40))
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 10)
	margin.add_child(root_vbox)

	var heading := Label.new()
	heading.text = "CONTROLLER TEST & PROFILES"
	MenuStyler.style_heading(heading, Color(0.96, 0.96, 0.98))
	root_vbox.add_child(heading)

	var subtitle := Label.new()
	subtitle.text = (
		"Choose the controller that owns gameplay input. Profiles remember "
		+ "bindings and deadzones per controller."
	)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.modulate = Color(0.76, 0.77, 0.69)
	root_vbox.add_child(subtitle)

	device_option = OptionButton.new()
	device_option.custom_minimum_size.y = 42.0
	device_option.item_selected.connect(_on_device_selected)
	root_vbox.add_child(device_option)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.modulate = Color(0.82, 0.80, 0.68)
	root_vbox.add_child(status_label)

	var glyph_row := HBoxContainer.new()
	glyph_row.add_theme_constant_override("separation", 10)
	root_vbox.add_child(glyph_row)
	var glyph_label := Label.new()
	glyph_label.text = "Button Icons"
	glyph_label.custom_minimum_size.x = 110.0
	glyph_row.add_child(glyph_label)
	glyph_option = OptionButton.new()
	glyph_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for entry in [
		["Auto detect", FootballControllerSupport.FAMILY_AUTO],
		["Xbox / XInput", FootballControllerSupport.FAMILY_XINPUT],
		["PlayStation", FootballControllerSupport.FAMILY_DUALSENSE],
		["Nintendo", FootballControllerSupport.FAMILY_NINTENDO],
		["Generic", FootballControllerSupport.FAMILY_GENERIC]
	]:
		glyph_option.add_item(str(entry[0]))
		glyph_option.set_item_metadata(glyph_option.item_count - 1, entry[1])
	glyph_option.item_selected.connect(_on_glyph_family_selected)
	glyph_row.add_child(glyph_option)

	var deadzone_heading := Label.new()
	deadzone_heading.text = "DEADZONE CALIBRATION"
	deadzone_heading.add_theme_font_size_override("font_size", 17)
	root_vbox.add_child(deadzone_heading)

	left_deadzone_slider = _add_slider_row(
		root_vbox,
		"Left Stick",
		0.03,
		0.45,
		0.01,
		_on_left_deadzone_changed
	)
	right_deadzone_slider = _add_slider_row(
		root_vbox,
		"Right Stick",
		0.03,
		0.45,
		0.01,
		_on_right_deadzone_changed
	)
	trigger_deadzone_slider = _add_slider_row(
		root_vbox,
		"Triggers",
		0.01,
		0.40,
		0.01,
		_on_trigger_deadzone_changed
	)

	var calibration_row := HBoxContainer.new()
	calibration_row.add_theme_constant_override("separation", 10)
	root_vbox.add_child(calibration_row)
	calibration_button = Button.new()
	calibration_button.text = "AUTO-CALIBRATE (2 SEC)"
	calibration_button.tooltip_text = (
		"Release both sticks and triggers, then keep them untouched for 2 seconds."
	)
	calibration_button.pressed.connect(_start_calibration)
	MenuStyler.style_button(calibration_button, Color(0.32, 0.86, 0.68), 40.0)
	calibration_row.add_child(calibration_button)
	calibration_label = Label.new()
	calibration_label.text = "Release inputs before calibrating."
	calibration_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	calibration_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	calibration_row.add_child(calibration_label)

	var live_heading := Label.new()
	live_heading.text = "LIVE INPUT"
	live_heading.add_theme_font_size_override("font_size", 17)
	root_vbox.add_child(live_heading)

	live_label = Label.new()
	live_label.custom_minimum_size.y = 90.0
	live_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	live_label.add_theme_font_size_override("font_size", 15)
	live_label.modulate = Color(0.90, 0.89, 0.82)
	root_vbox.add_child(live_label)

	close_button = Button.new()
	close_button.text = "BACK TO SETTINGS"
	close_button.pressed.connect(close_panel)
	MenuStyler.style_button(close_button, Color(1.0, 0.76, 0.25), 44.0)
	root_vbox.add_child(close_button)
	MenuStyler.apply_menu_consistency(self)
	MenuStyler.apply_premium_design(self, &"popup")


func _add_slider_row(
	parent: VBoxContainer,
	label_text: String,
	minimum: float,
	maximum: float,
	step_value: float,
	callback: Callable
) -> HSlider:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 110.0
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step_value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(callback)
	row.add_child(slider)
	var value_label := Label.new()
	value_label.name = "ValueLabel"
	value_label.custom_minimum_size.x = 58.0
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)
	slider.set_meta("value_label", value_label)
	return slider


func _refresh_device_list() -> void:
	if device_option == null or controller_support == null:
		return
	_refreshing_ui = true
	device_option.clear()
	device_option.add_item("Auto (last controller used)")
	device_option.set_item_metadata(0, -1)
	var selected_index := 0
	var descriptors := controller_support.get_connected_controller_descriptors()
	for descriptor in descriptors:
		var device_id := int(descriptor.get("device_id", -1))
		var suffix := ""
		if bool(descriptor.get("steam_input", false)):
			suffix = "  [Steam Input]"
		device_option.add_item(
			"%s%s" % [str(descriptor.get("name", "Controller")), suffix]
		)
		var item_index := device_option.item_count - 1
		device_option.set_item_metadata(item_index, device_id)
		if (
			not controller_support.is_controller_selection_auto()
			and str(descriptor.get("profile_key", ""))
			== controller_support.preferred_controller_profile
		):
			selected_index = item_index
	device_option.select(selected_index)
	_selected_preview_device = int(
		device_option.get_item_metadata(selected_index)
	)
	if _selected_preview_device < 0:
		_selected_preview_device = controller_support.active_device_id
	_refreshing_ui = false
	_sync_profile_controls()


func _sync_profile_controls() -> void:
	if controller_support == null or left_deadzone_slider == null:
		return
	_refreshing_ui = true
	left_deadzone_slider.set_value_no_signal(
		controller_support.left_stick_deadzone
	)
	right_deadzone_slider.set_value_no_signal(
		controller_support.right_stick_deadzone
	)
	trigger_deadzone_slider.set_value_no_signal(
		controller_support.trigger_deadzone
	)
	if glyph_option != null:
		for index in range(glyph_option.item_count):
			if StringName(str(glyph_option.get_item_metadata(index))) == controller_support.device_prompt_family_override:
				glyph_option.select(index)
				break
	_update_slider_label(left_deadzone_slider)
	_update_slider_label(right_deadzone_slider)
	_update_slider_label(trigger_deadzone_slider)
	_refreshing_ui = false
	_update_status_text()


func _update_slider_label(slider: HSlider) -> void:
	var value_label := slider.get_meta("value_label", null) as Label
	if value_label != null:
		value_label.text = "%d%%" % roundi(slider.value * 100.0)


func _update_status_text() -> void:
	if controller_support == null or status_label == null:
		return
	var mode := (
		"AUTO ASSIGN"
		if controller_support.is_controller_selection_auto()
		else "LOCKED TO SELECTED PAD"
	)
	var name := controller_support.get_controller_name()
	status_label.text = "%s  •  %s  •  %s" % [
		mode,
		controller_support.get_prompt_family_text().to_upper(),
		name
	]


func _update_live_readout() -> void:
	var device := _selected_preview_device
	if device < 0:
		device = controller_support.active_device_id
	var snapshot := controller_support.get_live_input_snapshot(device)
	if snapshot.is_empty():
		live_label.text = "No controller detected. Hot-plug one at any time."
		return
	var left: Vector2 = snapshot.get("left_stick", Vector2.ZERO)
	var right: Vector2 = snapshot.get("right_stick", Vector2.ZERO)
	var buttons: Array = snapshot.get("buttons", [])
	var mapping_status := (
		"mapped"
		if bool(snapshot.get("known_mapping", false))
		else "generic mapping"
	)
	var steam_text := (
		"Steam Input"
		if bool(snapshot.get("steam_input", false))
		else "native input"
	)
	live_label.text = (
		"LS  X %+0.2f  Y %+0.2f     RS  X %+0.2f  Y %+0.2f\n"
		+ "LT %.2f     RT %.2f     Buttons: %s\n"
		+ "%s • %s • device %d"
	) % [
		left.x,
		left.y,
		right.x,
		right.y,
		float(snapshot.get("left_trigger", 0.0)),
		float(snapshot.get("right_trigger", 0.0)),
		", ".join(PackedStringArray(buttons)) if not buttons.is_empty() else "none",
		steam_text,
		mapping_status,
		int(snapshot.get("device_id", -1))
	]


func _on_device_selected(index: int) -> void:
	if _refreshing_ui or controller_support == null:
		return
	var device_id := int(device_option.get_item_metadata(index))
	if device_id < 0:
		controller_support.select_auto_controller()
		_selected_preview_device = controller_support.active_device_id
	else:
		controller_support.select_controller(device_id)
		_selected_preview_device = device_id
	_sync_profile_controls()


func _on_active_controller_changed(device_id: int, _name: String) -> void:
	if controller_support.is_controller_selection_auto():
		_selected_preview_device = device_id
		_update_status_text()
		_sync_profile_controls()


func _on_glyph_family_selected(index: int) -> void:
	if _refreshing_ui or controller_support == null:
		return
	controller_support.set_device_prompt_family_override(
		StringName(str(glyph_option.get_item_metadata(index)))
	)
	_update_status_text()


func _on_left_deadzone_changed(value: float) -> void:
	if _refreshing_ui:
		return
	controller_support.set_left_stick_deadzone(value)
	_update_slider_label(left_deadzone_slider)


func _on_right_deadzone_changed(value: float) -> void:
	if _refreshing_ui:
		return
	controller_support.set_right_stick_deadzone(value)
	_update_slider_label(right_deadzone_slider)


func _on_trigger_deadzone_changed(value: float) -> void:
	if _refreshing_ui:
		return
	controller_support.set_trigger_deadzone(value)
	_update_slider_label(trigger_deadzone_slider)


func _start_calibration() -> void:
	if controller_support.start_deadzone_calibration():
		calibration_button.disabled = true


func _on_calibration_started(_device_id: int, duration: float) -> void:
	calibration_button.disabled = true
	calibration_label.text = (
		"Keep both sticks and triggers released... %.1fs" % duration
	)


func _on_calibration_finished(success: bool, message: String) -> void:
	calibration_button.disabled = false
	calibration_label.text = message
	calibration_label.modulate = (
		Color(0.55, 1.0, 0.72)
		if success
		else Color(1.0, 0.58, 0.46)
	)
	_sync_profile_controls()
