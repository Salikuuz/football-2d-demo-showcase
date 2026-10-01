extends CanvasLayer


var _panel: PanelContainer
var _label: Label
var _refresh_remaining: float = 0.0
var _overlay_visible: bool = false


func _ready() -> void:
	if OS.has_environment("THEODORE_RL_V2_HEADLESS"):
		set_process(false)
		set_process_unhandled_key_input(false)
		return
	layer = 200
	_panel = PanelContainer.new()
	_panel.name = "HybridAIDebugPanel"
	_panel.position = Vector2(20.0, 20.0)
	_panel.custom_minimum_size = Vector2(640.0, 120.0)
	_label = Label.new()
	_label.name = "HybridAIDebugLabel"
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.text = "Hybrid AI debug: press F10"
	_panel.add_child(_label)
	add_child(_panel)
	_panel.visible = false
	set_process(true)
	set_process_unhandled_key_input(true)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F10:
		_overlay_visible = not _overlay_visible
		_panel.visible = _overlay_visible
		if _overlay_visible:
			_refresh_text()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not _overlay_visible:
		return
	_refresh_remaining -= delta
	if _refresh_remaining <= 0.0:
		_refresh_remaining = 0.25
		_refresh_text()


func _refresh_text() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		_label.text = "Hybrid AI debug: no current scene"
		return
	var controllers: Array[Node] = []
	_collect_controllers(scene, controllers)
	if controllers.is_empty():
		_label.text = "Hybrid AI debug: no CPU controllers in the current scene"
		return
	var lines: PackedStringArray = [
		"AI DECISION DEBUG (F10 to close)"
	]
	for controller in controllers:
		var state := controller.call("get_hybrid_ai_debug_state") as Dictionary
		var player: Node = controller.get("controlled_player")
		var player_label := "unknown"
		if is_instance_valid(player):
			player_label = "%s/%s" % [
				str(player.get("team")),
				str(player.get("player_name"))
			]
		var target: Vector2 = state.get("attack_target", Vector2.ZERO)
		var destination: Vector2 = state.get(
			"attack_destination",
			Vector2.ZERO
		)
		var rejected_value: Variant = state.get(
			"attack_rejected",
			PackedStringArray()
		)
		var rejected_text := "none"
		if rejected_value is PackedStringArray:
			var rejected_array := rejected_value as PackedStringArray
			if not rejected_array.is_empty():
				rejected_text = "; ".join(rejected_array)
		elif rejected_value is Array:
			var rejected_array_generic: Array = rejected_value
			var rejected_list := PackedStringArray()
			for reason in rejected_array_generic:
				rejected_list.append(str(reason))
			if not rejected_list.is_empty():
				rejected_text = "; ".join(rejected_list)
		var candidate_scores: Dictionary = state.get(
			"attack_candidate_scores",
			{}
		)
		var score_parts: PackedStringArray = PackedStringArray()
		for candidate_name in candidate_scores:
			score_parts.append(
				"%s %.2f" % [
					str(candidate_name),
					float(candidate_scores[candidate_name])
				]
			)
		var scores_text := (
			", ".join(score_parts)
			if not score_parts.is_empty()
			else "none"
		)
		lines.append(
			"%s | ROLE %s | PERSONALITY %s/%s (depth %.2f) | INTENT %s | TARGET %s -> %s"
			% [
				player_label,
				str(state.get("tactical_role", "none")),
				str(state.get("cpu_personality", "none")),
				str(state.get("personality_strategy", "balanced")),
				float(state.get("personality_planning_depth", 0.0)),
				str(state.get("attack_intent", "none")),
				_format_point(target),
				_format_point(destination)
			]
		)
		lines.append(
			"  SHOT QUALITY %.2f | PASS QUALITY %.2f | PRESSURE %.2f | WHY %s"
			% [
				float(state.get("shot_quality", 0.0)),
				float(state.get("pass_quality", 0.0)),
				float(state.get("attack_pressure", 0.0)),
				str(state.get("attack_reason", "none"))
			]
		)
		lines.append(
			"  REJECTED %s | CANDIDATES %s | OFF-BALL %s (%s) | FIRST TOUCH %s"
			% [
				rejected_text,
				scores_text,
				str(state.get("off_ball_role", "none")),
				str(state.get("off_ball_reason", "none")),
				str(state.get("first_touch_mode", "none"))
			]
		)
	_label.text = "\n".join(lines)


func _format_point(value: Vector2) -> String:
	return "(%d,%d)" % [roundi(value.x), roundi(value.y)]


func _collect_controllers(node: Node, output: Array[Node]) -> void:
	if node.has_method("get_hybrid_ai_debug_state"):
		output.append(node)
	for child in node.get_children():
		_collect_controllers(child, output)
