class_name ChampionsLeagueLeaderboardPanel
extends PanelContainer


var manager: FootballMatchManager
var _scope: String = "overall"
var _value_label: Label
var _content_column: VBoxContainer
var _heading_label: Label
var _scope_buttons: Array[Button] = []
var _base_panel_style: StyleBoxFlat


func _ready() -> void:
	_content_column = VBoxContainer.new()
	_content_column.add_theme_constant_override("separation", 8)
	add_child(_content_column)
	_heading_label = Label.new()
	_heading_label.text = "DRAFT WINS"
	_heading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content_column.add_child(_heading_label)
	var scopes := HBoxContainer.new()
	scopes.alignment = BoxContainer.ALIGNMENT_CENTER
	_content_column.add_child(scopes)
	for scope: String in ["overall", "1v1", "2v2", "4v4", "5v5", "6v6"]:
		var button := Button.new()
		button.text = scope.to_upper()
		button.pressed.connect(_select_scope.bind(scope))
		scopes.add_child(button)
		_scope_buttons.append(button)
	_value_label = Label.new()
	_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_value_label.add_theme_font_size_override("font_size", 20)
	_content_column.add_child(_value_label)
	MenuStyler.style_panel(self, Color(0.72, 0.5, 1.0), Color(0.04, 0.02, 0.09, 0.9))
	var panel_style := get_theme_stylebox("panel") as StyleBoxFlat
	if panel_style != null:
		_base_panel_style = panel_style.duplicate() as StyleBoxFlat
	refresh()


func set_compact_layout(compact: bool) -> void:
	if _content_column == null:
		return
	_content_column.add_theme_constant_override("separation", 2 if compact else 8)
	if _heading_label != null:
		if compact:
			_heading_label.add_theme_font_size_override("font_size", 10)
		else:
			_heading_label.remove_theme_font_size_override("font_size")
	for button in _scope_buttons:
		if button == null:
			continue
		button.custom_minimum_size.y = 20.0 if compact else 0.0
		if compact:
			button.add_theme_font_size_override("font_size", 9)
		else:
			button.remove_theme_font_size_override("font_size")
	if _value_label != null:
		_value_label.add_theme_font_size_override("font_size", 12 if compact else 20)
	if _base_panel_style != null:
		var adjusted := _base_panel_style.duplicate() as StyleBoxFlat
		if compact:
			adjusted.content_margin_left = 4.0
			adjusted.content_margin_top = 4.0
			adjusted.content_margin_right = 4.0
			adjusted.content_margin_bottom = 4.0
		add_theme_stylebox_override("panel", adjusted)


func refresh() -> void:
	if _value_label == null or manager == null:
		return
	var snapshot: Dictionary = manager.get_draft_wins_snapshot()
	_value_label.text = "%s WINS: %d" % [_scope.to_upper(), int(snapshot.get(_scope, 0))]


func _select_scope(scope: String) -> void:
	_scope = scope
	refresh()
