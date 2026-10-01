class_name FootballIngamePauseOverlay
extends CanvasLayer


var match_manager: FootballMatchManager
var _overlay_root: Control
var _main_panel: PanelContainer
var _confirm_panel: PanelContainer
var _status_label: Label
var _resume_button: Button
var _cancel_button: Button
var _confirm_title: Label
var _confirm_body: Label
var _confirm_button: Button
var _confirm_back_button: Button
var _owns_tree_pause: bool = false
var _menu_open: bool = false
var _network_pause_active: bool = false
var _legacy_cancel_button: Button
var _blur_snapshot: TextureRect


func setup(manager: FootballMatchManager) -> void:
	match_manager = manager
	layer = 220
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	if not match_manager.match_started.is_connected(_on_match_started):
		match_manager.match_started.connect(_on_match_started)
	if not match_manager.match_ended.is_connected(_on_match_ended):
		match_manager.match_ended.connect(_on_match_ended)
	if not match_manager.match_cancelled.is_connected(_on_match_cancelled):
		match_manager.match_cancelled.connect(_on_match_cancelled)
	_suppress_legacy_cancel_button()
	set_process_input(true)


func _build_ui() -> void:
	_overlay_root = Control.new()
	_overlay_root.name = "PauseOverlay"
	_overlay_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay_root.hide()
	add_child(_overlay_root)

	# Use a detached, one-time screenshot as the pause background.
	# This avoids live screen-texture/back-buffer rendering entirely.
	_blur_snapshot = TextureRect.new()
	_blur_snapshot.name = "PauseSnapshot"
	_blur_snapshot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_blur_snapshot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_blur_snapshot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_blur_snapshot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_blur_snapshot.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_overlay_root.add_child(_blur_snapshot)

	var dim := ColorRect.new()
	dim.name = "PauseDim"
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.color = Color(0.015, 0.02, 0.032, 0.62)
	_overlay_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_root.add_child(center)

	_main_panel = _make_panel(Vector2(430.0, 410.0))
	center.add_child(_main_panel)
	_build_main_panel(_main_panel)

	_confirm_panel = _make_panel(Vector2(500.0, 330.0))
	center.add_child(_confirm_panel)
	_build_confirm_panel(_confirm_panel)
	_confirm_panel.hide()
	_configure_controller_focus()


func _make_panel(minimum: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = minimum
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.032, 0.048, 0.97)
	style.border_color = Color(0.28, 0.34, 0.45, 0.95)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.shadow_color = Color(0, 0, 0, 0.55)
	style.shadow_size = 18
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _build_main_panel(panel: PanelContainer) -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)

	var icon := Label.new()
	icon.text = "Ⅱ"
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 50)
	icon.add_theme_color_override("font_color", Color(0.94, 0.96, 1.0))
	column.add_child(icon)

	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 29)
	title.add_theme_color_override("font_color", Color(0.98, 0.98, 1.0))
	column.add_child(title)

	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size", 13)
	_status_label.add_theme_color_override("font_color", Color(0.64, 0.70, 0.80))
	column.add_child(_status_label)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 6
	column.add_child(spacer)

	_resume_button = Button.new()
	_resume_button.text = "RESUME"
	_resume_button.custom_minimum_size.y = 52
	_apply_button_style(
		_resume_button,
		Color(0.10, 0.25, 0.18, 0.96),
		Color(0.30, 0.92, 0.56),
		Color.WHITE
	)
	_resume_button.pressed.connect(_close_menu)
	column.add_child(_resume_button)

	_cancel_button = Button.new()
	_cancel_button.text = "CANCEL MATCH"
	_cancel_button.custom_minimum_size.y = 50
	_apply_button_style(
		_cancel_button,
		Color(0.30, 0.075, 0.085, 0.96),
		Color(1.0, 0.30, 0.34),
		Color.WHITE
	)
	_cancel_button.pressed.connect(_show_cancel_confirmation)
	column.add_child(_cancel_button)


