extends Node2D


@export var match_manager: FootballMatchManager
@export_range(0.0, 1.0, 0.01)
var color_strength: float = 0.92
@export var arena_bounds: Rect2 = Rect2(-5200.0, -2900.0, 20500.0, 10100.0)

const TEXTURE_WIDTH: int = 320
const TEXTURE_HEIGHT: int = 180
const SURFACE_TEXTURE_WIDTH: int = 1280
const SURFACE_TEXTURE_HEIGHT: int = 720
const GENERATED_TEXTURE_DIRECTORY: String = "res://Assets/generated_fields"



const VARIANT_THEMES: Array[Dictionary] = [
	{
		"name": "Aurora Haze",
		"base_a": Color(0.09, 0.09, 0.20),
		"base_b": Color(0.13, 0.62, 0.61),
		"accent": Color(0.30, 0.78, 0.70),
		"detail": Color(0.63, 0.91, 0.85),
		"preview_texture": preload("res://Assets/map_backgrounds/aurora_haze_preview.jpg"),
		"surface_texture": preload("res://Assets/map_backgrounds/aurora_haze_surface.jpg"),
	},
	{
		"name": "Classic Pitch",
		"base_a": Color(0.20, 0.56, 0.28),
		"base_b": Color(0.34, 0.67, 0.37),
		"accent": Color(0.48, 0.76, 0.45),
		"detail": Color(0.72, 0.90, 0.66),
		"preview_texture": preload("res://Assets/map_backgrounds/football_pitch_preview.jpg"),
		"surface_texture": preload("res://Assets/map_backgrounds/football_pitch_surface.jpg"),
	},
	{
		"name": "Verdant Canopy",
		"base_a": Color(0.060, 0.18, 0.070),
		"base_b": Color(0.24, 0.46, 0.16),
		"accent": Color(0.54, 0.77, 0.33),
		"detail": Color(0.87, 0.93, 0.62),
		"pattern_type": 21,
		"gradient_type": 3,
		"pattern_strength": 0.36,
		"brightness": 0.99,
		"contrast": 1.03,
		"grain_strength": 0.010,
		"baked_index": 16,
	},
	{
		"name": "Cotton Dusk",
		"base_a": Color(0.34, 0.38, 0.58),
		"base_b": Color(0.75, 0.60, 0.78),
		"accent": Color(0.94, 0.63, 0.75),
		"detail": Color(0.90, 0.88, 0.98),
		"preview_texture": preload("res://Assets/map_backgrounds/cotton_dusk_preview.jpg"),
		"surface_texture": preload("res://Assets/map_backgrounds/cotton_dusk_surface.jpg"),
	},
	{
		"name": "Violet Current",
		"base_a": Color(0.01, 0.005, 0.025),
		"base_b": Color(0.16, 0.05, 0.35),
		"accent": Color(0.48, 0.22, 0.92),
		"detail": Color(0.78, 0.60, 1.0),
		"preview_texture": preload("res://Assets/map_backgrounds/violet_waves_preview.jpg"),
		"surface_texture": preload("res://Assets/map_backgrounds/violet_waves_surface.jpg"),
	},
	{
		"name": "Sunset Wash",
		"base_a": Color(0.32, 0.68, 0.84),
		"base_b": Color(0.92, 0.55, 0.50),
		"accent": Color(1.0, 0.76, 0.48),
		"detail": Color(1.0, 0.88, 0.83),
		"preview_texture": preload("res://Assets/map_backgrounds/pastel_skies_preview.jpg"),
		"surface_texture": preload("res://Assets/map_backgrounds/pastel_skies_surface.jpg"),
	},
	{
		"name": "Midnight Veil",
		"base_a": Color(0.01, 0.012, 0.018),
		"base_b": Color(0.18, 0.21, 0.26),
		"accent": Color(0.48, 0.54, 0.62),
		"detail": Color(0.90, 0.92, 0.95),
		"preview_texture": preload("res://Assets/map_backgrounds/stellar_drift_preview.jpg"),
		"surface_texture": preload("res://Assets/map_backgrounds/stellar_drift_surface.jpg"),
	},
	{
		"name": "Inkstorm",
		"base_a": Color(0.02, 0.02, 0.03),
		"base_b": Color(0.18, 0.18, 0.19),
		"accent": Color(0.36, 0.36, 0.38),
		"detail": Color(0.58, 0.58, 0.60),
		"preview_texture": preload("res://Assets/map_backgrounds/inkstorm_preview.jpg"),
		"surface_texture": preload("res://Assets/map_backgrounds/inkstorm_surface.jpg"),
	},
	{
		"name": "Roseflow",
		"base_a": Color(0.48, 0.20, 0.38),
		"base_b": Color(0.96, 0.68, 0.78),
		"accent": Color(1.0, 0.54, 0.72),
		"detail": Color(1.0, 0.90, 0.94),
		"preview_texture": preload("res://Assets/map_backgrounds/roseflow_preview.jpg"),
		"surface_texture": preload("res://Assets/map_backgrounds/roseflow_surface.jpg"),
	},
	{
		"name": "Ivory Drift",
		"base_a": Color(0.68, 0.72, 0.82),
		"base_b": Color(0.96, 0.97, 1.0),
		"accent": Color(0.82, 0.88, 0.98),
		"detail": Color(1.0, 1.0, 1.0),
		"preview_texture": preload("res://Assets/map_backgrounds/ivory_drift_preview.jpg"),
		"surface_texture": preload("res://Assets/map_backgrounds/ivory_drift_surface.jpg"),
	},
	{
		"name": "Lime Stripes",
		"base_a": Color(0.03, 0.35, 0.06),
		"base_b": Color(0.18, 0.69, 0.10),
		"accent": Color(0.38, 0.82, 0.16),
		"detail": Color(0.66, 0.92, 0.34),
		"surface_brightness": 0.85,
		"preview_texture": preload("res://Assets/map_backgrounds/lime_stripes_preview.jpg"),
		"surface_texture": preload("res://Assets/map_backgrounds/lime_stripes_surface.jpg"),
	},
]


