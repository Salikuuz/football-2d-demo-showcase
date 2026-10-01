class_name MenuStyler
extends RefCounted


## Set this to false and restart the game to return to the pre-redesign UI.
## The original per-screen layout and behavior are deliberately left intact.
const PREMIUM_UI_V2_ENABLED: bool = true

const BASE_TEXT := Color(0.96, 0.96, 0.97)
const MUTED_TEXT := Color(0.69, 0.69, 0.72)
const SURFACE := Color(0.055, 0.055, 0.06, 0.80)
const SURFACE_HOVER := Color(0.078, 0.078, 0.086, 0.90)
const PANEL_ALPHA: float = 0.80
const BUTTON_RADIUS: int = 11
const PANEL_RADIUS: int = 14
const CONTROL_RADIUS: int = 10
const MENU_SPACING: int = 10
const GRID_SPACING: int = 8
const BUTTON_FONT_SIZE: int = 16
const BODY_FONT_SIZE: int = 15
const STANDARD_SHADOW_SIZE: int = 5
## Minimal graphite palette. Generic controls use white outlines; saturated
## colors are reserved for teams and ability roles where color has meaning.
const DEFAULT_ACCENT := Color(0.94, 0.94, 0.96)
const PREMIUM_SURFACE := Color(0.052, 0.052, 0.058, 0.80)
const PREMIUM_SURFACE_RAISED := Color(0.082, 0.082, 0.092, 0.90)
const PREMIUM_TEXT := Color(0.97, 0.97, 0.98)
const PREMIUM_MUTED := Color(0.69, 0.69, 0.72)
const PREMIUM_BLUE := Color(0.26, 0.68, 1.0)
const PREMIUM_RED := Color(1.0, 0.34, 0.42)
const PREMIUM_GOLD := Color(0.96, 0.73, 0.26)
const PREMIUM_GREEN := Color(0.31, 0.86, 0.56)
const PREMIUM_PURPLE := Color(0.76, 0.54, 0.92)
const MENU_CONSISTENCY_ROOTS: Array[String] = [
	"res://Scenes/connection_menu.gd",
	"res://Scenes/Teamselection.gd",
	"res://Scenes/freeplay_hud.gd",
	"res://Scenes/leaderboard.gd",
	"res://Scenes/controller_test_panel.gd"
]
const FROSTED_GLASS_SHADER := """
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform vec4 glass_tint : source_color = vec4(0.018, 0.024, 0.032, 1.0);
uniform float blur_level : hint_range(0.0, 5.0) = 1.65;
uniform float tint_strength : hint_range(0.0, 1.0) = 0.34;
uniform float glass_opacity : hint_range(0.0, 1.0) = 0.82;

void fragment() {
	vec4 original = texture(TEXTURE, UV) * COLOR;
	vec3 blurred = textureLod(screen_texture, SCREEN_UV, blur_level).rgb;
	vec3 glass = mix(blurred, glass_tint.rgb, tint_strength);
	float brightness = max(original.r, max(original.g, original.b));
	float border_mask = smoothstep(0.24, 0.58, brightness);
	vec3 final_color = mix(glass, original.rgb, border_mask);
	float final_alpha = mix(
		min(original.a, glass_opacity),
		original.a,
		border_mask
	);
	COLOR = vec4(final_color, final_alpha);
}
"""