func _build_confirm_panel(panel: PanelContainer) -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	margin.add_child(column)

	_confirm_title = Label.new()
	_confirm_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_confirm_title.add_theme_font_size_override("font_size", 25)
	_confirm_title.add_theme_color_override("font_color", Color(1.0, 0.38, 0.40))
	column.add_child(_confirm_title)

	_confirm_body = Label.new()
	_confirm_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_confirm_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirm_body.custom_minimum_size.y = 92
	_confirm_body.add_theme_font_size_override("font_size", 15)
	_confirm_body.add_theme_color_override("font_color", Color(0.88, 0.90, 0.94))
	column.add_child(_confirm_body)

	_confirm_button = Button.new()
	_confirm_button.custom_minimum_size.y = 52
	_apply_button_style(
		_confirm_button,
		Color(0.34, 0.065, 0.075, 0.98),
		Color(1.0, 0.27, 0.31),
		Color.WHITE
	)
	_confirm_button.pressed.connect(_confirm_cancel)
	column.add_child(_confirm_button)

	_confirm_back_button = Button.new()
	_confirm_back_button.text = "GO BACK"
	_confirm_back_button.custom_minimum_size.y = 46
	_apply_button_style(
		_confirm_back_button,
		Color(0.075, 0.085, 0.115, 0.98),
		Color(0.46, 0.52, 0.64),
		Color.WHITE
	)
	_confirm_back_button.pressed.connect(_hide_cancel_confirmation)
	column.add_child(_confirm_back_button)