static var _variant_texture_cache: Dictionary = {}
static var _surface_texture_cache: Dictionary = {}

var _surface_layer: CanvasLayer
var _surface_fill: ColorRect
var _surface: TextureRect


static func get_variant_theme(variant_index: int) -> Dictionary:
	return VARIANT_THEMES[posmod(variant_index, VARIANT_THEMES.size())]


static func get_variant_tint(variant_index: int) -> Color:
	var theme: Dictionary = get_variant_theme(variant_index)
	var base_a: Color = theme.get("base_a", Color.WHITE) as Color
	var base_b: Color = theme.get("base_b", Color.WHITE) as Color
	return base_a.lerp(base_b, 0.5)


static func get_variant_count() -> int:
	return VARIANT_THEMES.size()


static func get_variant_texture(variant_index: int) -> Texture2D:
	var safe_index: int = posmod(variant_index, VARIANT_THEMES.size())
	if _variant_texture_cache.has(safe_index):
		return _variant_texture_cache[safe_index] as Texture2D
	var texture: Texture2D = _load_explicit_variant_texture(safe_index, false)
	if texture == null:
		texture = _load_baked_variant_texture(safe_index, false)
	if texture == null:
		push_warning(
			"Generated preview for map %d is missing; using slow procedural fallback."
			% (safe_index + 1)
		)
		texture = _generate_variant_texture(
			safe_index,
			TEXTURE_WIDTH,
			TEXTURE_HEIGHT,
			false
		)
	_variant_texture_cache[safe_index] = texture
	return texture


static func get_surface_variant_texture(variant_index: int) -> Texture2D:
	var safe_index: int = posmod(variant_index, VARIANT_THEMES.size())
	if _surface_texture_cache.has(safe_index):
		return _surface_texture_cache[safe_index] as Texture2D
	var texture: Texture2D = _load_explicit_variant_texture(safe_index, true)
	if texture == null:
		texture = _load_baked_variant_texture(safe_index, true)
	if texture == null:
		push_warning(
			"Generated surface for map %d is missing; using slow procedural fallback."
			% (safe_index + 1)
		)
		texture = _generate_variant_texture(
			safe_index,
			SURFACE_TEXTURE_WIDTH,
			SURFACE_TEXTURE_HEIGHT,
			true
		)
	_surface_texture_cache[safe_index] = texture
	return texture


static func _load_explicit_variant_texture(
	variant_index: int,
	is_surface: bool
) -> Texture2D:
	var theme: Dictionary = get_variant_theme(variant_index)
	var texture_key: String = "surface_texture" if is_surface else "preview_texture"
	var texture: Texture2D = theme.get(texture_key, null) as Texture2D
	if texture != null:
		return texture
	var path_key: String = "surface_path" if is_surface else "preview_path"
	var source_path: String = str(theme.get(path_key, ""))
	if source_path.is_empty():
		return null
	return _load_texture_from_source_path(source_path, is_surface)


