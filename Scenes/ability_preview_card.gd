class_name FootballAbilityPreviewCard
extends PanelContainer


const PREVIEW_SIZE := Vector2(340.0, 300.0)
const ICON_PATHS: Dictionary = {
	FootballPlayer.ABILITY_NONE: "res://Characters/ability_none.svg",
	FootballPlayer.ABILITY_BURST_DRIBBLE: "res://Characters/ability_burst.svg",
	FootballPlayer.ABILITY_QUICK_TRIGGER: "res://Characters/ability_quick_trigger.svg",
	FootballPlayer.ABILITY_POWER_STRIKE: "res://Characters/ability_power_strike.svg",
	FootballPlayer.ABILITY_OVERDRIVE: "res://Characters/ability_overdrive.svg",
	FootballPlayer.ABILITY_HEEL_TURN: "res://Characters/ability_heel_turn.svg",
	FootballPlayer.ABILITY_ENFORCER: "res://Characters/ability_enforcer.svg",
	FootballPlayer.ABILITY_GOALKEEPER_REACH: "res://Characters/ability_goalkeeper_reach.svg",
	FootballPlayer.ABILITY_TIME_SKIP_PASS: "res://Characters/ability_time_skip_pass.svg",
	FootballPlayer.ABILITY_DIRECT_FINISH: "res://Characters/ability_direct_finish.svg",
	FootballPlayer.ABILITY_ELASTIC_STEP: "res://Characters/ability_elastic_step.svg",
	FootballPlayer.ABILITY_META_VISION: "res://Characters/ability_meta_vision.svg",
	FootballPlayer.ABILITY_COPYCAT: "res://Characters/ability_copycat.svg",
	FootballPlayer.ABILITY_REFLEX_BLOCK: "res://Characters/ability_reflex_block.svg",
	FootballPlayer.ABILITY_IRON_ANCHOR: "res://Characters/ability_iron_anchor.svg",
	FootballPlayer.ABILITY_BLIND_SPOT: "res://Characters/ability_blind_spot.svg",
	FootballPlayer.ABILITY_BOOGIE_WOOGIE: "res://Characters/ability_boogie_woogie.svg",
	FootballPlayer.ABILITY_ECHO: "res://Characters/ability_echo.svg",
	FootballPlayer.ABILITY_RETURN_TAG: "res://Characters/ability_return_tag.svg",
	FootballPlayer.ABILITY_BREAKAWAY: "res://Characters/ability_breakaway.png",
	FootballPlayer.ABILITY_SNAPBACK: "res://Characters/ability_snapback.svg",
	FootballPlayer.ABILITY_SIDE_SWIPE: "res://Characters/ability_side_swipe.svg",
	FootballPlayer.ABILITY_NUTMEG: "res://Characters/ability_nutmeg.svg",
	FootballPlayer.ABILITY_DECOY_RUN: "res://Characters/ability_decoy_run.svg"
}

const SCENARIOS: Dictionary = {
	FootballPlayer.ABILITY_NONE: "Pure fundamentals: carry the ball, read the defender, and finish with a charged shot.",
	FootballPlayer.ABILITY_BURST_DRIBBLE: "Chain both dashes through two defenders while keeping the ball close enough for the finish.",
	FootballPlayer.ABILITY_QUICK_TRIGGER: "Bend a charged shot around the nearest blocker and into the exposed side of goal.",
	FootballPlayer.ABILITY_POWER_STRIKE: "Charge in space, ignite the ball, and overpower the defensive line with a heavy finish.",
	FootballPlayer.ABILITY_OVERDRIVE: "Explode into a distant teammate's pass before either defender can recover.",
	FootballPlayer.ABILITY_HEEL_TURN: "Erase an incoming ball's speed and snap it behind you to escape the press instantly.",
	FootballPlayer.ABILITY_ENFORCER: "Launch a marker out of the lane so your team can attack the space they were protecting.",
	FootballPlayer.ABILITY_GOALKEEPER_REACH: "Dive beyond normal movement range and meet a top-corner shot at the final moment.",
	FootballPlayer.ABILITY_TIME_SKIP_PASS: "Fire through pressure, then brake the ball perfectly into a teammate's forward run.",
	FootballPlayer.ABILITY_DIRECT_FINISH: "Attack a high cross and turn the first touch into an immediate, unstoppable volley.",
	FootballPlayer.ABILITY_ELASTIC_STEP: "Orbit tightly around the ball, wrong-foot the defender, and emerge on a new shooting angle.",
	FootballPlayer.ABILITY_META_VISION: "Read the wall bounce, interception point, and dangerous goal path before anyone else can.",
	FootballPlayer.ABILITY_COPYCAT: "Read a teammate's Power Strike, copy it, and turn their ability into a second threat.",
	FootballPlayer.ABILITY_REFLEX_BLOCK: "Guard the shooting lane and redirect a dangerous strike directly into a counterattack.",
	FootballPlayer.ABILITY_IRON_ANCHOR: "Kill a full-speed shot dead at your feet, taking possession instead of only clearing it.",
	FootballPlayer.ABILITY_BLIND_SPOT: "Push the ball past a marker, vanish through their shadow, and collect it behind them.",
	FootballPlayer.ABILITY_BOOGIE_WOOGIE: "Swap with the nearest opponent and use the arrival shockwave to steal the open space.",
	FootballPlayer.ABILITY_ECHO: "Leave a blinking echo in the shooting lane, then challenge from a second angle while the copy absorbs one strike.",
	FootballPlayer.ABILITY_RETURN_TAG: "Tag a forward pass, move beyond the marker, and have the receiver return it into your new running lane.",
	FootballPlayer.ABILITY_BREAKAWAY: "Arm the self-pass, punch the ball into space past the defender, and win the race onto it.",
	FootballPlayer.ABILITY_SNAPBACK: "Mark a forward touch, bait the defender into stepping in, then curve the ball sharply back into your run.",
	FootballPlayer.ABILITY_SIDE_SWIPE: "Slash the ball sideways around the blocker so it becomes either a disguised lane-breaking pass or a sharp angled shot.",
	FootballPlayer.ABILITY_NUTMEG: "Invite the defender into your route, then send one controlled touch through their challenge and race them to the other side.",
	FootballPlayer.ABILITY_DECOY_RUN: "Sell a committed run with the fading copy while your muted real player cuts into the space the defender abandons."
}