static func style_button(
	button: Button,
	accent: Color,
	minimum_height: float = 48.0
) -> void:
	if button == null:
		return
	button.set_meta("_menu_style_ready", true)
	button.custom_minimum_size.y = maxf(
		button.custom_minimum_size.y,
		minimum_height
	)
	button.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
	button.add_theme_color_override("font_color", BASE_TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override(
		"font_disabled_color",
		Color(0.48, 0.53, 0.58, 0.82)
	)

	# Intentionally colored buttons use the same visual language as the large
	# main-menu mode cards. Keeping this in the shared styler means new colored
	# actions automatically stay consistent instead of each screen recreating
	# a slightly different outlined button. Neutral graphite/white controls
	# retain the quieter generic treatment.
	if _is_colored_button_accent(accent):
		style_accent_card_button(button, accent)
		return

	button.add_theme_stylebox_override(
		"normal",
		_make_button_box(SURFACE, accent, 0.42)
	)
	button.add_theme_stylebox_override(
		"hover",
		_make_button_box(
			SURFACE_HOVER,
			accent.lightened(0.12),
			0.74,
			4
		)
	)
	button.add_theme_stylebox_override(
		"pressed",
		_make_button_box(
			Color(0.035, 0.045, 0.058, 1.0),
			accent.lightened(0.08),
			0.92,
			2
		)
	)
	button.add_theme_stylebox_override(
		"disabled",
		_make_button_box(
			Color(0.018, 0.023, 0.03, 0.68),
			Color(accent.r, accent.g, accent.b, 0.2),
			0.24,
			0
		)
	)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	focus.border_width_left = 1
	focus.border_width_top = 1
	focus.border_width_right = 1
	focus.border_width_bottom = 1
	focus.border_color = accent.lightened(0.3)
	focus.corner_radius_top_left = BUTTON_RADIUS
	focus.corner_radius_top_right = BUTTON_RADIUS
	focus.corner_radius_bottom_left = BUTTON_RADIUS
	focus.corner_radius_bottom_right = BUTTON_RADIUS
	button.add_theme_stylebox_override("focus", focus)


static func style_accent_card_button(
	button: Button,
	accent: Color,
	featured: bool = false
) -> void:
	if button == null:
		return
	var tint_strength: float = 0.115 if featured else 0.075
	var normal := _make_accent_card_box(
		Color(
			0.024 + accent.r * tint_strength,
			0.032 + accent.g * tint_strength,
			0.040 + accent.b * tint_strength,
			0.94
		),
		Color(accent.r, accent.g, accent.b, 0.62),
		4 if featured else 3,
		7 if featured else 0
	)
	button.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(
		0.045 + accent.r * 0.08,
		0.065 + accent.g * 0.08,
		0.078 + accent.b * 0.08,
		0.98
	)
	hover.border_color = accent.lightened(0.10)
	hover.shadow_size = 10 if featured else 0
	button.add_theme_stylebox_override("hover", hover)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.018, 0.024, 0.03, 1.0)
	pressed.border_color = accent.lightened(0.18)
	pressed.shadow_size = 3 if featured else 0
	button.add_theme_stylebox_override("pressed", pressed)

	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.018, 0.023, 0.03, 0.58)
	disabled.border_color = Color(accent.r, accent.g, accent.b, 0.20)
	disabled.shadow_size = 0
	button.add_theme_stylebox_override("disabled", disabled)

	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.draw_center = false
	focus.border_color = accent.lightened(0.28)
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(12)
	button.add_theme_stylebox_override("focus", focus)


static func install_click_sounds(root: Node) -> void:
	if root == null:
		return
	var ui_root := root
	while ui_root.get_parent() != null and not ui_root is CanvasLayer:
		ui_root = ui_root.get_parent()

	var use_consistency := _is_menu_consistency_root(root)
	var prepare_node := func(node: Node) -> void:
		var button := node as Button
		if button != null and not button.has_meta("_menu_style_ready"):
			style_button(button, DEFAULT_ACCENT, 42.0)
		if use_consistency:
			_style_menu_node(node)

	prepare_node.call(root)
	for node in root.find_children("*", "", true, false):
		prepare_node.call(node)

	if not ui_root.has_meta("_menu_style_watcher_ready"):
		ui_root.set_meta("_menu_style_watcher_ready", true)
		ui_root.get_tree().node_added.connect(
			func(node: Node) -> void:
				if not ui_root.is_ancestor_of(node):
					return
				var dynamic_button := node as Button
				if (
					dynamic_button != null
					and not dynamic_button.has_meta("_menu_style_ready")
				):
					style_button(dynamic_button, DEFAULT_ACCENT, 42.0)
				if use_consistency and root.is_ancestor_of(node):
					_style_menu_node(node)
		)