func _apply_button_style(
	button: Button,
	background: Color,
	border: Color,
	font_color: Color
) -> void:
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", font_color)
	button.add_theme_color_override("font_pressed_color", font_color)

	for state_name: String in ["normal", "hover", "pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = background
		if state_name == "hover":
			style.bg_color = background.lightened(0.09)
		elif state_name == "pressed":
			style.bg_color = background.darkened(0.08)
		style.border_color = border
		style.set_border_width_all(1)
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_left = 10
		style.corner_radius_bottom_right = 10
		button.add_theme_stylebox_override(state_name, style)

	# Custom pause buttons otherwise have no obvious controller-focus state.
	var focus_style := StyleBoxFlat.new()
	focus_style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	focus_style.border_color = border.lightened(0.22)
	focus_style.set_border_width_all(3)
	focus_style.corner_radius_top_left = 10
	focus_style.corner_radius_top_right = 10
	focus_style.corner_radius_bottom_left = 10
	focus_style.corner_radius_bottom_right = 10
	focus_style.shadow_color = Color(border.r, border.g, border.b, 0.30)
	focus_style.shadow_size = 8
	button.add_theme_stylebox_override("focus", focus_style)


func _configure_controller_focus() -> void:
	# Explicit vertical neighbors keep the pause menu deterministic even while the
	# SceneTree is paused. Up/Down wrap within the active panel like a console menu.
	_set_focus_neighbor(_resume_button, SIDE_TOP, _cancel_button)
	_set_focus_neighbor(_resume_button, SIDE_BOTTOM, _cancel_button)
	_set_focus_neighbor(_cancel_button, SIDE_TOP, _resume_button)
	_set_focus_neighbor(_cancel_button, SIDE_BOTTOM, _resume_button)
	_set_focus_neighbor(_confirm_button, SIDE_TOP, _confirm_back_button)
	_set_focus_neighbor(_confirm_button, SIDE_BOTTOM, _confirm_back_button)
	_set_focus_neighbor(_confirm_back_button, SIDE_TOP, _confirm_button)
	_set_focus_neighbor(_confirm_back_button, SIDE_BOTTOM, _confirm_button)


func _set_focus_neighbor(
	source: Control,
	side: int,
	target: Control
) -> void:
	if source == null or target == null:
		return
	var path: NodePath = source.get_path_to(target)
	match side:
		SIDE_LEFT:
			source.focus_neighbor_left = path
		SIDE_TOP:
			source.focus_neighbor_top = path
		SIDE_RIGHT:
			source.focus_neighbor_right = path
		SIDE_BOTTOM:
			source.focus_neighbor_bottom = path


func _focus_main_panel() -> void:
	if _resume_button != null and not _resume_button.disabled:
		_resume_button.grab_focus()
	elif _cancel_button != null and not _cancel_button.disabled:
		_cancel_button.grab_focus()


func _focus_confirmation_panel() -> void:
	if _confirm_button != null and not _confirm_button.disabled:
		_confirm_button.grab_focus()
	elif _confirm_back_button != null:
		_confirm_back_button.grab_focus()


func _suppress_legacy_cancel_button() -> void:
	if match_manager == null or match_manager.get_parent() == null:
		return
	_legacy_cancel_button = match_manager.get_parent().get_node_or_null(
		"HUD/Scoreboard/SessionButtons/CancelMatchButton"
	) as Button
	if _legacy_cancel_button == null:
		return
	_legacy_cancel_button.hide()
	_legacy_cancel_button.disabled = true
	_legacy_cancel_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not _legacy_cancel_button.visibility_changed.is_connected(
		_keep_legacy_cancel_hidden
	):
		_legacy_cancel_button.visibility_changed.connect(
			_keep_legacy_cancel_hidden
		)


func _keep_legacy_cancel_hidden() -> void:
	if _legacy_cancel_button == null:
		return
	if _legacy_cancel_button.visible:
		_legacy_cancel_button.hide()
	_legacy_cancel_button.disabled = true


func _close_transient_quick_chat() -> void:
	# ESC is handled here in _input(), before the QuickChat Control gets its
	# normal _process() tick. Close it explicitly before pausing/capturing the
	# frame so the wheel cannot be left logically open behind this CanvasLayer.
	if match_manager == null or match_manager.get_parent() == null:
		return
	var quick_chat := match_manager.get_parent().get_node_or_null(
		"HUD/QuickChat"
	)
	if quick_chat != null and quick_chat.has_method("force_close_without_send"):
		quick_chat.call("force_close_without_send")


func _refresh_pause_snapshot() -> void:
	if _blur_snapshot == null:
		return

	var viewport_texture: ViewportTexture = get_viewport().get_texture()
	if viewport_texture == null:
		_blur_snapshot.texture = null
		return

	var image: Image = viewport_texture.get_image()
	if image == null or image.is_empty():
		_blur_snapshot.texture = null
		return

	var source_size: Vector2i = image.get_size()
	if source_size.x <= 0 or source_size.y <= 0:
		_blur_snapshot.texture = null
		return

	var blurred_width: int = maxi(1, source_size.x / 10)
	var blurred_height: int = maxi(1, source_size.y / 10)
	image.resize(
		blurred_width,
		blurred_height,
		Image.INTERPOLATE_LANCZOS
	)
	_blur_snapshot.texture = ImageTexture.create_from_image(image)


func _clear_pause_snapshot() -> void:
	if _blur_snapshot != null:
		_blur_snapshot.texture = null


func _input(event: InputEvent) -> void:
	if match_manager == null or not match_manager.game_has_started:
		return

	var pause_toggle := _is_pause_toggle_event(event)
	var pause_back := _menu_open and event.is_action_pressed(&"ui_cancel")
	if not pause_toggle and not pause_back:
		return

	# Clients cannot dismiss a host-synchronized network pause locally.
	if _network_pause_active and not multiplayer.is_server():
		get_viewport().set_input_as_handled()
		return

	# Start/Menu/Options (or Escape on keyboard) is the actual pause toggle.
	# B/Circle remains the standard UI Back action, but only while the pause
	# menu is already open; pressing B/Circle during gameplay can no longer
	# accidentally pause the match.
	if _confirm_panel != null and _confirm_panel.visible:
		_hide_cancel_confirmation()
	elif _menu_open:
		_close_menu()
	elif pause_toggle:
		_open_menu()
	get_viewport().set_input_as_handled()


func request_mobile_toggle() -> void:
	if match_manager == null or not match_manager.game_has_started:
		return
	# Mobile calls this directly instead of synthesizing an Escape key event.
	# That avoids browser/Web input dispatch differences while reusing the exact
	# same pause-menu state transitions as keyboard/controller.
	if _network_pause_active and not multiplayer.is_server():
		return
	if _confirm_panel != null and _confirm_panel.visible:
		_hide_cancel_confirmation()
	elif _menu_open:
		_close_menu()
	else:
		_open_menu()


func _is_pause_toggle_event(event: InputEvent) -> bool:
	var key_event := event as InputEventKey
	if key_event != null:
		return (
			key_event.pressed
			and not key_event.echo
			and (
				key_event.keycode == KEY_ESCAPE
				or key_event.physical_keycode == KEY_ESCAPE
			)
		)

	var joy_event := event as InputEventJoypadButton
	return (
		joy_event != null
		and joy_event.pressed
		and joy_event.button_index == JOY_BUTTON_START
	)


func _open_menu() -> void:
	if match_manager == null or not match_manager.game_has_started:
		return

	_close_transient_quick_chat()

	if multiplayer.is_server() and match_manager.can_host_pause_online_match():
		_set_host_network_pause(true)
		return

	_refresh_pause_snapshot()
	_menu_open = true
	_overlay_root.show()
	_main_panel.show()
	_confirm_panel.hide()

	if match_manager.can_locally_pause_match_simulation():
		_status_label.text = "GAME PAUSED"
		if not get_tree().paused:
			get_tree().paused = true
			_owns_tree_pause = true
	else:
		_status_label.text = "ONLINE MATCH • ONLY THE HOST CAN PAUSE THE MATCH"

	_resume_button.disabled = false
	_resume_button.text = "RESUME"
	var host_can_cancel: bool = multiplayer.is_server()
	_cancel_button.disabled = not host_can_cancel
	if not host_can_cancel:
		_cancel_button.text = "HOST CONTROLS MATCH"
	elif match_manager.cancel_match_is_forfeit():
		_cancel_button.text = "FORFEIT MATCH"
	else:
		_cancel_button.text = "CANCEL MATCH"

	_focus_main_panel.call_deferred()


func _close_menu() -> void:
	if _network_pause_active:
		if multiplayer.is_server():
			_set_host_network_pause(false)
		return

	if _owns_tree_pause:
		get_tree().paused = false
		_owns_tree_pause = false
	_menu_open = false
	if _overlay_root != null:
		_overlay_root.hide()
	get_viewport().gui_release_focus()
	_clear_pause_snapshot()


func _set_host_network_pause(paused: bool) -> void:
	if not multiplayer.is_server():
		return
	_apply_network_pause_state.rpc(paused)


@rpc("authority", "call_local", "reliable")
func _apply_network_pause_state(paused: bool) -> void:
	_network_pause_active = paused
	_owns_tree_pause = false

	if paused:
		_close_transient_quick_chat()
		_refresh_pause_snapshot()
		_menu_open = true
		_overlay_root.show()
		_main_panel.show()
		_confirm_panel.hide()

		if multiplayer.is_server():
			_status_label.text = "MATCH PAUSED • ALL PLAYERS"
			_resume_button.disabled = false
			_resume_button.text = "RESUME MATCH"
			_cancel_button.disabled = false
			_cancel_button.text = (
				"FORFEIT MATCH"
				if match_manager.cancel_match_is_forfeit()
				else "CANCEL MATCH"
			)
		else:
			_status_label.text = "MATCH PAUSED BY HOST"
			_resume_button.disabled = true
			_resume_button.text = "WAITING FOR HOST"
			_cancel_button.disabled = true
			_cancel_button.text = "HOST CONTROLS MATCH"

		get_tree().paused = true
		if multiplayer.is_server():
			_focus_main_panel.call_deferred()
	else:
		if get_tree().paused:
			get_tree().paused = false
		_network_pause_active = false
		_menu_open = false
		_overlay_root.hide()
		_clear_pause_snapshot()


func force_clear_network_pause() -> void:
	_network_pause_active = false
	_owns_tree_pause = false
	_menu_open = false
	if get_tree().paused:
		get_tree().paused = false
	if _overlay_root != null:
		_overlay_root.hide()
	_clear_pause_snapshot()


func _show_cancel_confirmation() -> void:
	if match_manager == null or not multiplayer.is_server():
		return
	var copy: Dictionary = match_manager.get_cancel_match_confirmation_copy()
	_confirm_title.text = str(copy.get("title", "CANCEL MATCH?"))
	_confirm_body.text = str(copy.get("body", "Are you sure?"))
	_confirm_button.text = str(copy.get("confirm", "CONFIRM"))
	_main_panel.hide()
	_confirm_panel.show()
	_focus_confirmation_panel.call_deferred()


func _hide_cancel_confirmation() -> void:
	_confirm_panel.hide()
	_main_panel.show()
	if _cancel_button != null and not _cancel_button.disabled:
		_cancel_button.grab_focus.call_deferred()
	else:
		_focus_main_panel.call_deferred()


func _confirm_cancel() -> void:
	if match_manager == null or not multiplayer.is_server():
		return

	if _network_pause_active:
		_set_host_network_pause(false)
	elif _owns_tree_pause:
		get_tree().paused = false
		_owns_tree_pause = false

	_menu_open = false
	_overlay_root.hide()
	_clear_pause_snapshot()
	match_manager.request_cancel_match()


func _on_match_started() -> void:
	_suppress_legacy_cancel_button()


func _on_match_ended(_winning_team: StringName) -> void:
	_force_close()


func _on_match_cancelled() -> void:
	_force_close()


func _force_close() -> void:
	force_clear_network_pause()
