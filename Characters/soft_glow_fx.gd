extends Node2D


@export var base_radius: float = 210.0
@export_range(0.0, 1.0, 0.01) var glow_alpha: float = 0.30
@export_range(0.0, 0.08, 0.005) var pulse_amount: float = 0.025
@export_range(0.1, 3.0, 0.05) var pulse_speed: float = 0.75

var _accent_color: Color = Color(0.72, 0.84, 1.0, 1.0)
var _size_multiplier: float = 1.0
var _elapsed: float = 0.0


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive
	queue_redraw()


func set_accent_color(color: Color) -> void:
	_accent_color = Color(
		clampf(color.r, 0.0, 1.0),
		clampf(color.g, 0.0, 1.0),
		clampf(color.b, 0.0, 1.0),
		1.0
	)
	queue_redraw()


func set_size_multiplier(multiplier: float) -> void:
	_size_multiplier = clampf(multiplier, 0.5, 2.0)
	queue_redraw()


func _process(delta: float) -> void:
	# Animate only the transform/opacity. The glow geometry itself stays cached,
	# so having one of these on every player does not rebuild vector draw calls
	# every rendered frame.
	_elapsed += maxf(0.0, delta)
	var wave: float = 0.5 + 0.5 * sin(_elapsed * TAU * pulse_speed)
	var pulse: float = lerpf(1.0 - pulse_amount, 1.0 + pulse_amount, wave)
	scale = Vector2.ONE * pulse
	modulate.a = lerpf(0.90, 1.0, wave)


func _draw() -> void:
	var radius: float = base_radius * _size_multiplier
	# This is intentionally a clearly visible light aura, not a tiny edge tint.
	# The additive discs overlap into a bright inner bloom and then feather out
	# over a wide radius. Geometry is still cached between color/size changes, so
	# the stronger look does not turn this into an every-frame redraw workload.
	var light_color: Color = _accent_color.lightened(0.32)
	for layer_index in range(12):
		var ratio: float = float(layer_index) / 11.0
		var layer_radius: float = lerpf(radius * 0.48, radius, ratio)
		var alpha: float = glow_alpha * pow(1.0 - ratio, 1.35) * 0.55
		draw_circle(Vector2.ZERO, layer_radius, Color(light_color, alpha))