static func apply_menu_consistency(root: Node) -> void:
	if root == null:
		return
	_style_menu_node(root)
	for node in root.find_children("*", "", true, false):
		_style_menu_node(node)


## A reversible presentation layer used by every player-facing surface. It
## only changes Theme overrides and never changes a node's layout, ownership,
## focus path, signals, or mouse filter.
static func apply_premium_design(
	root: Node,
	presentation: StringName = &"default"
) -> void:
	if root == null or not PREMIUM_UI_V2_ENABLED:
		return
	root.set_meta("_premium_ui_presentation", presentation)
	_apply_premium_node(root, presentation)
	for node in root.find_children("*", "", true, false):
		_apply_premium_node(node, presentation)
	if root.has_meta("_premium_ui_watcher_ready"):
		return
	root.set_meta("_premium_ui_watcher_ready", true)
	root.get_tree().node_added.connect(
		func(node: Node) -> void:
			if not is_instance_valid(root) or not root.is_inside_tree():
				return
			if root.is_ancestor_of(node):
				_apply_premium_node(node, presentation)
	)


static func apply_responsive_content_width(
	content: Control,
	viewport_size: Vector2,
	minimum_width: float,
	maximum_width: float,
	minimum_height: float = 0.0
) -> void:
	if content == null:
		return
	var horizontal_padding: float = clampf(
		viewport_size.x * 0.035,
		18.0,
		72.0
	)
	var available_width: float = maxf(
		minimum_width,
		viewport_size.x - horizontal_padding * 2.0
	)
	content.custom_minimum_size.x = clampf(
		available_width,
		minimum_width,
		maximum_width
	)
	if minimum_height > 0.0:
		content.custom_minimum_size.y = minf(
			minimum_height,
			maxf(0.0, viewport_size.y - 32.0)
		)


static func _apply_premium_node(
	node: Node,
	presentation: StringName
) -> void:
	var button := node as Button
	if button != null:
		_style_premium_button(button, _accent_for_button(button))
		return

	var panel := node as PanelContainer
	if panel != null:
		_style_premium_panel(
			panel,
			_accent_for_control(panel),
			presentation != &"hud"
		)
		return

	var tab_container := node as TabContainer
	if tab_container != null:
		_style_premium_tabs(
			tab_container,
			_accent_for_control(tab_container),
			presentation != &"hud"
		)
		return

	var tab_bar := node as TabBar
	if tab_bar != null:
		_style_premium_tab_bar(tab_bar, _accent_for_control(tab_bar))
		return

	var option_button := node as OptionButton
	if option_button != null:
		_style_premium_option_button(option_button, _accent_for_control(option_button))
		return

	var spin_box := node as SpinBox
	if spin_box != null:
		_style_premium_line_edit(spin_box.get_line_edit(), _accent_for_control(spin_box))
		return

	var check_box := node as CheckBox
	if check_box != null:
		_style_premium_toggle(check_box, _accent_for_control(check_box))
		return

	var check_button := node as CheckButton
	if check_button != null:
		_style_premium_toggle(check_button, _accent_for_control(check_button))
		return

	var line_edit := node as LineEdit
	if line_edit != null:
		_style_premium_line_edit(line_edit, _accent_for_control(line_edit))
		return

	var slider := node as HSlider
	if slider != null:
		_style_premium_slider(slider, _accent_for_control(slider))
		return

	var progress := node as ProgressBar
	if progress != null:
		_style_premium_progress(progress, _accent_for_control(progress))
		return

	var label := node as Label
	if label != null:
		_style_premium_label(label, presentation)
		return

	var rich_label := node as RichTextLabel
	if rich_label != null:
		rich_label.add_theme_color_override("default_color", PREMIUM_TEXT)


