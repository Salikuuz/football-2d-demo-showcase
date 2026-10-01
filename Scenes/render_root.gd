extends Control

# Theodore Ball intentionally keeps a 1152x648 logical canvas for gameplay.
# On a 1080p monitor that leaves only ~60 physical pixels for a player badge.
# Render the *unchanged* game at a 4K-equivalent pixel density, then resolve it
# with a real multi-sample box filter. At 4K the pass becomes 1:1 automatically.
const TARGET_VERTICAL_PIXELS: float = 2160.0
const MAX_SUPERSAMPLE: float = 2.0
# Mobile Web prioritizes stable 60 FPS and low input-to-photon latency over
# desktop-grade supersampling. On Retina iPhones the browser backing canvas can
# be well above 1080p even though the physical display is small. Cap the
# gameplay render target to a 1080p vertical budget and let the simple 2D art
# upscale once at presentation time.
const MOBILE_WEB_MAX_VERTICAL_PIXELS: float = 1080.0
const MIN_LOGICAL_SIZE := Vector2i(320, 180)

@onready var render_container: SubViewportContainer = $RenderContainer
@onready var game_viewport: SubViewport = $RenderContainer/GameViewport
@onready var resolve_material: ShaderMaterial = render_container.material as ShaderMaterial

var _last_physical_size := Vector2i.ZERO
var _last_logical_size := Vector2i.ZERO
var _last_factor: float = -1.0
var _mobile_web_runtime: bool = false


func _ready() -> void:
	_mobile_web_runtime = OS.has_feature("mobile_web")
	if _mobile_web_runtime:
		# The phone build is latency-sensitive. Godot physics interpolation
		# intentionally displays physics slightly in the past, while accumulated
		# input batches touch events to render frames. Both are useful defaults on
		# desktop, but they make a touch football game feel delayed when the WebGL
		# frame rate dips. Keep 60 Hz physics, remove that extra visual/input queue,
		# and avoid wasting work on high-refresh phone panels.
		Engine.max_fps = 60
		get_tree().physics_interpolation = false
		Engine.physics_jitter_fix = 0.0
		Input.use_accumulated_input = false

	# The game lives inside a SubViewport for the SSAA presentation pass. When a
	# solo match pauses the SceneTree, this outer forwarding chain must stay alive
	# or GUI/controller events never reach the pause overlay inside GameViewport.
	process_mode = Node.PROCESS_MODE_ALWAYS
	render_container.process_mode = Node.PROCESS_MODE_ALWAYS
	game_viewport.process_mode = Node.PROCESS_MODE_ALWAYS

	game_viewport.audio_listener_enable_2d = true
	game_viewport.gui_disable_input = false
	game_viewport.handle_input_locally = false
	# Do not quantize moving world transforms. The gameplay viewport is rendered
	# above the logical resolution and resolved down afterwards, so transform
	# snapping is unnecessary for clarity and makes a scrolling Camera2D visibly
	# step/jitter at high refresh rates (most obvious in 4v4 large-team camera).
	# Keep vertices unsnapped as well so curves/rings retain normal antialiasing.
	game_viewport.snap_2d_transforms_to_pixel = false
	game_viewport.snap_2d_vertices_to_pixel = false
	var root_viewport := get_viewport()
	if _mobile_web_runtime:
		# Mobile must not pay for the desktop resolve shader or multisampling. The
		# lower-resolution gameplay target is linearly upscaled directly once.
		render_container.material = null
		render_container.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		game_viewport.msaa_2d = Viewport.MSAA_DISABLED
		if root_viewport != null:
			root_viewport.msaa_2d = Viewport.MSAA_DISABLED
	_apply_render_density()
	if root_viewport != null and not root_viewport.size_changed.is_connected(_apply_render_density):
		root_viewport.size_changed.connect(_apply_render_density)


func _apply_render_density() -> void:
	var physical_size: Vector2i = get_window().size
	if physical_size.x <= 0 or physical_size.y <= 0:
		return
	var visible_size: Vector2 = get_viewport().get_visible_rect().size
	var logical_size := Vector2i(
		maxi(MIN_LOGICAL_SIZE.x, int(round(visible_size.x))),
		maxi(MIN_LOGICAL_SIZE.y, int(round(visible_size.y)))
	)
	# The Mobile Web export gets a true performance render path rather than merely
	# disabling desktop supersampling. Retina backing canvases can be much larger
	# than the useful phone presentation size, so cap the internal 2D target.
	# Generic Web keeps native density; desktop keeps the high-quality SSAA path.
	var factor: float
	if _mobile_web_runtime:
		factor = minf(
			1.0,
			MOBILE_WEB_MAX_VERTICAL_PIXELS / float(maxi(1, physical_size.y))
		)
	elif OS.has_feature("web"):
		factor = 1.0
	else:
		factor = clampf(
			TARGET_VERTICAL_PIXELS / float(maxi(1, physical_size.y)),
			1.0,
			MAX_SUPERSAMPLE
		)
	if (
		physical_size == _last_physical_size
		and logical_size == _last_logical_size
		and is_equal_approx(factor, _last_factor)
	):
		return
	_last_physical_size = physical_size
	_last_logical_size = logical_size
	_last_factor = factor

	# The render target follows the physical window, not the 1152x648 canvas.
	# 1920x1080 -> 3840x2160. 3840x2160 -> 3840x2160.
	var render_size := Vector2i(
		maxi(1, int(round(float(physical_size.x) * factor))),
		maxi(1, int(round(float(physical_size.y) * factor)))
	)
	game_viewport.size = render_size
	game_viewport.size_2d_override = logical_size
	game_viewport.size_2d_override_stretch = true
	_apply_render_target_msaa(factor)

	# Make the high-resolution container occupy exactly the original logical
	# canvas. SubViewportContainer keeps its native high-res texture; the Control
	# transform only determines where it lands on the main window.
	render_container.position = Vector2.ZERO
	render_container.size = Vector2(render_size)
	render_container.scale = Vector2(
		float(logical_size.x) / float(render_size.x),
		float(logical_size.y) / float(render_size.y)
	)
	if resolve_material != null and not _mobile_web_runtime:
		resolve_material.set_shader_parameter(
			"resolve_scale",
			Vector2(factor, factor)
		)


func get_game_scene() -> Node:
	return game_viewport.get_node_or_null("Playfield")


func _apply_render_target_msaa(supersample_factor: float) -> void:
	if _mobile_web_runtime:
		game_viewport.msaa_2d = Viewport.MSAA_DISABLED
		return
	if OS.has_feature("web"):
		# Keep a light edge pass without multiplying WebGL memory usage.
		game_viewport.msaa_2d = Viewport.MSAA_2X
		return
	# The gameplay viewport is already rasterized above the physical resolution.
	# Running 8x MSAA on a 3840x2160 target at 1080p stacked two expensive AA
	# techniques and multiplied GPU work for very little visible improvement.
	# Retain light MSAA for procedural circles/lines while letting SSAA do the
	# heavy lifting. Native-density output still gets 4x MSAA.
	if supersample_factor > 1.05:
		game_viewport.msaa_2d = Viewport.MSAA_2X
	else:
		game_viewport.msaa_2d = Viewport.MSAA_4X
