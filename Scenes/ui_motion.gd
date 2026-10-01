class_name UIMotion
extends RefCounted


const SHOW_DURATION: float = 0.22
const HIDE_DURATION: float = 0.16
const BUTTON_HOVER_SCALE: Vector2 = Vector2(1.035, 1.035)


static func prepare_buttons(root: Node) -> void:
	for node in root.find_children("*", "Button", true, false):
		var button := node as Button
		if button == null or button.has_meta("_motion_ready"):
			continue

		button.set_meta("_motion_ready", true)
		_center_pivot(button)
		button.resized.connect(
			func() -> void:
				_center_pivot(button)
		)
		button.mouse_entered.connect(
			func() -> void:
				if not button.disabled:
					_tween_scale(
						button,
						BUTTON_HOVER_SCALE,
						0.11
					)
		)
		button.mouse_exited.connect(
			func() -> void:
				_tween_scale(button, Vector2.ONE, 0.11)
		)
		button.focus_entered.connect(
			func() -> void:
				if not button.disabled:
					_tween_scale(
						button,
						BUTTON_HOVER_SCALE,
						0.11
					)
		)
		button.focus_exited.connect(
			func() -> void:
				_tween_scale(button, Vector2.ONE, 0.11)
		)
		button.pressed.connect(
			func() -> void:
				press_feedback(button)
		)


static func show_control(
	control: Control,
	duration: float = SHOW_DURATION,
	start_scale: Vector2 = Vector2(0.96, 0.96)
) -> void:
	if control == null:
		return

	_kill_tween(control, "_visibility_tween")
	_center_pivot(control)
	control.show()
	control.modulate.a = 0.0
	control.scale = start_scale

	var tween := control.create_tween()
	control.set_meta("_visibility_tween", tween)
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUART)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(
		control,
		"modulate:a",
		1.0,
		maxf(0.01, duration)
	)
	tween.tween_property(
		control,
		"scale",
		Vector2.ONE,
		maxf(0.01, duration)
	)


static func hide_control(
	control: Control,
	duration: float = HIDE_DURATION,
	end_scale: Vector2 = Vector2(0.97, 0.97)
) -> void:
	if control == null or not control.visible:
		return

	_kill_tween(control, "_visibility_tween")
	_center_pivot(control)
	var tween := control.create_tween()
	control.set_meta("_visibility_tween", tween)
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(
		control,
		"modulate:a",
		0.0,
		maxf(0.01, duration)
	)
	tween.tween_property(
		control,
		"scale",
		end_scale,
		maxf(0.01, duration)
	)
	tween.chain().tween_callback(
		func() -> void:
			control.hide()
			control.modulate.a = 1.0
			control.scale = Vector2.ONE
	)


static func pulse(
	control: Control,
	peak_scale: Vector2 = Vector2(1.12, 1.12),
	duration: float = 0.2
) -> void:
	if control == null or not control.is_visible_in_tree():
		return

	_kill_tween(control, "_pulse_tween")
	_center_pivot(control)
	control.scale = Vector2.ONE
	var tween := control.create_tween()
	control.set_meta("_pulse_tween", tween)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(
		control,
		"scale",
		peak_scale,
		maxf(0.01, duration * 0.45)
	)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(
		control,
		"scale",
		Vector2.ONE,
		maxf(0.01, duration * 0.55)
	)


static func press_feedback(button: Button) -> void:
	if button == null:
		return

	_kill_tween(button, "_scale_tween")
	_center_pivot(button)
	var tween := button.create_tween()
	button.set_meta("_scale_tween", tween)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(
		button,
		"scale",
		Vector2(0.97, 0.97),
		0.055
	)
	tween.tween_property(
		button,
		"scale",
		BUTTON_HOVER_SCALE if button.is_hovered()
		else Vector2.ONE,
		0.09
	)


static func _tween_scale(
	control: Control,
	target_scale: Vector2,
	duration: float
) -> void:
	_kill_tween(control, "_scale_tween")
	_center_pivot(control)
	var tween := control.create_tween()
	control.set_meta("_scale_tween", tween)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(
		control,
		"scale",
		target_scale,
		duration
	)


static func _center_pivot(control: Control) -> void:
	control.pivot_offset = control.size * 0.5


static func _kill_tween(control: Control, key: StringName) -> void:
	if not control.has_meta(key):
		return
	var tween: Variant = control.get_meta(key)
	if tween is Tween and tween.is_valid():
		tween.kill()
	control.remove_meta(key)