static func _style_premium_button(button: Button, accent: Color) -> void:
	if button == null:
		return
	button.set_meta("_premium_ui_ready", true)
	if not button.has_theme_color_override("font_color"):
		button.add_theme_color_override("font_color", PREMIUM_TEXT)
	if not button.has_theme_color_override("font_hover_color"):
		button.add_theme_color_override("font_hover_color", Color.WHITE)
	if not button.has_theme_color_override("font_pressed_color"):
		button.add_theme_color_override("font_pressed_color", Color.WHITE)
	if not button.has_theme_color_override("font_disabled_color"):
		button.add_theme_color_override(
			"font_disabled_color", Color(PREMIUM_MUTED, 0.52)
		)
	button.add_theme_color_override("font_outline_color", Color(0.0, 0.01, 0.02, 0.82))
	button.add_theme_constant_override("outline_size", 1)
	if _is_colored_button_accent(accent):
		style_accent_card_button(button, accent)
		return
	button.add_theme_stylebox_override(
		"normal", _make_premium_button_box(PREMIUM_SURFACE, accent, 0.68, 0)
	)
	button.add_theme_stylebox_override(
		"hover", _make_premium_button_box(PREMIUM_SURFACE_RAISED, accent.lightened(0.06), 1.0, 5)
	)
	button.add_theme_stylebox_override(
		"pressed", _make_premium_button_box(Color(0.10, 0.10, 0.11, 0.94), accent, 1.0, 2)
	)
	button.add_theme_stylebox_override(
		"disabled", _make_premium_button_box(Color(0.045, 0.045, 0.05, 0.58), Color(accent, 0.20), 0.18, 0)
	)
	var focus := _make_premium_button_box(Color.TRANSPARENT, accent.lightened(0.2), 1.0, 0)
	focus.draw_center = false
	focus.expand_margin_left = 3.0
	focus.expand_margin_top = 3.0
	focus.expand_margin_right = 3.0
	focus.expand_margin_bottom = 3.0
	button.add_theme_stylebox_override("focus", focus)


static func style_ability_role_button(
	button: Button,
	role_color: Color
) -> void:
	if button == null:
		return
	style_accent_card_button(button, role_color)
	button.add_theme_color_override(
		"font_color",
		role_color.lightened(0.18)
	)
	button.add_theme_color_override("font_hover_color", Color.WHITE)


static func _style_premium_panel(
	panel: PanelContainer,
	accent: Color,
	clear_legacy_material: bool
) -> void:
	if panel == null:
		return
	if clear_legacy_material:
		panel.material = null
	var style := StyleBoxFlat.new()
	style.bg_color = Color(PREMIUM_SURFACE.r, PREMIUM_SURFACE.g, PREMIUM_SURFACE.b, 0.80)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.58)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.content_margin_left = 16.0
	style.content_margin_top = 14.0
	style.content_margin_right = 16.0
	style.content_margin_bottom = 14.0
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.52)
	style.shadow_size = 9
	style.shadow_offset = Vector2(0.0, 3.0)
	panel.add_theme_stylebox_override("panel", style)


static func _style_premium_tabs(
	tabs: TabContainer,
	accent: Color,
	clear_legacy_material: bool
) -> void:
	if tabs == null:
		return
	if clear_legacy_material:
		tabs.material = null
	var panel := _make_premium_panel_box(accent)
	tabs.add_theme_stylebox_override("panel", panel)
	_style_premium_tab_bar(tabs.get_tab_bar(), accent)


static func _style_premium_tab_bar(tab_bar: TabBar, accent: Color) -> void:
	if tab_bar == null:
		return
	tab_bar.add_theme_font_size_override("font_size", 16)
	tab_bar.add_theme_color_override("font_selected_color", Color.WHITE)
	tab_bar.add_theme_color_override("font_unselected_color", PREMIUM_MUTED)
	tab_bar.add_theme_color_override("font_hovered_color", PREMIUM_TEXT)
	tab_bar.add_theme_color_override("font_outline_color", Color(0.0, 0.01, 0.02, 0.9))
	tab_bar.add_theme_constant_override("outline_size", 1)
	tab_bar.add_theme_stylebox_override(
		"tab_selected", _make_premium_tab_box(PREMIUM_SURFACE_RAISED, accent, 0.96)
	)
	tab_bar.add_theme_stylebox_override(
		"tab_unselected", _make_premium_tab_box(Color(0.05, 0.05, 0.056, 0.78), accent, 0.34)
	)
	tab_bar.add_theme_stylebox_override(
		"tab_hovered", _make_premium_tab_box(Color(0.09, 0.09, 0.10, 0.90), accent.lightened(0.05), 0.86)
	)