var _stage: FootballAbilityPreviewStage
var _icon: TextureRect
var _title: Label
var _role: Label
var _details: Label
var _caption: Label
var _current_button: Button
var _current_ability_id: int = -1
var _hide_generation: int = 0
var _button_details: Dictionary = {}
var _resolved_preview_size: Vector2 = PREVIEW_SIZE
var _opened_from_mouse: bool = false


func _ready() -> void:
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0
	grow_horizontal = Control.GROW_DIRECTION_END
	grow_vertical = Control.GROW_DIRECTION_END
	_resolve_preview_size()
	custom_minimum_size = _resolved_preview_size
	size = _resolved_preview_size
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 500
	_build_content()
	_apply_style()
	MenuStyler.apply_premium_design(self, &"preview")
	hide()


func _resolve_preview_size() -> void:
	var viewport_size := get_viewport_rect().size
	var compact: bool = viewport_size.y < 800.0 or viewport_size.x < 1280.0
	_resolved_preview_size = Vector2(300.0, 254.0) if compact else PREVIEW_SIZE


func register_button(button: Button, ability_id: int) -> void:
	if button == null:
		return
	set_button_details(button, button.tooltip_text)
	button.mouse_entered.connect(_show_for.bind(button, ability_id, true))
	button.focus_entered.connect(_show_for.bind(button, ability_id, false))
	button.mouse_exited.connect(_schedule_hide.bind(button, true))
	button.focus_exited.connect(_schedule_hide.bind(button, false))


func set_button_details(button: Button, details: String) -> void:
	if button == null:
		return
	_button_details[button.get_instance_id()] = details
	# The live preview replaces Godot's separate native tooltip.
	button.tooltip_text = ""
	if button == _current_button and _details != null:
		_details.text = details


func hide_preview() -> void:
	_hide_generation += 1
	_current_button = null
	_current_ability_id = -1
	_opened_from_mouse = false
	hide()


func _input(event: InputEvent) -> void:
	if not visible or not _opened_from_mouse or _current_button == null:
		return
	var motion := event as InputEventMouseMotion
	if motion == null:
		return
	# Do not rely solely on mouse_exited: a fast movement into the preview can
	# reorder GUI hover/focus callbacks and invalidate its deferred cleanup.
	# The button that opened the preview is the sole mouse-hover owner.
	if not _current_button.get_global_rect().has_point(motion.position):
		hide_preview()


