class_name FootballPlayerCosmeticLayer
extends Node2D

@export_enum("static", "animated") var layer_kind: String = "static"

const MAX_ANIMATION_REDRAW_HZ: float = 60.0
const ANIMATION_REDRAW_INTERVAL: float = 1.0 / MAX_ANIMATION_REDRAW_HZ

var _player: Node = null
var _animation_active: bool = false
var _animation_redraw_accumulator: float = 0.0


func _ready() -> void:
	_player = _resolve_player()
	set_process(layer_kind == "animated")
	if layer_kind == "animated":
		_refresh_animation_state()
	queue_redraw()
	_request_static_viewport_refresh()


func _process(delta: float) -> void:
	if layer_kind != "animated" or not _animation_active:
		return
	# Cosmetic motion does not need to rebuild procedural geometry at the
	# monitor refresh rate. Keep the exact same artwork and animation timing,
	# but sample the moving overlay at a stable 60 Hz maximum.
	_animation_redraw_accumulator += maxf(0.0, delta)
	if _animation_redraw_accumulator < ANIMATION_REDRAW_INTERVAL:
		return
	_animation_redraw_accumulator = fmod(
		_animation_redraw_accumulator,
		ANIMATION_REDRAW_INTERVAL
	)
	queue_redraw()


func _draw() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if not _player.has_method("_draw_player_cosmetic_cache_layer"):
		return
	_player._draw_player_cosmetic_cache_layer(self, layer_kind == "animated")


func invalidate() -> void:
	if _player == null or not is_instance_valid(_player):
		_player = _resolve_player()
	if layer_kind == "animated":
		_refresh_animation_state()
	queue_redraw()
	_request_static_viewport_refresh()


func _resolve_player() -> Node:
	var candidate: Node = get_parent()
	while candidate != null:
		if candidate.has_method("_draw_player_cosmetic_cache_layer"):
			return candidate
		candidate = candidate.get_parent()
	return null


func _request_static_viewport_refresh() -> void:
	if layer_kind != "static":
		return
	var viewport := get_parent() as SubViewport
	if viewport != null:
		# UPDATE_ONCE renders the cached vector badge exactly once, then Godot
		# keeps the resulting texture until the cosmetic/team actually changes.
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


func _refresh_animation_state() -> void:
	_animation_active = false
	_animation_redraw_accumulator = 0.0
	if _player == null or not is_instance_valid(_player):
		return
	if _player.has_method("_player_cosmetic_has_animated_details"):
		_animation_active = bool(_player._player_cosmetic_has_animated_details())