static func _style_premium_option_button(option_button: OptionButton, accent: Color) -> void:
	option_button.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	option_button.add_theme_color_override("font_color", PREMIUM_TEXT)
	option_button.add_theme_color_override("font_hover_color", Color.WHITE)
	option_button.add_theme_stylebox_override(
		"normal", _make_premium_button_box(PREMIUM_SURFACE, accent, 0.50, 0)
	)
	option_button.add_theme_stylebox_override(
		"hover", _make_premium_button_box(PREMIUM_SURFACE_RAISED, accent, 0.88, 5)
	)
	option_button.add_theme_stylebox_override(
		"pressed", _make_premium_button_box(Color(0.10, 0.10, 0.11, 0.94), accent, 1.0, 1)
	)


static func _style_premium_line_edit(line_edit: LineEdit, accent: Color) -> void:
	line_edit.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	line_edit.add_theme_color_override("font_color", PREMIUM_TEXT)
	line_edit.add_theme_color_override("font_placeholder_color", PREMIUM_MUTED)
	line_edit.add_theme_stylebox_override(
		"normal", _make_premium_field_box(PREMIUM_SURFACE, accent, 0.42)
	)
	line_edit.add_theme_stylebox_override(
		"focus", _make_premium_field_box(PREMIUM_SURFACE_RAISED, accent, 0.94)
	)


static func _style_premium_toggle(toggle: BaseButton, accent: Color) -> void:
	if toggle == null:
		return
	toggle.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	if not toggle.has_theme_color_override("font_color"):
		toggle.add_theme_color_override("font_color", PREMIUM_TEXT)
	if not toggle.has_theme_color_override("font_hover_color"):
		toggle.add_theme_color_override("font_hover_color", Color.WHITE)
	toggle.add_theme_color_override("font_pressed_color", accent.lightened(0.18))


static func _style_premium_slider(slider: HSlider, accent: Color) -> void:
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.045, 0.045, 0.05, 0.82)
	background.corner_radius_top_left = 5
	background.corner_radius_top_right = 5
	background.corner_radius_bottom_left = 5
	background.corner_radius_bottom_right = 5
	background.content_margin_top = 5.0
	background.content_margin_bottom = 5.0
	var fill: StyleBoxFlat = background.duplicate() as StyleBoxFlat
	fill.bg_color = Color(accent.r, accent.g, accent.b, 0.90)
	fill.shadow_color = Color(accent.r, accent.g, accent.b, 0.30)
	fill.shadow_size = 4
	var grabber := StyleBoxFlat.new()
	grabber.bg_color = PREMIUM_TEXT
	grabber.border_color = accent
	grabber.set_border_width_all(2)
	grabber.corner_radius_top_left = 8
	grabber.corner_radius_top_right = 8
	grabber.corner_radius_bottom_left = 8
	grabber.corner_radius_bottom_right = 8
	grabber.content_margin_left = 7.0
	grabber.content_margin_top = 7.0
	grabber.content_margin_right = 7.0
	grabber.content_margin_bottom = 7.0
	slider.add_theme_stylebox_override("slider", background)
	slider.add_theme_stylebox_override("grabber_area", fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill)
	slider.add_theme_stylebox_override("grabber", grabber)


static func _style_premium_progress(progress: ProgressBar, accent: Color) -> void:
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.045, 0.045, 0.05, 0.82)
	background.corner_radius_top_left = 5
	background.corner_radius_top_right = 5
	background.corner_radius_bottom_left = 5
	background.corner_radius_bottom_right = 5
	var fill: StyleBoxFlat = background.duplicate() as StyleBoxFlat
	fill.bg_color = accent
	fill.shadow_color = Color(accent.r, accent.g, accent.b, 0.35)
	fill.shadow_size = 3
	progress.add_theme_stylebox_override("background", background)
	progress.add_theme_stylebox_override("fill", fill)