static func _load_texture_from_source_path(
	source_path: String,
	with_mipmaps: bool
) -> Texture2D:
	if ResourceLoader.exists(source_path):
		var resource := ResourceLoader.load(source_path, "Texture2D") as Texture2D
		if resource != null:
			return resource
	var image: Image = Image.load_from_file(source_path)
	if image == null or image.is_empty():
		return null
	if with_mipmaps:
		image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


static func _load_baked_variant_texture(
	variant_index: int,
	is_surface: bool
) -> Texture2D:
	var theme: Dictionary = get_variant_theme(variant_index)
	if not theme.has("baked_index"):
		return null
	var baked_index: int = int(theme.get("baked_index", variant_index))
	var suffix: String = "surface" if is_surface else "preview"
	var path: String = "%s/map_%02d_%s.png" % [
		GENERATED_TEXTURE_DIRECTORY,
		baked_index,
		suffix,
	]
	if not ResourceLoader.exists(path):
		return null
	return ResourceLoader.load(path, "Texture2D") as Texture2D


static func _generate_variant_texture(
	variant_index: int,
	texture_width: int,
	texture_height: int,
	with_mipmaps: bool
) -> Texture2D:
	var theme: Dictionary = get_variant_theme(variant_index)
	var image: Image = Image.create(
		texture_width,
		texture_height,
		false,
		Image.FORMAT_RGBA8
	)
	var base_a: Color = theme.get("base_a", Color(0.1, 0.3, 0.16)) as Color
	var base_b: Color = theme.get("base_b", Color(0.22, 0.48, 0.27)) as Color
	var accent: Color = theme.get("accent", Color(0.45, 0.72, 0.36)) as Color
	var detail: Color = theme.get("detail", Color(0.8, 0.85, 0.58)) as Color
	var pattern_type: int = int(theme.get("pattern_type", 0))
	var gradient_type: int = int(theme.get("gradient_type", 0))
	var pattern_strength: float = float(theme.get("pattern_strength", 0.30))
	var brightness: float = float(theme.get("brightness", 1.0))
	var contrast: float = float(theme.get("contrast", 1.0))
	var grain_strength: float = float(theme.get("grain_strength", 0.014))

	for y in range(texture_height):
		var v: float = (float(y) + 0.5) / float(texture_height)
		for x in range(texture_width):
			var u: float = (float(x) + 0.5) / float(texture_width)
			var uv: Vector2 = Vector2(u, v)
			var base_mix: float = _base_mix_value(uv, gradient_type)
			var surface: Color = base_a.lerp(base_b, base_mix)
			var pattern_values: Vector2 = _pattern_values(uv, pattern_type)
			var mask: float = pattern_values.x
			var secondary_mask: float = pattern_values.y
			surface = surface.lerp(accent, clampf(mask * pattern_strength, 0.0, 0.72))
			surface = surface.lerp(detail, clampf(secondary_mask * pattern_strength * 0.72, 0.0, 0.38))
			if pattern_type == 20:
				surface = _andromeda_surface_detail(
					uv,
					surface,
					accent,
					detail
				)
			var large_grain: float = _hash21(Vector2(floor(u * 76.0), floor(v * 42.0))) - 0.5
			var fine_grain: float = _hash21(Vector2(floor(u * 420.0), floor(v * 230.0))) - 0.5
			var grain: float = 1.0 + (large_grain * 0.55 + fine_grain * 0.45) * grain_strength
			surface.r *= grain
			surface.g *= grain
			surface.b *= grain
			surface.r = clampf(((surface.r - 0.5) * contrast + 0.5) * brightness, 0.0, 1.0)
			surface.g = clampf(((surface.g - 0.5) * contrast + 0.5) * brightness, 0.0, 1.0)
			surface.b = clampf(((surface.b - 0.5) * contrast + 0.5) * brightness, 0.0, 1.0)
			surface.a = 1.0
			image.set_pixel(x, y, surface)

	if with_mipmaps:
		image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


