class_name PlayerVisualSupersampler
extends Node

# Player visuals stay in the real gameplay World2D, but are culled from the
# normal viewport and rendered a second time into a transparent, higher
# resolution viewport. The result is composited over the pitch at the same
# apparent size. Physics/collisions/networking never leave the real world.
const PLAYER_VISUAL_LAYER_INDEX := 19
const PLAYER_VISUAL_LAYER_MASK := 1 << PLAYER_VISUAL_LAYER_INDEX
const BASE_VISUAL_LAYER_MASK := 1
const MAX_1080P_WIDTH := 2200
const LOW_RES_SUPERSAMPLE := 2.0
const MID_RES_SUPERSAMPLE := 1.5

@export var players_parent_path: NodePath = NodePath("../Players")

var _main_viewport: Viewport
var _players_parent: Node2D
var _visual_viewport: SubViewport
var _composite_layer: CanvasLayer
var _composite: TextureRect
var _last_main_size := Vector2i.ZERO
var _last_visible_size := Vector2.ZERO
var _last_factor := 0.0


func _ready() -> void:
	_main_viewport = get_viewport()
	_players_parent = get_node_or_null(players_parent_path) as Node2D
	if _main_viewport == null or _players_parent == null:
		return

	# Mobile Web already pays the Safari/WebAssembly rendering cost. Rendering
	# every player a second time into a 2x supersampled SubViewport is a large GPU
	# and memory expense on phones (roughly 4x the pixels for this layer). Let the
	# normal world canvas render player visuals directly on touch Web instead.
	if OS.has_feature("web") and DisplayServer.is_touchscreen_available():
		set_process(false)
		return

	# Parent CanvasItems must share the presentation bit for the secondary
	# viewport to be able to traverse down to player CanvasItems.
	var playfield := get_parent() as CanvasItem
	if playfield != null:
		playfield.visibility_layer |= PLAYER_VISUAL_LAYER_MASK
	_players_parent.visibility_layer |= PLAYER_VISUAL_LAYER_MASK

	# The normal world viewport renders everything except the dedicated player
	# presentation bit. Players keep existing normally in physics; only their
	# CanvasItem drawing is redirected.
	_main_viewport.set_canvas_cull_mask_bit(PLAYER_VISUAL_LAYER_INDEX, false)

	_visual_viewport = SubViewport.new()
	_visual_viewport.name = "PlayerVisualViewport"
	_visual_viewport.disable_3d = true
	_visual_viewport.transparent_bg = true
	_visual_viewport.gui_disable_input = true
	_visual_viewport.handle_input_locally = false
	_visual_viewport.physics_object_picking = false
	_visual_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_visual_viewport.canvas_cull_mask = PLAYER_VISUAL_LAYER_MASK
	_visual_viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
	add_child(_visual_viewport)
	# Share the exact live football world/canvas. This does not duplicate any
	# player nodes and therefore cannot affect gameplay state.
	_visual_viewport.world_2d = _main_viewport.find_world_2d()

	_composite_layer = CanvasLayer.new()
	_composite_layer.name = "PlayerVisualCompositeLayer"
	# Layer 1 is above the default world canvas. The game's HUD CanvasLayer is
	# promoted to 10 below so existing UI remains above the player presentation.
	_composite_layer.layer = 1
	add_child(_composite_layer)

	_composite = TextureRect.new()
	_composite.name = "PlayerVisualComposite"
	_composite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_composite.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_composite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_composite.stretch_mode = TextureRect.STRETCH_SCALE
	_composite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_composite.texture = _visual_viewport.get_texture()
	_composite_layer.add_child(_composite)

	var hud := get_parent().get_node_or_null("HUD") as CanvasLayer
	if hud != null and hud.layer <= _composite_layer.layer:
		hud.layer = 10

	_players_parent.child_entered_tree.connect(_on_player_child_entered)
	get_tree().node_added.connect(_on_tree_node_added)
	for child in _players_parent.get_children():
		_mark_player_visual_tree(child)

	_main_viewport.size_changed.connect(_refresh_render_target)
	_refresh_render_target()
	set_process(true)


func _exit_tree() -> void:
	if _main_viewport != null:
		_main_viewport.set_canvas_cull_mask_bit(PLAYER_VISUAL_LAYER_INDEX, true)


func _process(_delta: float) -> void:
	if _main_viewport == null or _visual_viewport == null:
		return
	if (
		_main_viewport.size != _last_main_size
		or _main_viewport.get_visible_rect().size != _last_visible_size
	):
		_refresh_render_target()
	_sync_world_transform()


func _supersample_factor() -> float:
	var output_width := int(_main_viewport.size.x)
	if output_width <= MAX_1080P_WIDTH:
		return LOW_RES_SUPERSAMPLE
	if output_width < 3200:
		return MID_RES_SUPERSAMPLE
	return 1.0


func _refresh_render_target() -> void:
	if _main_viewport == null or _visual_viewport == null:
		return
	_last_main_size = _main_viewport.size
	_last_visible_size = _main_viewport.get_visible_rect().size
	_last_factor = _supersample_factor()
	var target_size := Vector2i(
		maxi(1, int(round(float(_last_main_size.x) * _last_factor))),
		maxi(1, int(round(float(_last_main_size.y) * _last_factor)))
	)
	_visual_viewport.size = target_size
	_sync_world_transform()


func _sync_world_transform() -> void:
	if _main_viewport == null or _visual_viewport == null:
		return
	# Main canvas_transform maps world -> 1152x648 logical coordinates. The
	# root final transform maps those logical coordinates -> real window pixels.
	# The secondary target is N times the real window size, so compose exactly
	# those transforms and then supersample once more.
	var physical_transform := (
		_main_viewport.get_final_transform()
		* _main_viewport.canvas_transform
	)
	var oversample_transform := Transform2D.IDENTITY.scaled(
		Vector2(_last_factor, _last_factor)
	)
	_visual_viewport.canvas_transform = oversample_transform * physical_transform


func _on_player_child_entered(node: Node) -> void:
	_mark_player_visual_tree(node)


func _on_tree_node_added(node: Node) -> void:
	# Ability/cosmetic nodes can be added under a player at runtime. Put those on
	# the same visual render path without touching unrelated scene nodes.
	if node is CanvasItem and _is_under_player(node):
		(node as CanvasItem).visibility_layer = PLAYER_VISUAL_LAYER_MASK


func _is_under_player(node: Node) -> bool:
	var cursor := node.get_parent()
	while cursor != null and cursor != _players_parent:
		if cursor is FootballPlayer:
			return true
		cursor = cursor.get_parent()
	return false


func _mark_player_visual_tree(node: Node) -> void:
	if not (node is FootballPlayer):
		return
	_mark_canvas_items_recursive(node)


func _mark_canvas_items_recursive(node: Node) -> void:
	if node is CanvasItem:
		(node as CanvasItem).visibility_layer = PLAYER_VISUAL_LAYER_MASK
	for child in node.get_children():
		_mark_canvas_items_recursive(child)