static func _style_premium_label(label: Label, presentation: StringName) -> void:
	var node_name := label.name.to_lower()
	if node_name.contains("title") or node_name == "heading":
		label.add_theme_color_override("font_color", PREMIUM_TEXT)
		label.add_theme_color_override("font_outline_color", Color(0.0, 0.01, 0.02, 0.92))
		label.add_theme_constant_override("outline_size", 2)
		label.add_theme_font_size_override(
			"font_size", maxi(18, label.get_theme_font_size("font_size"))
		)
	elif not label.has_theme_color_override("font_color"):
		label.add_theme_color_override("font_color", PREMIUM_TEXT)
	if node_name.contains("hint") or node_name.contains("status") or node_name.contains("description"):
		label.add_theme_color_override("font_color", PREMIUM_MUTED)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if presentation == &"hud" and node_name.contains("label"):
		label.add_theme_constant_override("outline_size", maxi(1, label.get_theme_constant("outline_size")))


static func _make_premium_button_box(
	background: Color,
	accent: Color,
	accent_alpha: float,
	shadow_size: int
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = Color(accent.r, accent.g, accent.b, accent_alpha)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 16.0
	style.content_margin_top = 8.0
	style.content_margin_right = 16.0
	style.content_margin_bottom = 8.0
	style.shadow_color = Color(accent.r, accent.g, accent.b, 0.12) if shadow_size > 0 else Color(0.0, 0.0, 0.0, 0.22)
	style.shadow_size = shadow_size
	style.shadow_offset = Vector2(0.0, 2.0)
	return style


static func _make_premium_field_box(background: Color, accent: Color, alpha: float) -> StyleBoxFlat:
	var style := _make_premium_button_box(background, accent, alpha, 0)
	style.border_width_left = 1
	style.content_margin_top = 9.0
	style.content_margin_bottom = 9.0
	return style


static func _make_premium_panel_box(accent: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(PREMIUM_SURFACE.r, PREMIUM_SURFACE.g, PREMIUM_SURFACE.b, 0.80)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.54)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.content_margin_left = 14.0
	style.content_margin_top = 12.0
	style.content_margin_right = 14.0
	style.content_margin_bottom = 14.0
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.42)
	style.shadow_size = 9
	return style