static func _andromeda_surface_detail(
	uv: Vector2,
	surface: Color,
	accent: Color,
	detail: Color
) -> Color:
	# A recognizable inclined spiral rather than a single generic color band.
	# The soft contrast keeps the pitch markings and players readable.
	var center := Vector2(0.56, 0.48)
	var delta := Vector2(
		(uv.x - center.x) * 1.08,
		(uv.y - center.y) * 1.82
	)
	var radius: float = delta.length()
	var angle: float = atan2(delta.y, delta.x)
	var radial_fade: float = 1.0 - _smoothstep(0.06, 0.62, radius)
	var spiral_a: float = 0.5 + 0.5 * cos(angle * 2.0 - radius * 29.0)
	var spiral_b: float = 0.5 + 0.5 * cos(angle * 2.0 - radius * 29.0 + PI)
	var arm_a: float = _smoothstep(0.58, 0.94, spiral_a) * radial_fade
	var arm_b: float = _smoothstep(0.60, 0.95, spiral_b) * radial_fade
	var core: float = 1.0 - _smoothstep(0.015, 0.13, radius)
	var halo: float = 1.0 - _smoothstep(0.12, 0.72, radius)
	var result: Color = surface
	result = result.lerp(Color(0.23, 0.36, 0.86), arm_a * 0.43)
	result = result.lerp(Color(0.70, 0.20, 0.77), arm_b * 0.34)
	result = result.lerp(accent.lightened(0.22), halo * 0.18)
	result = result.lerp(Color(0.86, 0.91, 1.0), core * 0.76)

	var dust_wave: float = 0.5 + 0.5 * cos(
		angle * 2.0 - radius * 29.0 + 0.48
	)
	var dust_lane: float = (
		_smoothstep(0.72, 0.94, dust_wave)
		* radial_fade
		* (1.0 - core)
	)
	result = result.lerp(Color(0.008, 0.006, 0.028), dust_lane * 0.34)

	var star_a: float = _andromeda_star_layer(
		uv,
		Vector2(146.0, 82.0),
		Vector2(17.0, 41.0),
		0.925,
		0.105
	)
	var star_b: float = _andromeda_star_layer(
		uv,
		Vector2(67.0, 38.0),
		Vector2(79.0, 13.0),
		0.965,
		0.075
	)
	var star_light: float = maxf(star_a * 0.86, star_b)
	result = result.lerp(detail.lightened(0.18), star_light * 0.92)
	return result


static func _andromeda_star_layer(
	uv: Vector2,
	grid_size: Vector2,
	seed_offset: Vector2,
	threshold: float,
	star_radius: float
) -> float:
	var grid_uv: Vector2 = uv * grid_size
	var cell: Vector2 = floor(grid_uv)
	var seed: float = _hash21(cell + seed_offset)
	if seed < threshold:
		return 0.0
	var local: Vector2 = Vector2(
		fposmod(grid_uv.x, 1.0),
		fposmod(grid_uv.y, 1.0)
	) - Vector2(0.5, 0.5)
	var intensity: float = 1.0 - _smoothstep(
		star_radius,
		star_radius * 2.8,
		local.length()
	)
	return intensity * lerpf(0.62, 1.0, seed)


static func _base_mix_value(uv: Vector2, gradient_type: int) -> float:
	if gradient_type == 1:
		return _smoothstep(0.0, 1.0, uv.x)
	if gradient_type == 2:
		return _smoothstep(0.0, 1.0, uv.y)
	if gradient_type == 3:
		return 1.0 - _smoothstep(0.02, 0.72, uv.distance_to(Vector2(0.5, 0.5)))
	if gradient_type == 4:
		var left_glow: float = 1.0 - _smoothstep(0.0, 0.95, uv.distance_to(Vector2(0.18, 0.42)))
		var right_glow: float = 1.0 - _smoothstep(0.0, 0.92, uv.distance_to(Vector2(0.83, 0.58)))
		return clampf(left_glow * 0.38 + right_glow * 0.92, 0.0, 1.0)
	if gradient_type == 5:
		return _smoothstep(0.30, 0.70, uv.x + sin(uv.y * TAU) * 0.08)
	return _smoothstep(0.0, 1.0, clampf(uv.x * 0.78 + uv.y * 0.22, 0.0, 1.0))


