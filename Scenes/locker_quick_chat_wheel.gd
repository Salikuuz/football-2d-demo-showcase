class_name FootballLockerQuickChatWheel
extends Control


signal slot_selected(index: int)
signal cancelled

const SLOT_COUNT: int = 8

var _buttons: Array[Button] = []
var _title: Label
var _center_label: Label
var _selected_item_name: String = ""
var _loadout_ids: Array[String] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	resized.connect(_layout_wheel)
	hide()


func open_for_item(
	item_name: String,
	loadout_ids: Array[String],
	payloads: Array[String]
) -> void:
	_selected_item_name = item_name
	_loadout_ids = loadout_ids.duplicate()
	_title.text = "PLACE \"%s\" ON YOUR QUICK-CHAT WHEEL" % item_name.to_upper()
	for index: int in range(mini(_buttons.size(), payloads.size())):
		_buttons[index].text = "%d\n%s" % [index + 1, payloads[index]]
	show()
	_layout_wheel()
	if not _buttons.is_empty():
		_buttons[0].grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		hide()
		cancelled.emit()


func _build_ui() -> void:
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.005, 0.01, 0.015, 0.91)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 23)
	_title.add_theme_color_override("font_color", Color("f5f7fa"))
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title)
	_center_label = Label.new()
	_center_label.text = "SELECT A DIRECTION\nDuplicates swap positions"
	_center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_center_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_center_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_center_label.add_theme_font_size_override("font_size", 14)
	_center_label.add_theme_color_override("font_color", Color("b8c4d0"))
	_center_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_center_label)
	for index: int in range(SLOT_COUNT):
		var button := Button.new()
		button.name = "WheelSlot%d" % (index + 1)
		button.custom_minimum_size = Vector2(190.0, 58.0)
		button.size = button.custom_minimum_size
		button.add_theme_font_size_override("font_size", 15)
		button.pressed.connect(_choose_slot.bind(index))
		add_child(button)
		_buttons.append(button)
	var cancel := Button.new()
	cancel.name = "CancelWheel"
	cancel.text = "CANCEL"
	cancel.custom_minimum_size = Vector2(140.0, 44.0)
	cancel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	cancel.position = Vector2(-70.0, -62.0)
	cancel.pressed.connect(_cancel)
	add_child(cancel)
	MenuStyler.apply_premium_design(self, &"quick_chat")
	MenuStyler.install_click_sounds(self)


func _layout_wheel() -> void:
	if _title == null:
		return
	var center: Vector2 = size * 0.5
	var radius: float = minf(245.0, maxf(155.0, minf(size.x, size.y) * 0.32))
	_title.position = Vector2(40.0, 34.0)
	_title.size = Vector2(maxf(1.0, size.x - 80.0), 42.0)
	_center_label.position = center - Vector2(125.0, 48.0)
	_center_label.size = Vector2(250.0, 96.0)
	for index: int in range(_buttons.size()):
		var angle: float = -PI * 0.5 + TAU * float(index) / float(SLOT_COUNT)
		var button: Button = _buttons[index]
		button.position = center + Vector2.from_angle(angle) * radius - button.size * 0.5
	queue_redraw()


func _draw() -> void:
	if not visible:
		return
	var center: Vector2 = size * 0.5
	var radius: float = minf(245.0, maxf(155.0, minf(size.x, size.y) * 0.32))
	draw_circle(center, radius + 62.0, Color(0.04, 0.075, 0.10, 0.72))
	draw_arc(center, radius + 22.0, 0.0, TAU, 96, Color(0.84, 0.89, 0.94, 0.58), 2.0, true)
	for index: int in range(SLOT_COUNT):
		var angle: float = -PI * 0.5 + TAU * float(index) / float(SLOT_COUNT)
		draw_line(center + Vector2.from_angle(angle) * 74.0, center + Vector2.from_angle(angle) * (radius - 78.0), Color(0.75, 0.82, 0.9, 0.22), 2.0, true)


func _choose_slot(index: int) -> void:
	hide()
	slot_selected.emit(index)


func _cancel() -> void:
	hide()
	cancelled.emit()