func _build_content() -> void:
	var content := VBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	content.add_theme_constant_override("separation", 3)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(header)

	_icon = TextureRect.new()
	_icon.custom_minimum_size = Vector2(32.0, 32.0)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(_icon)

	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_theme_constant_override("separation", 0)
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(heading)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 17)
	_title.add_theme_color_override("font_color", Color(0.98, 0.96, 0.89))
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading.add_child(_title)

	_role = Label.new()
	_role.add_theme_font_size_override("font_size", 9)
	_role.add_theme_color_override("font_color", Color(0.88, 0.76, 0.44))
	_role.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading.add_child(_role)

	var badge := Label.new()
	badge.text = "LIVE PREVIEW"
	badge.add_theme_font_size_override("font_size", 9)
	badge.add_theme_color_override("font_color", Color(0.25, 1.0, 0.62))
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(badge)

	_stage = FootballAbilityPreviewStage.new()
	_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stage.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(_stage)

	_details = Label.new()
	_details.custom_minimum_size = Vector2(0.0, 66.0)
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details.add_theme_font_size_override("font_size", 10)
	_details.add_theme_color_override(
		"font_color",
		Color(0.88, 0.88, 0.81)
	)
	_details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(_details)

	_caption = Label.new()
	_caption.custom_minimum_size = Vector2(0.0, 35.0)
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.add_theme_font_size_override("font_size", 9)
	_caption.add_theme_color_override("font_color", Color(0.70, 0.73, 0.66))
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(_caption)


func _apply_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.014, 0.031, 0.021, 0.97)
	style.border_color = Color(0.84, 0.72, 0.40, 0.90)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 7.0
	style.content_margin_bottom = 7.0
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.58)
	style.shadow_size = 10
	add_theme_stylebox_override("panel", style)


func _show_for(
	button: Button,
	ability_id: int,
	opened_from_mouse: bool
) -> void:
	_hide_generation += 1
	# A focus event can follow a mouse event for the same button. It must not
	# convert a mouse-owned preview into a sticky keyboard preview.
	if not (
		button == _current_button
		and visible
		and _opened_from_mouse
		and not opened_from_mouse
	):
		_opened_from_mouse = opened_from_mouse
	_current_button = button
	_current_ability_id = ability_id
	_title.text = FootballPlayer.get_ability_name(ability_id)
	_role.text = _role_text(ability_id)
	_details.text = str(_button_details.get(
		button.get_instance_id(),
		FootballPlayer.get_ability_description(ability_id)
	))
	_caption.text = "SHOWCASE  •  %s" % str(
		SCENARIOS.get(ability_id, "Ability showcase")
	)
	var icon_path := str(ICON_PATHS.get(ability_id, ""))
	if not icon_path.is_empty():
		_icon.texture = (
			load(icon_path) as Texture2D
			if ResourceLoader.exists(icon_path)
			else null
		)
	else:
		_icon.texture = null
	_icon.material = null
	_stage.set_ability(ability_id)
	show()
	_position_beside(button)
	_lock_compact_size.call_deferred()


func _schedule_hide(button: Button, mouse_exit: bool) -> void:
	_hide_generation += 1
	var generation := _hide_generation
	_hide_after_frame.call_deferred(button, generation, mouse_exit)


func _hide_after_frame(
	button: Button,
	generation: int,
	mouse_exit: bool
) -> void:
	if generation != _hide_generation or button != _current_button:
		return
	var pointer_is_on_button := button.get_global_rect().has_point(
		get_viewport().get_mouse_position()
	)
	# A mouse exit must always dismiss the visual preview, even if the click
	# also left keyboard focus on the Button. Focus-only previews still remain
	# available for controller/keyboard navigation.
	if mouse_exit and not pointer_is_on_button:
		hide_preview()
		return
	if button.has_focus() or pointer_is_on_button:
		return
	hide_preview()


func _position_beside(button: Button) -> void:
	var viewport_size := get_viewport_rect().size
	var button_rect := button.get_global_rect()
	var preview_size := _resolved_preview_size
	var left_x := button_rect.position.x - preview_size.x - 14.0
	var right_x := button_rect.end.x + 14.0
	var x := left_x if left_x >= 12.0 else right_x
	if x + preview_size.x > viewport_size.x - 12.0:
		x = maxf(12.0, viewport_size.x - preview_size.x - 12.0)
	var y := clampf(
		button_rect.get_center().y - preview_size.y * 0.5,
		12.0,
		maxf(12.0, viewport_size.y - preview_size.y - 12.0)
	)
	global_position = Vector2(x, y)


func _lock_compact_size() -> void:
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0
	_resolve_preview_size()
	custom_minimum_size = _resolved_preview_size
	size = _resolved_preview_size


func _role_text(ability_id: int) -> String:
	match FootballPlayer.get_ability_role(ability_id):
		FootballPlayer.ABILITY_ROLE_ATTACK:
			return "ATTACK"
		FootballPlayer.ABILITY_ROLE_PLAYMAKER:
			return "PLAYMAKER"
		FootballPlayer.ABILITY_ROLE_DEFENSE:
			return "DEFENSE"
		FootballPlayer.ABILITY_ROLE_FLEXIBLE:
			return "FLEXIBLE"
	return "ABILITY SHOWCASE"