static func _make_premium_tab_box(background: Color, accent: Color, alpha: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = Color(accent.r, accent.g, accent.b, alpha)
	style.border_width_top = 3
	style.border_width_left = 1
	style.border_width_right = 1
	style.corner_radius_top_left = 11
	style.corner_radius_top_right = 11
	style.content_margin_left = 18.0
	style.content_margin_top = 8.0
	style.content_margin_right = 18.0
	style.content_margin_bottom = 8.0
	return style


static func _accent_for_button(button: Button) -> Color:
	var key := (button.name + " " + button.text).to_lower()
	if key.contains("ready"):
		return PREMIUM_GREEN
	if key.contains("leave"):
		return PREMIUM_RED
	if key.contains("start"):
		return PREMIUM_GOLD
	if key.contains("map"):
		return PREMIUM_PURPLE
	if key.contains("blue"):
		return PREMIUM_BLUE
	if key.contains("red"):
		return PREMIUM_RED
	return DEFAULT_ACCENT


static func _accent_for_control(control: Control) -> Color:
	var key := control.name.to_lower()
	if key.contains("blue"):
		return PREMIUM_BLUE
	if key.contains("red"):
		return PREMIUM_RED
	return DEFAULT_ACCENT


static func _is_menu_consistency_root(root: Node) -> bool:
	if root == null:
		return false
	var script: Script = root.get_script() as Script
	if script == null:
		return false
	return script.resource_path in MENU_CONSISTENCY_ROOTS


static func _style_menu_node(node: Node) -> void:
	if node == null:
		return
	var panel := node as PanelContainer
	if panel != null and not panel.has_theme_stylebox_override("panel"):
		style_panel(panel, DEFAULT_ACCENT)

	var label := node as Label
	if label != null:
		if not label.has_theme_font_size_override("font_size"):
			label.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
		if not label.has_theme_color_override("font_color"):
			label.add_theme_color_override("font_color", BASE_TEXT)

	var line_edit := node as LineEdit
	if line_edit != null:
		_style_line_edit(line_edit)

	var check_box := node as CheckBox
	if check_box != null:
		check_box.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
		check_box.add_theme_color_override("font_color", BASE_TEXT)
		check_box.add_theme_color_override("font_hover_color", Color.WHITE)

	var check_button := node as CheckButton
	if check_button != null:
		check_button.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
		check_button.add_theme_color_override("font_color", BASE_TEXT)
		check_button.add_theme_color_override("font_hover_color", Color.WHITE)

	var vbox := node as VBoxContainer
	if vbox != null and not vbox.has_theme_constant_override("separation"):
		vbox.add_theme_constant_override("separation", MENU_SPACING)
	var hbox := node as HBoxContainer
	if hbox != null and not hbox.has_theme_constant_override("separation"):
		hbox.add_theme_constant_override("separation", MENU_SPACING)
	var grid := node as GridContainer
	if grid != null:
		if not grid.has_theme_constant_override("h_separation"):
			grid.add_theme_constant_override("h_separation", GRID_SPACING)
		if not grid.has_theme_constant_override("v_separation"):
			grid.add_theme_constant_override("v_separation", GRID_SPACING)


static func _style_line_edit(line_edit: LineEdit) -> void:
	line_edit.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	line_edit.add_theme_color_override("font_color", BASE_TEXT)
	line_edit.add_theme_color_override("font_placeholder_color", MUTED_TEXT)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(SURFACE.r, SURFACE.g, SURFACE.b, PANEL_ALPHA)
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.border_color = Color(DEFAULT_ACCENT.r, DEFAULT_ACCENT.g, DEFAULT_ACCENT.b, 0.32)
	normal.corner_radius_top_left = CONTROL_RADIUS
	normal.corner_radius_top_right = CONTROL_RADIUS
	normal.corner_radius_bottom_left = CONTROL_RADIUS
	normal.corner_radius_bottom_right = CONTROL_RADIUS
	normal.content_margin_left = 12.0
	normal.content_margin_right = 12.0
	line_edit.add_theme_stylebox_override("normal", normal)
	var focus: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	focus.border_color = Color(DEFAULT_ACCENT.r, DEFAULT_ACCENT.g, DEFAULT_ACCENT.b, 0.78)
	focus.shadow_color = Color(DEFAULT_ACCENT.r, DEFAULT_ACCENT.g, DEFAULT_ACCENT.b, 0.12)
	focus.shadow_size = STANDARD_SHADOW_SIZE
	line_edit.add_theme_stylebox_override("focus", focus)


static func style_panel(
	panel: PanelContainer,
	accent: Color,
	background: Color = SURFACE
) -> void:
	if panel == null:
		return
	var style := StyleBoxFlat.new()
	style.content_margin_left = 14.0
	style.content_margin_top = 12.0
	style.content_margin_right = 14.0
	style.content_margin_bottom = 12.0
	style.bg_color = Color(background.r, background.g, background.b, PANEL_ALPHA)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(accent.r, accent.g, accent.b, 0.34)
	style.corner_radius_top_left = PANEL_RADIUS
	style.corner_radius_top_right = PANEL_RADIUS
	style.corner_radius_bottom_left = PANEL_RADIUS
	style.corner_radius_bottom_right = PANEL_RADIUS
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.34)
	style.shadow_size = STANDARD_SHADOW_SIZE
	panel.add_theme_stylebox_override("panel", style)
	_apply_frosted_material(panel, background)


