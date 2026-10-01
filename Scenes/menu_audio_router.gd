class_name MenuAudioRouter
extends Node


@export var ui_root: Node
@export var click_audio: AudioStreamPlayer

var _scan_elapsed: float = 0.0


func _ready() -> void:
	if ui_root == null:
		ui_root = get_parent()
	if click_audio == null:
		push_error("MenuAudioRouter has no click AudioStreamPlayer.")
		return
	_register_buttons()
	get_tree().node_added.connect(_on_node_added)


func _process(delta: float) -> void:
	_scan_elapsed += delta
	if _scan_elapsed < 0.25:
		return
	_scan_elapsed = 0.0
	_register_buttons()


func _on_node_added(node: Node) -> void:
	if is_instance_valid(ui_root) and ui_root.is_ancestor_of(node):
		call_deferred("_register_control", node)


func _register_buttons() -> void:
	if not is_instance_valid(ui_root):
		return
	for node in ui_root.find_children("*", "Button", true, false):
		_register_button(node)
	for node in ui_root.find_children("*", "TabContainer", true, false):
		_register_tab_container(node)
	for node in ui_root.find_children("*", "TabBar", true, false):
		_register_tab_bar(node)


func _register_control(node: Node) -> void:
	_register_button(node)
	_register_tab_container(node)
	_register_tab_bar(node)


func _register_button(node: Node) -> void:
	var button := node as Button
	if button == null:
		return
	var callback := Callable(self, "_play_click")
	if not button.button_down.is_connected(callback):
		button.button_down.connect(callback)


func _register_tab_container(node: Node) -> void:
	var tabs := node as TabContainer
	if tabs == null:
		return
	var callback := Callable(self, "_play_tab_click")
	if not tabs.tab_clicked.is_connected(callback):
		tabs.tab_clicked.connect(callback)


func _register_tab_bar(node: Node) -> void:
	var tabs := node as TabBar
	if tabs == null or tabs.get_parent() is TabContainer:
		return
	var callback := Callable(self, "_play_tab_click")
	if not tabs.tab_clicked.is_connected(callback):
		tabs.tab_clicked.connect(callback)


func _play_tab_click(_tab_index: int) -> void:
	_play_click()


func _play_click() -> void:
	if click_audio == null or click_audio.stream == null:
		return
	click_audio.play()
