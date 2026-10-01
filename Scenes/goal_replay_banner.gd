class_name FootballGoalReplayBanner
extends Control


const MIN_PRESENTATION_WIDTH: float = 468.0
const MAX_PRESENTATION_WIDTH: float = 720.0
const VIEWPORT_WIDTH_RATIO: float = 0.432
const TALL_PRESENTATION_HEIGHT: float = 113.0
const COMPACT_PRESENTATION_HEIGHT: float = 98.0


var banner_id: String = "player_banner.classic"
var team: StringName = &""
var banner_color_index: int = FootballCosmeticInventory.PLAYER_SKIN_ORIGINAL_COLOR
var show_shadow: bool = false
var show_text_overlay: bool = false
var draw_inset: float = 8.0
var _banner_texture: Texture2D
var _animation_time: float = 0.0


static func presentation_size(viewport_size: Vector2) -> Vector2:
	var banner_width := minf(
		clampf(
			viewport_size.x * VIEWPORT_WIDTH_RATIO,
			MIN_PRESENTATION_WIDTH,
			MAX_PRESENTATION_WIDTH
		),
		viewport_size.x - 36.0
	)
	var banner_height := (
		TALL_PRESENTATION_HEIGHT
		if viewport_size.y >= 800.0
		else COMPACT_PRESENTATION_HEIGHT
	)
	return Vector2(banner_width, banner_height)


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_animation_time = fmod(_animation_time + delta, 60.0)
	queue_redraw()


func set_presentation(
	selected_banner_id: String,
	scoring_team: StringName,
	selected_color_index: int = FootballCosmeticInventory.PLAYER_SKIN_ORIGINAL_COLOR
) -> void:
	banner_id = selected_banner_id
	team = scoring_team
	banner_color_index = FootballCosmeticInventory.sanitize_player_banner_color_index(
		selected_color_index
	)
	_animation_time = 0.0
	var catalog_item: Dictionary = FootballCosmeticInventory.CATALOG.get(
		banner_id,
		{}
	) as Dictionary
	var display_item: Dictionary = FootballCosmeticInventory.apply_player_banner_color(
		catalog_item,
		banner_color_index
	)
	_banner_texture = FootballPlayerBannerVisuals.load_image(display_item)
	queue_redraw()


func _draw() -> void:
	var draw_bounds: Rect2 = Rect2(Vector2.ZERO, size)
	if draw_bounds.size.x <= 0.0 or draw_bounds.size.y <= 0.0:
		return
	var team_color: Color = (
		Color(1.0, 0.22, 0.29, 1.0)
		if team == &"red"
		else Color(0.24, 0.62, 1.0, 1.0)
	)
	var base_item: Dictionary = FootballCosmeticInventory.CATALOG.get(banner_id, {}) as Dictionary
	var catalog_item: Dictionary = FootballCosmeticInventory.apply_player_banner_color(
		base_item,
		banner_color_index
	)
	FootballPlayerBannerVisuals.draw_banner(
		self,
		draw_bounds.grow(-maxf(0.0, draw_inset)),
		catalog_item,
		team_color,
		true,
		_banner_texture,
		_animation_time,
		show_shadow
	)
	if show_text_overlay:
		draw_rect(
			Rect2(
				Vector2(draw_bounds.position.x + draw_bounds.size.x * 0.46, draw_bounds.position.y + 10.0),
				Vector2(draw_bounds.size.x * 0.52 - 10.0, draw_bounds.size.y - 20.0)
			),
			Color(0.008, 0.01, 0.014, 0.72),
			true
		)