static func _pattern_values(uv: Vector2, pattern_type: int) -> Vector2:
	var mask: float = 0.0
	var secondary_mask: float = 0.0

	if pattern_type == 0:
		var chevron_a: float = 0.5 + 0.5 * sin((uv.x + absf(uv.y - 0.5) * 0.72) * PI * 12.0)
		var chevron_b: float = 0.5 + 0.5 * sin((uv.x - absf(uv.y - 0.5) * 0.72) * PI * 6.0)
		mask = _smoothstep(0.58, 0.86, chevron_a)
		secondary_mask = _smoothstep(0.66, 0.92, chevron_b)
	elif pattern_type == 1:
		var d1: float = uv.distance_to(Vector2(0.50, 0.50))
		var rings1: float = 0.5 + 0.5 * sin(d1 * PI * 14.0)
		var angle1: float = atan2(uv.y - 0.5, uv.x - 0.5)
		var rays1: float = 0.5 + 0.5 * sin(angle1 * 10.0)
		var radial1: float = 1.0 - _smoothstep(0.08, 0.74, d1)
		mask = rings1 * radial1
		secondary_mask = rays1 * radial1
	elif pattern_type == 2:
		var thin_lines: float = 0.5 + 0.5 * sin(uv.x * PI * 34.0)
		var cross_lines: float = 0.5 + 0.5 * sin((uv.x * 0.35 + uv.y) * PI * 8.0)
		mask = _smoothstep(0.78, 0.96, thin_lines)
		secondary_mask = _smoothstep(0.70, 0.92, cross_lines)
	elif pattern_type == 3:
		var prism_a: float = 0.5 + 0.5 * sin((uv.x + uv.y * 0.85) * PI * 8.0)
		var prism_b: float = 0.5 + 0.5 * sin((uv.x - uv.y * 0.85) * PI * 8.0)
		mask = _smoothstep(0.56, 0.90, prism_a)
		secondary_mask = _smoothstep(0.56, 0.90, prism_b)
	elif pattern_type == 4:
		var marble_a: float = 0.5 + 0.5 * sin((uv.y + sin(uv.x * TAU * 1.6) * 0.085) * PI * 8.0)
		var marble_b: float = 0.5 + 0.5 * sin((uv.x + sin(uv.y * TAU * 1.2) * 0.060) * PI * 5.0)
		mask = _smoothstep(0.48, 0.84, marble_a)
		secondary_mask = _smoothstep(0.62, 0.91, marble_b)
	elif pattern_type == 5:
		var cell_x5: float = floor(uv.x * 10.0)
		var cell_y5: float = floor(uv.y * 6.0)
		var checker5: float = fmod(cell_x5 + cell_y5, 2.0)
		var fx5: float = absf(fposmod(uv.x * 10.0, 1.0) - 0.5)
		var fy5: float = absf(fposmod(uv.y * 6.0, 1.0) - 0.5)
		var lattice5: float = maxf(_smoothstep(0.44, 0.49, fx5), _smoothstep(0.44, 0.49, fy5))
		mask = checker5 * 0.70
		secondary_mask = lattice5
	elif pattern_type == 6:
		var d6: float = uv.distance_to(Vector2(0.5, 0.5))
		var rings6: float = 0.5 + 0.5 * sin(d6 * PI * 22.0)
		var ring_fade6: float = 1.0 - _smoothstep(0.10, 0.78, d6)
		mask = _smoothstep(0.50, 0.86, rings6) * ring_fade6
		secondary_mask = 1.0 - _smoothstep(0.0, 0.56, d6)
	elif pattern_type == 7:
		var terrain7: float = uv.y + sin(uv.x * 11.0) * 0.045 + sin(uv.x * 25.0 + 1.4) * 0.018
		var contour7: float = 0.5 + 0.5 * sin(terrain7 * PI * 20.0)
		var broad7: float = 0.5 + 0.5 * sin((uv.x + uv.y * 0.18) * PI * 2.6)
		mask = _smoothstep(0.76, 0.96, contour7)
		secondary_mask = broad7
	elif pattern_type == 8:
		var side_lanes8: float = maxf(
			1.0 - _smoothstep(0.04, 0.25, uv.x),
			_smoothstep(0.75, 0.96, uv.x)
		)
		var center8: float = 1.0 - _smoothstep(0.04, 0.20, absf(uv.x - 0.5))
		var diagonal8: float = 0.5 + 0.5 * sin((uv.x + uv.y * 0.48) * PI * 9.0)
		mask = side_lanes8
		secondary_mask = center8 * 0.55 + _smoothstep(0.72, 0.94, diagonal8) * 0.45
	elif pattern_type == 9:
		var ribbon9: float = 0.5 + 0.5 * sin((uv.y + sin(uv.x * 7.0) * 0.13) * PI * 5.0)
		var drift9: float = 0.5 + 0.5 * sin((uv.x * 0.76 - uv.y * 0.46) * PI * 4.0)
		mask = _smoothstep(0.44, 0.82, ribbon9)
		secondary_mask = _smoothstep(0.54, 0.89, drift9)
	elif pattern_type == 10:
		var diamond_uv10: Vector2 = Vector2(fposmod(uv.x * 8.0, 1.0), fposmod(uv.y * 5.0, 1.0)) - Vector2(0.5, 0.5)
		var diamond10: float = absf(diamond_uv10.x) + absf(diamond_uv10.y)
		mask = 1.0 - _smoothstep(0.24, 0.47, diamond10)
		var diamond_line10: float = 1.0 - _smoothstep(0.018, 0.060, absf(diamond10 - 0.34))
		secondary_mask = diamond_line10
	elif pattern_type == 11:
		var broad_band11: float = 0.5 + 0.5 * sin((uv.x * 0.82 + uv.y * 0.24) * PI * 4.0)
		var split11: float = _smoothstep(0.18, 0.82, uv.x)
		var wave11: float = 0.5 + 0.5 * sin((uv.y + sin(uv.x * 8.0) * 0.08) * PI * 6.0)
		mask = broad_band11 * 0.55 + split11 * 0.45
		secondary_mask = _smoothstep(0.62, 0.90, wave11)
	elif pattern_type == 12:
		var corner_a12: float = 1.0 - _smoothstep(0.02, 0.76, uv.distance_to(Vector2.ZERO))
		var corner_b12: float = 1.0 - _smoothstep(0.02, 0.76, uv.distance_to(Vector2.ONE))
		var arc_a12: float = 0.5 + 0.5 * sin(uv.distance_to(Vector2.ZERO) * PI * 12.0)
		var arc_b12: float = 0.5 + 0.5 * sin(uv.distance_to(Vector2.ONE) * PI * 12.0)
		mask = maxf(_smoothstep(0.60, 0.90, arc_a12) * corner_a12, _smoothstep(0.60, 0.90, arc_b12) * corner_b12)
		secondary_mask = maxf(corner_a12, corner_b12)
	elif pattern_type == 13:
		var cell13: Vector2 = Vector2(fposmod(uv.x * 14.0, 1.0), fposmod(uv.y * 8.0, 1.0)) - Vector2(0.5, 0.5)
		var dots13: float = 1.0 - _smoothstep(0.10, 0.25, cell13.length())
		var wave13: float = 0.5 + 0.5 * sin((uv.x + uv.y * 0.28) * PI * 5.0)
		mask = dots13
		secondary_mask = _smoothstep(0.62, 0.91, wave13)
	elif pattern_type == 14:
		var grid_uv14: Vector2 = Vector2(fposmod(uv.x * 12.0, 1.0), fposmod(uv.y * 7.0, 1.0))
		var line_x14: float = 1.0 - _smoothstep(0.03, 0.09, absf(grid_uv14.x - 0.5))
		var line_y14: float = 1.0 - _smoothstep(0.03, 0.09, absf(grid_uv14.y - 0.5))
		var enable_x14: float = 1.0 if grid_uv14.y >= 0.28 else 0.0
		var enable_y14: float = 1.0 if grid_uv14.x <= 0.72 else 0.0
		var circuit14: float = maxf(line_x14 * enable_x14, line_y14 * enable_y14)
		var node14: float = 1.0 - _smoothstep(0.06, 0.16, (grid_uv14 - Vector2(0.5, 0.5)).length())
		mask = circuit14
		secondary_mask = node14
	elif pattern_type == 15:
		var tile15: Vector2 = floor(uv * Vector2(12.0, 7.0))
		var local15: Vector2 = Vector2(fposmod(uv.x * 12.0, 1.0), fposmod(uv.y * 7.0, 1.0))
		var flip15: float = 1.0 if _hash21(tile15) >= 0.5 else 0.0
		var shard15: float = local15.x + local15.y if flip15 > 0.5 else local15.x + (1.0 - local15.y)
		mask = _smoothstep(0.72, 0.92, shard15)
		secondary_mask = 1.0 - _smoothstep(0.02, 0.10, absf(shard15 - 1.0))
	elif pattern_type == 16:
		# Clean graphite: broad soft sweeps instead of dense pinstripes.
		var sweep_a16: float = 0.5 + 0.5 * sin((uv.x * 0.72 + uv.y * 0.34 - 0.08) * PI * 2.5)
		var sweep_b16: float = 0.5 + 0.5 * sin((uv.x * 0.55 - uv.y * 0.48 + 0.22) * PI * 3.0)
		var center16: float = 1.0 - _smoothstep(0.08, 0.68, uv.distance_to(Vector2(0.50, 0.50)))
		mask = _smoothstep(0.58, 0.92, sweep_a16) * 0.72 + center16 * 0.18
		secondary_mask = _smoothstep(0.70, 0.96, sweep_b16) * 0.45
	elif pattern_type == 17:
		# Clean jade: wide flowing ribbons with a soft offset halo.
		var flow17: float = 0.5 + 0.5 * sin((uv.y + sin(uv.x * TAU * 1.15) * 0.095) * PI * 4.2)
		var drift17: float = 0.5 + 0.5 * sin((uv.x * 0.70 + uv.y * 0.26) * PI * 3.2)
		var halo17: float = 1.0 - _smoothstep(0.12, 0.70, uv.distance_to(Vector2(0.68, 0.42)))
		mask = _smoothstep(0.55, 0.90, flow17) * 0.70 + halo17 * 0.18
		secondary_mask = _smoothstep(0.68, 0.94, drift17) * 0.42
	elif pattern_type == 18:
		# Broad crossing light currents. Their generous spacing keeps the ball,
		# player badges, and field markings readable on darker colorways.
		var current_a18: float = 0.5 + 0.5 * sin(
			(uv.y + sin(uv.x * TAU * 1.20) * 0.105) * PI * 4.0
		)
		var current_b18: float = 0.5 + 0.5 * sin(
			(uv.x - uv.y * 0.42 + 0.16) * PI * 3.2
		)
		var center_glow18: float = 1.0 - _smoothstep(
			0.08,
			0.72,
			uv.distance_to(Vector2(0.52, 0.48))
		)
		mask = _smoothstep(0.62, 0.94, current_a18) * 0.72
		mask += center_glow18 * 0.14
		secondary_mask = _smoothstep(0.70, 0.96, current_b18) * 0.58
	elif pattern_type == 19:
		# Large hex-like cells made from three restrained lattice directions.
		# The lines are intentionally soft so the pitch does not become noisy.
		var lattice_uv19: Vector2 = uv * Vector2(8.0, 5.0)
		var diagonal_a19: float = absf(
			fposmod(lattice_uv19.x + lattice_uv19.y * 0.52, 1.0) - 0.5
		)
		var diagonal_b19: float = absf(
			fposmod(lattice_uv19.x - lattice_uv19.y * 0.52, 1.0) - 0.5
		)
		var horizontal19: float = absf(
			fposmod(lattice_uv19.y, 1.0) - 0.5
		)
		mask = maxf(
			_smoothstep(0.43, 0.49, diagonal_a19),
			_smoothstep(0.43, 0.49, diagonal_b19)
		)
		secondary_mask = _smoothstep(0.45, 0.495, horizontal19)
	elif pattern_type == 20:
		# A broad, softly curved galactic band with sparse deterministic stars.
		# Keeping the star field procedural prevents scaling artifacts on the
		# full-size pitch while retaining the existing lightweight thumbnails.
		var galaxy_center20: float = (
			0.70
			- uv.x * 0.40
			+ sin((uv.x + 0.08) * TAU * 1.15) * 0.045
		)
		var galaxy_distance20: float = absf(uv.y - galaxy_center20)
		var galaxy_band20: float = 1.0 - _smoothstep(
			0.035,
			0.30,
			galaxy_distance20
		)
		var nebula_ripple20: float = 0.5 + 0.5 * sin(
			(uv.x * 2.8 + uv.y * 1.7) * TAU
		)
		var star_grid20: Vector2 = uv * Vector2(92.0, 52.0)
		var star_cell20: Vector2 = floor(star_grid20)
		var star_local20: Vector2 = Vector2(
			fposmod(star_grid20.x, 1.0),
			fposmod(star_grid20.y, 1.0)
		) - Vector2(0.5, 0.5)
		var star_seed20: float = _hash21(star_cell20 + Vector2(31.0, 73.0))
		var star_radius20: float = lerpf(0.055, 0.16, star_seed20)
		var star20: float = 0.0
		if star_seed20 > 0.86:
			star20 = 1.0 - _smoothstep(
				star_radius20,
				star_radius20 * 2.25,
				star_local20.length()
			)
		mask = galaxy_band20 * lerpf(0.42, 0.92, nebula_ripple20)
		secondary_mask = maxf(star20, galaxy_band20 * 0.16)
	elif pattern_type == 21:
		# Broad warm rays visibly cross the grass without obscuring markings.
		var sun_center21 := Vector2(0.16, 0.06)
		var sun_delta21: Vector2 = uv - sun_center21
		var sun_distance21: float = sun_delta21.length()
		var sun_angle21: float = atan2(sun_delta21.y, sun_delta21.x)
		var sun_glow21: float = 1.0 - _smoothstep(0.03, 0.78, sun_distance21)
		var rays21: float = 0.5 + 0.5 * cos(sun_angle21 * 11.0 + sin(sun_distance21 * 18.0) * 0.4)
		var warm_bands21: float = 0.5 + 0.5 * sin((uv.x * 0.48 + uv.y) * PI * 7.0)
		mask = sun_glow21 * (0.30 + _smoothstep(0.58, 0.94, rays21) * 0.70)
		secondary_mask = sun_glow21 * _smoothstep(0.68, 0.95, warm_bands21)
	else:
		# Silvery tidal arcs and sparse glints create a calm moonlit surface.
		var moon_center22 := Vector2(0.80, 0.12)
		var moon_distance22: float = uv.distance_to(moon_center22)
		var tides22: float = 0.5 + 0.5 * sin(
			moon_distance22 * PI * 18.0 + uv.x * PI * 1.5
		)
		var moon_glow22: float = 1.0 - _smoothstep(0.02, 0.72, moon_distance22)
		var glint_grid22: Vector2 = uv * Vector2(46.0, 26.0)
		var glint_seed22: float = _hash21(floor(glint_grid22) + Vector2(19.0, 47.0))
		var glint22: float = 0.0
		if glint_seed22 > 0.955:
			var glint_local22: Vector2 = Vector2(
				fposmod(glint_grid22.x, 1.0),
				fposmod(glint_grid22.y, 1.0)
			) - Vector2(0.5, 0.5)
			glint22 = 1.0 - _smoothstep(0.06, 0.19, glint_local22.length())
		mask = _smoothstep(0.62, 0.94, tides22) * 0.62 + moon_glow22 * 0.28
		secondary_mask = maxf(glint22, moon_glow22 * 0.32)

	return Vector2(clampf(mask, 0.0, 1.0), clampf(secondary_mask, 0.0, 1.0))