static func style_tabs(tabs: TabContainer, accent: Color) -> void:
	if tabs == null:
		return
	var panel := StyleBoxFlat.new()
	panel.content_margin_left = 10.0
	panel.content_margin_top = 10.0
	panel.content_margin_right = 10.0
	panel.content_margin_bottom = 10.0
	panel.bg_color = Color(SURFACE.r, SURFACE.g, SURFACE.b, PANEL_ALPHA)
	panel.border_width_left = 1
	panel.border_width_top = 1
	panel.border_width_right = 1
	panel.border_width_bottom = 1
	panel.border_color = Color(accent.r, accent.g, accent.b, 0.3)
	panel.corner_radius_top_left = PANEL_RADIUS
	panel.corner_radius_top_right = PANEL_RADIUS
	panel.corner_radius_bottom_left = PANEL_RADIUS
	panel.corner_radius_bottom_right = PANEL_RADIUS
	panel.shadow_color = Color(0.0, 0.0, 0.0, 0.34)
	panel.shadow_size = STANDARD_SHADOW_SIZE
	tabs.add_theme_stylebox_override("panel", panel)
	_apply_frosted_material(tabs, SURFACE)

	tabs.add_theme_stylebox_override(
		"tab_unselected",
		_make_tab_box(SURFACE, accent, 0.18)
	)
	tabs.add_theme_stylebox_override(
		"tab_hovered",
		_make_tab_box(SURFACE_HOVER, accent, 0.46)
	)
	tabs.add_theme_stylebox_override(
		"tab_selected",
		_make_tab_box(Color(0.035, 0.045, 0.058, 1.0), accent, 0.82)
	)
	tabs.add_theme_color_override("font_unselected_color", MUTED_TEXT)
	tabs.add_theme_color_override("font_hovered_color", Color.WHITE)
	tabs.add_theme_color_override("font_selected_color", Color.WHITE)


static func style_heading(label: Label, color: Color) -> void:
	if label == null:
		return
	label.add_theme_font_size_override("font_size", 21)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override(
		"font_outline_color",
		Color(0.0, 0.0, 0.0, 0.92)
	)
	label.add_theme_constant_override("outline_size", 3)


static func _apply_frosted_material(
	control: Control,
	tint: Color
) -> void:
	var shader := Shader.new()
	shader.code = FROSTED_GLASS_SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter(
		"glass_tint",
		Color(tint.r, tint.g, tint.b, 1.0)
	)
	material.set_shader_parameter("blur_level", 1.65)
	material.set_shader_parameter("tint_strength", 0.34)
	material.set_shader_parameter("glass_opacity", PANEL_ALPHA)
	control.material = material


static func _is_colored_button_accent(accent: Color) -> bool:
	var maximum: float = maxf(accent.r, maxf(accent.g, accent.b))
	var minimum: float = minf(accent.r, minf(accent.g, accent.b))
	return maximum - minimum > 0.045


static func _make_accent_card_box(
	background: Color,
	border: Color,
	left_border_width: int,
	shadow_size: int
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.border_width_left = left_border_width
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.set_corner_radius_all(12)
	style.content_margin_left = 15.0
	style.content_margin_right = 15.0
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.42)
	style.shadow_size = shadow_size
	return style


static func _make_button_box(
	background: Color,
	accent: Color,
	accent_alpha: float,
	shadow_size: int = 5
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.content_margin_left = 15.0
	style.content_margin_right = 15.0
	style.bg_color = background
	style.border_width_left = 3
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(
		accent.r,
		accent.g,
		accent.b,
		clampf(accent_alpha, 0.0, 1.0)
	)
	style.corner_radius_top_left = BUTTON_RADIUS
	style.corner_radius_top_right = BUTTON_RADIUS
	style.corner_radius_bottom_left = BUTTON_RADIUS
	style.corner_radius_bottom_right = BUTTON_RADIUS
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.3)
	style.shadow_size = mini(shadow_size, STANDARD_SHADOW_SIZE)
	return style


static func _make_tab_box(
	background: Color,
	accent: Color,
	accent_alpha: float
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.content_margin_left = 18.0
	style.content_margin_top = 8.0
	style.content_margin_right = 18.0
	style.content_margin_bottom = 8.0
	style.bg_color = background
	style.border_width_top = 3
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_color = Color(
		accent.r,
		accent.g,
		accent.b,
		clampf(accent_alpha, 0.0, 1.0)
	)
	style.corner_radius_top_left = BUTTON_RADIUS
	style.corner_radius_top_right = BUTTON_RADIUS
	return style