static func _smoothstep(edge0: float, edge1: float, x: float) -> float:
	if is_equal_approx(edge0, edge1):
		return 0.0
	var t: float = clampf((x - edge0) / (edge1 - edge0), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


static func _hash21(point: Vector2) -> float:
	var value: float = sin(point.dot(Vector2(127.1, 311.7))) * 43758.5453123
	return value - floor(value)


func _ready() -> void:
	_disable_legacy_background_sprites()
	_build_surface()
	if match_manager == null:
		push_error("FieldVariant MatchManager was not assigned.")
		return
	# Keep the authoritative MatchManager catalog size tied to this actual map
	# catalog.  This prevents newly added selector entries from wrapping back
	# into older maps when a stale hard-coded field_variant_count is present.
	match_manager.field_variant_count = maxi(1, get_variant_count())
	match_manager.current_field_variant = posmod(
		match_manager.current_field_variant,
		match_manager.field_variant_count
	)
	match_manager.field_variant_changed.connect(_apply_variant)
	_apply_variant(match_manager.current_field_variant)


func _disable_legacy_background_sprites() -> void:
	for child_node in get_children():
		var sprite: Sprite2D = child_node as Sprite2D
		if sprite != null:
			sprite.visible = false


func _build_surface() -> void:
	# User-supplied map art is a complete 16:9 composition. Keep it in screen
	# space so camera movement/zoom never crops or stretches that composition.
	_surface_layer = CanvasLayer.new()
	_surface_layer.name = "MapBackgroundLayer"
	_surface_layer.layer = -100
	_surface_layer.follow_viewport_enabled = false
	add_child(_surface_layer)

	_surface_fill = ColorRect.new()
	_surface_fill.name = "MapBackgroundFill"
	_surface_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_surface_layer.add_child(_surface_fill)

	_surface = TextureRect.new()
	_surface.name = "MapBackgroundTexture"
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_surface.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	# KEEP_ASPECT_CENTERED is deliberately used instead of COVERED: the complete
	# 16:9 image is always visible and is never center-cropped/zoomed.
	_surface.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_surface.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_surface.texture = get_surface_variant_texture(0)
	_surface_layer.add_child(_surface)

	_sync_surface_to_viewport()
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_sync_surface_to_viewport):
		viewport.size_changed.connect(_sync_surface_to_viewport)


func _sync_surface_to_viewport() -> void:
	if _surface == null or _surface_fill == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	_surface_fill.position = Vector2.ZERO
	_surface_fill.size = viewport_size
	_surface.position = Vector2.ZERO
	_surface.size = viewport_size


func _apply_variant(variant_index: int) -> void:
	if _surface == null:
		return
	var theme: Dictionary = get_variant_theme(variant_index)
	var surface_alpha := clampf(color_strength / 0.92, 0.55, 1.0)
	var surface_brightness := clampf(float(theme.get("surface_brightness", 1.0)), 0.0, 1.0)
	_surface.texture = get_surface_variant_texture(variant_index)
	_surface.modulate = Color(
		surface_brightness,
		surface_brightness,
		surface_brightness,
		surface_alpha
	)
	if _surface_fill != null:
		var fill_color := get_variant_tint(variant_index).darkened(0.46)
		fill_color.a = 1.0
		_surface_fill.color = fill_color
